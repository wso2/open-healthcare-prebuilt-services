//go:build integration

package store_test

import (
	"context"
	"errors"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/testutil"
)

func newStore(t *testing.T) *store.Store {
	t.Helper()
	pool := testutil.MustSeededDB(t)
	reg := testutil.MustRegistry(t, pool)
	return store.New(pool, reg)
}

// ─── Create ───────────────────────────────────────────────────────────────────

func TestCreate_StoresResource(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	body := map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "Smith", "given": []any{"Alice"}}},
		"birthDate":    "1990-05-15",
		"gender":       "female",
	}

	created, err := s.Create(ctx, "Patient", body)
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	if created["id"] == nil || created["id"] == "" {
		t.Fatal("expected id to be assigned")
	}
	meta := created["meta"].(map[string]any)
	if meta["versionId"] != "1" {
		t.Errorf("expected versionId=1, got %v", meta["versionId"])
	}
}

func TestCreate_AssignsUUID_WhenNoIDGiven(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	r1, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	r2, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})

	id1, _ := r1["id"].(string)
	id2, _ := r2["id"].(string)
	if id1 == "" || id2 == "" || id1 == id2 {
		t.Fatalf("expected unique UUIDs, got %q and %q", id1, id2)
	}
}

func TestCreate_UsesProvidedID(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	body := map[string]any{"resourceType": "Patient", "id": "my-patient-1"}
	created, err := s.Create(ctx, "Patient", body)
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	if created["id"] != "my-patient-1" {
		t.Errorf("expected id='my-patient-1', got %v", created["id"])
	}
}

// ─── Read ─────────────────────────────────────────────────────────────────────

func TestRead_RoundTrip(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "Jones"}},
	})
	id := created["id"].(string)

	read, err := s.Read(ctx, "Patient", id)
	if err != nil {
		t.Fatalf("Read: %v", err)
	}
	names := read["name"].([]any)
	firstFamily := names[0].(map[string]any)["family"].(string)
	if firstFamily != "Jones" {
		t.Errorf("expected family=Jones, got %q", firstFamily)
	}
}

func TestRead_NotFound(t *testing.T) {
	s := newStore(t)
	_, err := s.Read(context.Background(), "Patient", "does-not-exist")
	var nfe store.NotFoundError
	if !errors.As(err, &nfe) {
		t.Fatalf("expected NotFoundError, got %T: %v", err, err)
	}
}

func TestRead_WrongResourceType_NotFound(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	id := created["id"].(string)

	_, err := s.Read(ctx, "Observation", id) // right ID, wrong type
	var nfe store.NotFoundError
	if !errors.As(err, &nfe) {
		t.Fatalf("expected NotFoundError for wrong type, got %T: %v", err, err)
	}
}

// ─── Update ───────────────────────────────────────────────────────────────────

func TestUpdate_BumpsVersion(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"active":       true,
	})
	id := created["id"].(string)

	updated, err := s.Update(ctx, "Patient", id, map[string]any{
		"resourceType": "Patient",
		"id":           id,
		"active":       false,
	})
	if err != nil {
		t.Fatalf("Update: %v", err)
	}
	meta := updated["meta"].(map[string]any)
	if meta["versionId"] != "2" {
		t.Errorf("expected versionId=2, got %v", meta["versionId"])
	}
	if updated["active"] != false {
		t.Errorf("expected active=false, got %v", updated["active"])
	}
}

func TestUpdate_NotFound(t *testing.T) {
	s := newStore(t)
	_, err := s.Update(context.Background(), "Patient", "ghost-id", map[string]any{})
	var nfe store.NotFoundError
	if !errors.As(err, &nfe) {
		t.Fatalf("expected NotFoundError, got %T: %v", err, err)
	}
}

// ─── Patch ────────────────────────────────────────────────────────────────────

func TestPatch_MergesFields(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"active":       true,
		"gender":       "male",
	})
	id := created["id"].(string)

	patched, err := s.Patch(ctx, "Patient", id, map[string]any{
		"gender": "female", // change only gender
	})
	if err != nil {
		t.Fatalf("Patch: %v", err)
	}
	if patched["gender"] != "female" {
		t.Errorf("expected gender=female, got %v", patched["gender"])
	}
	if patched["active"] != true {
		t.Errorf("active should survive patch, got %v", patched["active"])
	}
}

func TestPatch_DeleteFieldWithNull(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"gender":       "male",
		"active":       true,
	})
	id := created["id"].(string)

	patched, err := s.Patch(ctx, "Patient", id, map[string]any{
		"gender": nil, // RFC 7396: null removes the field
	})
	if err != nil {
		t.Fatalf("Patch: %v", err)
	}
	if _, ok := patched["gender"]; ok {
		t.Error("gender should have been deleted by null patch")
	}
}

