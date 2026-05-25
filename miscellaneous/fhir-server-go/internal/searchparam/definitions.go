// Package searchparam loads and caches FHIR search parameter definitions
// from the search_param_definitions table.
package searchparam

import (
	"context"
	"fmt"
	"log/slog"
	"sort"
	"sync"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Definition struct {
	ResourceType string
	ParamName    string
	ParamType    string // string|token|date|number|quantity|uri|reference|composite|special
	FHIRPath     string
	IsCustom     bool
	IGSource     string // '' = base FHIR R4, 'user' = user-defined, 'name@ver' = IG package
}

type Registry struct {
	mu    sync.RWMutex
	byRes map[string][]Definition // resource_type → []Definition
	byKey map[string]Definition   // "ResourceType.paramName" → Definition
}

func NewRegistry() *Registry {
	return &Registry{
		byRes: make(map[string][]Definition),
		byKey: make(map[string]Definition),
	}
}

// Load reads all definitions from the DB and replaces the current cache.
func (r *Registry) Load(ctx context.Context, pool *pgxpool.Pool) error {
	slog.Info("loading search param definitions from database")
	rows, err := pool.Query(ctx, `
		SELECT resource_type, param_name, param_type, fhirpath_expr, is_custom, ig_source
		FROM search_param_definitions
		ORDER BY resource_type, param_name
	`)
	if err != nil {
		return fmt.Errorf("query search_param_definitions: %w", err)
	}
	defer rows.Close()

	byRes := make(map[string][]Definition)
	byKey := make(map[string]Definition)
	count := 0

	for rows.Next() {
		var d Definition
		if err := rows.Scan(&d.ResourceType, &d.ParamName, &d.ParamType, &d.FHIRPath, &d.IsCustom, &d.IGSource); err != nil {
			return fmt.Errorf("scan definition row: %w", err)
		}
		byRes[d.ResourceType] = append(byRes[d.ResourceType], d)
		byKey[d.ResourceType+"."+d.ParamName] = d
		count++
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate definitions: %w", err)
	}

	r.mu.Lock()
	r.byRes = byRes
	r.byKey = byKey
	r.mu.Unlock()

	slog.Info("loaded search param definitions", "count", count)
	return nil
}

func (r *Registry) ForResource(resourceType string) []Definition {
	r.mu.RLock()
	defer r.mu.RUnlock()
	defs := r.byRes[resourceType]
	if len(defs) == 0 {
		return nil
	}
	out := make([]Definition, len(defs))
	copy(out, defs)
	return out
}

// ResourceTypes returns the sorted set of concrete FHIR resource types known
// to the registry. The abstract base types Resource and DomainResource are
// excluded so callers (e.g. the CapabilityStatement builder) get the list of
// types a client can actually POST/GET against.
func (r *Registry) ResourceTypes() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]string, 0, len(r.byRes))
	for rt := range r.byRes {
		if rt == "Resource" || rt == "DomainResource" {
			continue
		}
		out = append(out, rt)
	}
	sort.Strings(out)
	return out
}

func (r *Registry) Lookup(resourceType, paramName string) (Definition, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	d, ok := r.byKey[resourceType+"."+paramName]
	return d, ok
}

// Upsert adds or replaces a custom definition (for SearchParameter resource writes).
func (r *Registry) Upsert(d Definition) {
	r.mu.Lock()
	defer r.mu.Unlock()
	key := d.ResourceType + "." + d.ParamName
	existing := r.byRes[d.ResourceType]
	for i, e := range existing {
		if e.ParamName == d.ParamName {
			existing[i] = d
			r.byRes[d.ResourceType] = existing
			r.byKey[key] = d
			return
		}
	}
	r.byRes[d.ResourceType] = append(existing, d)
	r.byKey[key] = d
}

// Remove drops a custom definition by code (for SearchParameter deletes).
func (r *Registry) Remove(resourceType, paramName string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	key := resourceType + "." + paramName
	delete(r.byKey, key)
	existing := r.byRes[resourceType]
	filtered := existing[:0]
	for _, e := range existing {
		if e.ParamName != paramName {
			filtered = append(filtered, e)
		}
	}
	r.byRes[resourceType] = filtered
}
