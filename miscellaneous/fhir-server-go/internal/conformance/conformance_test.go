//go:build conformance

package conformance

import (
	"fmt"
	"net/http"
	"strings"
	"testing"
)

// CapabilityStatement — https://hl7.org/fhir/R4/http.html#capabilities
func TestConformance_CapabilityStatement(t *testing.T) {
	resp := hreq(t, http.MethodGet, "/metadata", nil)
	wantStatus(t, resp, http.StatusOK)
	cs := jbody(t, resp)

	if cs["resourceType"] != "CapabilityStatement" {
		t.Fatalf("resourceType: got %v", cs["resourceType"])
	}
	if cs["fhirVersion"] != "4.0.1" {
		t.Errorf("fhirVersion: got %v, want 4.0.1", cs["fhirVersion"])
	}
	rest, _ := cs["rest"].([]any)
	if len(rest) == 0 {
		t.Fatal("rest is empty")
	}
	r0, _ := rest[0].(map[string]any)
	if r0["mode"] != "server" {
		t.Errorf("rest.mode: got %v, want server", r0["mode"])
	}
	resources, _ := r0["resource"].([]any)
	if len(resources) == 0 {
		t.Fatal("rest.resource is empty")
	}
	// Patient must advertise interactions, conditional flags and search params.
	var patient map[string]any
	for _, r := range resources {
		m, _ := r.(map[string]any)
		if m["type"] == "Patient" {
			patient = m
			break
		}
	}
	if patient == nil {
		t.Fatal("Patient not advertised")
	}
	if patient["conditionalCreate"] != true {
		t.Errorf("Patient.conditionalCreate: got %v, want true", patient["conditionalCreate"])
	}
	if sp, _ := patient["searchParam"].([]any); len(sp) == 0 {
		t.Error("Patient.searchParam should be enumerated")
	}
}

// create / read / vread / update / delete — https://hl7.org/fhir/R4/http.html
func TestConformance_CRUD_Lifecycle(t *testing.T) {
	id, _ := createPatient(t, map[string]any{"gender": "female"})

	// read → 200, ETag present
	resp := hreq(t, http.MethodGet, "/Patient/"+id, nil)
	wantStatus(t, resp, http.StatusOK)
	if resp.Header.Get("ETag") == "" {
		t.Error("read: missing ETag")
	}
	got := jbody(t, resp)
	if got["id"] != id || got["gender"] != "female" {
		t.Errorf("read round-trip mismatch: %v", got)
	}

	// update → version 2
	resp = hreq(t, http.MethodPut, "/Patient/"+id, map[string]any{
		"resourceType": "Patient", "id": id, "gender": "male",
	})
	wantStatus(t, resp, http.StatusOK)
	upd := jbody(t, resp)
	if meta, _ := upd["meta"].(map[string]any); meta["versionId"] != "2" {
		t.Errorf("update versionId: got %v, want 2", upd["meta"])
	}

	// vread v1 still returns the original
	resp = hreq(t, http.MethodGet, "/Patient/"+id+"/_history/1", nil)
	wantStatus(t, resp, http.StatusOK)
	if v1 := jbody(t, resp); v1["gender"] != "female" {
		t.Errorf("vread v1 gender: got %v, want female", v1["gender"])
	}

	// delete → 204, then read → 410 Gone
	resp = hreq(t, http.MethodDelete, "/Patient/"+id, nil)
	wantStatus(t, resp, http.StatusNoContent)
	resp.Body.Close()

	resp = hreq(t, http.MethodGet, "/Patient/"+id, nil)
	wantStatus(t, resp, http.StatusGone)
	resp.Body.Close()
}

// Optimistic concurrency — https://hl7.org/fhir/R4/http.html#concurrency
func TestConformance_IfMatchConcurrency(t *testing.T) {
	id, _ := createPatient(t, nil)

	// Stale If-Match → 412.
	resp := hreq(t, http.MethodPut, "/Patient/"+id, map[string]any{
		"resourceType": "Patient", "id": id, "gender": "other",
	}, "If-Match", `W/"99"`)
	wantStatus(t, resp, http.StatusPreconditionFailed)
	resp.Body.Close()

	// Correct If-Match → 200.
	resp = hreq(t, http.MethodPut, "/Patient/"+id, map[string]any{
		"resourceType": "Patient", "id": id, "gender": "other",
	}, "If-Match", `W/"1"`)
	wantStatus(t, resp, http.StatusOK)
	resp.Body.Close()
}

// instance history — https://hl7.org/fhir/R4/http.html#history
func TestConformance_History(t *testing.T) {
	id, _ := createPatient(t, nil)
	hreq(t, http.MethodPut, "/Patient/"+id, map[string]any{"resourceType": "Patient", "id": id, "active": true}).Body.Close()

	resp := hreq(t, http.MethodGet, "/Patient/"+id+"/_history", nil)
	wantStatus(t, resp, http.StatusOK)
	b := jbody(t, resp)
	if b["type"] != "history" {
		t.Errorf("history Bundle.type: got %v, want history", b["type"])
	}
	if entries, _ := b["entry"].([]any); len(entries) < 2 {
		t.Errorf("expected >=2 history entries, got %d", len(entries))
	}
}

