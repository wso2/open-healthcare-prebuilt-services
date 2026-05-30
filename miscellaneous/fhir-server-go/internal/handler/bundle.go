package handler

import (
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"strings"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// bundle handles POST /fhir/r4 — a system-level transaction or batch Bundle.
func (h *fhirHandler) bundle(w http.ResponseWriter, r *http.Request) {
	if !requireFHIRContent(w, r) {
		return
	}

	body, err := readBody(r)
	if err != nil {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid", "invalid JSON: "+err.Error())
		return
	}

	if rt, _ := body["resourceType"].(string); rt != "Bundle" {
		operationOutcome(w, http.StatusBadRequest, "error", "invalid",
			"request body must be a Bundle resource")
		return
	}

	bundleType, _ := body["type"].(string)
	if bundleType != "transaction" && bundleType != "batch" {
		operationOutcome(w, http.StatusBadRequest, "error", "value",
			fmt.Sprintf("Bundle.type must be 'transaction' or 'batch', got %q", bundleType))
		return
	}

	entries, perr := parseBundleEntries(body)
	if perr != "" {
		operationOutcome(w, http.StatusBadRequest, "error", "value", perr)
		return
	}

	results, err := h.store.ExecuteBundle(r.Context(), bundleType, h.baseURL, entries)
	if err != nil {
		var be *store.BundleError
		if errors.As(err, &be) {
			slog.Error("bundle execution failed", "bundleType", bundleType,
				"entryIndex", be.EntryIndex, "status", be.HTTPStatus, "err", be.Diagnostics)
			diag := be.Diagnostics
			if be.EntryIndex >= 0 {
				diag = fmt.Sprintf("entry[%d]: %s", be.EntryIndex, be.Diagnostics)
			}
			operationOutcome(w, be.HTTPStatus, "error", be.Code, diag)
			return
		}
		slog.Error("bundle execution failed", "bundleType", bundleType, "err", err)
		operationOutcome(w, http.StatusInternalServerError, "error", "exception", err.Error())
		return
	}

	// Keep the in-memory SearchParameter registry in sync with any custom
	// SearchParameters written by the Bundle, mirroring the single-resource path:
	// create/update re-sync the definition, delete removes it.
	for _, res := range results {
		if res.ResourceType != "SearchParameter" {
			continue
		}
		switch res.Method {
		case "POST", "PUT", "PATCH":
			if res.Resource != nil {
				_ = h.store.SyncSearchParameter(r.Context(), res.Resource)
			}
		case "DELETE":
			if res.ID != "" {
				_ = h.store.DeleteSearchParameter(r.Context(), res.ID)
			}
		}
	}

	responseType := "transaction-response"
	if bundleType == "batch" {
		responseType = "batch-response"
	}
	writeJSON(w, http.StatusOK, h.buildBundleResponse(responseType, results))
}

// buildBundleResponse assembles the transaction-response / batch-response Bundle.
func (h *fhirHandler) buildBundleResponse(responseType string, results []store.BundleEntryResult) map[string]any {
	entries := make([]any, 0, len(results))
	for _, res := range results {
		response := map[string]any{"status": res.Status}
		if res.Location != "" {
			response["location"] = h.absoluteLocation(res.Location)
		}
		if res.ETag != "" {
			response["etag"] = res.ETag
		}
		if res.Outcome != nil {
			response["outcome"] = res.Outcome
		}

		entry := map[string]any{"response": response}
		if res.Resource != nil {
			entry["resource"] = res.Resource
		}
		entries = append(entries, entry)
	}

	return map[string]any{
		"resourceType": "Bundle",
		"type":         responseType,
		"entry":        entries,
	}
}

// absoluteLocation turns a relative "Type/id/_history/v" location into an
// absolute URL under the server base.
func (h *fhirHandler) absoluteLocation(loc string) string {
	if strings.Contains(loc, "://") {
		return loc
	}
	return strings.TrimRight(h.baseURL, "/") + "/" + strings.TrimLeft(loc, "/")
}

// parseBundleEntries converts the raw Bundle.entry array into typed store
// requests. It returns a non-empty error string on a malformed Bundle.
func parseBundleEntries(bundle map[string]any) ([]store.BundleEntryRequest, string) {
	rawEntries, ok := bundle["entry"].([]any)
	if !ok {
		// An empty Bundle is valid — nothing to process.
		return nil, ""
	}

	entries := make([]store.BundleEntryRequest, 0, len(rawEntries))
	for i, raw := range rawEntries {
		entryMap, ok := raw.(map[string]any)
		if !ok {
			return nil, fmt.Sprintf("entry[%d] is not an object", i)
		}

		req, ok := entryMap["request"].(map[string]any)
		if !ok {
			return nil, fmt.Sprintf("entry[%d].request is required for transaction/batch", i)
		}

		method, _ := req["method"].(string)
		url, _ := req["url"].(string)
		if method == "" || url == "" {
			return nil, fmt.Sprintf("entry[%d].request.method and request.url are required", i)
		}

		entry := store.BundleEntryRequest{
			Method:      method,
			URL:         url,
			IfMatch:     stringField(req, "ifMatch"),
			IfNoneExist: stringField(req, "ifNoneExist"),
			FullURL:     stringField(entryMap, "fullUrl"),
		}
		if resource, ok := entryMap["resource"].(map[string]any); ok {
			entry.Resource = resource
		}
		entries = append(entries, entry)
	}
	slog.Debug("parsed bundle entries", "count", len(entries))
	return entries, ""
}

func stringField(m map[string]any, key string) string {
	if v, ok := m[key].(string); ok {
		return v
	}
	return ""
}
