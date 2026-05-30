//go:build integration

package handler_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/testutil"
)

// ─── Transaction: create with inter-entry reference resolution ─────────────────

func TestIntegration_Transaction_CreateWithReferences(t *testing.T) {
	srv := newRealServer(t)

	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "transaction",
		"entry": []any{
			map[string]any{
				"fullUrl":  "urn:uuid:patient-1",
				"resource": map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "Tx"}}},
				"request":  map[string]any{"method": "POST", "url": "Patient"},
			},
			map[string]any{
				"fullUrl": "urn:uuid:obs-1",
				"resource": map[string]any{
					"resourceType": "Observation",
					"status":       "final",
					"code":         map[string]any{"text": "hr"},
					"subject":      map[string]any{"reference": "urn:uuid:patient-1"},
				},
				"request": map[string]any{"method": "POST", "url": "Observation"},
			},
		},
	}

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4", bundle)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("transaction: want 200, got %d", resp.StatusCode)
	}
	body := iJSON(t, resp)
	if body["type"] != "transaction-response" {
		t.Fatalf("want transaction-response, got %v", body["type"])
	}
	entries := body["entry"].([]any)
	if len(entries) != 2 {
		t.Fatalf("want 2 entries, got %d", len(entries))
	}

	// Both entries created.
	for i, e := range entries {
		resp := e.(map[string]any)["response"].(map[string]any)
		if resp["status"] != "201 Created" {
			t.Errorf("entry[%d] status = %v, want 201 Created", i, resp["status"])
		}
	}

	// The Observation's subject reference must have been rewritten to Patient/<id>.
	patientLoc := entries[0].(map[string]any)["response"].(map[string]any)["location"].(string)
	patientID := lastPathID(patientLoc)
	obs := entries[1].(map[string]any)["resource"].(map[string]any)
	gotRef := obs["subject"].(map[string]any)["reference"].(string)
	wantRef := "Patient/" + patientID
	if gotRef != wantRef {
		t.Errorf("subject.reference = %q, want %q", gotRef, wantRef)
	}

	// The Patient is actually retrievable.
	rd := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+patientID, nil)
	if rd.StatusCode != http.StatusOK {
		t.Fatalf("read created Patient: want 200, got %d", rd.StatusCode)
	}
	rd.Body.Close()
}

// ─── Transaction: atomic rollback ──────────────────────────────────────────────

func TestIntegration_Transaction_RollsBackOnError(t *testing.T) {
	srv := newRealServer(t)

	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "transaction",
		"entry": []any{
			map[string]any{
				"fullUrl":  "urn:uuid:good",
				"resource": map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "ShouldNotPersist"}}},
				"request":  map[string]any{"method": "POST", "url": "Patient"},
			},
			// This entry fails: PUT to a non-existent id WITH an If-Match guard,
			// which cannot create and must error → whole transaction rolls back.
			map[string]any{
				"resource": map[string]any{"resourceType": "Patient", "id": "definitely-missing"},
				"request": map[string]any{
					"method":  "PUT",
					"url":     "Patient/definitely-missing",
					"ifMatch": "W/\"9\"",
				},
			},
		},
	}

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4", bundle)
	if resp.StatusCode == http.StatusOK {
		t.Fatalf("expected transaction to fail, got 200")
	}
	body := iJSON(t, resp)
	if body["resourceType"] != "OperationOutcome" {
		t.Fatalf("want OperationOutcome on failure, got %v", body["resourceType"])
	}

	// The good Patient must NOT have been persisted (full rollback).
	search := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?family=ShouldNotPersist", nil)
	sbody := iJSON(t, search)
	if total, _ := sbody["total"].(float64); total != 0 {
		t.Errorf("rollback failed: found %v Patients that should not exist", total)
	}
}

// ─── Batch: independent entries ────────────────────────────────────────────────

func TestIntegration_Batch_IndependentEntries(t *testing.T) {
	srv := newRealServer(t)

	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "batch",
		"entry": []any{
			map[string]any{
				"resource": map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "BatchGood"}}},
				"request":  map[string]any{"method": "POST", "url": "Patient"},
			},
			// Fails (404) but must not affect the good entry.
			map[string]any{
				"request": map[string]any{"method": "GET", "url": "Patient/does-not-exist"},
			},
		},
	}

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4", bundle)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("batch: want 200 overall, got %d", resp.StatusCode)
	}
	body := iJSON(t, resp)
	if body["type"] != "batch-response" {
		t.Fatalf("want batch-response, got %v", body["type"])
	}
	entries := body["entry"].([]any)
	if len(entries) != 2 {
		t.Fatalf("want 2 entries, got %d", len(entries))
	}

	r0 := entries[0].(map[string]any)["response"].(map[string]any)
	if r0["status"] != "201 Created" {
		t.Errorf("entry[0] status = %v, want 201 Created", r0["status"])
	}
	r1 := entries[1].(map[string]any)["response"].(map[string]any)
	if status, _ := r1["status"].(string); !strings.HasPrefix(status, "404") {
		t.Errorf("entry[1] status = %v, want 404", r1["status"])
	}

	// The good Patient persisted despite the sibling failure.
	search := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?family=BatchGood", nil)
	sbody := iJSON(t, search)
	if total, _ := sbody["total"].(float64); total != 1 {
		t.Errorf("want 1 BatchGood Patient, got %v", total)
	}
}