// search basics — https://hl7.org/fhir/R4/search.html
func TestConformance_Search_Basics(t *testing.T) {
	id, idv := createPatient(t, map[string]any{"gender": "female"})

	resp := hreq(t, http.MethodGet, "/Patient?identifier=urn:conformance%7C"+idv, nil)
	wantStatus(t, resp, http.StatusOK)
	b := jbody(t, resp)
	if b["resourceType"] != "Bundle" || b["type"] != "searchset" {
		t.Fatalf("search Bundle: got type=%v", b["type"])
	}
	if total, _ := b["total"].(float64); total != 1 {
		t.Errorf("expected total=1, got %v", b["total"])
	}
	// self link present
	if links, _ := b["link"].([]any); len(links) == 0 {
		t.Error("search Bundle should carry link[]")
	}
	// _id search returns the same resource
	resp = hreq(t, http.MethodGet, "/Patient?_id="+id, nil)
	wantStatus(t, resp, http.StatusOK)
	if b := jbody(t, resp); firstEntryID(b) != id {
		t.Errorf("_id search returned wrong resource: %v", firstEntryID(b))
	}
}

// search controls: _sort, _summary=count, _elements, _total=none
func TestConformance_Search_Controls(t *testing.T) {
	// Three patients with sortable family names sharing a unique tag value.
	tag := "sortgrp-" + nextID()
	for _, fam := range []string{"Charlie", "Alice", "Bob"} {
		hreq(t, http.MethodPost, "/Patient", map[string]any{
			"resourceType": "Patient",
			"name":         []any{map[string]any{"family": fam}},
			"identifier":   []any{map[string]any{"system": "urn:sortgrp", "value": tag}},
		}).Body.Close()
	}
	q := "/Patient?identifier=urn:sortgrp%7C" + tag

	// _sort=family ascending
	b := jbody(t, hreq(t, http.MethodGet, q+"&_sort=family", nil))
	if fams := familyOrder(b); len(fams) != 3 || fams[0] != "Alice" || fams[2] != "Charlie" {
		t.Errorf("_sort=family asc: got %v", fams)
	}
	// _sort=-family descending
	b = jbody(t, hreq(t, http.MethodGet, q+"&_sort=-family", nil))
	if fams := familyOrder(b); len(fams) != 3 || fams[0] != "Charlie" {
		t.Errorf("_sort=-family desc: got %v", fams)
	}
	// _summary=count → total, no entries
	b = jbody(t, hreq(t, http.MethodGet, q+"&_summary=count", nil))
	if total, _ := b["total"].(float64); total != 3 {
		t.Errorf("_summary=count total: got %v, want 3", b["total"])
	}
	if entries, _ := b["entry"].([]any); len(entries) != 0 {
		t.Errorf("_summary=count should return no entries, got %d", len(entries))
	}
	// _total=none → total omitted
	b = jbody(t, hreq(t, http.MethodGet, q+"&_total=none", nil))
	if _, present := b["total"]; present {
		t.Error("_total=none should omit Bundle.total")
	}
	// _elements projects and tags SUBSETTED
	b = jbody(t, hreq(t, http.MethodGet, q+"&_elements=identifier", nil))
	if e := firstEntry(b); e != nil {
		if _, ok := e["name"]; ok {
			t.Error("_elements=identifier should drop name")
		}
		if !hasSubsetted(e) {
			t.Error("_elements response must carry SUBSETTED tag")
		}
	}
}

// chained search — https://hl7.org/fhir/R4/search.html#chaining
func TestConformance_Search_Chained(t *testing.T) {
	orgName := "Acme-" + nextID()
	resp := hreq(t, http.MethodPost, "/Organization", map[string]any{"resourceType": "Organization", "name": orgName})
	org := jbody(t, resp)
	orgID := org["id"].(string)

	idv := "chain-" + nextID()
	hreq(t, http.MethodPost, "/Patient", map[string]any{
		"resourceType":         "Patient",
		"identifier":           []any{map[string]any{"system": "urn:conformance", "value": idv}},
		"managingOrganization": map[string]any{"reference": "Organization/" + orgID},
	}).Body.Close()

	b := jbody(t, hreq(t, http.MethodGet, "/Patient?organization.name="+orgName, nil))
	if total, _ := b["total"].(float64); total != 1 {
		t.Errorf("Patient?organization.name=%s: got total %v, want 1", orgName, b["total"])
	}
}

