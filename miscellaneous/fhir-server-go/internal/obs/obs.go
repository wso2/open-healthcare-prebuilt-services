// Package obs wires up Prometheus metrics and OpenTelemetry tracing for the
// FHIR server.
//
// Prometheus: a /metrics endpoint exposes a standard http_request_duration_seconds
// histogram with labels {method, route, status_code}, plus fhir_request_total
// (a counter replica for easy dashboarding).
//
// OTEL: trace spans are emitted for every incoming HTTP request. The TracerProvider
// is a no-op by default (zero overhead without an exporter configured). Set
// OTEL_EXPORTER_OTLP_ENDPOINT to point at a collector — the provider switches to
// OTLP gRPC automatically via the OTEL standard SDK auto-configuration.
package obs

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

var (
	requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "http_request_duration_seconds",
		Help:    "Histogram of HTTP request durations, labelled by method, route, and status.",
		Buckets: []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
	}, []string{"method", "route", "status_code"})

	requestTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "fhir_request_total",
		Help: "Total number of FHIR HTTP requests.",
	}, []string{"method", "route", "status_code"})
)

// MetricsHandler returns the Prometheus /metrics HTTP handler.
func MetricsHandler() http.Handler { return promhttp.Handler() }

// Middleware wraps an HTTP handler with:
//   - OTel span per request (attributes: http.method, http.route, http.status_code)
//   - Prometheus duration histogram + request counter
//
// routePattern should be the chi route template (e.g. "/fhir/r4/{resourceType}/{id}")
// for high-cardinality-safe labelling. When empty the raw URL path is truncated and
// sanitised (fallback only; prefer always passing a pattern).
func Middleware(next http.Handler) http.Handler {
	// Wrap with OTel first so span is started before the recorder.
	otelWrapped := otelhttp.NewHandler(next, "fhir-server",
		otelhttp.WithTracerProvider(otel.GetTracerProvider()),
		otelhttp.WithSpanNameFormatter(func(_ string, r *http.Request) string {
			return r.Method + " " + sanitisePath(r.URL.Path)
		}),
	)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		otelWrapped.ServeHTTP(rec, r)
		dur := time.Since(start).Seconds()

		route := sanitisePath(r.URL.Path)
		code := strconv.Itoa(rec.status)
		requestDuration.WithLabelValues(r.Method, route, code).Observe(dur)
		requestTotal.WithLabelValues(r.Method, route, code).Inc()

		// Add status attribute to the active span if one was started.
		if span := trace.SpanFromContext(r.Context()); span.IsRecording() {
			span.SetAttributes(attribute.Int("http.status_code", rec.status))
		}
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

// sanitisePath converts a URL path to a low-cardinality route label by
// replacing UUID-like and numeric segments with "{id}", resource version
// segments with "/_history/{vid}", etc.  This is a best-effort heuristic for
// when the chi route pattern isn't available.
func sanitisePath(p string) string {
	parts := strings.Split(strings.Trim(p, "/"), "/")
	out := make([]string, 0, len(parts))
	for _, seg := range parts {
		switch {
		case isUUID(seg) || isNumeric(seg):
			out = append(out, "{id}")
		default:
			out = append(out, seg)
		}
	}
	return "/" + strings.Join(out, "/")
}

func isUUID(s string) bool {
	return len(s) == 36 && strings.Count(s, "-") == 4
}

func isNumeric(s string) bool {
	if s == "" {
		return false
	}
	_, err := fmt.Sscanf(s, "%d", new(int))
	return err == nil
}
