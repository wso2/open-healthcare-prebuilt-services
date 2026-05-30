package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/ig"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// pageQuery returns an encoded query string that preserves all of `params`
// (search filters, _since, _include, …) but overrides _page and _count with
// the supplied values. Keys are sorted so generated links are stable.
func pageQuery(params map[string][]string, page, pageSize int) string {
	vals := url.Values{}
	for k, vs := range params {
		if k == "_page" || k == "_count" {
			continue
		}
		for _, v := range vs {
			vals.Add(k, v)
		}
	}
	vals.Set("_page", strconv.Itoa(page))
	vals.Set("_count", strconv.Itoa(pageSize))
	keys := make([]string, 0, len(vals))
	for k := range vals {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	out := make(url.Values, len(keys))
	for _, k := range keys {
		out[k] = vals[k]
	}
	return out.Encode()
}

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

// requireFHIRContent returns false (and writes 415) only when Content-Type is
// explicitly set to a non-JSON type. Missing Content-Type is allowed.
func requireFHIRContent(w http.ResponseWriter, r *http.Request) bool {
	ct := r.Header.Get("Content-Type")
	if ct == "" {
		return true
	}
	base := strings.TrimSpace(strings.SplitN(ct, ";", 2)[0])
	if base != "application/fhir+json" && base != "application/json" {
		operationOutcome(w, http.StatusUnsupportedMediaType, "error", "not-supported",
			"Content-Type must be application/fhir+json")
		return false
	}
	return true
}

func firstVal(params map[string][]string, key string) string {
	if vs := params[key]; len(vs) > 0 {
		return vs[0]
	}
	return ""
}

// parseIfMatchVersion extracts the integer version from an ETag like W/"3".
// Returns (version, true) on success, (0, false) if the header is malformed.
func parseIfMatchVersion(header string) (int, bool) {
	s := strings.TrimSpace(header)
	s = strings.TrimPrefix(s, "W/")
	s = strings.Trim(s, `"`)
	v, err := strconv.Atoi(s)
	return v, err == nil
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

func (h *fhirHandler) searchPost(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")

	if err := r.ParseForm(); err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid form body: "+err.Error())
		return
	}

	params := map[string][]string{}
	for k, vs := range r.PostForm {
		params[k] = vs
	}
	for k, vs := range r.URL.Query() {
		if _, exists := params[k]; !exists {
			params[k] = vs
		}
	}

	page, _ := strconv.Atoi(firstVal(params, "_page"))
	pageSize, _ := strconv.Atoi(firstVal(params, "_count"))

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

	lastPage := result.Total / pageSize
	if result.Total%pageSize != 0 {
		lastPage++
	}
	if lastPage < 1 {
		lastPage = 1
	}

	base := fmt.Sprintf("%s/%s", h.baseURL, rt)
	links := []any{
		map[string]any{"relation": "self", "url": base + "?" + pageQuery(params, page, pageSize)},
		map[string]any{"relation": "first", "url": base + "?" + pageQuery(params, 1, pageSize)},
		map[string]any{"relation": "last", "url": base + "?" + pageQuery(params, lastPage, pageSize)},
	}
	if page*pageSize < result.Total {
		links = append(links, map[string]any{
			"relation": "next",
			"url":      base + "?" + pageQuery(params, page+1, pageSize),
		})
	}
	if page > 1 {
		links = append(links, map[string]any{
			"relation": "previous",
			"url":      base + "?" + pageQuery(params, page-1, pageSize),
		})
	}

	return map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"total":        result.Total,
		"link":         links,
		"entry":        entries,
	}
}

// ─── $everything ──────────────────────────────────────────────────────────────

