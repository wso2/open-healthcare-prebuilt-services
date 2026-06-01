//go:build integration

package handler_test

import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/testutil"
)

// ─── Infrastructure ───────────────────────────────────────────────────────────

func newRealServer(t *testing.T) *httptest.Server {
	t.Helper()
	pool := testutil.MustSeededDB(t)
	reg := testutil.MustRegistry(t, pool)
	s := store.New(pool, reg)
	var ready atomic.Int32
	ready.Store(1)
	srv := httptest.NewServer(handler.NewRouter(s, pool, reg, "http://test-server/fhir/r4", &ready))
	t.Cleanup(srv.Close)
	return srv
}

// iDo sends method+path to srv. body (if non-nil) is JSON-encoded.
// headers is a flat key/value list. Caller must close resp.Body.
func iDo(t *testing.T, srv *httptest.Server, method, path string, body any, headers ...string) *http.Response {
	t.Helper()
	var r io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("marshal: %v", err)
		}
		r = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, srv.URL+path, r)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	for i := 0; i+1 < len(headers); i += 2 {
		req.Header.Set(headers[i], headers[i+1])
	}
	if body != nil && req.Header.Get("Content-Type") == "" {
		req.Header.Set("Content-Type", "application/fhir+json")
	}
	resp, err := srv.Client().Do(req)
	if err != nil {
		t.Fatalf("do %s %s: %v", method, path, err)
	}
	return resp
}

// iJSON decodes the JSON body of resp and closes it.
func iJSON(t *testing.T, resp *http.Response) map[string]any {
	t.Helper()
	defer resp.Body.Close()
	var m map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&m); err != nil {
		t.Fatalf("decode JSON (status %d): %v", resp.StatusCode, err)
	}
	return m
}

// iCreate creates a FHIR resource and returns its id and ETag.
func iCreate(t *testing.T, srv *httptest.Server, rt string, body map[string]any) (id, etag string) {
	t.Helper()
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/"+rt, body)
	m := iJSON(t, resp)
	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("create %s: want 201, got %d: %v", rt, resp.StatusCode, m)
	}
	return m["id"].(string), resp.Header.Get("ETag")
}

// linkRels returns a map of relation→URL from a Bundle's link array.
func linkRels(bundle map[string]any) map[string]string {
	rels := map[string]string{}
	links, _ := bundle["link"].([]any)
	for _, l := range links {
		lm, _ := l.(map[string]any)
		rel, _ := lm["relation"].(string)
		url, _ := lm["url"].(string)
		rels[rel] = url
	}
	return rels
}

// ─── Full CRUD + 410 Gone ─────────────────────────────────────────────────────

func TestIntegration_CRUD_Patient(t *testing.T) {
	srv := newRealServer(t)

	id, etag := iCreate(t, srv, "Patient", map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "Smith"}},
	})
	if id == "" {
		t.Fatal("expected non-empty id")
	}
	if etag == "" {
		t.Fatal("expected ETag on create")
	}

	// Read
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+id, nil)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("read: want 200, got %d", resp.StatusCode)
	}
	if body["id"] != id {
		t.Errorf("read: want id=%q, got %v", id, body["id"])
	}
	if resp.Header.Get("ETag") == "" {
		t.Error("read: want ETag header")
	}

	// Update
	resp = iDo(t, srv, http.MethodPut, "/fhir/r4/Patient/"+id, map[string]any{
		"resourceType": "Patient",
		"id":           id,
		"active":       true,
	})
	body = iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("update: want 200, got %d: %v", resp.StatusCode, body)
	}
	meta, _ := body["meta"].(map[string]any)
	if meta["versionId"] != "2" {
		t.Errorf("update: want versionId=2, got %v", meta["versionId"])
	}

	// Delete
	resp = iDo(t, srv, http.MethodDelete, "/fhir/r4/Patient/"+id, nil)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("delete: want 204, got %d", resp.StatusCode)
	}

	// Read after delete → 410 Gone
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+id, nil)
	body = iJSON(t, resp)
	if resp.StatusCode != http.StatusGone {
		t.Fatalf("read-after-delete: want 410, got %d: %v", resp.StatusCode, body)
	}
	if body["resourceType"] != "OperationOutcome" {
		t.Errorf("expected OperationOutcome body, got %v", body["resourceType"])
	}
}

