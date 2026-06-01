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
	"github.com/wso2/open-healthcare-fhir-server-go/internal/validate"
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

	summary, elements := projectionFromParams(params)
	result, err := h.store.Search(r.Context(), store.SearchParams{
		ResourceType: rt,
		Params:       params,
		Page:         page,
		PageSize:     pageSize,
		Total:        firstVal(params, "_total"),
		CountOnly:    summary == "count",
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

	bundle := h.buildBundle(rt, result, params, page, pageSize, summary, elements)
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

	summary, elements := projectionFromParams(params)
	result, err := h.store.Search(r.Context(), store.SearchParams{
		ResourceType: rt,
		Params:       params,
		Page:         page,
		PageSize:     pageSize,
		Total:        firstVal(params, "_total"),
		CountOnly:    summary == "count",
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

	bundle := h.buildBundle(rt, result, params, page, pageSize, summary, elements)
	writeJSON(w, http.StatusOK, bundle)
}

func (h *fhirHandler) buildBundle(rt string, result store.SearchResult, params map[string][]string, page, pageSize int, summary string, elements []string) map[string]any {
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
			"resource": applyProjection(res, summary, elements),
			"search":   map[string]any{"mode": "match"},
		})
	}
	for _, res := range result.Included {
		inclRT, _ := res["resourceType"].(string)
		id, _ := res["id"].(string)
		entries = append(entries, map[string]any{
			"fullUrl":  fmt.Sprintf("%s/%s/%s", h.baseURL, inclRT, id),
			"resource": applyProjection(res, summary, elements),
			"search":   map[string]any{"mode": "include"},
		})
	}

	base := fmt.Sprintf("%s/%s", h.baseURL, rt)
	links := []any{
		map[string]any{"relation": "self", "url": base + "?" + pageQuery(params, page, pageSize)},
		map[string]any{"relation": "first", "url": base + "?" + pageQuery(params, 1, pageSize)},
	}
	// result.Total < 0 means the count was skipped (_total=none): we can't
	// compute the last page or a count-based next link.
	if result.Total >= 0 {
		lastPage := result.Total / pageSize
		if result.Total%pageSize != 0 {
			lastPage++
		}
		if lastPage < 1 {
			lastPage = 1
		}
		links = append(links, map[string]any{"relation": "last", "url": base + "?" + pageQuery(params, lastPage, pageSize)})
		if page*pageSize < result.Total {
			links = append(links, map[string]any{
				"relation": "next",
				"url":      base + "?" + pageQuery(params, page+1, pageSize),
			})
		}
	}
	if page > 1 {
		links = append(links, map[string]any{
			"relation": "previous",
			"url":      base + "?" + pageQuery(params, page-1, pageSize),
		})
	}

	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "searchset",
		"link":         links,
		"entry":        entries,
	}
	if result.Total >= 0 {
		bundle["total"] = result.Total
	}
	return bundle
}

// projectionFromParams extracts the _summary mode and the _elements list from
// the request's query params.
func projectionFromParams(params map[string][]string) (summary string, elements []string) {
	summary = firstVal(params, "_summary")
	if e := firstVal(params, "_elements"); e != "" {
		for _, p := range strings.Split(e, ",") {
			if p = strings.TrimSpace(p); p != "" {
				elements = append(elements, p)
			}
		}
	}
	return
}

// alwaysKept are the elements every projected resource must retain regardless
// of _summary / _elements, per the FHIR spec.
var alwaysKept = map[string]bool{"resourceType": true, "id": true, "meta": true}

