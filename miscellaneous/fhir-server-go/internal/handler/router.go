package handler

import (
	"net/http"
	"sync/atomic"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/obs"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
)

// NewRouter constructs the chi router. validateOnWrite enables profile
// validation on create/update (default off in production; controlled by
// FHIR_VALIDATE_ON_WRITE).
func NewRouter(s StoreAPI, pool *pgxpool.Pool, registry *searchparam.Registry, baseURL string, igReady *atomic.Int32, validateOnWrite ...bool) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RealIP)
	r.Use(middleware.RequestID)
	r.Use(middleware.Recoverer)
	r.Use(obs.Middleware)

	// Prometheus metrics endpoint — outside the FHIR base path so it can be
	// scraped without traversing the FHIR middleware stack.
	r.Get("/metrics", obs.MetricsHandler().ServeHTTP)

	vow := len(validateOnWrite) > 0 && validateOnWrite[0]
	h := &fhirHandler{store: s, pool: pool, registry: registry, baseURL: baseURL, igReady: igReady, validateOnWrite: vow}

	// Health probes
	r.Get("/health/live", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	r.Get("/health/ready", func(w http.ResponseWriter, _ *http.Request) {
		if igReady != nil && igReady.Load() == 1 {
			w.WriteHeader(http.StatusOK)
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
		}
	})

	// System-level transaction / batch Bundle, posted to the FHIR base. Registered
	// without a trailing slash here and with one below so both /fhir/r4 and
	// /fhir/r4/ are accepted.
	r.Post("/fhir/r4", h.bundle)

	r.Route("/fhir/r4", func(r chi.Router) {
		// Capability statement
		r.Get("/metadata", h.metadata)

		// System-level history
		r.Get("/_history", h.systemHistory)

		// System-level transaction / batch Bundle (trailing-slash form)
		r.Post("/", h.bundle)

		// Per-resource-type routes
		r.Route("/{resourceType}", func(r chi.Router) {
			r.Get("/", h.search)
			r.Post("/", h.create)
			r.Put("/", h.conditionalUpdate)    // PUT /{type}?<search>
			r.Delete("/", h.conditionalDelete) // DELETE /{type}?<search>
			r.Post("/_search", h.searchPost)
			r.Post("/$validate", h.validate)
			r.Get("/_history", h.typeHistory)

			r.Route("/{id}", func(r chi.Router) {
				r.Get("/", h.read)
				r.Put("/", h.update)
				r.Patch("/", h.patch)
				r.Delete("/", h.delete)
				r.Get("/_history", h.history)
				r.Get("/_history/{vid}", h.vread)
				r.Get("/$everything", h.everything)

				// Compartment search: /Patient/{id}/Observation etc.
				// Determined at runtime by checking if the URL's resourceType
				// is a known compartment type.
				r.Get("/{targetResourceType}", h.compartmentSearch)
			})
		})
	})

	return r
}

type fhirHandler struct {
	store           StoreAPI
	pool            *pgxpool.Pool
	registry        *searchparam.Registry
	baseURL         string
	igReady         *atomic.Int32
	validateOnWrite bool // enforce profile validation on create/update when true
}