// ─── VRead ────────────────────────────────────────────────────────────────────

func TestIntegration_VRead_Version1(t *testing.T) {
	srv := newRealServer(t)

	id, _ := iCreate(t, srv, "Patient", map[string]any{
		"resourceType": "Patient",
		"active":       true,
	})

	// Update to create version 2
	resp := iDo(t, srv, http.MethodPut, "/fhir/r4/Patient/"+id, map[string]any{
		"resourceType": "Patient",
		"id":           id,
		"active":       false,
	})
	iJSON(t, resp) // drain

	// VRead version 1 — should still have active=true
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+id+"/_history/1", nil)
	v1 := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("vread: want 200, got %d", resp.StatusCode)
	}
	if v1["active"] != true {
		t.Errorf("vread v1: want active=true, got %v", v1["active"])
	}
}

// ─── If-Match version enforcement ─────────────────────────────────────────────

func TestIntegration_IfMatch_StaleVersion_412(t *testing.T) {
	srv := newRealServer(t)

	id, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})

	resp := iDo(t, srv, http.MethodPut, "/fhir/r4/Patient/"+id,
		map[string]any{"resourceType": "Patient", "id": id},
		"If-Match", `W/"999"`,
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusPreconditionFailed {
		t.Fatalf("want 412, got %d: %v", resp.StatusCode, body)
	}
	if body["resourceType"] != "OperationOutcome" {
		t.Errorf("want OperationOutcome, got %v", body["resourceType"])
	}
}

func TestIntegration_IfMatch_CorrectVersion_200(t *testing.T) {
	srv := newRealServer(t)

	id, etag := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})

	resp := iDo(t, srv, http.MethodPut, "/fhir/r4/Patient/"+id,
		map[string]any{"resourceType": "Patient", "id": id, "active": true},
		"If-Match", etag,
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d: %v", resp.StatusCode, body)
	}
}

// ─── Content-Type enforcement ─────────────────────────────────────────────────

func TestIntegration_Create_415_WrongContentType(t *testing.T) {
	srv := newRealServer(t)

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient",
		map[string]any{"resourceType": "Patient"},
		"Content-Type", "text/xml",
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnsupportedMediaType {
		t.Fatalf("want 415, got %d: %v", resp.StatusCode, body)
	}
}

// ─── Create validation ────────────────────────────────────────────────────────

func TestIntegration_Create_422_ResourceTypeMismatch(t *testing.T) {
	srv := newRealServer(t)

	// Send Observation body to /Patient endpoint
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient",
		map[string]any{
			"resourceType": "Observation",
			"status":       "final",
			"code":         map[string]any{"text": "test"},
		},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnprocessableEntity {
		t.Fatalf("want 422, got %d: %v", resp.StatusCode, body)
	}
}

func TestIntegration_Create_422_MissingRequired_Observation(t *testing.T) {
	srv := newRealServer(t)

	// Observation without required `code` field
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Observation",
		map[string]any{"resourceType": "Observation", "status": "final"},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnprocessableEntity {
		t.Fatalf("want 422, got %d: %v", resp.StatusCode, body)
	}
}

func TestIntegration_Create_422_MissingRequired_Encounter(t *testing.T) {
	srv := newRealServer(t)

	// Encounter without required `status` field
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Encounter",
		map[string]any{
			"resourceType": "Encounter",
			"class":        map[string]any{"code": "IMP"},
		},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnprocessableEntity {
		t.Fatalf("want 422, got %d: %v", resp.StatusCode, body)
	}
}

// ─── Update validation ────────────────────────────────────────────────────────