// applyProjection returns a view of resource reduced according to _summary and
// _elements. _elements takes precedence. Any reduced resource is tagged with
// the SUBSETTED meta tag so clients know not to persist it as authoritative.
//
// _summary=true is approximated by dropping the narrative (text) and contained
// resources: precise per-element summary filtering needs StructureDefinition
// isSummary flags, which are not yet loaded (tracked for the validation phase).
func applyProjection(resource map[string]any, summary string, elements []string) map[string]any {
	switch {
	case len(elements) > 0:
		out := make(map[string]any, len(elements)+len(alwaysKept))
		for k := range alwaysKept {
			if v, ok := resource[k]; ok {
				out[k] = v
			}
		}
		for _, e := range elements {
			if v, ok := resource[e]; ok {
				out[e] = v
			}
		}
		return tagSubsetted(out)
	case summary == "text":
		out := make(map[string]any, 4)
		for k := range alwaysKept {
			if v, ok := resource[k]; ok {
				out[k] = v
			}
		}
		if v, ok := resource["text"]; ok {
			out["text"] = v
		}
		return tagSubsetted(out)
	case summary == "data":
		out := shallowCopy(resource)
		delete(out, "text")
		return tagSubsetted(out)
	case summary == "true":
		out := shallowCopy(resource)
		delete(out, "text")
		delete(out, "contained")
		return tagSubsetted(out)
	default: // "", "false", "count" (count never reaches here — no entries)
		return resource
	}
}

func shallowCopy(m map[string]any) map[string]any {
	out := make(map[string]any, len(m))
	for k, v := range m {
		out[k] = v
	}
	return out
}

