package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// ─── Mock store ───────────────────────────────────────────────────────────────

type mockStore struct {
	readFn               func(ctx context.Context, rt, id string) (map[string]any, error)
	getVersionFn         func(ctx context.Context, rt, id string, vid int) (map[string]any, error)
	createFn             func(ctx context.Context, rt string, body map[string]any) (map[string]any, error)
	updateFn             func(ctx context.Context, rt, id string, body map[string]any) (map[string]any, error)
	patchFn              func(ctx context.Context, rt, id string, patch map[string]any) (map[string]any, error)
	deleteFn             func(ctx context.Context, rt, id string) error
	getHistoryFn         func(ctx context.Context, rt, id string) ([]store.HistoryEntry, error)
	searchFn             func(ctx context.Context, sp store.SearchParams) (store.SearchResult, error)
	fetchReferencesFn    func(ctx context.Context, rt, id string, reverse bool) ([]map[string]any, error)
	syncSearchParamFn    func(ctx context.Context, body map[string]any) error
	deleteSearchParamFn  func(ctx context.Context, id string) error
}

func (m *mockStore) Read(ctx context.Context, rt, id string) (map[string]any, error) {
	return m.readFn(ctx, rt, id)
}
func (m *mockStore) GetVersion(ctx context.Context, rt, id string, vid int) (map[string]any, error) {
	return m.getVersionFn(ctx, rt, id, vid)
}
func (m *mockStore) Create(ctx context.Context, rt string, body map[string]any) (map[string]any, error) {
	return m.createFn(ctx, rt, body)
}
func (m *mockStore) Update(ctx context.Context, rt, id string, body map[string]any) (map[string]any, error) {
	return m.updateFn(ctx, rt, id, body)
}
func (m *mockStore) Patch(ctx context.Context, rt, id string, patch map[string]any) (map[string]any, error) {
	return m.patchFn(ctx, rt, id, patch)
}
func (m *mockStore) Delete(ctx context.Context, rt, id string) error {
	return m.deleteFn(ctx, rt, id)
}
func (m *mockStore) GetHistory(ctx context.Context, rt, id string) ([]store.HistoryEntry, error) {
	return m.getHistoryFn(ctx, rt, id)
}
func (m *mockStore) Search(ctx context.Context, sp store.SearchParams) (store.SearchResult, error) {
	return m.searchFn(ctx, sp)
}
func (m *mockStore) FetchReferences(ctx context.Context, rt, id string, reverse bool) ([]map[string]any, error) {
	return m.fetchReferencesFn(ctx, rt, id, reverse)
}
func (m *mockStore) SyncSearchParameter(ctx context.Context, body map[string]any) error {
	if m.syncSearchParamFn != nil {
		return m.syncSearchParamFn(ctx, body)
	}
	return nil
}
func (m *mockStore) DeleteSearchParameter(ctx context.Context, id string) error {
	if m.deleteSearchParamFn != nil {
		return m.deleteSearchParamFn(ctx, id)
	}
	return nil
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func newRouter(s handler.StoreAPI) http.Handler {
	var ready atomic.Int32
	ready.Store(1)
	return handler.NewRouter(s, nil, "http://localhost:9090/fhir/r4", &ready)
}

func do(t *testing.T, h http.Handler, method, path string, body any) *httptest.ResponseRecorder {
	t.Helper()
	var bodyBytes []byte
	if body != nil {
		var err error
		bodyBytes, err = json.Marshal(body)
		if err != nil {
			t.Fatalf("marshal body: %v", err)
		}
	}
	req := httptest.NewRequest(method, path, bytes.NewReader(bodyBytes))
	if body != nil {
		req.Header.Set("Content-Type", "application/fhir+json")
	}
	w := httptest.NewRecorder()
	h.ServeHTTP(w, req)
	return w
}

func decodeJSON(t *testing.T, w *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var m map[string]any
	if err := json.NewDecoder(w.Body).Decode(&m); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return m
}

// ─── Health endpoints ─────────────────────────────────────────────────────────

func TestHealth_Live(t *testing.T) {
	h := newRouter(&mockStore{})
	w := do(t, h, http.MethodGet, "/health/live", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}

func TestHealth_Ready_WhenReady(t *testing.T) {
	h := newRouter(&mockStore{})
	w := do(t, h, http.MethodGet, "/health/ready", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}

func TestHealth_Ready_WhenNotReady(t *testing.T) {
	var ready atomic.Int32
	// ready == 0 means not ready
	h := handler.NewRouter(&mockStore{}, nil, "http://localhost/fhir/r4", &ready)
	req := httptest.NewRequest(http.MethodGet, "/health/ready", nil)
	w := httptest.NewRecorder()
	h.ServeHTTP(w, req)
	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("want 503, got %d", w.Code)
	}
}

// ─── Read ─────────────────────────────────────────────────────────────────────

func TestRead_Found(t *testing.T) {
	ms := &mockStore{}
	ms.readFn = func(_ context.Context, rt, id string) (map[string]any, error) {
		return map[string]any{
			"resourceType": rt,
			"id":           id,
			"meta":         map[string]any{"versionId": "1"},
		}, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/p1", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
	body := decodeJSON(t, w)
	if body["id"] != "p1" {
		t.Errorf("unexpected id: %v", body["id"])
	}
	if w.Header().Get("ETag") == "" {
		t.Error("ETag header should be set")
	}
}

func TestRead_NotFound(t *testing.T) {
	ms := &mockStore{}
	ms.readFn = func(_ context.Context, rt, id string) (map[string]any, error) {
		return nil, store.NotFoundError{ResourceType: rt, ResourceID: id}
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/missing", nil)
	if w.Code != http.StatusNotFound {
		t.Fatalf("want 404, got %d", w.Code)
	}
	body := decodeJSON(t, w)
	if body["resourceType"] != "OperationOutcome" {
		t.Errorf("want OperationOutcome, got %v", body["resourceType"])
	}
}

// ─── VRead ────────────────────────────────────────────────────────────────────

func TestVRead_Found(t *testing.T) {
	ms := &mockStore{}
	ms.getVersionFn = func(_ context.Context, rt, id string, vid int) (map[string]any, error) {
		return map[string]any{"resourceType": rt, "id": id, "meta": map[string]any{"versionId": "2"}}, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/p1/_history/2", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}

func TestVRead_InvalidVersionID(t *testing.T) {
	h := newRouter(&mockStore{})
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/p1/_history/not-a-number", nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("want 400, got %d", w.Code)
	}
}

// ─── Create ───────────────────────────────────────────────────────────────────

func TestCreate_Success(t *testing.T) {
	ms := &mockStore{}
	ms.createFn = func(_ context.Context, rt string, body map[string]any) (map[string]any, error) {
		body["id"] = "generated-id"
		body["meta"] = map[string]any{"versionId": "1"}
		return body, nil
	}

	h := newRouter(ms)
	payload := map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "Smith"}}}
	w := do(t, h, http.MethodPost, "/fhir/r4/Patient", payload)
	if w.Code != http.StatusCreated {
		t.Fatalf("want 201, got %d", w.Code)
	}
	if w.Header().Get("Location") == "" {
		t.Error("Location header should be set")
	}
}

func TestCreate_InvalidJSON(t *testing.T) {
	h := newRouter(&mockStore{})
	req := httptest.NewRequest(http.MethodPost, "/fhir/r4/Patient", bytes.NewBufferString("not-json"))
	w := httptest.NewRecorder()
	h.ServeHTTP(w, req)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("want 400, got %d", w.Code)
	}
}

// ─── Update ───────────────────────────────────────────────────────────────────

func TestUpdate_Success(t *testing.T) {
	ms := &mockStore{}
	ms.updateFn = func(_ context.Context, rt, id string, body map[string]any) (map[string]any, error) {
		body["meta"] = map[string]any{"versionId": "2"}
		return body, nil
	}

	h := newRouter(ms)
	payload := map[string]any{"resourceType": "Patient", "id": "p1", "active": true}
	w := do(t, h, http.MethodPut, "/fhir/r4/Patient/p1", payload)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}

func TestUpdate_NotFound(t *testing.T) {
	ms := &mockStore{}
	ms.updateFn = func(_ context.Context, rt, id string, _ map[string]any) (map[string]any, error) {
		return nil, store.NotFoundError{ResourceType: rt, ResourceID: id}
	}

	h := newRouter(ms)
	payload := map[string]any{"resourceType": "Patient", "id": "missing"}
	w := do(t, h, http.MethodPut, "/fhir/r4/Patient/missing", payload)
	if w.Code != http.StatusNotFound {
		t.Fatalf("want 404, got %d", w.Code)
	}
}

// ─── Patch ────────────────────────────────────────────────────────────────────

func TestPatch_Success(t *testing.T) {
	ms := &mockStore{}
	ms.patchFn = func(_ context.Context, rt, id string, patch map[string]any) (map[string]any, error) {
		return map[string]any{"resourceType": rt, "id": id, "meta": map[string]any{"versionId": "3"}}, nil
	}

	h := newRouter(ms)
	payload := map[string]any{"active": false}
	w := do(t, h, http.MethodPatch, "/fhir/r4/Patient/p1", payload)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
}

// ─── Delete ───────────────────────────────────────────────────────────────────

func TestDelete_Success(t *testing.T) {
	ms := &mockStore{}
	ms.deleteFn = func(_ context.Context, rt, id string) error { return nil }

	h := newRouter(ms)
	w := do(t, h, http.MethodDelete, "/fhir/r4/Patient/p1", nil)
	if w.Code != http.StatusNoContent {
		t.Fatalf("want 204, got %d", w.Code)
	}
}

func TestDelete_NotFound(t *testing.T) {
	ms := &mockStore{}
	ms.deleteFn = func(_ context.Context, rt, id string) error {
		return store.NotFoundError{ResourceType: rt, ResourceID: id}
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodDelete, "/fhir/r4/Patient/missing", nil)
	if w.Code != http.StatusNotFound {
		t.Fatalf("want 404, got %d", w.Code)
	}
}

// ─── Search ───────────────────────────────────────────────────────────────────

func TestSearch_ReturnsBundle(t *testing.T) {
	ms := &mockStore{}
	ms.searchFn = func(_ context.Context, sp store.SearchParams) (store.SearchResult, error) {
		return store.SearchResult{
			Total: 1,
			Entries: []map[string]any{
				{"resourceType": "Patient", "id": "p1", "meta": map[string]any{"versionId": "1"}},
			},
		}, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient?name=Smith", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
	body := decodeJSON(t, w)
	if body["resourceType"] != "Bundle" {
		t.Errorf("want Bundle, got %v", body["resourceType"])
	}
	if body["type"] != "searchset" {
		t.Errorf("want searchset, got %v", body["type"])
	}
}

func TestSearch_EmptyResult(t *testing.T) {
	ms := &mockStore{}
	ms.searchFn = func(_ context.Context, sp store.SearchParams) (store.SearchResult, error) {
		return store.SearchResult{Total: 0, Entries: nil}, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Observation", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
	body := decodeJSON(t, w)
	total, _ := body["total"].(float64)
	if total != 0 {
		t.Errorf("want total=0, got %v", body["total"])
	}
}

// ─── History ──────────────────────────────────────────────────────────────────

func TestHistory_ReturnsBundle(t *testing.T) {
	ms := &mockStore{}
	ms.getHistoryFn = func(_ context.Context, rt, id string) ([]store.HistoryEntry, error) {
		return []store.HistoryEntry{
			{VersionID: 1, Operation: "POST", Resource: map[string]any{"resourceType": rt, "id": id}},
		}, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/p1/_history", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
	body := decodeJSON(t, w)
	if body["type"] != "history" {
		t.Errorf("want type=history, got %v", body["type"])
	}
}

// ─── $everything ──────────────────────────────────────────────────────────────

func TestEverything_ReturnsBundle(t *testing.T) {
	ms := &mockStore{}
	ms.readFn = func(_ context.Context, rt, id string) (map[string]any, error) {
		return map[string]any{"resourceType": rt, "id": id, "meta": map[string]any{"versionId": "1"}}, nil
	}
	ms.fetchReferencesFn = func(_ context.Context, rt, id string, reverse bool) ([]map[string]any, error) {
		if !reverse {
			return []map[string]any{
				{"resourceType": "Organization", "id": "org1", "meta": map[string]any{"versionId": "1", "lastUpdated": "2024-01-01T00:00:00Z"}},
			}, nil
		}
		return nil, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/p1/$everything", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d: %s", w.Code, w.Body.String())
	}
	body := decodeJSON(t, w)
	if body["resourceType"] != "Bundle" {
		t.Errorf("want Bundle, got %v", body["resourceType"])
	}
	total, _ := body["total"].(float64)
	if total < 2 {
		t.Errorf("expect at least anchor + 1 reference, total=%v", total)
	}
}

func TestEverything_AnchorNotFound(t *testing.T) {
	ms := &mockStore{}
	ms.readFn = func(_ context.Context, rt, id string) (map[string]any, error) {
		return nil, store.NotFoundError{ResourceType: rt, ResourceID: id}
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/missing/$everything", nil)
	if w.Code != http.StatusNotFound {
		t.Fatalf("want 404, got %d", w.Code)
	}
}

// ─── Metadata ─────────────────────────────────────────────────────────────────

func TestMetadata_ReturnsCapabilityStatement(t *testing.T) {
	h := newRouter(&mockStore{})
	w := do(t, h, http.MethodGet, "/fhir/r4/metadata", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("want 200, got %d", w.Code)
	}
	body := decodeJSON(t, w)
	if body["resourceType"] != "CapabilityStatement" {
		t.Errorf("want CapabilityStatement, got %v", body["resourceType"])
	}
	if body["fhirVersion"] != "4.0.1" {
		t.Errorf("want fhirVersion=4.0.1, got %v", body["fhirVersion"])
	}
}

// ─── Content-Type ─────────────────────────────────────────────────────────────

func TestContentType_IsFHIRJSON(t *testing.T) {
	ms := &mockStore{}
	ms.readFn = func(_ context.Context, rt, id string) (map[string]any, error) {
		return map[string]any{"resourceType": rt, "id": id, "meta": map[string]any{"versionId": "1"}}, nil
	}

	h := newRouter(ms)
	w := do(t, h, http.MethodGet, "/fhir/r4/Patient/p1", nil)
	ct := w.Header().Get("Content-Type")
	if ct != "application/fhir+json" {
		t.Errorf("want application/fhir+json, got %q", ct)
	}
}