func TestIntegration_Update_422_MissingRequired(t *testing.T) {
	srv := newRealServer(t)

	// Create valid Observation first
	id, _ := iCreate(t, srv, "Observation", map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"code":         map[string]any{"text": "test"},
	})

	// Update without code → 422
	resp := iDo(t, srv, http.MethodPut, "/fhir/r4/Observation/"+id,
		map[string]any{"resourceType": "Observation", "id": id, "status": "amended"},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnprocessableEntity {
		t.Fatalf("want 422, got %d: %v", resp.StatusCode, body)
	}
}

func TestIntegration_Update_400_BodyIdMismatch(t *testing.T) {
	srv := newRealServer(t)

	id, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})

	resp := iDo(t, srv, http.MethodPut, "/fhir/r4/Patient/"+id,
		map[string]any{"resourceType": "Patient", "id": "different-id"},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("want 400, got %d: %v", resp.StatusCode, body)
	}
}

// ─── Search ───────────────────────────────────────────────────────────────────

func TestIntegration_Search_String(t *testing.T) {
	srv := newRealServer(t)

	iCreate(t, srv, "Patient", map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "Dragonborn", "use": "official"}},
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?family=dragon", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("search: want 200, got %d", resp.StatusCode)
	}
	total, _ := bundle["total"].(float64)
	if total < 1 {
		t.Errorf("expected ≥1 result for family=dragon, got total=%v", total)
	}
}

func TestIntegration_Search_Token(t *testing.T) {
	srv := newRealServer(t)

	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient", "gender": "female"})
	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient", "gender": "male"})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?gender=female", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("search: want 200, got %d", resp.StatusCode)
	}
	total, _ := bundle["total"].(float64)
	if total < 1 {
		t.Errorf("expected ≥1 female patient, got %v", total)
	}
	entries, _ := bundle["entry"].([]any)
	for _, e := range entries {
		em, _ := e.(map[string]any)
		res, _ := em["resource"].(map[string]any)
		if res["gender"] != "female" {
			t.Errorf("non-female returned: gender=%v", res["gender"])
		}
	}
}

func TestIntegration_SearchPost(t *testing.T) {
	srv := newRealServer(t)

	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient", "gender": "male"})

	req, _ := http.NewRequest(http.MethodPost,
		srv.URL+"/fhir/r4/Patient/_search",
		strings.NewReader("gender=male"),
	)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	resp, err := srv.Client().Do(req)
	if err != nil {
		t.Fatalf("do: %v", err)
	}
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d: %v", resp.StatusCode, bundle)
	}
	total, _ := bundle["total"].(float64)
	if total < 1 {
		t.Errorf("expected ≥1 result, got %v", total)
	}
}

// ─── Pagination links ─────────────────────────────────────────────────────────

func TestIntegration_Search_Pagination_Links(t *testing.T) {
	srv := newRealServer(t)

	for i := 0; i < 5; i++ {
		iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	}

	// Page 1 with _count=2 — expect self/first/last/next but no previous
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?_page=1&_count=2", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d", resp.StatusCode)
	}
	rels := linkRels(bundle)
	for _, rel := range []string{"self", "first", "last", "next"} {
		if rels[rel] == "" {
			t.Errorf("page 1: expected link %q to be present; links=%v", rel, rels)
		}
	}
	if rels["previous"] != "" {
		t.Errorf("page 1 should have no previous link, got %q", rels["previous"])
	}

	// Page 2 — expect both next and previous
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient?_page=2&_count=2", nil)
	bundle = iJSON(t, resp)
	rels = linkRels(bundle)
	if rels["next"] == "" {
		t.Error("page 2 should have next link")
	}
	if rels["previous"] == "" {
		t.Error("page 2 should have previous link")
	}
}

// ─── $validate ────────────────────────────────────────────────────────────────

func TestIntegration_Validate_Valid(t *testing.T) {
	srv := newRealServer(t)

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/$validate",
		map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "OK"}}},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d: %v", resp.StatusCode, body)
	}
	if body["resourceType"] != "OperationOutcome" {
		t.Errorf("expected OperationOutcome, got %v", body["resourceType"])
	}
	issues, _ := body["issue"].([]any)
	if len(issues) == 0 {
		t.Fatal("expected at least one issue in OperationOutcome")
	}
	first := issues[0].(map[string]any)
	if first["severity"] != "information" {
		t.Errorf("expected severity=information, got %v", first["severity"])
	}
}

