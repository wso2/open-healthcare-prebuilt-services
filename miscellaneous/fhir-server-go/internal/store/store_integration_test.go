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

func TestSearch_Sort(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Distinct family names; create out of order to prove the sort is real.
	for _, fam := range []string{"Charlie", "Alice", "Bob"} {
		s.Create(ctx, "Patient", map[string]any{
			"resourceType": "Patient",
			"name":         []any{map[string]any{"family": fam}},
		})
	}

	familiesInOrder := func(params map[string][]string) []string {
		result, err := s.Search(ctx, store.SearchParams{ResourceType: "Patient", Params: params})
		if err != nil {
			t.Fatalf("Search: %v", err)
		}
		var fams []string
		for _, e := range result.Entries {
			names, _ := e["name"].([]any)
			if len(names) == 0 {
				continue
			}
			n, _ := names[0].(map[string]any)
			fams = append(fams, n["family"].(string))
		}
		return fams
	}

	asc := familiesInOrder(map[string][]string{"family": {"a,b,c"}, "_sort": {"family"}})
	// The family search filter matches all three (prefix a/b/c); assert order.
	if len(asc) != 3 || asc[0] != "Alice" || asc[1] != "Bob" || asc[2] != "Charlie" {
		t.Fatalf("ascending _sort=family: got %v, want [Alice Bob Charlie]", asc)
	}

	desc := familiesInOrder(map[string][]string{"family": {"a,b,c"}, "_sort": {"-family"}})
	if len(desc) != 3 || desc[0] != "Charlie" || desc[1] != "Bob" || desc[2] != "Alice" {
		t.Fatalf("descending _sort=-family: got %v, want [Charlie Bob Alice]", desc)
	}
}

func TestSearch_CountOnly(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	for i := 0; i < 3; i++ {
		s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	}

	result, err := s.Search(ctx, store.SearchParams{ResourceType: "Patient", CountOnly: true})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if result.Total != 3 {
		t.Errorf("_summary=count: expected total=3, got %d", result.Total)
	}
	if len(result.Entries) != 0 {
		t.Errorf("_summary=count: expected no entries, got %d", len(result.Entries))
	}
}

func TestSearch_TotalNone_SkipsCount(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	for i := 0; i < 3; i++ {
		s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	}

	result, err := s.Search(ctx, store.SearchParams{ResourceType: "Patient", Total: "none"})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if result.Total != -1 {
		t.Errorf("_total=none: expected total=-1 (not computed), got %d", result.Total)
	}
	if len(result.Entries) != 3 {
		t.Errorf("_total=none: expected entries still returned, got %d", len(result.Entries))
	}
}

func TestSearch_NotModifier(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "gender": "female"})
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "gender": "male"})

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"gender:not": {"male"}},
	})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if result.Total != 1 {
		t.Fatalf("gender:not=male: expected 1 (the female), got %d", result.Total)
	}
	if g, _ := result.Entries[0]["gender"].(string); g != "female" {
		t.Errorf("expected female, got %q", g)
	}
}

func TestSearch_TextModifier(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// clinical-status (token, CodeableConcept with display) is indexed, so its
	// display text is available for the :text modifier.
	s.Create(ctx, "Condition", map[string]any{
		"resourceType": "Condition",
		"clinicalStatus": map[string]any{"coding": []any{map[string]any{
			"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active", "display": "Active and ongoing",
		}}},
	})
	s.Create(ctx, "Condition", map[string]any{
		"resourceType": "Condition",
		"clinicalStatus": map[string]any{"coding": []any{map[string]any{
			"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "resolved", "display": "Resolved",
		}}},
	})

	result, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Condition",
		Params:       map[string][]string{"clinical-status:text": {"ongoing"}},
	})
	if err != nil {
		t.Fatalf("Search: %v", err)
	}
	if result.Total != 1 {
		t.Fatalf("clinical-status:text=ongoing: expected 1, got %d", result.Total)
	}
}

func TestSearch_URIModifiers(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	for _, u := range []string{"http://acme.org/cs", "http://acme.org/cs/child", "http://other.org/cs"} {
		s.Create(ctx, "CodeSystem", map[string]any{
			"resourceType": "CodeSystem", "url": u, "status": "active", "content": "complete",
		})
	}

	below, err := s.Search(ctx, store.SearchParams{
		ResourceType: "CodeSystem",
		Params:       map[string][]string{"url:below": {"http://acme.org/cs"}},
	})
	if err != nil {
		t.Fatalf("below: %v", err)
	}
	if below.Total != 2 {
		t.Errorf("url:below=http://acme.org/cs: expected 2, got %d", below.Total)
	}

	above, err := s.Search(ctx, store.SearchParams{
		ResourceType: "CodeSystem",
		Params:       map[string][]string{"url:above": {"http://acme.org/cs/child"}},
	})
	if err != nil {
		t.Fatalf("above: %v", err)
	}
	// Stored URIs that are prefixes of the search value: the cs and cs/child.
	if above.Total != 2 {
		t.Errorf("url:above=http://acme.org/cs/child: expected 2, got %d", above.Total)
	}
}

