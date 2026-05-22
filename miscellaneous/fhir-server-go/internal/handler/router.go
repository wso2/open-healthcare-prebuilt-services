package handler

import (
	"net/http"
	"sync/atomic"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
)

func NewRouter(s StoreAPI, pool *pgxpool.Pool, baseURL string, igReady *atomic.Int32) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RealIP)
	r.Use(middleware.RequestID)
	r.Use(middleware.Recoverer)

	h := &fhirHandler{store: s, pool: pool, baseURL: baseURL, igReady: igReady}

	// Health probes
	r.Get("/health/live", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
	r.Get("/health/ready", func(w http.ResponseWriter, _ *http.Request) {
		if igReady.Load() == 1 {
			w.WriteHeader(http.StatusOK)
		} else {
			w.WriteHeader(http.StatusServiceUnavailable)
		}
	})

	r.Route("/fhir/r4", func(r chi.Router) {
		// Capability statement
		r.Get("/metadata", h.metadata)

		// Per-resource-type routes
		r.Route("/{resourceType}", func(r chi.Router) {
			r.Get("/", h.search)
			r.Post("/", h.create)
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
			})
		})
	})

	return r
}

type fhirHandler struct {
	store   StoreAPI
	pool    *pgxpool.Pool
	baseURL string
	igReady *atomic.Int32
}
