//go:build integration

package handler_test

import (
	"net/http"
	"testing"
)

func patientWithIdentifier(system, value string) map[string]any {
	return map[string]any{
		"resourceType": "Patient",
		"identifier":   []any{map[string]any{"system": system, "value": value}},
	}
}

func TestIntegration_ConditionalCreate_IfNoneExist(t *testing.T) {
	srv := newRealServer(t)
	const sys = "urn:oid:1.2.3"
	cond := "identifier=" + sys + "%7Cmrn-1"

	// First create: no match → 201.
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient", patientWithIdentifier(sys, "mrn-1"),
		"If-None-Exist", cond)
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("first conditional create: want 201, got %d", resp.StatusCode)
	}
	first := iJSON(t, resp)
	firstID, _ := first["id"].(string)

	// Second create with the same If-None-Exist: one match → 200, no new resource.
	resp = iDo(t, srv, http.MethodPost, "/fhir/r4/Patient", patientWithIdentifier(sys, "mrn-1"),
		"If-None-Exist", cond)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("second conditional create: want 200, got %d", resp.StatusCode)
	}
	second := iJSON(t, resp)
	if id, _ := second["id"].(string); id != firstID {
		t.Errorf("conditional create should return the existing id %q, got %q", firstID, id)
	}

	// Exactly one Patient with that identifier should exist.
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?identifier="+sys+"%7Cmrn-1", nil)
	bundle := iJSON(t, resp)
	if total, _ := bundle["total"].(float64); total != 1 {
		t.Errorf("expected exactly 1 Patient, got %v", bundle["total"])
	}
}

func TestIntegration_ConditionalUpdate(t *testing.T) {
	srv := newRealServer(t)
	const sys = "urn:oid:1.2.3"
	cond := "/fhir/r4/Patient?identifier=" + sys + "%7Cmrn-2"

	// No match → create (201).
	resp := iDo(t, srv, http.MethodPut, cond, patientWithIdentifier(sys, "mrn-2"))
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("conditional update (no match): want 201, got %d", resp.StatusCode)
	}
	created := iJSON(t, resp)
	createdID, _ := created["id"].(string)

	// One match → update (200), version bumps.
	body := patientWithIdentifier(sys, "mrn-2")
	body["gender"] = "female"
	resp = iDo(t, srv, http.MethodPut, cond, body)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("conditional update (one match): want 200, got %d", resp.StatusCode)
	}
	updated := iJSON(t, resp)
	if id, _ := updated["id"].(string); id != createdID {
		t.Errorf("conditional update should target existing id %q, got %q", createdID, id)
	}
	meta, _ := updated["meta"].(map[string]any)
	if v, _ := meta["versionId"].(string); v != "2" {
		t.Errorf("expected versionId 2 after conditional update, got %q", v)
	}
}

func TestIntegration_ConditionalDelete(t *testing.T) {
	srv := newRealServer(t)
	const sys = "urn:oid:1.2.3"

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient", patientWithIdentifier(sys, "mrn-3"))
	created := iJSON(t, resp)
	id, _ := created["id"].(string)

	// Delete by criteria → 204.
	resp = iDo(t, srv, http.MethodDelete, "/fhir/r4/Patient?identifier="+sys+"%7Cmrn-3", nil)
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("conditional delete: want 204, got %d", resp.StatusCode)
	}
	resp.Body.Close()

	// The resource is now gone.
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+id, nil)
	if resp.StatusCode != http.StatusGone {
		t.Errorf("after conditional delete: want 410 Gone, got %d", resp.StatusCode)
	}
	resp.Body.Close()

	// No criteria → 400 (no mass delete).
	resp = iDo(t, srv, http.MethodDelete, "/fhir/r4/Patient", nil)
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("criteria-less conditional delete: want 400, got %d", resp.StatusCode)
	}
	resp.Body.Close()
}

func TestIntegration_ConditionalCreate_MultipleMatch_412(t *testing.T) {
	srv := newRealServer(t)
	const sys = "urn:oid:1.2.3"

	// Two patients sharing an identifier.
	for i := 0; i < 2; i++ {
		iDo(t, srv, http.MethodPost, "/fhir/r4/Patient", patientWithIdentifier(sys, "dup")).Body.Close()
	}

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient", patientWithIdentifier(sys, "dup"),
		"If-None-Exist", "identifier="+sys+"%7Cdup")
	if resp.StatusCode != http.StatusPreconditionFailed {
		t.Fatalf("conditional create with >1 match: want 412, got %d", resp.StatusCode)
	}
	resp.Body.Close()
}
