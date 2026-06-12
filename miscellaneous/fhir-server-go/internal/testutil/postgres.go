//go:build integration

// Package testutil provides shared helpers for integration tests.
// All helpers require Docker (via testcontainers-go).
package testutil

import (
	"context"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/db"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/seed"
)

// MustDB starts a PostgreSQL 16 container, runs schema migrations, and returns
// a ready pool. The container is terminated when t completes.
func MustDB(t *testing.T) *pgxpool.Pool {
	t.Helper()
	ctx := context.Background()

	pgc, err := tcpostgres.Run(ctx,
		"postgres:16-alpine",
		tcpostgres.WithDatabase("testdb"),
		tcpostgres.WithUsername("test"),
		tcpostgres.WithPassword("test"),
		tcpostgres.BasicWaitStrategies(),
	)
	if err != nil {
		t.Fatalf("start postgres container: %v", err)
	}
	t.Cleanup(func() {
		if err := pgc.Terminate(ctx); err != nil {
			t.Logf("terminate container: %v", err)
		}
	})

	connStr, err := pgc.ConnectionString(ctx, "sslmode=disable")
	if err != nil {
		t.Fatalf("get connection string: %v", err)
	}

	pool, err := db.Connect(ctx, connStr)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(pool.Close)

	if err := db.Migrate(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	return pool
}

// MustSeededDB is like MustDB but also inserts the FHIR R4 base search params.
func MustSeededDB(t *testing.T) *pgxpool.Pool {
	t.Helper()
	pool := MustDB(t)
	if err := seed.SeedSearchParams(context.Background(), pool); err != nil {
		t.Fatalf("seed search params: %v", err)
	}
	return pool
}

// MustRegistry loads a search param registry from an already-seeded pool.
func MustRegistry(t *testing.T, pool *pgxpool.Pool) *searchparam.Registry {
	t.Helper()
	reg := searchparam.NewRegistry()
	if err := reg.Load(context.Background(), pool); err != nil {
		t.Fatalf("load registry: %v", err)
	}
	return reg
}
