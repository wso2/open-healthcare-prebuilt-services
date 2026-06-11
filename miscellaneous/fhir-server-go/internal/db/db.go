package db

import (
	"context"
	"embed"
	"fmt"
	"log/slog"
	"runtime"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed schema.sql
var schemaFS embed.FS

// PoolConfig controls pgxpool sizing. Zero values trigger automatic defaults
// based on GOMAXPROCS: MaxConns = max(20, NumCPU*4), MinConns = NumCPU.
type PoolConfig struct {
	MaxConns int
	MinConns int
}

func Connect(ctx context.Context, dsn string, pc PoolConfig) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("parse dsn: %w", err)
	}

	// Apply pool sizing. The pgxpool default (4) is far too small for a
	// concurrent FHIR server where every write opens a transaction.
	maxConns := int32(pc.MaxConns)
	if maxConns <= 0 {
		n := int32(runtime.NumCPU() * 4)
		if n < 20 {
			n = 20
		}
		maxConns = n
	}
	cfg.MaxConns = maxConns

	minConns := int32(pc.MinConns)
	if minConns <= 0 {
		n := int32(runtime.NumCPU())
		if n < 2 {
			n = 2
		}
		minConns = n
	}
	cfg.MinConns = minConns

	// Recycle idle connections so the pool doesn't hold more than needed
	// during quiet periods.
	cfg.MaxConnIdleTime = 30 * time.Second
	cfg.HealthCheckPeriod = 1 * time.Minute

	slog.Info("opening DB pool", "maxConns", maxConns, "minConns", minConns)

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("open pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping: %w", err)
	}

	return pool, nil
}

func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	schema, err := schemaFS.ReadFile("schema.sql")
	if err != nil {
		return fmt.Errorf("read embedded schema: %w", err)
	}

	_, err = pool.Exec(ctx, string(schema))
	if err != nil {
		return fmt.Errorf("apply schema: %w", err)
	}

	slog.Info("schema migration complete")
	return nil
}
