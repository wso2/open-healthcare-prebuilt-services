//go:build integration

package handler_test

import (
	"net/http"
	"testing"
)

func TestIntegration_Validate_SystemAndInstance(t *testing.T) {
	srv := newRealServer(t)
	// System-level $validate (no profile loaded → 200 informational).
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/$validate",
		map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "X"}}})
	if resp.StatusCode != http.StatusOK {
		b := iJSON(t, resp)
		t.Fatalf("system $validate: want 200, got %d: %v", resp.StatusCode, b)
	}
	resp.Body.Close()

	// Instance-level $validate on a stored resource (no body).
	id, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	resp = iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/"+id+"/$validate", nil)
	if resp.StatusCode != http.StatusOK {
		b := iJSON(t, resp)
		t.Fatalf("instance $validate: want 200, got %d: %v", resp.StatusCode, b)
	}
	if oo := iJSON(t, resp); oo["resourceType"] != "OperationOutcome" {
		t.Errorf("instance $validate should return OperationOutcome, got %v", oo["resourceType"])
	}
}

func TestIntegration_Convert(t *testing.T) {
	srv := newRealServer(t)
	// POST JSON, ask for XML back via Accept.
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/$convert",
		map[string]any{"resourceType": "Patient", "gender": "female"},
		"Accept", "application/fhir+xml")
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("$convert: want 200, got %d", resp.StatusCode)
	}
	if ct := resp.Header.Get("Content-Type"); ct != "application/fhir+xml" {
		t.Errorf("$convert: want XML content type, got %q", ct)
	}
	resp.Body.Close()
}

func TestIntegration_Meta_Family(t *testing.T) {
	srv := newRealServer(t)
	id, _ := iCreate(t, srv, "Patient", map[string]any{
		"resourceType": "Patient",
		"meta": map[string]any{"tag": []any{map[string]any{"system": "urn:s", "code": "orig"}}},
	})

	// $meta-add a new tag.
	addBody := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{"name": "meta", "valueMeta": map[string]any{
			"tag": []any{map[string]any{"system": "urn:s", "code": "added"}},
		}}},
	}
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/"+id+"/$meta-add", addBody)
	if resp.StatusCode != http.StatusOK {
		b := iJSON(t, resp)
		t.Fatalf("$meta-add: want 200, got %d: %v", resp.StatusCode, b)
	}
	resp.Body.Close()

	// Instance $meta should now show both tags.
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+id+"/$meta", nil)
	p := iJSON(t, resp)
	codes := metaTagCodes(p)
	if !codes["orig"] || !codes["added"] {
		t.Errorf("instance $meta after add: want orig+added, got %v", codes)
	}

	// $meta-delete the original tag.
	delBody := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{"name": "meta", "valueMeta": map[string]any{
			"tag": []any{map[string]any{"system": "urn:s", "code": "orig"}},
		}}},
	}
	resp = iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/"+id+"/$meta-delete", delBody)
	resp.Body.Close()
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+id+"/$meta", nil)
	codes = metaTagCodes(iJSON(t, resp))
	if codes["orig"] || !codes["added"] {
		t.Errorf("instance $meta after delete: want only added, got %v", codes)
	}

	// System + type $meta should include the surviving tag.
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/$meta", nil)
	if !metaTagCodes(iJSON(t, resp))["added"] {
		t.Error("type $meta should include 'added' tag")
	}
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/$meta", nil)
	if !metaTagCodes(iJSON(t, resp))["added"] {
		t.Error("system $meta should include 'added' tag")
	}
}

// metaTagCodes extracts the set of meta.tag codes from a $meta Parameters result.
func metaTagCodes(params map[string]any) map[string]bool {
	out := map[string]bool{}
	ps, _ := params["parameter"].([]any)
	for _, raw := range ps {
		p, _ := raw.(map[string]any)
		if p == nil || p["name"] != "return" {
			continue
		}
		meta, _ := p["valueMeta"].(map[string]any)
		tags, _ := meta["tag"].([]any)
		for _, t := range tags {
			tm, _ := t.(map[string]any)
			if c, ok := tm["code"].(string); ok {
				out[c] = true
			}
		}
	}
	return out
}