func TestIntegration_Validate_NoProfileLoaded_Passes(t *testing.T) {
	// $validate with no profile loaded is soft-fail: returns 200 informational.
	// Real enforcement happens only when a StructureDefinition is in ig_profiles.
	srv := newRealServer(t)
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Observation/$validate",
		map[string]any{"resourceType": "Observation", "status": "final"},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200 (no profile loaded), got %d: %v", resp.StatusCode, body)
	}
}

func TestIntegration_Validate_ProfileDriven(t *testing.T) {
	pool := testutil.MustSeededDB(t)
	// Inject a synthetic StructureDefinition that requires Patient.name (min=1).
	sd := map[string]any{
		"resourceType": "StructureDefinition",
		"url":          "http://example.org/fhir/StructureDefinition/must-have-name",
		"kind":         "resource", "derivation": "constraint", "type": "Patient",
		"snapshot": map[string]any{"element": []any{
			map[string]any{"path": "Patient", "min": float64(1), "max": "*"},
			map[string]any{"path": "Patient.name", "min": float64(1), "max": "*"},
		}},
	}
	sdJSON, _ := json.Marshal(sd)
	_, err := pool.Exec(
		t.Context(),
		`INSERT INTO ig_profiles (package_name, profile_url, resource_type, sd_json)
		 VALUES ('test', 'http://example.org/fhir/StructureDefinition/must-have-name', 'Patient', $1)
		 ON CONFLICT (profile_url) DO UPDATE SET sd_json = EXCLUDED.sd_json`,
		sdJSON,
	)
	if err != nil {
		t.Fatalf("inject profile: %v", err)
	}

	reg := testutil.MustRegistry(t, pool)
	s := store.New(pool, reg)
	var ready atomic.Int32
	ready.Store(1)
	srv := httptest.NewServer(handler.NewRouter(s, pool, reg, "http://test-server/fhir/r4", &ready))
	t.Cleanup(srv.Close)

	profileURL := "http://example.org/fhir/StructureDefinition/must-have-name"

	// Validate with ?profile=: invalid (missing name) → 422.
	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/$validate?profile="+profileURL,
		map[string]any{"resourceType": "Patient"},
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnprocessableEntity {
		t.Fatalf("want 422 for profile violation, got %d: %v", resp.StatusCode, body)
	}
	issues, _ := body["issue"].([]any)
	if len(issues) == 0 {
		t.Fatal("expected at least one validation issue")
	}

	// Validate with meta.profile: valid (name present) → 200.
	resp = iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/$validate",
		map[string]any{
			"resourceType": "Patient",
			"name":         []any{map[string]any{"family": "OK"}},
			"meta":         map[string]any{"profile": []any{profileURL}},
		},
	)
	body = iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200 for valid resource, got %d: %v", resp.StatusCode, body)
	}

	// Auto-validate on write (validateOnWrite=true): create without name → 422.
	srvStrict := httptest.NewServer(handler.NewRouter(s, pool, reg, "http://test-server/fhir/r4", &ready, true))
	t.Cleanup(srvStrict.Close)

	resp = iDo(t, srvStrict, http.MethodPost, "/fhir/r4/Patient",
		map[string]any{
			"resourceType": "Patient",
			"meta":         map[string]any{"profile": []any{profileURL}},
		},
	)
	if resp.StatusCode != http.StatusUnprocessableEntity {
		body = iJSON(t, resp)
		t.Fatalf("auto-validate: want 422, got %d: %v", resp.StatusCode, body)
	}
	resp.Body.Close()

	// Auto-validate on write: create with name → 201.
	resp = iDo(t, srvStrict, http.MethodPost, "/fhir/r4/Patient",
		map[string]any{
			"resourceType": "Patient",
			"name":         []any{map[string]any{"family": "Valid"}},
			"meta":         map[string]any{"profile": []any{profileURL}},
		},
	)
	if resp.StatusCode != http.StatusCreated {
		body = iJSON(t, resp)
		t.Fatalf("auto-validate: want 201 for valid write, got %d: %v", resp.StatusCode, body)
	}
	resp.Body.Close()
}

