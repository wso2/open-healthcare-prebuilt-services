package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/ig"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// ─── FHIR content type ────────────────────────────────────────────────────────

const fhirJSON = "application/fhir+json"

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", fhirJSON)
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(body)
}

func operationOutcome(w http.ResponseWriter, status int, severity, code, diagnostics string) {
	writeJSON(w, status, map[string]any{
		"resourceType": "OperationOutcome",
		"issue": []any{map[string]any{
			"severity":    severity,
			"code":        code,
			"diagnostics": diagnostics,
		}},
	})
}

func readBody(r *http.Request) (map[string]any, error) {
	var body map[string]any
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		return nil, err
	}
	return body, nil
}

// ─── Read ─────────────────────────────────────────────────────────────────────

func (h *fhirHandler) read(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")

	resource, err := h.store.Read(r.Context(), rt, id)
	if err != nil {
		handleError(w, err)
		return
	}
	w.Header().Set("ETag", fmt.Sprintf(`W/"%s"`, versionFromMeta(resource)))
	writeJSON(w, http.StatusOK, resource)
}

// ─── VRead ────────────────────────────────────────────────────────────────────

func (h *fhirHandler) vread(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")
	vid, err := strconv.Atoi(chi.URLParam(r, "vid"))
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "version id must be an integer")
		return
	}

	resource, err := h.store.GetVersion(r.Context(), rt, id, vid)
	if err != nil {
		handleError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, resource)
}

// ─── Search ───────────────────────────────────────────────────────────────────

func (h *fhirHandler) search(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")

	params := map[string][]string{}
	for k, vs := range r.URL.Query() {
		params[k] = vs
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("_page"))
	pageSize, _ := strconv.Atoi(r.URL.Query().Get("_count"))

	result, err := h.store.Search(r.Context(), store.SearchParams{
		ResourceType: rt,
		Params:       params,
		Page:         page,
		PageSize:     pageSize,
	})
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	bundle := h.buildBundle(rt, result, params, page, pageSize)
	writeJSON(w, http.StatusOK, bundle)
}

func (h *fhirHandler) buildBundle(rt string, result store.SearchResult, params map[string][]string, page, pageSize int) map[string]any {
	if pageSize <= 0 {
		pageSize = 20
	}
	if page <= 0 {
		page = 1
	}

	entries := make([]any, 0, len(result.Entries)+len(result.Included))
	for _, res := range result.Entries {
		id, _ := res["id"].(string)
		entries = append(entries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, rt, id),
			"resource": res,
			"search":   map[string]any{"mode": "match"},
		})
	}
	for _, res := range result.Included {
		inclRT, _ := res["resourceType"].(string)
		id, _ := res["id"].(string)
		entries = append(entries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, inclRT, id),
			"resource": res,
			"search":   map[string]any{"mode": "include"},
		})
	}

	return map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"total":        result.Total,
		"link": []any{
			map[string]any{"relation": "self", "url": fmt.Sprintf("%s/%s?_page=%d&_count=%d", h.baseURL, rt, page, pageSize)},
			map[string]any{"relation": "first", "url": fmt.Sprintf("%s/%s?_page=1&_count=%d", h.baseURL, rt, pageSize)},
		},
		"entry": entries,
	}
}

// ─── $everything ──────────────────────────────────────────────────────────────

func (h *fhirHandler) everything(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")
	since := r.URL.Query().Get("_since")
	typeFilter := r.URL.Query()["_type"]

	// Read the anchor resource
	anchor, err := h.store.Read(r.Context(), rt, id)
	if err != nil {
		handleError(w, err)
		return
	}

	entries := []any{map[string]any{
		"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, rt, id),
		"resource": anchor,
		"search":   map[string]any{"mode": "match"},
	}}

	// Forward references (resources this resource points to)
	forward, err := h.store.FetchReferences(r.Context(), rt, id, false)
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	// Reverse references (resources that point to this resource)
	reverse, err := h.store.FetchReferences(r.Context(), rt, id, true)
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	seen := map[string]bool{rt + "/" + id: true}
	for _, res := range append(forward, reverse...) {
		inclRT, _ := res["resourceType"].(string)
		inclID, _ := res["id"].(string)
		key := inclRT + "/" + inclID

		if seen[key] {
			continue
		}
		if since != "" {
			if lu := lastUpdatedStr(res); lu != "" && lu <= since {
				continue
			}
		}
		if len(typeFilter) > 0 && !containsStr(typeFilter, inclRT) {
			continue
		}

		seen[key] = true
		entries = append(entries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, inclRT, inclID),
			"resource": res,
			"search":   map[string]any{"mode": "include"},
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"total":        len(entries),
		"entry":        entries,
	})
}

// ─── Create ───────────────────────────────────────────────────────────────────

func (h *fhirHandler) create(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	resource, err := h.store.Create(r.Context(), rt, body)
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	if rt == "SearchParameter" {
		if err := h.store.SyncSearchParameter(r.Context(), resource); err != nil {
			// Non-fatal — log and continue
			_ = err
		}
	}

	id, _ := resource["id"].(string)
	w.Header().Set("Location", fmt.Sprintf("%s/%s/%s/_history/1", h.baseURL, rt, id))
	w.Header().Set("ETag", `W/"1"`)
	writeJSON(w, http.StatusCreated, resource)
}

// ─── Update ───────────────────────────────────────────────────────────────────

