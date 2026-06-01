// Package validate walks a FHIR StructureDefinition's snapshot.element list
// and checks a resource map against the constraints it encodes:
//
//   - Required elements (min >= 1) must be present and non-null.
//   - Forbidden elements (max = "0") must be absent.
//   - fixed[x] values — the resource must carry exactly that value.
//   - pattern[x] values — the resource value must include every key/value
//     present in the pattern (deep partial match).
//
// Slicing discriminators and FHIRPath invariant expressions (constraint[].
// expression) require a constraint-evaluation engine and are not yet enforced.
package validate

import (
	"fmt"
	"strings"
)

// Issue is one validation finding.
type Issue struct {
	Severity    string // "error" | "warning"
	Code        string // "required" | "value" | "structure"
	Expression  string // FHIRPath-style location, e.g. "Patient.name"
	Diagnostics string
}

// AgainstProfile validates resource against a loaded StructureDefinition sd.
// Returns a slice of Issues (empty → valid).
func AgainstProfile(resource, sd map[string]any) []Issue {
	snapshot, _ := sd["snapshot"].(map[string]any)
	if snapshot == nil {
		// No snapshot — try differential (less complete, but better than nothing)
		snapshot, _ = sd["differential"].(map[string]any)
	}
	if snapshot == nil {
		return nil
	}
	elements, _ := snapshot["element"].([]any)
	if len(elements) == 0 {
		return nil
	}

	// Build a flat constraint map keyed by element path.
	type elemConstraint struct {
		min     int
		maxZero bool
		fixed   any // fixed[x] value
		pattern any // pattern[x] value
	}
	constraints := make(map[string]elemConstraint, len(elements))
	for _, raw := range elements {
		el, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		path, _ := el["path"].(string)
		if path == "" {
			continue
		}
		var c elemConstraint

		if minV, ok := el["min"].(float64); ok {
			c.min = int(minV)
		}
		if maxV, _ := el["max"].(string); maxV == "0" {
			c.maxZero = true
		}
		for k, v := range el {
			if strings.HasPrefix(k, "fixed") {
				c.fixed = v
				break
			}
		}
		for k, v := range el {
			if strings.HasPrefix(k, "pattern") {
				c.pattern = v
				break
			}
		}
		constraints[path] = c
	}

	var issues []Issue
	rootType, _ := sd["type"].(string)

	for path, c := range constraints {
		// Skip the root element itself (e.g. "Patient" — cardinality is meaningless there).
		if path == rootType || !strings.Contains(path, ".") {
			continue
		}
		// Convert SD path (Patient.name.family) to a relative key path within
		// the resource (name.family) by stripping the resource type prefix.
		relPath := strings.TrimPrefix(path, rootType+".")

		val := getPath(resource, relPath)
		present := val != nil

		if c.min >= 1 && !present {
			issues = append(issues, Issue{
				Severity:    "error",
				Code:        "required",
				Expression:  path,
				Diagnostics: fmt.Sprintf("%s: minimum cardinality is %d but element is absent", path, c.min),
			})
		}
		if c.maxZero && present {
			issues = append(issues, Issue{
				Severity:    "error",
				Code:        "structure",
				Expression:  path,
				Diagnostics: fmt.Sprintf("%s: element is not permitted (max=0)", path),
			})
		}
		if c.fixed != nil && present && !deepEqual(val, c.fixed) {
			issues = append(issues, Issue{
				Severity:    "error",
				Code:        "value",
				Expression:  path,
				Diagnostics: fmt.Sprintf("%s: value does not match fixed value", path),
			})
		}
		if c.pattern != nil && present && !matchesPattern(val, c.pattern) {
			issues = append(issues, Issue{
				Severity:    "error",
				Code:        "value",
				Expression:  path,
				Diagnostics: fmt.Sprintf("%s: value does not match required pattern", path),
			})
		}
	}
	return issues
}

// getPath navigates a dot-delimited relative path into a resource map.
// Returns the value at the path (may be a scalar, map, or []any).
// For intermediate array segments it descends into the first element.
// Returns nil when any segment is absent.
func getPath(resource map[string]any, path string) any {
	parts := strings.SplitN(path, ".", 2)
	key := parts[0]
	val, ok := resource[key]
	if !ok || val == nil {
		return nil
	}
	// Terminal segment — return the raw value (array, map, or scalar).
	if len(parts) == 1 {
		return val
	}
	// Intermediate segment: unwrap a single-element array to descend.
	switch v := val.(type) {
	case map[string]any:
		return getPath(v, parts[1])
	case []any:
		if len(v) == 0 {
			return nil
		}
		if m, ok := v[0].(map[string]any); ok {
			return getPath(m, parts[1])
		}
		return nil
	}
	return nil
}

// deepEqual compares two values for equality (handles maps, slices, scalars).
func deepEqual(a, b any) bool {
	switch av := a.(type) {
	case map[string]any:
		bm, ok := b.(map[string]any)
		if !ok || len(av) != len(bm) {
			return false
		}
		for k, v := range av {
			if !deepEqual(v, bm[k]) {
				return false
			}
		}
		return true
	case []any:
		bl, ok := b.([]any)
		if !ok || len(av) != len(bl) {
			return false
		}
		for i := range av {
			if !deepEqual(av[i], bl[i]) {
				return false
			}
		}
		return true
	default:
		return fmt.Sprintf("%v", a) == fmt.Sprintf("%v", b)
	}
}

// matchesPattern checks that val satisfies the pattern constraint:
//   - Pattern map → every key in the pattern must be present and match in val.
//   - Val is an array → at least one element must satisfy the pattern.
//   - Otherwise → deep equality.
func matchesPattern(val, pattern any) bool {
	pm, ok := pattern.(map[string]any)
	if !ok {
		return deepEqual(val, pattern)
	}
	// If the actual value is an array (e.g. category is []any), at least one
	// element must contain all the pattern keys.
	if arr, ok := val.([]any); ok {
		for _, elem := range arr {
			if matchesPattern(elem, pm) {
				return true
			}
		}
		return false
	}
	vm, ok := val.(map[string]any)
	if !ok {
		return false
	}
	for k, pv := range pm {
		vv, exists := vm[k]
		if !exists {
			return false
		}
		if !matchesPattern(vv, pv) {
			return false
		}
	}
	return true
}
