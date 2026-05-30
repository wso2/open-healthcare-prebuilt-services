//go:build integration

package store_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
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
	}, -1)
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
	_, err := s.Update(context.Background(), "Patient", "ghost-id", map[string]any{}, 0)
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

	// Read should now return GoneError (soft-deleted, not absent)
	_, err := s.Read(ctx, "Patient", id)
	var ge store.GoneError
	if !errors.As(err, &ge) {
		t.Fatalf("expected GoneError after delete, got %T: %v", err, err)
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
	}, -1)
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
	}, -1)

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

func TestSearch_ByReferenceParam(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	pat, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	patID := pat["id"].(string)

	obs, _ := s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"subject":      map[string]any{"reference": "Patient/" + patID},
		"code": map[string]any{
			"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8310-5"}},
		},
	})
	obsID := obs["id"].(string)

	// An Observation for a different patient that must NOT match.
	s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"subject":      map[string]any{"reference": "Patient/someone-else"},
		"code": map[string]any{
			"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8310-5"}},
		},
	})

	// Type/id form: Observation?subject=Patient/<id>
	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Observation",
		Params:       map[string][]string{"subject": {"Patient/" + patID}},
	})
	if err != nil {
		t.Fatalf("Search by subject=Patient/id: %v", err)
	}
	if result.Total != 1 {
		t.Fatalf("expected exactly 1 Observation for subject=Patient/%s, got %d", patID, result.Total)
	}
	if result.Entries[0]["id"] != obsID {
		t.Errorf("wrong Observation returned: got %v, want %v", result.Entries[0]["id"], obsID)
	}

	// Bare id form: Observation?subject=<id>
	bare, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Observation",
		Params:       map[string][]string{"subject": {patID}},
	})
	if err != nil {
		t.Fatalf("Search by subject=<bare id>: %v", err)
	}
	if bare.Total != 1 {
		t.Errorf("expected 1 Observation for subject=%s (bare id), got %d", patID, bare.Total)
	}
}

func TestSearch_ByQuantityParam(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Encounter.length is a quantity search param (Encounter.length).
	s.Create(ctx, "Encounter", map[string]any{
		"resourceType": "Encounter",
		"status":       "finished",
		"class":        map[string]any{"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "AMB"},
		"length": map[string]any{
			"value":  float64(120),
			"unit":   "min",
			"system": "http://unitsofmeasure.org",
			"code":   "min",
		},
	})

	// Exact value with system|code.
	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Encounter",
		Params:       map[string][]string{"length": {"120|http://unitsofmeasure.org|min"}},
	})
	if err != nil {
		t.Fatalf("Search by length=120|...|min: %v", err)
	}
	if result.Total < 1 {
		t.Errorf("expected ≥1 Encounter for length=120|...|min, got %d", result.Total)
	}

	// gt prefix.
	gt, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Encounter",
		Params:       map[string][]string{"length": {"gt100"}},
	})
	if err != nil {
		t.Fatalf("Search by length=gt100: %v", err)
	}
	if gt.Total < 1 {
		t.Errorf("expected ≥1 Encounter for length=gt100, got %d", gt.Total)
	}

	// Non-matching upper bound: lt100 should exclude the 120-min encounter.
	lt, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Encounter",
		Params:       map[string][]string{"length": {"lt100"}},
	})
	if err != nil {
		t.Fatalf("Search by length=lt100: %v", err)
	}
	if lt.Total != 0 {
		t.Errorf("expected 0 Encounters for length=lt100, got %d", lt.Total)
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

// ─── Concurrency ──────────────────────────────────────────────────────────────

// TestConcurrent_Updates fires N concurrent PUTs to the same resource and
// verifies that all succeed (due to FOR UPDATE lock serialisation) and that
// the final version equals N+1 (1 from Create + N updates).
func TestConcurrent_Updates(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()
	const workers = 10

	created, err := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"active":       true,
	})
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	id := created["id"].(string)

	var wg sync.WaitGroup
	errs := make([]error, workers)
	for i := range workers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			_, errs[i] = s.Update(ctx, "Patient", id, map[string]any{
				"resourceType": "Patient",
				"id":           id,
				"active":       i%2 == 0,
			}, -1)
		}(i)
	}
	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Errorf("worker %d Update failed: %v", i, err)
		}
	}

	final, err := s.Read(ctx, "Patient", id)
	if err != nil {
		t.Fatalf("Read after concurrent updates: %v", err)
	}
	meta := final["meta"].(map[string]any)
	if meta["versionId"] != fmt.Sprintf("%d", workers+1) {
		t.Errorf("expected versionId=%d after %d concurrent updates, got %v", workers+1, workers, meta["versionId"])
	}
}

// TestConcurrent_Patches fires N concurrent PATCHes each setting a distinct
// field and verifies no lost-update: every field must be present in the result.
func TestConcurrent_Patches(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()
	const workers = 5

	created, err := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"active":       true,
	})
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	id := created["id"].(string)

	// Each goroutine patches a unique top-level extension field.
	var wg sync.WaitGroup
	errs := make([]error, workers)
	for i := range workers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			_, errs[i] = s.Patch(ctx, "Patient", id, map[string]any{
				fmt.Sprintf("x-field-%d", i): fmt.Sprintf("value-%d", i),
			})
		}(i)
	}
	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Errorf("worker %d Patch failed: %v", i, err)
		}
	}

	final, err := s.Read(ctx, "Patient", id)
	if err != nil {
		t.Fatalf("Read after concurrent patches: %v", err)
	}
	// Every distinct field set by each goroutine must survive.
	for i := range workers {
		key := fmt.Sprintf("x-field-%d", i)
		if final[key] != fmt.Sprintf("value-%d", i) {
			t.Errorf("lost update: field %q missing or wrong in final resource", key)
		}
	}
}

// TestConcurrent_DeleteIdempotent verifies that calling Delete from multiple
// goroutines simultaneously on the same resource does not produce errors;
// exactly one goroutine performs the delete, the rest get a clean nil return
// (idempotent 204 semantics).
func TestConcurrent_DeleteIdempotent(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()
	const workers = 5

	created, err := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
	})
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	id := created["id"].(string)

	var wg sync.WaitGroup
	errs := make([]error, workers)
	for i := range workers {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			errs[i] = s.Delete(ctx, "Patient", id)
		}(i)
	}
	wg.Wait()

	for i, err := range errs {
		if err != nil {
			t.Errorf("worker %d Delete returned unexpected error: %v", i, err)
		}
	}
}
