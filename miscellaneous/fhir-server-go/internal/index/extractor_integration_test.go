//go:build integration

package index_test

import (
	"context"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/index"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/testutil"
)

func setup(t *testing.T) (*index.Extractor, *pgxpool.Pool) {
	t.Helper()
	pool := testutil.MustSeededDB(t)
	reg := testutil.MustRegistry(t, pool)
	return index.New(reg), pool
}

func countRows(t *testing.T, pool *pgxpool.Pool, table, resourceID string) int {
	t.Helper()
	var n int
	pool.QueryRow(context.Background(),
		"SELECT COUNT(*) FROM "+table+" WHERE resource_id = $1", resourceID,
	).Scan(&n)
	return n
}

// ─── Tests ────────────────────────────────────────────────────────────────────

func TestExtractor_IndexStringParam(t *testing.T) {
	ext, pool := setup(t)
	ctx := context.Background()

	// Ensure the param is in the registry (it comes from seed, but be explicit)
	reg := testutil.MustRegistry(t, pool)
	reg.Upsert(searchparam.Definition{
		ResourceType: "Patient", ParamName: "family",
		ParamType: "string", FHIRPath: "Patient.name.family",
	})
	ext2 := index.New(reg)

	resource := map[string]any{
		"resourceType": "Patient",
		"name":         []any{map[string]any{"family": "TestFamily"}},
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback(ctx)

	if err := ext2.Index(ctx, tx, "Patient", "test-str-1", resource); err != nil {
		t.Fatalf("Index: %v", err)
	}
	tx.Commit(ctx)

	var count int
	pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM sp_string WHERE resource_id='test-str-1' AND param_name='family'`,
	).Scan(&count)
	if count < 1 {
		t.Errorf("expected ≥1 sp_string row for family param, got %d", count)
	}
}

func TestExtractor_IndexTokenParam_FromGender(t *testing.T) {
	ext, pool := setup(t)
	ctx := context.Background()

	resource := map[string]any{
		"resourceType": "Patient",
		"gender":       "female",
	}

	tx, _ := pool.Begin(ctx)
	defer tx.Rollback(ctx)

	if err := ext.Index(ctx, tx, "Patient", "test-gender-1", resource); err != nil {
		t.Fatalf("Index: %v", err)
	}
	tx.Commit(ctx)

	var count int
	pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM sp_token WHERE resource_id='test-gender-1' AND param_name='gender' AND code='female'`,
	).Scan(&count)
	if count < 1 {
		t.Errorf("expected gender=female token row, got %d", count)
	}
}

func TestExtractor_IndexDateParam(t *testing.T) {
	ext, pool := setup(t)
	ctx := context.Background()

	resource := map[string]any{
		"resourceType": "Patient",
		"birthDate":    "1990-06-15",
	}

	tx, _ := pool.Begin(ctx)
	defer tx.Rollback(ctx)

	if err := ext.Index(ctx, tx, "Patient", "test-bd-1", resource); err != nil {
		t.Fatalf("Index: %v", err)
	}
	tx.Commit(ctx)

	var count int
	pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM sp_date WHERE resource_id='test-bd-1' AND param_name='birthdate'`,
	).Scan(&count)
	if count < 1 {
		t.Errorf("expected ≥1 sp_date row for birthdate, got %d", count)
	}
}

func TestExtractor_IndexReferenceParam(t *testing.T) {
	ext, pool := setup(t)
	ctx := context.Background()

	resource := map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"subject":      map[string]any{"reference": "Patient/ref-patient-1"},
		"code": map[string]any{
			"coding": []any{map[string]any{"system": "http://loinc.org", "code": "8310-5"}},
		},
	}

	tx, _ := pool.Begin(ctx)
	defer tx.Rollback(ctx)

	if err := ext.Index(ctx, tx, "Observation", "test-ref-obs-1", resource); err != nil {
		t.Fatalf("Index: %v", err)
	}
	tx.Commit(ctx)

	var count int
	pool.QueryRow(ctx,
		`SELECT COUNT(*) FROM sp_reference WHERE resource_id='test-ref-obs-1' AND target_id='ref-patient-1'`,
	).Scan(&count)
	if count < 1 {
		t.Errorf("expected ≥1 sp_reference row pointing to ref-patient-1, got %d", count)
	}
}

func TestExtractor_IndexTokenParam_CodeableConcept(t *testing.T) {
	ext, pool := setup(t)
	ctx := context.Background()

	resource := map[string]any{
		"resourceType": "Observation",
		"status":       "final",
		"code": map[string]any{
			"coding": []any{
				map[string]any{
					"system":  "http://loinc.org",
					"code":    "8310-5",
					"display": "Body temperature",
				},
			},
		},
		"subject": map[string]any{"reference": "Patient/p1"},
	}

	tx, _ := pool.Begin(ctx)
	defer tx.Rollback(ctx)

	if err := ext.Index(ctx, tx, "Observation", "test-obs-code-1", resource); err != nil {
		t.Fatalf("Index: %v", err)
	}
	tx.Commit(ctx)

	var code string
	pool.QueryRow(ctx,
		`SELECT code FROM sp_token WHERE resource_id='test-obs-code-1' AND param_name='code' AND system='http://loinc.org'`,
	).Scan(&code)
	if code != "8310-5" {
		t.Errorf("expected code=8310-5, got %q", code)
	}
}

func TestExtractor_Delete_ClearsAllSpTables(t *testing.T) {
	ext, pool := setup(t)
	ctx := context.Background()

	resource := map[string]any{
		"resourceType": "Patient",
		"gender":       "male",
		"birthDate":    "1985-03-20",
	}
	rid := "test-delete-rid-1"

	tx, _ := pool.Begin(ctx)
	ext.Index(ctx, tx, "Patient", rid, resource)
	tx.Commit(ctx)

	tx2, _ := pool.Begin(ctx)
	if err := index.Delete(ctx, tx2, "Patient", rid); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	tx2.Commit(ctx)

	for _, tbl := range []string{"sp_string", "sp_token", "sp_date", "sp_number", "sp_quantity", "sp_uri", "sp_reference"} {
		if n := countRows(t, pool, tbl, rid); n != 0 {
			t.Errorf("table %s: expected 0 rows after Delete, got %d", tbl, n)
		}
	}
}