// _include — https://hl7.org/fhir/R4/search.html#include
func TestConformance_Search_Include(t *testing.T) {
	resp := hreq(t, http.MethodPost, "/Organization", map[string]any{"resourceType": "Organization", "name": "Inc-" + nextID()})
	orgID := jbody(t, resp)["id"].(string)
	idv := "incl-" + nextID()
	hreq(t, http.MethodPost, "/Patient", map[string]any{
		"resourceType":         "Patient",
		"identifier":           []any{map[string]any{"system": "urn:conformance", "value": idv}},
		"managingOrganization": map[string]any{"reference": "Organization/" + orgID},
	}).Body.Close()

	b := jbody(t, hreq(t, http.MethodGet, "/Patient?identifier=urn:conformance%7C"+idv+"&_include=Patient:organization", nil))
	var modes []string
	for _, e := range entries(b) {
		if s, _ := e["search"].(map[string]any); s != nil {
			modes = append(modes, fmt.Sprintf("%v", s["mode"]))
		}
	}
	if !contains(modes, "match") || !contains(modes, "include") {
		t.Errorf("_include should yield match+include entries, got modes %v", modes)
	}
}

// conditional ops — https://hl7.org/fhir/R4/http.html#cond-update etc.
func TestConformance_Conditional(t *testing.T) {
	idv := "cond-" + nextID()
	cond := "identifier=urn:conformance%7C" + idv

	// Conditional create, twice — second is a no-op returning the same id.
	resp := hreq(t, http.MethodPost, "/Patient",
		map[string]any{"resourceType": "Patient", "identifier": []any{map[string]any{"system": "urn:conformance", "value": idv}}},
		"If-None-Exist", cond)
	wantStatus(t, resp, http.StatusCreated)
	id1 := jbody(t, resp)["id"].(string)

	resp = hreq(t, http.MethodPost, "/Patient",
		map[string]any{"resourceType": "Patient", "identifier": []any{map[string]any{"system": "urn:conformance", "value": idv}}},
		"If-None-Exist", cond)
	wantStatus(t, resp, http.StatusOK)
	if jbody(t, resp)["id"] != id1 {
		t.Error("conditional create should return the existing resource")
	}

	// Conditional delete by criteria, then it's gone.
	resp = hreq(t, http.MethodDelete, "/Patient?"+cond, nil)
	wantStatus(t, resp, http.StatusNoContent)
	resp.Body.Close()
	resp = hreq(t, http.MethodGet, "/Patient/"+id1, nil)
	wantStatus(t, resp, http.StatusGone)
	resp.Body.Close()
}

// transaction Bundle — https://hl7.org/fhir/R4/http.html#transaction
func TestConformance_Transaction(t *testing.T) {
	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "transaction",
		"entry": []any{
			map[string]any{
				"resource": map[string]any{"resourceType": "Patient", "identifier": []any{map[string]any{"system": "urn:conformance", "value": "txn-" + nextID()}}},
				"request":  map[string]any{"method": "POST", "url": "Patient"},
			},
		},
	}
	resp := hreq(t, http.MethodPost, "", bundle)
	wantStatus(t, resp, http.StatusOK)
	b := jbody(t, resp)
	if b["type"] != "transaction-response" {
		t.Errorf("Bundle.type: got %v, want transaction-response", b["type"])
	}
	es := entries(b)
	if len(es) != 1 {
		t.Fatalf("expected 1 response entry, got %d", len(es))
	}
	if respMeta, _ := es[0]["response"].(map[string]any); respMeta == nil || !strings.HasPrefix(fmt.Sprintf("%v", respMeta["status"]), "201") {
		t.Errorf("transaction entry status: got %v, want 201*", es[0]["response"])
	}
}

// Error handling — correct status + OperationOutcome.
func TestConformance_ErrorOutcomes(t *testing.T) {
	// Unknown resource → 404 OperationOutcome.
	resp := hreq(t, http.MethodGet, "/Patient/does-not-exist-"+nextID(), nil)
	wantStatus(t, resp, http.StatusNotFound)
	if oo := jbody(t, resp); !isOperationOutcome(oo) {
		t.Error("404 body should be an OperationOutcome")
	}

	// Malformed JSON → 400.
	resp = postRaw(t, "/Patient", "{not json", "application/fhir+json")
	wantStatus(t, resp, http.StatusBadRequest)
	resp.Body.Close()

	// Unsupported Content-Type (server now accepts JSON and XML; text/plain is still 415).
	resp = postRaw(t, "/Patient", `{"resourceType":"Patient"}`, "text/plain")
	wantStatus(t, resp, http.StatusUnsupportedMediaType)
	resp.Body.Close()

	// Unsupported (composite) search param → 400, fail-closed.
	resp = hreq(t, http.MethodGet, "/Observation?code-value-quantity=x", nil)
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("composite param should fail closed with 400, got %d", resp.StatusCode)
	}
	resp.Body.Close()
}