// ─── Transaction: conditional create (If-None-Exist) ───────────────────────────

func TestIntegration_Transaction_ConditionalCreate(t *testing.T) {
	srv := newRealServer(t)

	// Seed a Patient with a unique identifier.
	id, _ := iCreate(t, srv, "Patient", map[string]any{
		"resourceType": "Patient",
		"identifier":   []any{map[string]any{"system": "urn:cond", "value": "abc"}},
	})

	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "transaction",
		"entry": []any{
			map[string]any{
				"resource": map[string]any{
					"resourceType": "Patient",
					"identifier":   []any{map[string]any{"system": "urn:cond", "value": "abc"}},
				},
				"request": map[string]any{
					"method":      "POST",
					"url":         "Patient",
					"ifNoneExist": "identifier=urn:cond|abc",
				},
			},
		},
	}

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4", bundle)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("conditional create: want 200, got %d", resp.StatusCode)
	}
	body := iJSON(t, resp)
	entry := body["entry"].([]any)[0].(map[string]any)["response"].(map[string]any)
	// Matched the existing one → 200, not a new create, pointing at the seeded id.
	if entry["status"] != "200 OK" {
		t.Errorf("status = %v, want 200 OK (matched existing)", entry["status"])
	}
	if loc, _ := entry["location"].(string); lastPathID(loc) != id {
		t.Errorf("conditional create should reuse existing id %s, got location %v", id, loc)
	}
}

// ─── Transaction: SearchParameter DELETE cleans up the registry ────────────────

// newServerWithRegistry builds a real server but also returns the registry so a
// test can assert custom SearchParameter definitions are added/removed.
func newServerWithRegistry(t *testing.T) (*httptest.Server, *searchparam.Registry) {
	t.Helper()
	pool := testutil.MustSeededDB(t)
	reg := testutil.MustRegistry(t, pool)
	s := store.New(pool, reg)
	var ready atomic.Int32
	ready.Store(1)
	srv := httptest.NewServer(handler.NewRouter(s, pool, reg, "http://test-server/fhir/r4", &ready))
	t.Cleanup(srv.Close)
	return srv, reg
}

func TestIntegration_Transaction_SearchParameterDeleteCleansUpRegistry(t *testing.T) {
	srv, reg := newServerWithRegistry(t)

	// Create a custom SearchParameter directly so it lands in the registry.
	id, _ := iCreate(t, srv, "SearchParameter", map[string]any{
		"resourceType": "SearchParameter",
		"code":         "bundle-custom",
		"base":         []any{"Patient"},
		"type":         "string",
		"expression":   "Patient.extension('http://example.com/bundle-custom')",
	})
	if _, ok := reg.Lookup("Patient", "bundle-custom"); !ok {
		t.Fatal("custom SearchParameter should be in the registry after create")
	}

	// Delete it via a transaction Bundle. Before the fix, the Bundle path never
	// called DeleteSearchParameter, so the registry/definition leaked.
	bundle := map[string]any{
		"resourceType": "Bundle",
		"type":         "transaction",
		"entry": []any{map[string]any{
			"request": map[string]any{"method": "DELETE", "url": "SearchParameter/" + id},
		}},
	}
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4", bundle)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("transaction delete: want 200, got %d", resp.StatusCode)
	}
	resp.Body.Close()

	if _, ok := reg.Lookup("Patient", "bundle-custom"); ok {
		t.Error("custom SearchParameter should be removed from the registry after Bundle DELETE")
	}
}

// lastPathID returns the id segment of a location like ".../Patient/<id>/_history/1".
func lastPathID(loc string) string {
	parts := splitNonEmpty(loc, '/')
	for i, p := range parts {
		if p == "_history" && i > 0 {
			return parts[i-1]
		}
	}
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return ""
}

func splitNonEmpty(s string, sep byte) []string {
	var out []string
	cur := ""
	for i := 0; i < len(s); i++ {
		if s[i] == sep {
			if cur != "" {
				out = append(out, cur)
			}
			cur = ""
		} else {
			cur += string(s[i])
		}
	}
	if cur != "" {
		out = append(out, cur)
	}
	return out
}