func (h *fhirHandler) update(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	resource, err := h.store.Update(r.Context(), rt, id, body)
	if err != nil {
		handleError(w, err)
		return
	}

	if rt == "SearchParameter" {
		_ = h.store.SyncSearchParameter(r.Context(), resource)
	}

	w.Header().Set("ETag", fmt.Sprintf(`W/"%s"`, versionFromMeta(resource)))
	writeJSON(w, http.StatusOK, resource)
}

// ─── Patch ────────────────────────────────────────────────────────────────────

func (h *fhirHandler) patch(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	resource, err := h.store.Patch(r.Context(), rt, id, body)
	if err != nil {
		handleError(w, err)
		return
	}
	w.Header().Set("ETag", fmt.Sprintf(`W/"%s"`, versionFromMeta(resource)))
	writeJSON(w, http.StatusOK, resource)
}

// ─── Delete ───────────────────────────────────────────────────────────────────

func (h *fhirHandler) delete(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")

	if rt == "SearchParameter" {
		_ = h.store.DeleteSearchParameter(r.Context(), id)
	}

	if err := h.store.Delete(r.Context(), rt, id); err != nil {
		handleError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ─── History ──────────────────────────────────────────────────────────────────

func (h *fhirHandler) history(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")

	entries, err := h.store.GetHistory(r.Context(), rt, id)
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	bundleEntries := make([]any, 0, len(entries))
	for _, e := range entries {
		rid, _ := e.Resource["id"].(string)
		bundleEntries = append(bundleEntries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s/_history/%d", h.baseURL, rt, rid, e.VersionID),
			"resource": e.Resource,
			"request":  map[string]any{"method": e.Operation, "url": fmt.Sprintf("%s/%s/%s", h.baseURL, rt, rid)},
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "history",
		"total":        len(bundleEntries),
		"entry":        bundleEntries,
	})
}

func (h *fhirHandler) typeHistory(w http.ResponseWriter, r *http.Request) {
	// Type-level history — return 501 for now
	operationOutcome(w, http.StatusNotImplemented, "information", "not-supported", "type-level _history not yet implemented")
}

// ─── Metadata ─────────────────────────────────────────────────────────────────

func (h *fhirHandler) metadata(w http.ResponseWriter, r *http.Request) {
	packages, _ := ig.LoadedPackages(r.Context(), h.pool)
	profiles, _ := ig.SupportedProfiles(r.Context(), h.pool)

	// Build implementationGuide list
	igURLs := make([]string, 0, len(packages))
	for _, p := range packages {
		igURLs = append(igURLs, fmt.Sprintf("http://hl7.org/fhir/ig/%s/%s", p.Name, p.Version))
	}

	// Build rest.resource list with supportedProfile entries
	fhirResourceTypes := []string{
		"Patient", "Practitioner", "Organization", "Observation", "Condition",
		"Encounter", "MedicationRequest", "DiagnosticReport", "Procedure",
		"AllergyIntolerance", "Immunization", "Coverage", "Claim", "ExplanationOfBenefit",
	}
	resources := make([]any, 0, len(fhirResourceTypes))
	for _, rt := range fhirResourceTypes {
		entry := map[string]any{
			"type": rt,
			"interaction": []any{
				map[string]any{"code": "read"},
				map[string]any{"code": "vread"},
				map[string]any{"code": "update"},
				map[string]any{"code": "patch"},
				map[string]any{"code": "delete"},
				map[string]any{"code": "create"},
				map[string]any{"code": "search-type"},
			},
			"versioning":       "versioned",
			"readHistory":      true,
			"updateCreate":     false,
			"conditionalCreate": false,
		}
		if profs, ok := profiles[rt]; ok && len(profs) > 0 {
			entry["supportedProfile"] = profs
		}
		resources = append(resources, entry)
	}

	cs := map[string]any{
		"resourceType":        "CapabilityStatement",
		"status":              "active",
		"kind":                "instance",
		"fhirVersion":         "4.0.1",
		"format":              []string{"application/fhir+json"},
		"implementationGuide": igURLs,
		"software": map[string]any{
			"name":    "open-healthcare-fhir-server-go",
			"version": "1.0.0",
		},
		"rest": []any{map[string]any{
			"mode":      "server",
			"resource":  resources,
			"operation": []any{map[string]any{"name": "everything", "definition": "http://hl7.org/fhir/OperationDefinition/Patient-everything"}},
		}},
	}
	writeJSON(w, http.StatusOK, cs)
}

// ─── Helpers for $everything ──────────────────────────────────────────────────

func lastUpdatedStr(res map[string]any) string {
	if meta, ok := res["meta"].(map[string]any); ok {
		if lu, ok := meta["lastUpdated"].(string); ok {
			return lu
		}
	}
	return ""
}

func containsStr(ss []string, s string) bool {
	for _, v := range ss {
		if v == s {
			return true
		}
	}
	return false
}

// ─── Error handling ───────────────────────────────────────────────────────────

func handleError(w http.ResponseWriter, err error) {
	var notFound store.NotFoundError
	if errors.As(err, &notFound) {
		operationOutcome(w, http.StatusNotFound, "error", "not-found", err.Error())
		return
	}
	operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
}

func versionFromMeta(resource map[string]any) string {
	if meta, ok := resource["meta"].(map[string]any); ok {
		if v, ok := meta["versionId"].(string); ok {
			return v
		}
	}
	return "1"
}