func TestSearch_UnsupportedTokenModifier(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "gender": "female"})

	_, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"gender:above": {"x"}},
	})
	var unsup *store.UnsupportedParamError
	if !errors.As(err, &unsup) {
		t.Fatalf("expected UnsupportedParamError for token :above, got %v", err)
	}
}

func TestSearch_SeededBinaryAndObservationDefinition(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Binary", map[string]any{"resourceType": "Binary", "contentType": "application/pdf"})
	s.Create(ctx, "Binary", map[string]any{"resourceType": "Binary", "contentType": "image/png"})

	res, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Binary",
		Params:       map[string][]string{"contenttype": {"application/pdf"}},
	})
	if err != nil {
		t.Fatalf("Binary contenttype search: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("Binary?contenttype=application/pdf: expected 1, got %d", res.Total)
	}

	s.Create(ctx, "ObservationDefinition", map[string]any{
		"resourceType": "ObservationDefinition",
		"code":         map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "1234-5"}}},
	})
	res, err = s.Search(ctx, store.SearchParams{
		ResourceType: "ObservationDefinition",
		Params:       map[string][]string{"code": {"http://loinc.org|1234-5"}},
	})
	if err != nil {
		t.Fatalf("ObservationDefinition code search: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("ObservationDefinition?code=...: expected 1, got %d", res.Total)
	}
}

func TestSearch_MetaParams(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient",
		"language":     "en-US",
		"meta": map[string]any{
			"profile":  []any{"http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"},
			"source":   "http://example.org/feed",
			"tag":      []any{map[string]any{"system": "http://example.org/tags", "code": "vip"}},
			"security": []any{map[string]any{"system": "http://terminology.hl7.org/CodeSystem/v3-Confidentiality", "code": "R"}},
		},
	})
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "language": "fr"})

	cases := []struct {
		name   string
		params map[string][]string
		want   int
	}{
		{"_tag", map[string][]string{"_tag": {"http://example.org/tags|vip"}}, 1},
		{"_tag code-only", map[string][]string{"_tag": {"vip"}}, 1},
		{"_profile", map[string][]string{"_profile": {"http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"}}, 1},
		{"_source", map[string][]string{"_source": {"http://example.org/feed"}}, 1},
		{"_security", map[string][]string{"_security": {"R"}}, 1},
		{"_language", map[string][]string{"_language": {"en-US"}}, 1},
		{"_language fr", map[string][]string{"_language": {"fr"}}, 1},
		{"_profile:below", map[string][]string{"_profile:below": {"http://hl7.org/fhir/us/core"}}, 1},
	}
	for _, tc := range cases {
		res, err := s.Search(ctx, store.SearchParams{ResourceType: "Patient", Params: tc.params})
		if err != nil {
			t.Errorf("%s: %v", tc.name, err)
			continue
		}
		if res.Total != tc.want {
			t.Errorf("%s: expected %d, got %d", tc.name, tc.want, res.Total)
		}
	}
}

func TestSearch_CompositeParam(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Observation with code 8480-6 and a quantity value of 120 mm[Hg]
	s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"code":          map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8480-6"}}},
		"valueQuantity": map[string]any{"value": float64(120), "system": "http://unitsofmeasure.org", "code": "mm[Hg]"},
	})
	// Observation with same code but different value
	s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"code":          map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8480-6"}}},
		"valueQuantity": map[string]any{"value": float64(80), "system": "http://unitsofmeasure.org", "code": "mm[Hg]"},
	})
	// Observation with a different code
	s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"code":          map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "9999-9"}}},
		"valueQuantity": map[string]any{"value": float64(120), "system": "http://unitsofmeasure.org", "code": "mm[Hg]"},
	})

	// code-value-quantity=http://loinc.org|8480-6$120 should match only the first.
	res, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Observation",
		Params:       map[string][]string{"code-value-quantity": {"http://loinc.org|8480-6$120"}},
	})
	if err != nil {
		t.Fatalf("composite search: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("code-value-quantity=...8480-6$120: expected 1, got %d", res.Total)
	}
}