// ─── Delete ───────────────────────────────────────────────────────────────────

func TestDelete_SoftDeletes(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	id := created["id"].(string)

	if err := s.Delete(ctx, "Patient", id); err != nil {
		t.Fatalf("Delete: %v", err)
	}

	// Read should now return NotFound
	_, err := s.Read(ctx, "Patient", id)
	var nfe store.NotFoundError
	if !errors.As(err, &nfe) {
		t.Fatalf("expected NotFoundError after delete, got %T: %v", err, err)
	}
}

func TestDelete_NotFound(t *testing.T) {
	s := newStore(t)
	err := s.Delete(context.Background(), "Patient", "no-such-id")
	var nfe store.NotFoundError
	if !errors.As(err, &nfe) {
		t.Fatalf("expected NotFoundError, got %T: %v", err, err)
	}
}

// ─── History ──────────────────────────────────────────────────────────────────

func TestGetHistory_RecordsOperations(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient", "active": true,
	})
	id := created["id"].(string)

	s.Update(ctx, "Patient", id, map[string]any{
		"resourceType": "Patient", "id": id, "active": false,
	})
	s.Delete(ctx, "Patient", id)

	entries, err := s.GetHistory(ctx, "Patient", id)
	if err != nil {
		t.Fatalf("GetHistory: %v", err)
	}
	if len(entries) != 3 {
		t.Fatalf("expected 3 history entries, got %d", len(entries))
	}
	// History is returned newest first
	ops := make([]string, len(entries))
	for i, e := range entries {
		ops[i] = e.Operation
	}
	// newest = DELETE, then PUT, then POST
	if ops[0] != "DELETE" {
		t.Errorf("first entry should be DELETE, got %q", ops[0])
	}
	if ops[2] != "POST" {
		t.Errorf("last entry should be POST, got %q", ops[2])
	}
}

// ─── GetVersion ───────────────────────────────────────────────────────────────

func TestGetVersion_ReturnsSpecificVersion(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient", "active": true,
	})
	id := created["id"].(string)

	s.Update(ctx, "Patient", id, map[string]any{
		"resourceType": "Patient", "id": id, "active": false,
	})

	// Read version 1 — should have active=true
	v1, err := s.GetVersion(ctx, "Patient", id, 1)
	if err != nil {
		t.Fatalf("GetVersion: %v", err)
	}
	if v1["active"] != true {
		t.Errorf("version 1: expected active=true, got %v", v1["active"])
	}

	// Read version 2 — should have active=false
	v2, err := s.GetVersion(ctx, "Patient", id, 2)
	if err != nil {
		t.Fatalf("GetVersion v2: %v", err)
	}
	if v2["active"] != false {
		t.Errorf("version 2: expected active=false, got %v", v2["active"])
	}
}

func TestGetVersion_NotFound(t *testing.T) {
	s := newStore(t)
	_, err := s.GetVersion(context.Background(), "Patient", "ghost", 99)
	var nfe store.NotFoundError
	if !errors.As(err, &nfe) {
		t.Fatalf("expected NotFoundError, got %T: %v", err, err)
	}
}

// ─── Search ───────────────────────────────────────────────────────────────────

func TestSearch_ByID(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	id := created["id"].(string)

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_id": {id}},
	})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if result.Total != 1 {
		t.Errorf("expected 1 result, got %d", result.Total)
	}
	foundID, _ := result.Entries[0]["id"].(string)
	if foundID != id {
		t.Errorf("expected id=%q, got %q", id, foundID)
	}
}

func TestSearch_Pagination(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Create 5 patients
	for i := 0; i < 5; i++ {
		s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	}

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Page:         1,
		PageSize:     2,
	})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if len(result.Entries) > 2 {
		t.Errorf("expected ≤2 entries on page, got %d", len(result.Entries))
	}
	if result.Total < 5 {
		t.Errorf("expected total≥5, got %d", result.Total)
	}
}

func TestSearch_ByStringParam(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "Dragonborn", "use": "official"}},
	})
	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "Generic"}},
	})

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"family": {"dragon"}},
	})
	if err != nil {
		t.Fatalf("Search by family: %v", err)
	}
	if result.Total < 1 {
		t.Errorf("expected ≥1 result for family=dragon, got %d", result.Total)
	}
}

func TestSearch_ByTokenParam(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"gender":       "female",
	})
	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"gender":       "male",
	})

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"gender": {"female"}},
	})
	if err != nil {
		t.Fatalf("Search by gender: %v", err)
	}
	if result.Total < 1 {
		t.Errorf("expected ≥1 female patient, got %d", result.Total)
	}
	for _, entry := range result.Entries {
		if entry["gender"] != "female" {
			t.Errorf("non-female patient returned: gender=%v", entry["gender"])
		}
	}
}

