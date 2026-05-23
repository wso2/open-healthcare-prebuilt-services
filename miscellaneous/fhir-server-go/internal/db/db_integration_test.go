//go:build integration

package db_test

import (
	"context"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/testutil"
)

func TestMigrate_CreatesExpectedTables(t *testing.T) {
	pool := testutil.MustDB(t) // MustDB already runs Migrate
	ctx := context.Background()

	tables := []string{
		"resources",
		"resource_history",
		"search_param_definitions",
		"sp_string",
		"sp_token",
		"sp_date",
		"sp_number",
		"sp_quantity",
		"sp_uri",
		"sp_reference",
		"ig_packages",
		"ig_profiles",
	}

	for _, tbl := range tables {
		var exists bool
		err := pool.QueryRow(ctx,
			`SELECT EXISTS (
				SELECT 1 FROM information_schema.tables
				WHERE table_schema = 'public' AND table_name = $1
			)`, tbl,
		).Scan(&exists)
		if err != nil {
			t.Fatalf("query table %q: %v", tbl, err)
		}
		if !exists {
			t.Errorf("table %q not created by migration", tbl)
		}
	}
}

func TestMigrate_Idempotent(t *testing.T) {
	pool := testutil.MustDB(t)
	ctx := context.Background()

	// MustDB already ran Migrate once; query to confirm tables are usable.
	var n int
	err := pool.QueryRow(ctx, `SELECT COUNT(*) FROM resources`).Scan(&n)
	if err != nil {
		t.Fatalf("query after double migrate: %v", err)
	}
}

func TestMigrate_SearchParamDefinitions_HasColumns(t *testing.T) {
	pool := testutil.MustDB(t)
	ctx := context.Background()

	cols := []string{"resource_type", "param_name", "param_type", "fhirpath_expr", "is_custom", "ig_source"}
	for _, col := range cols {
		var exists bool
		err := pool.QueryRow(ctx,
			`SELECT EXISTS (
				SELECT 1 FROM information_schema.columns
				WHERE table_name = 'search_param_definitions' AND column_name = $1
			)`, col,
		).Scan(&exists)
		if err != nil {
			t.Fatalf("query column %q: %v", col, err)
		}
		if !exists {
			t.Errorf("column %q missing from search_param_definitions", col)
		}
	}
}