func TestIntegration_Everything_TypeLevel(t *testing.T) {
	srv := newRealServer(t)
	patID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	iCreate(t, srv, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"code":    map[string]any{"text": "BP"},
		"subject": map[string]any{"reference": "Patient/" + patID},
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/$everything", nil)
	if resp.StatusCode != http.StatusOK {
		b := iJSON(t, resp)
		t.Fatalf("type $everything: want 200, got %d: %v", resp.StatusCode, b)
	}
	b := iJSON(t, resp)
	if total, _ := b["total"].(float64); total < 2 {
		t.Errorf("Patient/$everything: want >=2 (patient + observation), got %v", total)
	}
}

func TestIntegration_LastN(t *testing.T) {
	srv := newRealServer(t)
	patID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	// Three observations of the same code at different times.
	for _, d := range []string{"2024-01-01", "2024-02-01", "2024-03-01"} {
		iCreate(t, srv, "Observation", map[string]any{
			"resourceType": "Observation", "status": "final",
			"subject":          map[string]any{"reference": "Patient/" + patID},
			"code":             map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8480-6"}}},
			"effectiveDateTime": d,
		})
	}

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Observation/$lastn?max=1", nil)
	if resp.StatusCode != http.StatusOK {
		b := iJSON(t, resp)
		t.Fatalf("$lastn: want 200, got %d: %v", resp.StatusCode, b)
	}
	b := iJSON(t, resp)
	// max=1 per code group → exactly 1 entry for the single code.
	if total, _ := b["total"].(float64); total != 1 {
		t.Errorf("$lastn max=1: want 1, got %v", total)
	}
}

func TestIntegration_Document(t *testing.T) {
	srv := newRealServer(t)
	patID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	compID, _ := iCreate(t, srv, "Composition", map[string]any{
		"resourceType": "Composition", "status": "final",
		"type":    map[string]any{"text": "Discharge summary"},
		"subject": map[string]any{"reference": "Patient/" + patID},
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Composition/"+compID+"/$document", nil)
	if resp.StatusCode != http.StatusOK {
		b := iJSON(t, resp)
		t.Fatalf("$document: want 200, got %d: %v", resp.StatusCode, b)
	}
	b := iJSON(t, resp)
	if b["type"] != "document" {
		t.Errorf("$document: want Bundle.type=document, got %v", b["type"])
	}
	entries, _ := b["entry"].([]any)
	if len(entries) < 2 {
		t.Errorf("$document: want >=2 entries (Composition + subject), got %d", len(entries))
	}
	// First entry must be the Composition.
	if len(entries) > 0 {
		e0, _ := entries[0].(map[string]any)
		res0, _ := e0["resource"].(map[string]any)
		if res0["resourceType"] != "Composition" {
			t.Errorf("$document: first entry should be Composition, got %v", res0["resourceType"])
		}
	}
}

func TestIntegration_LastN_PerCodeGrouping(t *testing.T) {
	srv := newRealServer(t)
	patID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	// Two distinct codes, two observations each at different times.
	for _, code := range []string{"8480-6", "8867-4"} {
		for _, d := range []string{"2024-01-01", "2024-02-01"} {
			iCreate(t, srv, "Observation", map[string]any{
				"resourceType": "Observation", "status": "final",
				"subject":           map[string]any{"reference": "Patient/" + patID},
				"code":              map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": code}}},
				"effectiveDateTime": d,
			})
		}
	}
	// max=1 → exactly one (the most recent) per code = 2 total. This is the
	// per-code-recency property that a global top-N cap would break.
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Observation/$lastn?max=1", nil)
	b := iJSON(t, resp)
	if total, _ := b["total"].(float64); total != 2 {
		t.Errorf("$lastn max=1 over 2 codes: want 2 (one per code), got %v", total)
	}
}

func TestIntegration_MetaAdd_RejectsNonParameters(t *testing.T) {
	srv := newRealServer(t)
	id, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	// A Patient body (not Parameters) must be rejected with 400.
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/"+id+"/$meta-add",
		map[string]any{"resourceType": "Patient", "meta": map[string]any{"tag": []any{}}})
	if resp.StatusCode != http.StatusBadRequest {
		b := iJSON(t, resp)
		t.Fatalf("$meta-add with non-Parameters body: want 400, got %d: %v", resp.StatusCode, b)
	}
	resp.Body.Close()
}
