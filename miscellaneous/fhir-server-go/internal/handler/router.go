package handler

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

func NewRouter(s *store.Store, baseURL string) http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RealIP)
	r.Use(middleware.RequestID)
	r.Use(middleware.Recoverer)

	h := &fhirHandler{store: s, baseURL: baseURL}

	r.Route("/fhir/r4", func(r chi.Router) {
		// Capability statement
		r.Get("/metadata", h.metadata)

		// Per-resource-type routes
		r.Route("/{resourceType}", func(r chi.Router) {
			r.Get("/", h.search)
			r.Post("/", h.create)
			r.Get("/_history", h.typeHistory)

			r.Route("/{id}", func(r chi.Router) {
				r.Get("/", h.read)
				r.Put("/", h.update)
				r.Patch("/", h.patch)
				r.Delete("/", h.delete)
				r.Get("/_history", h.history)
				r.Get("/_history/{vid}", h.vread)
			})
		})
	})

	return r
}

type fhirHandler struct {
	store   *store.Store
	baseURL string
}