func TestSearch_PreviouslyBlankExpressions(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Observation.code — its CSV expression was blank, so this returned nothing.
	s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation", "status": "final",
		"code": map[string]any{"coding": []any{map[string]any{
			"system": "http://loinc.org", "code": "85354-9",
		}}},
		"valueQuantity": map[string]any{"value": 120, "system": "http://unitsofmeasure.org", "code": "mm[Hg]"},
	})
	// Patient.death-date — polymorphic deceased[x] via ofType(dateTime).
	s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient", "deceasedDateTime": "2020-03-15T00:00:00Z",
	})

	cases := []struct {
		rt     string
		params map[string][]string
		want   int
		label  string
	}{
		{"Observation", map[string][]string{"code": {"http://loinc.org|85354-9"}}, 1, "Observation?code"},
		{"Observation", map[string][]string{"value-quantity": {"120"}}, 1, "Observation?value-quantity"},
		{"Patient", map[string][]string{"death-date": {"2020-03-15"}}, 1, "Patient?death-date"},
	}
	for _, tc := range cases {
		res, err := s.Search(ctx, store.SearchParams{ResourceType: tc.rt, Params: tc.params})
		if err != nil {
			t.Errorf("%s: %v", tc.label, err)
			continue
		}
		if res.Total != tc.want {
			t.Errorf("%s: expected %d, got %d", tc.label, tc.want, res.Total)
		}
	}
}

func TestSearch_Has(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	pat, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "name": []any{map[string]any{"family": "Has-Target"}}})
	patID := pat["id"].(string)

	// An Encounter with status=finished referencing the patient.
	s.Create(ctx, "Encounter", map[string]any{
		"resourceType": "Encounter", "status": "finished",
		"subject": map[string]any{"reference": "Patient/" + patID},
	})
	// A second Encounter with status=planned referencing the same patient.
	s.Create(ctx, "Encounter", map[string]any{
		"resourceType": "Encounter", "status": "planned",
		"subject": map[string]any{"reference": "Patient/" + patID},
	})
	// An unrelated patient with no encounters.
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})

	// Find Patients that have a finished Encounter referencing them via subject.
	res, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_has:Encounter:subject:status": {"finished"}},
	})
	if err != nil {
		t.Fatalf("_has search: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("_has:Encounter:subject:status=finished: expected 1, got %d", res.Total)
	} else if id, _ := res.Entries[0]["id"].(string); id != patID {
		t.Errorf("expected patient %s, got %s", patID, id)
	}

	// Bad modifier (missing segment) → error.
	_, err = s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_has:Encounter:subject": {"x"}},
	})
	var unsup *store.UnsupportedParamError
	if !errors.As(err, &unsup) {
		t.Errorf("malformed _has: expected UnsupportedParamError, got %v", err)
	}
}

func TestSearch_Chained(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Organization "Acme" referenced by a Patient via managingOrganization.
	org, _ := s.Create(ctx, "Organization", map[string]any{"resourceType": "Organization", "name": "Acme"})
	orgID := org["id"].(string)
	s.Create(ctx, "Patient", map[string]any{
		"resourceType":         "Patient",
		"name":                 []any{map[string]any{"family": "Smith"}},
		"managingOrganization": map[string]any{"reference": "Organization/" + orgID},
	})
	// A second Patient pointing at a different org, to prove the chain filters.
	org2, _ := s.Create(ctx, "Organization", map[string]any{"resourceType": "Organization", "name": "Globex"})
	s.Create(ctx, "Patient", map[string]any{
		"resourceType":         "Patient",
		"name":                 []any{map[string]any{"family": "Jones"}},
		"managingOrganization": map[string]any{"reference": "Organization/" + org2["id"].(string)},
	})

	// Untyped chain, ref name == target type: organization.name=Acme.
	res, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"organization.name": {"Acme"}},
	})
	if err != nil {
		t.Fatalf("organization.name: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("Patient?organization.name=Acme: expected 1, got %d", res.Total)
	} else if fam := res.Entries[0]["name"].([]any)[0].(map[string]any)["family"]; fam != "Smith" {
		t.Errorf("expected Smith, got %v", fam)
	}

	// Encounter.subject typed chain to Patient.
	pat, _ := s.Create(ctx, "Patient", map[string]any{
		"resourceType": "Patient", "name": []any{map[string]any{"family": "Targaryen"}},
	})
	s.Create(ctx, "Encounter", map[string]any{
		"resourceType": "Encounter", "status": "finished",
		"subject": map[string]any{"reference": "Patient/" + pat["id"].(string)},
	})

	typed, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Encounter",
		Params:       map[string][]string{"subject:Patient.family": {"Targaryen"}},
	})
	if err != nil {
		t.Fatalf("subject:Patient.family: %v", err)
	}
	if typed.Total != 1 {
		t.Errorf("Encounter?subject:Patient.family=Targaryen: expected 1, got %d", typed.Total)
	}

	// Untyped chain inferred from ref name "patient" → Patient.
	inferred, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Encounter",
		Params:       map[string][]string{"patient.family": {"Targaryen"}},
	})
	if err != nil {
		t.Fatalf("patient.family: %v", err)
	}
	if inferred.Total != 1 {
		t.Errorf("Encounter?patient.family=Targaryen: expected 1, got %d", inferred.Total)
	}

	// Multi-hop is rejected (fail closed).
	_, err = s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"organization.partof.name": {"x"}},
	})
	var unsup *store.UnsupportedParamError
	if !errors.As(err, &unsup) {
		t.Errorf("expected UnsupportedParamError for multi-hop chain, got %v", err)
	}
}

