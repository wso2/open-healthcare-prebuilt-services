package handler

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// everythingType implements type-level $everything (GET /{type}/$everything for
// Patient/Encounter/Group). It unions the per-instance closures of every
// instance of the type. Only the three compartment-owner types support it.
func (h *fhirHandler) everythingType(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	switch rt {
	case "Patient", "Encounter", "Group":
	default:
		operationOutcome(w, http.StatusNotFound, "error", "not-supported",
			fmt.Sprintf("$everything is not supported at type level for %s", rt))
		return
	}

	// Fetch all instances of the type (bounded page — $everything across an
	// entire type is inherently large; we cap to avoid unbounded responses).
	anchors, err := h.store.Search(r.Context(), store.SearchParams{
		ResourceType: rt, Page: 1, PageSize: 1000,
	})
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	seen := map[string]bool{}
	var entries []any
	add := func(res map[string]any, mode string) {
		irt, _ := res["resourceType"].(string)
		iid, _ := res["id"].(string)
		key := irt + "/" + iid
		if irt == "" || iid == "" || seen[key] {
			return
		}
		seen[key] = true
		entries = append(entries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, irt, iid),
			"resource": res,
			"search":   map[string]any{"mode": mode},
		})
	}

	for _, anchor := range anchors.Entries {
		id, _ := anchor["id"].(string)
		if id == "" {
			continue
		}
		add(anchor, "match")
		fwd, err := h.store.FetchReferences(r.Context(), rt, id, false)
		if err != nil {
			operationOutcome(w, http.StatusInternalServerError, "error", "exception", "forward reference fetch failed: "+err.Error())
			return
		}
		rev, err := h.store.FetchReferences(r.Context(), rt, id, true)
		if err != nil {
			operationOutcome(w, http.StatusInternalServerError, "error", "exception", "reverse reference fetch failed: "+err.Error())
			return
		}
		for _, res := range append(fwd, rev...) {
			add(res, "include")
		}
	}

	writeFHIR(w, r, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"total":        len(entries),
		"entry":        entries,
	})
}

// lastN implements Observation/$lastn (type level): the most recent N
// observations per code group, optionally filtered by patient/category. max
// defaults to 1.
func (h *fhirHandler) lastN(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	if rt != "Observation" {
		operationOutcome(w, http.StatusNotFound, "error", "not-supported",
			fmt.Sprintf("$lastn is only defined for Observation, not %s", rt))
		return
	}
	q := r.URL.Query()
	maxN := 1
	if m := q.Get("max"); m != "" {
		if n, err := strconv.Atoi(m); err == nil && n > 0 {
			maxN = n
		}
	}

	// Pass the supported filters to the store, which does per-code top-N with a
	// window function (correct regardless of overall volume).
	params := map[string][]string{}
	for _, p := range []string{"patient", "subject", "category", "code"} {
		if v := q[p]; len(v) > 0 {
			params[p] = v
		}
	}

	result, err := h.store.LastN(r.Context(), params, maxN)
	if err != nil {
		var unsup *store.UnsupportedParamError
		if errors.As(err, &unsup) {
			operationOutcome(w, http.StatusBadRequest, "error", "not-supported", unsup.Msg)
			return
		}
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	entries := make([]any, 0, len(result.Entries))
	for _, obs := range result.Entries {
		id, _ := obs["id"].(string)
		entries = append(entries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/Observation/%s", h.baseURL, id),
			"resource": obs,
			"search":   map[string]any{"mode": "match"},
		})
	}

	writeFHIR(w, r, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"total":        len(entries),
		"entry":        entries,
	})
}

// document implements Composition/{id}/$document (instance level): assembles a
// document Bundle with the Composition first, then the resources it references.
func (h *fhirHandler) document(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")
	if rt != "Composition" {
		operationOutcome(w, http.StatusNotFound, "error", "not-supported",
			fmt.Sprintf("$document is only defined for Composition, not %s", rt))
		return
	}

	comp, err := h.store.Read(r.Context(), rt, id)
	if err != nil {
		handleError(w, err)
		return
	}

	entries := []any{map[string]any{
		"fullUrl":  fmt.Sprintf("%s/Composition/%s", h.baseURL, id),
		"resource": comp,
	}}
	seen := map[string]bool{"Composition/" + id: true}

	// Transitive closure: BFS over forward references starting from the
	// Composition, so the document Bundle is self-contained (Composition →
	// Encounter → Patient → …). Bounded to avoid runaway closures.
	type ref struct{ rt, id string }
	queue := []ref{{rt, id}}
	const maxDocResources = 500
	for len(queue) > 0 && len(entries) < maxDocResources {
		cur := queue[0]
		queue = queue[1:]
		refs, err := h.store.FetchReferences(r.Context(), cur.rt, cur.id, false)
		if err != nil {
			operationOutcome(w, http.StatusInternalServerError, "error", "exception", "document assembly failed: "+err.Error())
			return
		}
		for _, res := range refs {
			irt, _ := res["resourceType"].(string)
			iid, _ := res["id"].(string)
			key := irt + "/" + iid
			if irt == "" || iid == "" || seen[key] {
				continue
			}
			seen[key] = true
			entries = append(entries, map[string]any{
				"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, irt, iid),
				"resource": res,
			})
			queue = append(queue, ref{irt, iid})
		}
	}

	// A document Bundle requires a persistent identifier and a timestamp.
	writeFHIR(w, r, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "document",
		"identifier":   map[string]any{"system": "urn:ietf:rfc:3986", "value": "urn:uuid:" + uuid.NewString()},
		"timestamp":    time.Now().UTC().Format(time.RFC3339),
		"entry":        entries,
	})
}
