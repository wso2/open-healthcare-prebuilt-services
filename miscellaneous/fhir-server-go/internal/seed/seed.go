// Package seed populates search_param_definitions from the embedded FHIR R4
// search parameter CSV at server startup.
package seed

import (
	"context"
	"embed"
	"encoding/csv"
	"fmt"
	"io"
	"log/slog"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed fhir-r4-search-params.csv
var csvFS embed.FS

// SeedSearchParams inserts all standard FHIR R4 search parameters into
// search_param_definitions. Rows that already exist (by resource_type + param_name)
// are silently skipped so custom parameters are never overwritten.
func SeedSearchParams(ctx context.Context, pool *pgxpool.Pool) error {
	f, err := csvFS.Open("fhir-r4-search-params.csv")
	if err != nil {
		return fmt.Errorf("open embedded csv: %w", err)
	}
	defer f.Close()
	return seedFromReader(ctx, pool, f)
}

// SeedFromFile seeds from an external CSV path (useful for testing or
// overriding the embedded dataset).
func SeedFromFile(ctx context.Context, pool *pgxpool.Pool, path string) error {
	f, err := csvFS.Open(path)
	if err != nil {
		return fmt.Errorf("open %s: %w", path, err)
	}
	defer f.Close()
	return seedFromReader(ctx, pool, f)
}

func seedFromReader(ctx context.Context, pool *pgxpool.Pool, r io.Reader) error {
	cr := csv.NewReader(r)
	cr.FieldsPerRecord = -1 // variable columns (expression may be empty)
	cr.TrimLeadingSpace = true

	// Read and validate header
	header, err := cr.Read()
	if err != nil {
		return fmt.Errorf("read csv header: %w", err)
	}
	colIdx := csvColumnIndex(header)

	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	inserted := 0
	for {
		row, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("read csv row: %w", err)
		}
		if len(row) <= colIdx.maxIdx() {
			continue
		}

		paramName := strings.TrimSpace(row[colIdx.paramName])
		resourceType := strings.TrimSpace(row[colIdx.resourceType])
		paramType := strings.TrimSpace(row[colIdx.paramType])
		expression := ""
		if colIdx.expression < len(row) {
			expression = strings.TrimSpace(row[colIdx.expression])
		}

		if paramName == "" || resourceType == "" {
			continue
		}

		_, err = tx.Exec(ctx, `
			INSERT INTO search_param_definitions
				(resource_type, param_name, param_type, fhirpath_expr, is_custom)
			VALUES ($1, $2, $3, $4, FALSE)
			ON CONFLICT (resource_type, param_name) DO NOTHING`,
			resourceType, paramName, paramType, expression,
		)
		if err != nil {
			return fmt.Errorf("insert %s.%s: %w", resourceType, paramName, err)
		}
		inserted++
	}

	if err := tx.Commit(ctx); err != nil {
		return err
	}

	slog.Info("seeded search param definitions", "rows", inserted)
	return nil
}

type colIndex struct {
	paramName    int
	resourceType int
	paramType    int
	expression   int
}

func (c colIndex) maxIdx() int {
	m := c.paramName
	if c.resourceType > m {
		m = c.resourceType
	}
	if c.paramType > m {
		m = c.paramType
	}
	return m
}

// csvColumnIndex detects column positions from the header row, supporting
// the Ballerina CSV format (Search_Parm, Resource, Search_Pram_Type, Expression)
// and a canonical format (param_name, resource_type, param_type, fhirpath_expr).
func csvColumnIndex(header []string) colIndex {
	idx := colIndex{paramName: 0, resourceType: 1, paramType: 2, expression: 3}
	for i, h := range header {
		switch strings.ToLower(strings.TrimSpace(h)) {
		case "search_parm", "param_name", "name":
			idx.paramName = i
		case "resource", "resource_type":
			idx.resourceType = i
		case "search_pram_type", "param_type", "type":
			idx.paramType = i
		case "expression", "fhirpath_expr", "fhirpath":
			idx.expression = i
		}
	}
	return idx
}