func TestSearch_ByDateParam(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"birthDate":    "1990-01-01",
	})

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"birthdate": {"ge1980"}},
	})
	if err != nil {
		t.Fatalf("Search by birthdate: %v", err)
	}
	if result.Total < 1 {
		t.Errorf("expected ≥1 patient born after 1980, got %d", result.Total)
	}
}

func TestSearch_DeletedResourcesExcluded(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	created, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	id := created["id"].(string)
	s.Delete(ctx, "Patient", id)

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_id": {id}},
	})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if result.Total != 0 {
		t.Errorf("deleted resource should not appear in search, got total=%d", result.Total)
	}
}

// ─── FetchReferences ──────────────────────────────────────────────────────────

func TestFetchReferences_Forward(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	org, _ := s.Create(ctx, "Organization", map[string]any{
		"resourceType": "Organization",
		"name":         "General Hospital",
	})
	orgID := org["id"].(string)

	pat, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType":         "Patient",
		"managingOrganization": map[string]any{"reference": "Organization/" + orgID},
	})
	patID := pat["id"].(string)

	refs, err := s.FetchReferences(ctx, "Patient", patID, false)
	if err != nil {
		t.Fatalf("FetchReferences (forward): %v", err)
	}
	if len(refs) == 0 {
		t.Fatal("expected ≥1 forward reference (Organization)")
	}
	found := false
	for _, r := range refs {
		if r["id"] == orgID {
			found = true
		}
	}
	if !found {
		t.Errorf("expected orgID %q in forward refs, got: %v", orgID, refs)
	}
}

func TestFetchReferences_Reverse(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	pat, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	patID := pat["id"].(string)

	obs, _ := s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"subject":      map[string]any{"reference": "Patient/" + patID},
		"code": map[string]any{
			"coding": []any{
				map[string]any{"system": "http://loinc.org", "code": "8310-5"},
			},
		},
	})
	obsID := obs["id"].(string)

	refs, err := s.FetchReferences(ctx, "Patient", patID, true)
	if err != nil {
		t.Fatalf("FetchReferences (reverse): %v", err)
	}
	found := false
	for _, r := range refs {
		if r["id"] == obsID {
			found = true
		}
	}
	if !found {
		t.Errorf("expected obsID %q in reverse refs, got: %v", obsID, refs)
	}
}

// ─── SearchParameter sync ─────────────────────────────────────────────────────

func TestSyncSearchParameter_UpsertAndLookup(t *testing.T) {
	pool := testutil.MustSeededDB(t)
	reg := testutil.MustRegistry(t, pool)
	s := store.New(pool, reg)
	ctx := context.Background()

	// Create a custom SearchParameter resource
	spBody := map[string]any{
		"resourceType": "SearchParameter",
		"code":         "my-custom-param",
		"type":         "string",
		"base":         []any{"Patient"},
		"expression":   "Patient.extension('http://example.com/custom')",
	}
	if err := s.SyncSearchParameter(ctx, spBody); err != nil {
		t.Fatalf("SyncSearchParameter: %v", err)
	}

	// Should now be in the registry
	def, ok := reg.Lookup("Patient", "my-custom-param")
	if !ok {
		t.Fatal("expected custom param to be in registry after sync")
	}
	if !def.IsCustom {
		t.Error("expected IsCustom=true")
	}
	if def.ParamType != "string" {
		t.Errorf("expected type=string, got %q", def.ParamType)
	}
}

func TestDeleteSearchParameter_RemovesFromRegistry(t *testing.T) {
	pool := testutil.MustSeededDB(t)
	reg := testutil.MustRegistry(t, pool)
	s := store.New(pool, reg)
	ctx := context.Background()

	// Create and sync a SearchParameter resource
	spBody := map[string]any{
		"resourceType": "SearchParameter",
		"code":         "delete-me-param",
		"type":         "token",
		"base":         []any{"Observation"},
		"expression":   "Observation.extension('http://example.com/dm')",
	}
	s.SyncSearchParameter(ctx, spBody)

	// Persist it as a resource so DeleteSearchParameter can find it
	created, _ := s.Create(ctx, "SearchParameter", spBody)
	resourceID := created["id"].(string)

	if err := s.DeleteSearchParameter(ctx, resourceID); err != nil {
		t.Fatalf("DeleteSearchParameter: %v", err)
	}

	_, stillExists := reg.Lookup("Observation", "delete-me-param")
	if stillExists {
		t.Error("expected param to be removed from registry after delete")
	}
}