func TestIntegration_Validate_415_WrongContentType(t *testing.T) {
	srv := newRealServer(t)

	resp := iDo(t, srv, http.MethodPost, "/fhir/r4/Patient/$validate",
		map[string]any{"resourceType": "Patient"},
		"Content-Type", "text/xml",
	)
	body := iJSON(t, resp)
	if resp.StatusCode != http.StatusUnsupportedMediaType {
		t.Fatalf("want 415, got %d: %v", resp.StatusCode, body)
	}
}

// ─── $everything for Encounter and Group ─────────────────────────────────────

func TestIntegration_Everything_Encounter(t *testing.T) {
	srv := newRealServer(t)

	// Create a Patient and an Encounter referencing it.
	patID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	encID, _ := iCreate(t, srv, "Encounter", map[string]any{
		"resourceType": "Encounter", "status": "finished",
		"class":   map[string]any{"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB"},
		"subject": map[string]any{"reference": "Patient/" + patID},
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Encounter/"+encID+"/$everything", nil)
	if resp.StatusCode != http.StatusOK {
		body := iJSON(t, resp)
		t.Fatalf("Encounter/$everything: want 200, got %d: %v", resp.StatusCode, body)
	}
	bundle := iJSON(t, resp)
	if bundle["type"] != "searchset" {
		t.Errorf("bundle.type: want searchset, got %v", bundle["type"])
	}
	total, _ := bundle["total"].(float64)
	if total < 2 {
		t.Errorf("Encounter/$everything should include the Encounter + Patient, got total=%v", total)
	}
}

func TestIntegration_Everything_Group(t *testing.T) {
	srv := newRealServer(t)

	// Create a Group. $everything with no related resources should still return the Group itself.
	grpID, _ := iCreate(t, srv, "Group", map[string]any{
		"resourceType": "Group", "type": "person", "actual": true,
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Group/"+grpID+"/$everything", nil)
	if resp.StatusCode != http.StatusOK {
		body := iJSON(t, resp)
		t.Fatalf("Group/$everything: want 200, got %d: %v", resp.StatusCode, body)
	}
	bundle := iJSON(t, resp)
	total, _ := bundle["total"].(float64)
	if total < 1 {
		t.Errorf("Group/$everything should return at least the Group itself, got total=%v", total)
	}
}

// ─── searchRevInclude in CapabilityStatement ──────────────────────────────────

func TestIntegration_CapabilityStatement_SearchRevInclude(t *testing.T) {
	srv := newRealServer(t)
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/metadata", nil)
	cs := iJSON(t, resp)
	if cs["resourceType"] != "CapabilityStatement" {
		t.Fatalf("expected CapabilityStatement, got %v", cs["resourceType"])
	}
	rest, _ := cs["rest"].([]any)
	if len(rest) == 0 {
		t.Fatal("rest is empty")
	}
	r0, _ := rest[0].(map[string]any)
	resources, _ := r0["resource"].([]any)
	var patient map[string]any
	for _, r := range resources {
		rm, _ := r.(map[string]any)
		if rm["type"] == "Patient" {
			patient = rm
			break
		}
	}
	if patient == nil {
		t.Fatal("Patient not found in CapabilityStatement")
	}
	revIncludes, _ := patient["searchRevInclude"].([]any)
	if len(revIncludes) == 0 {
		t.Fatal("Patient.searchRevInclude should be non-empty (Encounter:patient etc.)")
	}
	// Encounter:patient must be one of them
	found := false
	for _, ri := range revIncludes {
		if ri == "Encounter:patient" {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Encounter:patient not in Patient.searchRevInclude; got %v", revIncludes[:min(len(revIncludes), 5)])
	}
}

// ─── Type-level history ───────────────────────────────────────────────────────

func TestIntegration_SystemHistory(t *testing.T) {
	srv := newRealServer(t)
	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	iCreate(t, srv, "Organization", map[string]any{"resourceType": "Organization", "name": "Acme"})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/_history", nil)
	if resp.StatusCode != http.StatusOK {
		body := iJSON(t, resp)
		t.Fatalf("system history: want 200, got %d: %v", resp.StatusCode, body)
	}
	b := iJSON(t, resp)
	if b["type"] != "history" {
		t.Errorf("bundle.type: want history, got %v", b["type"])
	}
	if total, _ := b["total"].(float64); total < 2 {
		t.Errorf("system history should include both Patient and Organization, got total=%v", total)
	}
}

func TestIntegration_TypeHistory_Basic(t *testing.T) {
	srv := newRealServer(t)

	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/_history", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d: %v", resp.StatusCode, bundle)
	}
	if bundle["type"] != "history" {
		t.Errorf("want type=history, got %v", bundle["type"])
	}
	total, _ := bundle["total"].(float64)
	if total < 2 {
		t.Errorf("expected ≥2 history entries, got %v", total)
	}
}

func TestIntegration_TypeHistory_Since(t *testing.T) {
	srv := newRealServer(t)

	iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})

	// _since=epoch → all records visible
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/_history?_since=2000-01-01T00:00:00Z", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d", resp.StatusCode)
	}
	totalPast, _ := bundle["total"].(float64)
	if totalPast < 1 {
		t.Errorf("_since=past: expected ≥1 entry, got %v", totalPast)
	}

	// _since=far future → no records visible
	future := time.Now().Add(24 * time.Hour).UTC().Format(time.RFC3339)
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/_history?_since="+future, nil)
	bundle = iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d", resp.StatusCode)
	}
	totalFuture, _ := bundle["total"].(float64)
	if totalFuture != 0 {
		t.Errorf("_since=future: expected 0 entries, got %v", totalFuture)
	}
}