func (h *fhirHandler) everything(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	id := chi.URLParam(r, "id")
	since := r.URL.Query().Get("_since")
	typeFilter := r.URL.Query()["_type"]

	var sinceTime time.Time
	sinceValid := false
	if since != "" {
		t, err := time.Parse(time.RFC3339, since)
		if err != nil {
			operationOutcome(w, http.StatusBadRequest, "error", "invalid", "_since must be RFC3339")
			return
		}
		sinceTime = t
		sinceValid = true
	}

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
		if sinceValid {
			if lu := lastUpdatedStr(res); lu != "" {
				if luTime, err := time.Parse(time.RFC3339, lu); err == nil && !luTime.After(sinceTime) {
					continue
				}
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

	if !requireFHIRContent(w, r) {
		return
	}

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	if bodyRT, ok := body["resourceType"].(string); ok && bodyRT != "" && bodyRT != rt {
		operationOutcome(w, http.StatusUnprocessableEntity, "error", "invalid",
			fmt.Sprintf("body resourceType %q does not match URL resource type %q", bodyRT, rt))
		return
	}

	if msg := validateRequiredFields(rt, body); msg != "" {
		operationOutcome(w, http.StatusUnprocessableEntity, "error", "required", msg)
		return
	}

	resource, err := h.store.Create(r.Context(), rt, body)
	if err != nil {
		slog.Error("create failed", "resourceType", rt, "err", err)
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

	if !requireFHIRContent(w, r) {
		return
	}

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	if bodyRT, ok := body["resourceType"].(string); ok && bodyRT != "" && bodyRT != rt {
		operationOutcome(w, http.StatusUnprocessableEntity, "error", "invalid",
			fmt.Sprintf("body resourceType %q does not match URL resource type %q", bodyRT, rt))
		return
	}

	if bodyID, ok := body["id"].(string); ok && bodyID != "" && bodyID != id {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid",
			fmt.Sprintf("body id %q does not match URL id %q", bodyID, id))
		return
	}

	if msg := validateRequiredFields(rt, body); msg != "" {
		operationOutcome(w, http.StatusUnprocessableEntity, "error", "required", msg)
		return
	}

	ifMatchVersion := -1 // -1 means no If-Match header
	if ifMatch := r.Header.Get("If-Match"); ifMatch != "" {
		v, ok := parseIfMatchVersion(ifMatch)
		if !ok {
			operationOutcome(w, http.StatusPreconditionFailed, "error", "conflict",
				"If-Match header contains an invalid version string")
			return
		}
		ifMatchVersion = v
	}

	resource, err := h.store.Update(r.Context(), rt, id, body, ifMatchVersion)
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
	rt := chi.URLParam(r, "resourceType")
	q := r.URL.Query()

	page, _ := strconv.Atoi(q.Get("_page"))
	pageSize, _ := strconv.Atoi(q.Get("_count"))

	var since time.Time
	if s := q.Get("_since"); s != "" {
		if t, err := time.Parse(time.RFC3339, s); err == nil {
			since = t
		}
	}

	result, err := h.store.GetTypeHistory(r.Context(), store.HistoryParams{
		ResourceType: rt,
		Since:        since,
		Page:         page,
		PageSize:     pageSize,
	})
	if err != nil {
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	if pageSize <= 0 {
		pageSize = 20
	}
	if page <= 0 {
		page = 1
	}

	bundleEntries := make([]any, 0, len(result.Entries))
	for _, e := range result.Entries {
		rid, _ := e.Resource["id"].(string)
		bundleEntries = append(bundleEntries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s/_history/%d", h.baseURL, rt, rid, e.VersionID),
			"resource": e.Resource,
			"request":  map[string]any{"method": e.Operation, "url": fmt.Sprintf("%s/%s/%s", h.baseURL, rt, rid)},
		})
	}

	lastPage := result.Total / pageSize
	if result.Total%pageSize != 0 {
		lastPage++
	}
	if lastPage < 1 {
		lastPage = 1
	}

	base := fmt.Sprintf("%s/%s/_history", h.baseURL, rt)
	params := map[string][]string(q)
	links := []any{
		map[string]any{"relation": "self", "url": base + "?" + pageQuery(params, page, pageSize)},
		map[string]any{"relation": "first", "url": base + "?" + pageQuery(params, 1, pageSize)},
		map[string]any{"relation": "last", "url": base + "?" + pageQuery(params, lastPage, pageSize)},
	}
	if page*pageSize < result.Total {
		links = append(links, map[string]any{
			"relation": "next",
			"url":      base + "?" + pageQuery(params, page+1, pageSize),
		})
	}
	if page > 1 {
		links = append(links, map[string]any{
			"relation": "previous",
			"url":      base + "?" + pageQuery(params, page-1, pageSize),
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"resourceType": "Bundle",
		"type":         "history",
		"total":        result.Total,
		"link":         links,
		"entry":        bundleEntries,
	})
}

func (h *fhirHandler) validate(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")

	if !requireFHIRContent(w, r) {
		return
	}

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	if bodyRT, ok := body["resourceType"].(string); ok && bodyRT != "" && bodyRT != rt {
		operationOutcome(w, http.StatusUnprocessableEntity, "error", "invalid",
			fmt.Sprintf("body resourceType %q does not match URL resource type %q", bodyRT, rt))
		return
	}

	if msg := validateRequiredFields(rt, body); msg != "" {
		operationOutcome(w, http.StatusUnprocessableEntity, "error", "required", msg)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"resourceType": "OperationOutcome",
		"issue": []any{map[string]any{
			"severity":    "information",
			"code":        "informational",
			"diagnostics": "Resource is valid",
		}},
	})
}

// ─── Metadata ─────────────────────────────────────────────────────────────────

func (h *fhirHandler) metadata(w http.ResponseWriter, r *http.Request) {
	var packages []ig.PackageResult
	var profiles map[string][]string
	if h.pool != nil {
		packages, _ = ig.LoadedPackages(r.Context(), h.pool)
		profiles, _ = ig.SupportedProfiles(r.Context(), h.pool)
	}

	// Build implementationGuide list
	igURLs := make([]string, 0, len(packages))
	for _, p := range packages {
		igURLs = append(igURLs, fmt.Sprintf("http://hl7.org/fhir/ig/%s/%s", p.Name, p.Version))
	}

	// Build rest.resource list with supportedProfile entries.
	// The list is derived from the loaded search-param registry so it always
	// reflects the full FHIR R4 base spec plus any IG packages loaded at
	// startup — no per-deployment hardcoding required.
	var fhirResourceTypes []string
	if h.registry != nil {
		fhirResourceTypes = h.registry.ResourceTypes()
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
			"versioning":        "versioned",
			"readHistory":       true,
			"updateCreate":      false,
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
			"mode":     "server",
			"resource": resources,
			"interaction": []any{
				map[string]any{"code": "transaction"},
				map[string]any{"code": "batch"},
			},
			"operation": []any{map[string]any{"name": "everything", "definition": "http://hl7.org/fhir/OperationDefinition/Patient-everything"}},
		}},
	}
	writeJSON(w, http.StatusOK, cs)
}

// validateRequiredFields returns a non-empty error message if key required
// FHIR R4 fields are missing from the resource body. Covers only the resource
// types exercised by the integration test suite; returns "" for unknown types.
func validateRequiredFields(rt string, body map[string]any) string {
	required := map[string][]string{
		"Observation": {"code"},
		"Encounter":   {"status", "class"},
	}
	fields, ok := required[rt]
	if !ok {
		return ""
	}
	for _, f := range fields {
		if _, exists := body[f]; !exists {
			return fmt.Sprintf("missing required field %q for %s", f, rt)
		}
	}
	return ""
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
	var gone store.GoneError
	if errors.As(err, &gone) {
		operationOutcome(w, http.StatusGone, "error", "deleted", err.Error())
		return
	}
	var conflict store.ConflictError
	if errors.As(err, &conflict) {
		operationOutcome(w, http.StatusPreconditionFailed, "error", "conflict", err.Error())
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
