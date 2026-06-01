// Package searchparam loads and caches FHIR search parameter definitions
// from the search_param_definitions table.
package searchparam

import (
	"context"
	"fmt"
	"log/slog"
	"sort"
	"strings"
	"sync"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Definition struct {
	ResourceType string
	ParamName    string
	ParamType    string   // string|token|date|number|quantity|uri|reference|composite|special
	FHIRPath     string
	IsCustom     bool
	IGSource     string   // '' = base FHIR R4, 'user' = user-defined, 'name@ver' = IG package
	Targets      []string // reference params only: allowed target resource types (from SearchParameter.target)
}

type Registry struct {
	mu      sync.RWMutex
	byRes   map[string][]Definition   // resource_type → []Definition
	byKey   map[string]Definition     // "ResourceType.paramName" → Definition
	revIncl map[string][]string       // targetType → []"SourceType:paramName" for _revinclude
}

func NewRegistry() *Registry {
	return &Registry{
		byRes:   make(map[string][]Definition),
		byKey:   make(map[string]Definition),
		revIncl: make(map[string][]string),
	}
}

// RevInclude returns the searchRevInclude entries for a given target resource
// type (e.g. "Patient" → ["Encounter:patient", "Observation:subject", ...]).
func (r *Registry) RevInclude(targetType string) []string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := r.revIncl[targetType]
	if len(out) == 0 {
		return nil
	}
	cp := make([]string, len(out))
	copy(cp, out)
	return cp
}

// Load reads all definitions from the DB and replaces the current cache.
func (r *Registry) Load(ctx context.Context, pool *pgxpool.Pool) error {
	slog.Info("loading search param definitions from database")
	rows, err := pool.Query(ctx, `
		SELECT resource_type, param_name, param_type, fhirpath_expr, is_custom, ig_source,
		       COALESCE(target_types, '')
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
		var targetTypes string
		if err := rows.Scan(&d.ResourceType, &d.ParamName, &d.ParamType, &d.FHIRPath, &d.IsCustom, &d.IGSource, &targetTypes); err != nil {
			return fmt.Errorf("scan definition row: %w", err)
		}
		if targetTypes != "" {
			d.Targets = strings.Split(targetTypes, "|")
		}
		byRes[d.ResourceType] = append(byRes[d.ResourceType], d)
		byKey[d.ResourceType+"."+d.ParamName] = d
		count++
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate definitions: %w", err)
	}

	// Build reverse-include index: targetType → []"SourceType:paramName"
	revIncl := make(map[string][]string)
	for _, defs := range byRes {
		for _, d := range defs {
			if d.ParamType != "reference" {
				continue
			}
			entry := d.ResourceType + ":" + d.ParamName
			for _, tgt := range d.Targets {
				revIncl[tgt] = append(revIncl[tgt], entry)
			}
		}
	}

	r.mu.Lock()
	r.byRes = byRes
	r.byKey = byKey
	r.revIncl = revIncl
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
// types a client can actually POST/GET against. Types whose definitions have
// all been removed via Remove() are also excluded — Remove leaves the map key
// in place with a zero-length slice.
func (r *Registry) ResourceTypes() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]string, 0, len(r.byRes))
	for rt, defs := range r.byRes {
		if len(defs) == 0 {
			continue
		}
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
			r.removeRevIncl(e)
			existing[i] = d
			r.byRes[d.ResourceType] = existing
			r.byKey[key] = d
			r.addRevIncl(d)
			return
		}
	}
	r.byRes[d.ResourceType] = append(existing, d)
	r.byKey[key] = d
	r.addRevIncl(d)
}

func (r *Registry) addRevIncl(d Definition) {
	if d.ParamType != "reference" {
		return
	}
	entry := d.ResourceType + ":" + d.ParamName
	for _, tgt := range d.Targets {
		r.revIncl[tgt] = append(r.revIncl[tgt], entry)
	}
}

func (r *Registry) removeRevIncl(d Definition) {
	if d.ParamType != "reference" {
		return
	}
	entry := d.ResourceType + ":" + d.ParamName
	for _, tgt := range d.Targets {
		sl := r.revIncl[tgt]
		for i, v := range sl {
			if v == entry {
				r.revIncl[tgt] = append(sl[:i], sl[i+1:]...)
				break
			}
		}
	}
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