func TestIntegration_TypeHistory_Pagination(t *testing.T) {
	srv := newRealServer(t)

	for i := 0; i < 4; i++ {
		iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	}

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/_history?_count=2&_page=1", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d", resp.StatusCode)
	}
	rels := linkRels(bundle)
	for _, rel := range []string{"self", "first", "last", "next"} {
		if rels[rel] == "" {
			t.Errorf("_history page 1: expected link %q; links=%v", rel, rels)
		}
	}
	entries, _ := bundle["entry"].([]any)
	if len(entries) > 2 {
		t.Errorf("expected ≤2 entries per page, got %d", len(entries))
	}
}

// ─── $everything ──────────────────────────────────────────────────────────────

func TestIntegration_Everything(t *testing.T) {
	srv := newRealServer(t)

	orgID, _ := iCreate(t, srv, "Organization", map[string]any{
		"resourceType": "Organization",
		"name":         "General Hospital",
	})

	patID, _ := iCreate(t, srv, "Patient", map[string]any{
		"resourceType":         "Patient",
		"name":                 []any{map[string]any{"family": "Doe"}},
		"managingOrganization": map[string]any{"reference": "Organization/" + orgID},
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+patID+"/$everything", nil)
	bundle := iJSON(t, resp)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d: %v", resp.StatusCode, bundle)
	}
	total, _ := bundle["total"].(float64)
	if total < 2 {
		t.Errorf("expected ≥2 entries (Patient + Organization), got %v", total)
	}
	entries, _ := bundle["entry"].([]any)
	foundOrg := false
	for _, e := range entries {
		em, _ := e.(map[string]any)
		res, _ := em["resource"].(map[string]any)
		if res["id"] == orgID {
			foundOrg = true
		}
	}
	if !foundOrg {
		t.Errorf("Organization %q not found in $everything bundle", orgID)
	}
}