func TestSearch_List(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	p1, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	p2, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"}) // not in list

	list, _ := s.Create(ctx, "List", map[string]any{
		"resourceType": "List", "status": "current", "mode": "working",
		"entry": []any{
			map[string]any{"item": map[string]any{"reference": "Patient/" + p1["id"].(string)}},
			map[string]any{"item": map[string]any{"reference": "Patient/" + p2["id"].(string)}},
		},
	})
	listID := list["id"].(string)

	res, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_list": {listID}},
	})
	if err != nil {
		t.Fatalf("_list search: %v", err)
	}
	if res.Total != 2 {
		t.Errorf("_list: expected 2, got %d", res.Total)
	}
}

func TestSearch_Filter(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "gender": "female", "active": true})
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "gender": "male", "active": true})
	s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient", "gender": "female", "active": false})

	// eq filter: gender eq female → 2 results.
	res, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_filter": {"gender eq female"}},
	})
	if err != nil {
		t.Fatalf("_filter gender eq female: %v", err)
	}
	if res.Total != 2 {
		t.Errorf("gender eq female: expected 2, got %d", res.Total)
	}

	// and combiner: gender eq female and active eq true → 1 result.
	res, err = s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_filter": {"gender eq female and active eq true"}},
	})
	if err != nil {
		t.Fatalf("_filter and: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("gender eq female and active eq true: expected 1, got %d", res.Total)
	}

	// ne: gender ne female → 1 result (the male).
	res, err = s.Search(ctx, store.SearchParams{
		ResourceType: "Patient",
		Params:       map[string][]string{"_filter": {"gender ne female"}},
	})
	if err != nil {
		t.Fatalf("_filter ne: %v", err)
	}
	if res.Total != 1 {
		t.Errorf("gender ne female: expected 1 (male), got %d", res.Total)
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

	// Boundary: gt120 must NOT match the encounter whose length is exactly 120.
	gtBoundary, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Encounter",
		Params:       map[string][]string{"length": {"gt120"}},
	})
	if err != nil {
		t.Fatalf("Search by length=gt120: %v", err)
	}
	if gtBoundary.Total != 0 {
		t.Errorf("expected 0 Encounters for length=gt120 (boundary), got %d", gtBoundary.Total)
	}
}

func TestSearch_MissingModifier(t *testing.T) {
	s := newStore(t)
	ctx := context.Background()

	// Observation.subject is a reference param, indexed into sp_reference — the
	// table :missing previously failed to consult.
	pat, _ := s.Create(ctx, "Patient", map[string]any{"resourceType": "Patient"})
	patID := pat["id"].(string)

	withSubject, _ := s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"subject":      map[string]any{"reference": "Patient/" + patID},
		"code":         map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8310-5"}}},
	})
	withID := withSubject["id"].(string)

	noSubject, _ := s.Create(ctx, "Observation", map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"code":         map[string]any{"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8310-5"}}},
	})
	noID := noSubject["id"].(string)

	// subject:missing=true → only the Observation without a subject.
	missing, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Observation",
		Params:       map[string][]string{"subject:missing": {"true"}},
	})
	if err != nil {
		t.Fatalf("Search subject:missing=true: %v", err)
	}
	if missing.Total != 1 || missing.Entries[0]["id"] != noID {
		t.Errorf("subject:missing=true expected only %s, got total=%d", noID, missing.Total)
	}

	// subject:missing=false → only the Observation with a subject.
	present, err := s.Search(ctx, store.SearchParams{
		ResourceType: "Observation",
		Params:       map[string][]string{"subject:missing": {"false"}},
	})
	if err != nil {
		t.Fatalf("Search subject:missing=false: %v", err)
	}
	if present.Total != 1 || present.Entries[0]["id"] != withID {
		t.Errorf("subject:missing=false expected only %s, got total=%d", withID, present.Total)
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