// tagSubsetted adds the SUBSETTED tag to meta.tag (creating meta/tag as needed),
// idempotently.
func tagSubsetted(resource map[string]any) map[string]any {
	const system = "http://terminology.hl7.org/CodeSystem/v3-ObservationValue"
	meta, _ := resource["meta"].(map[string]any)
	if meta == nil {
		meta = map[string]any{}
	} else {
		meta = shallowCopy(meta)
	}
	tags, _ := meta["tag"].([]any)
	for _, t := range tags {
		if tm, ok := t.(map[string]any); ok && tm["system"] == system && tm["code"] == "SUBSETTED" {
			resource["meta"] = meta
			return resource
		}
	}
	meta["tag"] = append(tags, map[string]any{"system": system, "code": "SUBSETTED"})
	resource["meta"] = meta
	return resource
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

	// Conditional create (If-None-Exist): create only if no existing resource
	// matches the query. One match → return it (200, no create); many → 412.
	if ifne := strings.TrimSpace(r.Header.Get("If-None-Exist")); ifne != "" {
		existingID, count, err := h.store.ConditionalMatch(r.Context(), rt, ifne)
		if err != nil {
			slog.Error("conditional create match failed", "resourceType", rt, "err", err)
			operationOutcome(w, http.StatusInternalServerError, "error", "exception", "conditional match failed")
			return
		}
		switch {
		case count > 1:
			operationOutcome(w, http.StatusPreconditionFailed, "error", "conflict",
				fmt.Sprintf("If-None-Exist matched %d resources", count))
			return
		case count == 1:
			existing, err := h.store.Read(r.Context(), rt, existingID)
			if err != nil {
				handleError(w, err)
				return
			}
			w.Header().Set("Location", fmt.Sprintf("%s/%s/%s", h.baseURL, rt, existingID))
			w.Header().Set("ETag", fmt.Sprintf(`W/"%s"`, versionFromMeta(existing)))
			writeJSON(w, http.StatusOK, existing)
			return
		}
		// count == 0 → fall through to a normal create.
	}

	if h.validateOnWrite {
		if stop := h.enforceProfiles(w, r, body); stop {
			return
		}
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

	if h.validateOnWrite {
		if stop := h.enforceProfiles(w, r, body); stop {
			return
		}
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

// ─── Conditional update / delete (collection level) ────────────────────────────

// conditionalUpdate handles PUT /{resourceType}?<search> — update the single
// matching resource, create when none match, and 412 when more than one match.
func (h *fhirHandler) conditionalUpdate(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	query := strings.TrimSpace(r.URL.RawQuery)
	if query == "" {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "conditional update requires search criteria")
		return
	}
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

	existingID, count, err := h.store.ConditionalMatch(r.Context(), rt, query)
	if err != nil {
		slog.Error("conditional update match failed", "resourceType", rt, "err", err)
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", "conditional match failed")
		return
	}
	if count > 1 {
		operationOutcome(w, http.StatusPreconditionFailed, "error", "conflict",
			fmt.Sprintf("conditional update matched %d resources", count))
		return
	}

	if count == 1 {
		resource, err := h.store.Update(r.Context(), rt, existingID, body, -1)
		if err != nil {
			handleError(w, err)
			return
		}
		if rt == "SearchParameter" {
			_ = h.store.SyncSearchParameter(r.Context(), resource)
		}
		w.Header().Set("ETag", fmt.Sprintf(`W/"%s"`, versionFromMeta(resource)))
		writeJSON(w, http.StatusOK, resource)
		return
	}

	// No match → create a new resource.
	resource, err := h.store.Create(r.Context(), rt, body)
	if err != nil {
		slog.Error("conditional update create failed", "resourceType", rt, "err", err)
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}
	if rt == "SearchParameter" {
		_ = h.store.SyncSearchParameter(r.Context(), resource)
	}
	id, _ := resource["id"].(string)
	w.Header().Set("Location", fmt.Sprintf("%s/%s/%s/_history/1", h.baseURL, rt, id))
	w.Header().Set("ETag", `W/"1"`)
	writeJSON(w, http.StatusCreated, resource)
}

// conditionalDelete handles DELETE /{resourceType}?<search> — delete the single
// matching resource. Refuses without criteria (no mass delete) and 412s on more
// than one match (multiple conditional delete is not supported).
func (h *fhirHandler) conditionalDelete(w http.ResponseWriter, r *http.Request) {
	rt := chi.URLParam(r, "resourceType")
	query := strings.TrimSpace(r.URL.RawQuery)
	if query == "" {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid",
			"conditional delete requires search criteria")
		return
	}

	existingID, count, err := h.store.ConditionalMatch(r.Context(), rt, query)
	if err != nil {
		slog.Error("conditional delete match failed", "resourceType", rt, "err", err)
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", "conditional match failed")
		return
	}
	if count > 1 {
		operationOutcome(w, http.StatusPreconditionFailed, "error", "conflict",
			fmt.Sprintf("conditional delete matched %d resources; multiple delete is not supported", count))
		return
	}
	if count == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	if rt == "SearchParameter" {
		_ = h.store.DeleteSearchParameter(r.Context(), existingID)
	}
	if err := h.store.Delete(r.Context(), rt, existingID); err != nil {
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

	// Determine which profiles to validate against:
	//   ?profile=<url>  → the named profile only
	//   no param        → all profiles declared in meta.profile on the resource
	var profileURLs []string
	if p := r.URL.Query().Get("profile"); p != "" {
		profileURLs = []string{p}
	} else if meta, ok := body["meta"].(map[string]any); ok {
		if profs, ok := meta["profile"].([]any); ok {
			for _, pr := range profs {
				if s, ok := pr.(string); ok && s != "" {
					profileURLs = append(profileURLs, s)
				}
			}
		}
	}

	issues := h.validateAgainstProfiles(r, body, profileURLs)
	if len(issues) == 0 {
		writeJSON(w, http.StatusOK, map[string]any{
			"resourceType": "OperationOutcome",
			"issue": []any{map[string]any{
				"severity":    "information",
				"code":        "informational",
				"diagnostics": "Resource is valid",
			}},
		})
		return
	}

	fhirIssues := make([]any, 0, len(issues))
	for _, iss := range issues {
		fhirIssues = append(fhirIssues, map[string]any{
			"severity":    iss.Severity,
			"code":        iss.Code,
			"diagnostics": iss.Diagnostics,
			"expression":  []string{iss.Expression},
		})
	}
	writeJSON(w, http.StatusUnprocessableEntity, map[string]any{
		"resourceType": "OperationOutcome",
		"issue":        fhirIssues,
	})
}

// validateAgainstProfiles looks up each profile URL in ig_profiles and runs
// the StructureDefinition validator. Returns an empty slice when no profiles
// are loaded (soft-fail: unrecognised profiles are skipped with a warning).
func (h *fhirHandler) validateAgainstProfiles(r *http.Request, resource map[string]any, profileURLs []string) []validate.Issue {
	if h.pool == nil || len(profileURLs) == 0 {
		return nil
	}
	ctx := r.Context()
	var all []validate.Issue
	for _, profileURL := range profileURLs {
		sd, err := ig.LookupProfile(ctx, h.pool, profileURL)
		if err != nil {
			slog.Warn("profile lookup failed", "url", profileURL, "err", err)
			continue
		}
		if sd == nil {
			slog.Debug("profile not loaded, skipping validation", "url", profileURL)
			continue
		}
		all = append(all, validate.AgainstProfile(resource, sd)...)
	}
	return all
}

// universalSearchParams are the search params the store implements for every
// resource type (handled directly in store.applyParam rather than via the
// per-resource registry). They are advertised on every resource in the
// CapabilityStatement so capability-driven clients discover them.
var universalSearchParams = []struct {
	name      string
	paramType string
}{
	{"_id", "token"},
	{"_lastUpdated", "date"},
	{"_text", "string"},
	{"_content", "string"},
	{"_tag", "token"},
	{"_profile", "uri"},
	{"_security", "token"},
	{"_source", "uri"},
	{"_language", "token"},
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
			"conditionalCreate": true,
			"conditionalUpdate": true,
			"conditionalDelete": "single",
		}
		if profs, ok := profiles[rt]; ok && len(profs) > 0 {
			entry["supportedProfile"] = profs
		}

		// searchParam: every param the registry knows for this resource type,
		// plus the universal params the search layer implements for all types
		// (_id, _lastUpdated, _text, _content — see store.applyParam). These are
		// not stored per-resource in the registry, so they are appended here.
		// searchInclude: reference params can be used as _include targets.
		// (searchRevInclude is intentionally omitted — it requires per-param
		// target-type knowledge the registry's FHIRPath strings don't carry
		// reliably for un-filtered refs like "Encounter.subject".)
		sps := make([]any, 0, len(universalSearchParams)+8)
		for _, u := range universalSearchParams {
			sps = append(sps, map[string]any{"name": u.name, "type": u.paramType})
		}
		if h.registry != nil {
			defs := h.registry.ForResource(rt)
			var includes []string
			for _, d := range defs {
				sps = append(sps, map[string]any{
					"name": d.ParamName,
					"type": d.ParamType,
				})
				if d.ParamType == "reference" {
					includes = append(includes, rt+":"+d.ParamName)
				}
			}
			if len(includes) > 0 {
				entry["searchInclude"] = includes
			}
		}
		entry["searchParam"] = sps
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

// enforceProfiles runs profile validation on a write (create/update) when
// validateOnWrite is enabled. Writes the OperationOutcome and returns true
// when the caller should abort. Profiles are taken from meta.profile.
func (h *fhirHandler) enforceProfiles(w http.ResponseWriter, r *http.Request, body map[string]any) bool {
	var profileURLs []string
	if meta, ok := body["meta"].(map[string]any); ok {
		if profs, ok := meta["profile"].([]any); ok {
			for _, pr := range profs {
				if s, ok := pr.(string); ok && s != "" {
					profileURLs = append(profileURLs, s)
				}
			}
		}
	}
	if len(profileURLs) == 0 {
		return false
	}
	issues := h.validateAgainstProfiles(r, body, profileURLs)
	if len(issues) == 0 {
		return false
	}
	fhirIssues := make([]any, 0, len(issues))
	for _, iss := range issues {
		fhirIssues = append(fhirIssues, map[string]any{
			"severity":    iss.Severity,
			"code":        iss.Code,
			"diagnostics": iss.Diagnostics,
			"expression":  []string{iss.Expression},
		})
	}
	writeJSON(w, http.StatusUnprocessableEntity, map[string]any{
		"resourceType": "OperationOutcome",
		"issue":        fhirIssues,
	})
	return true
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