// TestMetadata_ListsFullR4ResourceSet verifies that /metadata advertises the
// full set of FHIR R4 resource types seeded into the search-param registry
// (i.e. is derived dynamically rather than from a hardcoded subset).
func TestMetadata_ListsFullR4ResourceSet(t *testing.T) {
	srv := newRealServer(t)
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/metadata", nil)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d", resp.StatusCode)
	}
	cs := iJSON(t, resp)

	rest, _ := cs["rest"].([]any)
	if len(rest) == 0 {
		t.Fatal("rest array empty")
	}
	rest0, _ := rest[0].(map[string]any)
	resources, _ := rest0["resource"].([]any)

	// The seeded R4 base spec covers ~125+ concrete resource types. The exact
	// count may drift if the CSV is updated, so assert a generous floor instead
	// of an exact match.
	if len(resources) < 100 {
		t.Errorf("want ≥100 resources in CapabilityStatement, got %d", len(resources))
	}
	t.Logf("CapabilityStatement advertises %d resource types", len(resources))

	seen := make(map[string]bool, len(resources))
	for _, r := range resources {
		entry, _ := r.(map[string]any)
		if rt, ok := entry["type"].(string); ok {
			seen[rt] = true
		}
	}
	for _, rt := range []string{"Patient", "Observation", "Encounter", "Condition", "Procedure", "Medication", "Bundle", "ValueSet"} {
		if !seen[rt] {
			t.Errorf("expected %q in CapabilityStatement, missing", rt)
		}
	}
	// Abstract base types should be excluded.
	for _, rt := range []string{"Resource", "DomainResource"} {
		if seen[rt] {
			t.Errorf("abstract type %q should not appear in CapabilityStatement", rt)
		}
	}
}

// TestMetadata_AdvertisesSearchParams verifies each rest.resource entry carries
// a populated searchParam list sourced from the registry, and that reference
// params are projected into searchInclude. Capability-driven clients (SMART
// launchers, generic explorers) rely on this for param discovery.
func TestMetadata_AdvertisesSearchParams(t *testing.T) {
	srv := newRealServer(t)
	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/metadata", nil)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("want 200, got %d", resp.StatusCode)
	}
	cs := iJSON(t, resp)
	rest, _ := cs["rest"].([]any)
	rest0, _ := rest[0].(map[string]any)
	resources, _ := rest0["resource"].([]any)

	byType := map[string]map[string]any{}
	for _, r := range resources {
		e, _ := r.(map[string]any)
		if rt, ok := e["type"].(string); ok {
			byType[rt] = e
		}
	}

	enc, ok := byType["Encounter"]
	if !ok {
		t.Fatal("Encounter missing from CapabilityStatement")
	}
	sps, _ := enc["searchParam"].([]any)
	if len(sps) == 0 {
		t.Fatal("Encounter.searchParam is empty — registry contents not projected")
	}

	// Spot-check that "patient" is present and typed as reference.
	var foundPatient bool
	for _, p := range sps {
		m, _ := p.(map[string]any)
		if m["name"] == "patient" {
			foundPatient = true
			if m["type"] != "reference" {
				t.Errorf("Encounter.searchParam[patient].type = %v, want reference", m["type"])
			}
		}
	}
	if !foundPatient {
		t.Error("Encounter.searchParam is missing 'patient'")
	}

	// searchInclude should at minimum list reference params on this resource.
	incs, _ := enc["searchInclude"].([]any)
	if len(incs) == 0 {
		t.Fatal("Encounter.searchInclude is empty — reference params not projected as _include targets")
	}
	var foundEncPatient bool
	for _, v := range incs {
		if s, _ := v.(string); s == "Encounter:patient" {
			foundEncPatient = true
		}
	}
	if !foundEncPatient {
		t.Errorf("Encounter.searchInclude missing 'Encounter:patient'; got %v", incs)
	}
}

// ─── Patch formats ────────────────────────────────────────────────────────────

// ─── Compartment search ───────────────────────────────────────────────────────

