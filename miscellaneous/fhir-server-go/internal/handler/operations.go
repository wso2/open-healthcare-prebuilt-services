package handler

import (
	"errors"
	"fmt"
	"net/http"
	"sort"
	"strconv"

	"github.com/go-chi/chi/v5"
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
		fwd, _ := h.store.FetchReferences(r.Context(), rt, id, false)
		rev, _ := h.store.FetchReferences(r.Context(), rt, id, true)
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

	// Build the underlying search from the supported filter params.
	params := map[string][]string{}
	for _, p := range []string{"patient", "subject", "category", "code"} {
		if v := q[p]; len(v) > 0 {
			params[p] = v
		}
	}
	// Sort newest-first so the first maxN per group are the most recent.
	params["_sort"] = []string{"-date"}

	result, err := h.store.Search(r.Context(), store.SearchParams{
		ResourceType: "Observation", Params: params, Page: 1, PageSize: 1000,
	})
	if err != nil {
		var unsup *store.UnsupportedParamError
		if errors.As(err, &unsup) {
			operationOutcome(w, http.StatusBadRequest, "error", "not-supported", unsup.Msg)
			return
		}
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	// Group by the observation's code (system|code of the first coding) and keep
	// the most recent maxN in each group (entries are already date-desc).
	groupCount := map[string]int{}
	var entries []any
	for _, obs := range result.Entries {
		key := observationCodeKey(obs)
		if groupCount[key] >= maxN {
			continue
		}
		groupCount[key]++
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

// observationCodeKey returns a stable grouping key from Observation.code's
// first coding (system|code), falling back to code.text.
func observationCodeKey(obs map[string]any) string {
	code, _ := obs["code"].(map[string]any)
	if code == nil {
		return ""
	}
	if codings, ok := code["coding"].([]any); ok {
		// Sort coding keys so multiple codings yield a deterministic group key.
		var keys []string
		for _, c := range codings {
			cm, _ := c.(map[string]any)
			if cm == nil {
				continue
			}
			sys, _ := cm["system"].(string)
			cd, _ := cm["code"].(string)
			keys = append(keys, sys+"|"+cd)
		}
		sort.Strings(keys)
		if len(keys) > 0 {
			return keys[0]
		}
	}
	if txt, ok := code["text"].(string); ok {
		return "text:" + txt
	}
	return ""
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

	// Pull in everything the Composition references (subject, author, sections, …).
	refs, _ := h.store.FetchReferences(r.Context(), rt, id, false)
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
	}

	writeFHIR(w, r, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "document",
		"entry":        entries,
	})
}