func TestIntegration_CompartmentSearch_Patient_Observation(t *testing.T) {
	srv := newRealServer(t)
	patID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})
	otherPatID, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient"})

	// Observation for our patient.
	iCreate(t, srv, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"subject": map[string]any{"reference": "Patient/" + patID},
		"code":    map[string]any{"text": "BP"},
	})
	// Observation for a different patient — should NOT appear.
	iCreate(t, srv, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"subject": map[string]any{"reference": "Patient/" + otherPatID},
		"code":    map[string]any{"text": "HR"},
	})

	resp := iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/"+patID+"/Observation", nil)
	if resp.StatusCode != http.StatusOK {
		body := iJSON(t, resp)
		t.Fatalf("compartment search: want 200, got %d: %v", resp.StatusCode, body)
	}
	bundle := iJSON(t, resp)
	if total, _ := bundle["total"].(float64); total != 1 {
		t.Errorf("Patient/%s/Observation: expected 1, got %v", patID, total)
	}

	// Unknown compartment type → 404.
	resp = iDo(t, srv, http.MethodGet, "/fhir/r4/Medication/some-id/Observation", nil)
	if resp.StatusCode != http.StatusNotFound {
		t.Errorf("unknown compartment type: want 404, got %d", resp.StatusCode)
	}
	resp.Body.Close()
}

func TestIntegration_JSONPatch_RFC6902(t *testing.T) {
	srv := newRealServer(t)
	id, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient", "gender": "female"})

	ops := []map[string]any{
		{"op": "replace", "path": "/gender", "value": "male"},
		{"op": "add", "path": "/active", "value": true},
	}
	b, _ := json.Marshal(ops)
	req, _ := http.NewRequest(http.MethodPatch, srv.URL+"/fhir/r4/Patient/"+id, bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json-patch+json")
	resp, _ := srv.Client().Do(req)
	if resp.StatusCode != http.StatusOK {
		body := iJSON(t, resp)
		t.Fatalf("JSON Patch: want 200, got %d: %v", resp.StatusCode, body)
	}
	updated := iJSON(t, resp)
	if updated["gender"] != "male" {
		t.Errorf("gender: want male, got %v", updated["gender"])
	}
	if updated["active"] != true {
		t.Errorf("active: want true, got %v", updated["active"])
	}
	meta, _ := updated["meta"].(map[string]any)
	if v, _ := meta["versionId"].(string); v != "2" {
		t.Errorf("versionId: want 2, got %v", v)
	}
}

func TestIntegration_FHIRPatch(t *testing.T) {
	srv := newRealServer(t)
	id, _ := iCreate(t, srv, "Patient", map[string]any{"resourceType": "Patient", "gender": "female"})

	params := map[string]any{
		"resourceType": "Parameters",
		"parameter": []any{map[string]any{
			"name": "operation",
			"part": []any{
				map[string]any{"name": "type", "valueCode": "replace"},
				map[string]any{"name": "path", "valueString": "Patient.gender"},
				map[string]any{"name": "value", "valueString": "other"},
			},
		}},
	}
	resp := iDo(t, srv, http.MethodPatch, "/fhir/r4/Patient/"+id, params, "Content-Type", "application/fhir+json")
	if resp.StatusCode != http.StatusOK {
		body := iJSON(t, resp)
		t.Fatalf("FHIR Patch: want 200, got %d: %v", resp.StatusCode, body)
	}
	updated := iJSON(t, resp)
	if updated["gender"] != "other" {
		t.Errorf("gender: want other, got %v", updated["gender"])
	}
}

func TestIntegration_Metrics_Endpoint(t *testing.T) {
	srv := newRealServer(t)
	// Make a request to populate the histogram.
	iDo(t, srv, http.MethodGet, "/fhir/r4/Patient/does-not-exist", nil).Body.Close()

	resp := iDo(t, srv, http.MethodGet, "/metrics", nil)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("metrics: want 200, got %d", resp.StatusCode)
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	if !strings.Contains(string(body), "http_request_duration_seconds") {
		t.Error("metrics should contain http_request_duration_seconds")
	}
	if !strings.Contains(string(body), "fhir_request_total") {
		t.Error("metrics should contain fhir_request_total")
	}
}
