package store

import (
	"context"
	"fmt"
	"log/slog"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/terminology"
)

// SearchParams are the parsed query parameters from the HTTP request.
type SearchParams struct {
	ResourceType string
	Params       map[string][]string // raw query params
	Page         int
	PageSize     int
	// Total is the _total mode: "none" skips the (potentially expensive) count
	// query. Any other value (including "") computes an accurate count.
	Total string
	// CountOnly is set for _summary=count: compute the total but skip fetching
	// and including the matching resources.
	CountOnly bool
}

type SearchResult struct {
	// Total is the number of matches, or -1 when not computed (_total=none).
	Total    int
	Entries  []map[string]any
	Included []map[string]any // _include / _revinclude results
}

// UnsupportedParamError is returned when a search request names a registry-known
// param whose type the query builder can't translate (composite, special).
// The HTTP layer should map this to a 400 OperationOutcome rather than execute
// a query that silently ignores the predicate.
type UnsupportedParamError struct{ Msg string }

func (e *UnsupportedParamError) Error() string { return e.Msg }

// Search executes a FHIR search against the resources + sp_* tables,
// and resolves _include / _revinclude parameters.
func (s *Store) Search(ctx context.Context, sp SearchParams) (SearchResult, error) {
	if sp.PageSize <= 0 {
		sp.PageSize = 20
	}
	if sp.Page <= 0 {
		sp.Page = 1
	}
	offset := (sp.Page - 1) * sp.PageSize

	// _list=<id>: resolve the named List resource and inject its entry IDs as
	// additional _id filters so only listed resources are returned.
	if listIDs, ok := sp.Params["_list"]; ok && len(listIDs) > 0 {
		ids, err := s.resolveListIDs(ctx, listIDs)
		if err != nil {
			return SearchResult{}, err
		}
		if len(ids) == 0 {
			return SearchResult{Total: 0}, nil
		}
		params := make(map[string][]string, len(sp.Params))
		for k, v := range sp.Params {
			if k != "_list" {
				params[k] = v
			}
		}
		// Inject as a single comma-joined value so _id's comma-OR logic applies.
		params["_id"] = []string{strings.Join(ids, ",")}
		sp.Params = params
	}

	b := &queryBuilder{rt: sp.ResourceType, reg: s.registry, terminology: s.terminology, ctx: ctx}
	b.writeBase()

	for rawKey, values := range sp.Params {
		if len(values) == 0 {
			continue
		}
		for _, v := range values {
			b.applyParam(rawKey, v)
		}
	}

	if b.err != nil {
		return SearchResult{}, b.err
	}

	// _summary=count: only the total is needed, no rows to fetch.
	if sp.CountOnly {
		n, err := b.count(ctx, s.pool)
		if err != nil {
			slog.Error("search count failed", "resourceType", sp.ResourceType, "err", err)
			return SearchResult{}, err
		}
		return SearchResult{Total: n}, nil
	}

	total := -1
	var entries []map[string]any
	if sp.Total == "none" {
		// _total=none: skip the count entirely, just fetch rows.
		var err error
		entries, err = b.fetch(ctx, s.pool, sp.PageSize, offset)
		if err != nil {
			return SearchResult{}, err
		}
	} else {
		// Default: fetch rows and total in a single query via COUNT(*) OVER().
		var err error
		total, entries, err = b.fetchWithCount(ctx, s.pool, sp.PageSize, offset)
		if err != nil {
			slog.Error("search failed", "resourceType", sp.ResourceType, "err", err)
			return SearchResult{}, err
		}
	}

	result := SearchResult{Total: total, Entries: entries}

	// _include / _revinclude
	if incl := sp.Params["_include"]; len(incl) > 0 {
		included, err := s.resolveIncludes(ctx, entries, sp.ResourceType, false)
		if err != nil {
			return result, err
		}
		result.Included = append(result.Included, included...)
	}
	if rIncl := sp.Params["_revinclude"]; len(rIncl) > 0 {
		included, err := s.resolveIncludes(ctx, entries, sp.ResourceType, true)
		if err != nil {
			return result, err
		}
		result.Included = append(result.Included, included...)
	}

	return result, nil
}

// resolveListIDs fetches the List resources named by listIDs and returns the
// set of resource IDs they reference via entry[].item.reference. The returned
// IDs are the bare resource IDs (e.g. "abc-123", not "Patient/abc-123").
func (s *Store) resolveListIDs(ctx context.Context, listIDs []string) ([]string, error) {
	seen := map[string]bool{}
	var out []string
	for _, listID := range listIDs {
		list, err := s.Read(ctx, "List", listID)
		if err != nil {
			return nil, fmt.Errorf("_list: read List/%s: %w", listID, err)
		}
		entries, _ := list["entry"].([]any)
		for _, raw := range entries {
			entry, _ := raw.(map[string]any)
			if entry == nil {
				continue
			}
			item, _ := entry["item"].(map[string]any)
			if item == nil {
				continue
			}
			ref, _ := item["reference"].(string)
			if ref == "" {
				continue
			}
			// Strip resource type prefix: "Patient/123" → "123", bare "123" stays.
			if idx := strings.LastIndex(ref, "/"); idx >= 0 {
				ref = ref[idx+1:]
			}
			if ref != "" && !seen[ref] {
				seen[ref] = true
				out = append(out, ref)
			}
		}
	}
	return out, nil
}

// resolveIncludes fetches include/revinclude resources for a set of matched entries.
func (s *Store) resolveIncludes(ctx context.Context, entries []map[string]any, resourceType string, reverse bool) ([]map[string]any, error) {
	seen := make(map[string]bool)
	var results []map[string]any

	for _, entry := range entries {
		id, _ := entry["id"].(string)
		if id == "" {
			continue
		}
		refs, err := s.FetchReferences(ctx, resourceType, id, reverse)
		if err != nil {
			continue
		}
		for _, ref := range refs {
			refID, _ := ref["id"].(string)
			key := ref["resourceType"].(string) + "/" + refID
			if !seen[key] {
				seen[key] = true
				results = append(results, ref)
			}
		}
	}
	return results, nil
}

// ─── Query builder ────────────────────────────────────────────────────────────

type queryBuilder struct {
	rt          string
	reg         *searchparam.Registry
	terminology *terminology.Client // nil if no terminology server configured
	ctx         context.Context     // for terminology expansion calls
	where       strings.Builder
	args        []any
	argN        int
	sort        []sortKey
	// err is set when the request can't be satisfied (e.g. a registry-known
	// param of unsupported type like composite/special). Search() returns it
	// as an UnsupportedParamError rather than silently widening the result set.
	err error
}

// sortKey is one component of a _sort directive: the search param name and
// whether the order is descending (the param was prefixed with '-').
type sortKey struct {
	param string
	desc  bool
}

func (b *queryBuilder) next(v any) string {
	b.args = append(b.args, v)
	b.argN++
	return fmt.Sprintf("$%d", b.argN)
}

func (b *queryBuilder) writeBase() {
	rtP := b.next(b.rt)
	b.where.WriteString(fmt.Sprintf(
		"r.resource_type = %s AND r.is_deleted = FALSE", rtP,
	))
}

func (b *queryBuilder) and(cond string) {
	b.where.WriteString(" AND ")
	b.where.WriteString(cond)
}

func (b *queryBuilder) applyParam(rawKey, value string) {
	paramName, modifier := splitModifier(rawKey)

	// _has reverse chaining: _has:SourceType:refParam:valueParam=value
	// "give me resources of b.rt referenced by a SourceType resource via refParam
	// whose valueParam matches value".
	if paramName == "_has" {
		b.applyHas(modifier, value)
		return
	}

	// Chained search: organization.name=… or subject:Patient.name=… — a dot in
	// the param name (or in a type modifier) walks a reference to the target
	// resource's own search params.
	if ref, targetType, targetParam, targetMod, ok := parseChain(paramName, modifier); ok {
		b.applyChained(ref, targetType, targetParam, targetMod, value)
		return
	}

	switch paramName {
	case "_id":
		parts := strings.Split(value, ",")
		if len(parts) == 1 {
			p := b.next(strings.TrimSpace(value))
			b.and(fmt.Sprintf("r.fhir_id = %s", p))
		} else {
			var ors []string
			for _, part := range parts {
				p := b.next(strings.TrimSpace(part))
				ors = append(ors, fmt.Sprintf("r.fhir_id = %s", p))
			}
			b.and("(" + strings.Join(ors, " OR ") + ")")
		}
	case "_lastUpdated":
		b.applyLastUpdated(value)
	case "_text", "_content":
		p := b.next(value)
		b.and(fmt.Sprintf("r.search_text @@ plainto_tsquery('english', %s)", p))
	case "_sort":
		b.addSort(value)
	case "_filter":
		b.applyFilter(value)
	case "_count", "_page", "_include", "_revinclude", "_format", "_summary", "_elements", "_total", "_list":
		// control params — handled at the HTTP layer
	default:
		b.applySearchParam(paramName, modifier, value)
	}
}

func (b *queryBuilder) applySearchParam(param, modifier, value string) {
	if modifier == "missing" {
		// :missing must look in the table the param was actually indexed into,
		// otherwise typed params (reference, token, date, quantity, uri) are all
		// reported as missing. Fall back to sp_string for params the registry
		// doesn't know.
		table := "sp_string"
		if pt, ok := universalParamType[param]; ok {
			table = tableForType(pt)
		} else if b.reg != nil {
			if def, ok := b.reg.Lookup(b.rt, param); ok {
				t := tableForType(def.ParamType)
				if t == "" {
					// composite / special — we can't tell from registry alone where
					// this param indexes, so :missing is unanswerable. Fail closed
					// rather than skipping the predicate (which widens the result
					// set unexpectedly).
					b.err = &UnsupportedParamError{Msg: fmt.Sprintf("param %q on %s has type %q which is not yet supported for :missing", param, b.rt, def.ParamType)}
					return
				}
				table = t
			}
		}
		exists := b.spExists(table, param, "")
		if value == "true" {
			b.and(fmt.Sprintf("NOT EXISTS (%s)", exists))
		} else {
			b.and(fmt.Sprintf("EXISTS (%s)", exists))
		}
		return
	}

	// :not negates the match. :not-in is also negated (handled in buildTypedExists
	// but needs to be NOT EXISTS at the applyParam level).
	if modifier == "not" {
		if expr := b.combinedExists(param, "", value); expr != "" {
			b.and("NOT " + expr)
		}
		return
	}
	if modifier == "not-in" {
		if expr := b.combinedExists(param, "not-in", value); expr != "" {
			b.and("NOT " + expr)
		}
		return
	}

	if expr := b.combinedExists(param, modifier, value); expr != "" {
		b.and(expr)
	}
}

// applyHas implements _has reverse chaining.
// rawKey form: "_has:SourceType:refParam:valueParam", value = search value.
// The modifier contains "SourceType:refParam:valueParam".
// Result: add a predicate that the current resource is referenced by a
// SourceType resource (via refParam) that also satisfies valueParam=value.
func (b *queryBuilder) applyHas(modifier, value string) {
	parts := strings.SplitN(modifier, ":", 3)
	if len(parts) != 3 {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("_has modifier must be SourceType:refParam:valueParam, got %q", modifier)}
		return
	}
	sourceType, refParam, valueParam := parts[0], parts[1], parts[2]

	// Build the inner predicate for valueParam=value on sourceType, shadowing
	// the outer 'r' alias with the source resource row.
	saved := b.rt
	b.rt = sourceType
	inner := b.combinedExists(valueParam, "", value)
	b.rt = saved
	if inner == "" {
		return
	}

	rtP := b.next(b.rt)
	srcP := b.next(sourceType)
	refP := b.next(refParam)

	// The source resource references the current resource via sp_reference.
	b.and(fmt.Sprintf(
		"EXISTS (SELECT 1 FROM sp_reference sr WHERE sr.target_id = r.fhir_id AND sr.target_type = %s AND sr.resource_type = %s AND sr.param_name = %s AND EXISTS (SELECT 1 FROM resources r WHERE r.fhir_id = sr.resource_id AND r.resource_type = %s AND r.is_deleted = FALSE AND %s))",
		rtP, srcP, refP, srcP, inner,
	))
}

// buildCompositeExists builds an AND of two component EXISTS subqueries for a
// composite search param (e.g. code-value-quantity=8480-6$gt110).
// The value is split on "$" to get the two component values. Each component's
// expression maps to a sub-param name in the registry.
func (b *queryBuilder) buildCompositeExists(def searchparam.Definition, param, value string) (string, bool) {
	if len(def.Components) < 2 {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("composite param %q has no component definitions — cannot execute", param)}
		return "", false
	}
	// Split on "$" to separate component values. Only two-component composites
	// are supported.
	dollarIdx := strings.IndexByte(value, '$')
	if dollarIdx < 0 {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("composite param %q value %q must contain '$' separating the two component values", param, value)}
		return "", false
	}
	val1, val2 := value[:dollarIdx], value[dollarIdx+1:]

	// Resolve component expressions to param names in the registry.
	comp1Name := resolveComponentName(b.rt, def.Components[0].Expression, b.reg)
	comp2Name := resolveComponentName(b.rt, def.Components[1].Expression, b.reg)
	if comp1Name == "" || comp2Name == "" {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("composite param %q: cannot resolve component params from expressions %q / %q", param, def.Components[0].Expression, def.Components[1].Expression)}
		return "", false
	}

	// Build the component EXISTS subqueries directly (not via combinedExists which
	// wraps them in EXISTS again) so the composite becomes AND(cond1, cond2)
	// at the same level as other predicates rather than EXISTS(EXISTS AND EXISTS).
	cond1, ok1 := b.buildExistsForValue(comp1Name, "", val1)
	cond2, ok2 := b.buildExistsForValue(comp2Name, "", val2)
	if !ok1 || !ok2 || cond1 == "" || cond2 == "" {
		return "", false
	}
	// Return a raw AND of the two EXISTS subqueries. The caller in
	// buildTypedExists → combinedExists will wrap it in EXISTS(...) again,
	// so we must NOT add EXISTS here — we return the inner content for the
	// EXISTS wrapper to wrap.
	// Actually: the caller adds EXISTS around our return value. So we should
	// return a SELECT that yields 1 when both match. Use INTERSECT:
	return cond1 + " INTERSECT " + cond2, true
}

// resolveComponentName converts a component expression like "code",
// "value.as(Quantity)", or "interpretation" to the search param name
// registered in the registry for the given resource type.
// It tries: exact match, then strips ".as(Type)" suffix to get the base field,
// then looks for a param whose FHIRPath starts with the expression.
func resolveComponentName(rt, expr string, reg *searchparam.Registry) string {
	if expr == "" || reg == nil {
		return ""
	}
	// Exact match by FHIRPath.
	for _, d := range reg.ForResource(rt) {
		if d.FHIRPath == expr {
			return d.ParamName
		}
	}

	// Extract the type hint from "value.as(Quantity)" → typeHint="Quantity"
	// and the base field: "value".
	typeHint := ""
	plain := expr
	if i := strings.Index(plain, ".as("); i >= 0 {
		end := strings.IndexByte(plain[i:], ')')
		if end >= 0 {
			typeHint = plain[i+4 : i+end]
		}
		plain = plain[:i]
	}
	// Strip leading resource-type prefix: "Observation.code" → "code".
	if dot := strings.IndexByte(plain, '.'); dot >= 0 {
		plain = plain[dot+1:]
	}
	if plain == "" {
		plain = expr
	}

	// Type hint → expected search param type mapping.
	expectedType := ""
	switch typeHint {
	case "Quantity", "SampledData":
		expectedType = "quantity"
	case "CodeableConcept":
		expectedType = "token"
	case "dateTime", "Period", "Date", "Instant":
		expectedType = "date"
	case "string", "string+":
		expectedType = "string"
	case "Reference":
		expectedType = "reference"
	}

	// 1. Exact name match (possibly filtered by type hint).
	for _, d := range reg.ForResource(rt) {
		if d.ParamName == plain {
			if expectedType == "" || d.ParamType == expectedType {
				return d.ParamName
			}
		}
	}
	// 2. FHIRPath contains the plain segment, filtered by type hint if available.
	for _, d := range reg.ForResource(rt) {
		pathMatch := strings.Contains(d.FHIRPath, "."+plain+".") ||
			strings.HasSuffix(d.FHIRPath, "."+plain) ||
			strings.HasPrefix(d.FHIRPath, plain+".") ||
			d.FHIRPath == plain
		if pathMatch {
			if expectedType == "" || d.ParamType == expectedType {
				return d.ParamName
			}
		}
	}
	return ""
}

// parseChain detects a chained-search parameter and splits it into the
// reference param on the current resource, an optional explicit target type,
// and the search param on the target resource. Two forms are recognised:
//
//	organization.name      → ref=organization, type="",      target=name   (modifier applies to target)
//	subject:Patient.name   → ref=subject,      type=Patient, target=name
//
// Returns ok=false when the key is not a chain.
func parseChain(paramName, modifier string) (ref, targetType, targetParam, targetModifier string, ok bool) {
	if i := strings.IndexByte(paramName, '.'); i >= 0 {
		return paramName[:i], "", paramName[i+1:], modifier, true
	}
	if i := strings.IndexByte(modifier, '.'); i >= 0 {
		return paramName, modifier[:i], modifier[i+1:], "", true
	}
	return "", "", "", "", false
}

// applyChained builds the predicate for a single-hop chained search: the
// resource has a `ref` reference to a `targetType` resource that itself matches
// `targetParam`=value. The inner match reuses the normal value builders by
// shadowing the `r` alias with the target resource inside an IN-subquery.
func (b *queryBuilder) applyChained(ref, targetType, targetParam, targetModifier, value string) {
	cond := b.buildChainedCondition(b.rt, ref, targetType, targetParam, targetModifier, value, 0)
	if cond != "" {
		b.and(cond)
	}
}

const maxChainDepth = 5 // prevent pathological queries

// buildChainedCondition builds the EXISTS…IN SQL fragment for one hop of a
// chained search, recursing for multi-hop chains.
// sourceType is the type of the resource at the current hop (the one we're
// filtering by the sp_reference table).
func (b *queryBuilder) buildChainedCondition(sourceType, ref, targetType, targetParam, targetModifier, value string, depth int) string {
	if depth > maxChainDepth {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("chained search exceeds maximum depth %d", maxChainDepth)}
		return ""
	}

	// Resolve the target type for this hop.
	if targetType == "" {
		guess := strings.ToUpper(ref[:1]) + ref[1:]
		if b.reg != nil && len(b.reg.ForResource(guess)) > 0 {
			targetType = guess
		}
	}
	if targetType == "" {
		// Try to infer from the registry Targets of the ref param.
		if b.reg != nil {
			if def, ok := b.reg.Lookup(sourceType, ref); ok && len(def.Targets) == 1 {
				targetType = def.Targets[0]
			}
		}
	}
	if targetType == "" {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("chained search: cannot infer target type for %s.%s — use explicit Type, e.g. %s:Type.%s", sourceType, ref, ref, targetParam)}
		return ""
	}

	refP := b.next(ref)
	stP := b.next(sourceType)
	ttP := b.next(targetType)

	// If targetParam still contains a dot, this is a further hop.
	if dot := strings.IndexByte(targetParam, '.'); dot >= 0 {
		nextRef := targetParam[:dot]
		rest := targetParam[dot+1:]
		// Determine next explicit type from the modifier if present.
		nextType, nextParam := "", rest
		if i := strings.IndexByte(rest, '.'); i >= 0 {
			// rest could be "nextType.finalParam" if we were given explicit types
			// but that's handled by the outer parseChain — here rest is just the
			// remaining chain without type qualifiers.
			_ = i
		}
		inner := b.buildChainedCondition(targetType, nextRef, nextType, nextParam, targetModifier, value, depth+1)
		if inner == "" {
			return ""
		}
		return fmt.Sprintf(
			"EXISTS (SELECT 1 FROM sp_reference sr WHERE sr.resource_id = r.fhir_id AND sr.resource_type = %s AND sr.param_name = %s AND sr.target_type = %s AND sr.target_id IN (SELECT r.fhir_id FROM resources r WHERE r.is_deleted = FALSE AND r.resource_type = %s AND %s))",
			stP, refP, ttP, ttP, inner,
		)
	}

	// Leaf hop: build the value predicate on the final target type.
	saved := b.rt
	b.rt = targetType
	inner := b.combinedExists(targetParam, targetModifier, value)
	b.rt = saved
	if inner == "" {
		return ""
	}

	return fmt.Sprintf(
		"EXISTS (SELECT 1 FROM sp_reference sr WHERE sr.resource_id = r.fhir_id AND sr.resource_type = %s AND sr.param_name = %s AND sr.target_type = %s AND sr.target_id IN (SELECT r.fhir_id FROM resources r WHERE r.is_deleted = FALSE AND r.resource_type = %s AND %s))",
		stP, refP, ttP, ttP, inner,
	)
}

// combinedExists builds the EXISTS predicate for a (possibly comma-separated)
// value, OR-joining the parts. Returns "" when no part produced a condition.
func (b *queryBuilder) combinedExists(param, modifier, value string) string {
	var ors []string
	for _, p := range strings.Split(value, ",") {
		cond, ok := b.buildExistsForValue(param, modifier, strings.TrimSpace(p))
		if ok {
			ors = append(ors, fmt.Sprintf("EXISTS (%s)", cond))
		}
	}
	switch len(ors) {
	case 0:
		return ""
	case 1:
		return ors[0]
	default:
		return "(" + strings.Join(ors, " OR ") + ")"
	}
}

// buildExistsForValue builds an EXISTS subquery for a single value, routing to
// the correct sp_* table by the param's declared type in the registry. When the
// param is unknown to the registry (e.g. a custom param not yet loaded) it falls
// back to a best-effort guess from the value format.
func (b *queryBuilder) buildExistsForValue(param, modifier, value string) (string, bool) {
	// Universal meta params have a fixed type and aren't in the per-resource
	// registry; resolve them first so they route to the right sp_* table.
	if pt, ok := universalParamType[param]; ok {
		return b.buildTypedExists(searchparam.Definition{ParamType: pt, ParamName: param}, param, modifier, value)
	}
	if b.reg != nil {
		if def, ok := b.reg.Lookup(b.rt, param); ok {
			return b.buildTypedExists(def, param, modifier, value)
		}
	}
	return b.buildHeuristicExists(param, modifier, value)
}

// universalParamType maps the meta.* search params (indexed for every resource
// type by index.indexMeta) to their FHIR search param type. _id/_lastUpdated/
// _text/_content are handled separately in applyParam.
var universalParamType = map[string]string{
	"_tag":      "token",
	"_security": "token",
	"_profile":  "uri",
	"_source":   "uri",
	"_language": "token",
}

// buildTypedExists routes a value match to the sp_* table for the given FHIR
// search param type. Returns (subquery, false) for types we don't yet support
// (composite, special) so the caller can skip the filter rather than misroute it.
func (b *queryBuilder) buildTypedExists(def searchparam.Definition, param, modifier, value string) (string, bool) {
	paramType := def.ParamType
	switch paramType {
	case "composite":
		sub, ok := b.buildCompositeExists(def, param, value)
		return sub, ok
	case "string":
		return b.buildStringExists(param, modifier, value), true
	case "token":
		// :in/:not-in expand a ValueSet via the terminology server.
		// :of-type matches Identifier.type + value (indexed under <param>:of-type).
		// :above/:below need code-system subsumption (terminology).
		switch modifier {
		case "in", "not-in":
			return b.buildTokenInExists(param, modifier, value)
		case "of-type":
			return b.buildOfTypeExists(param, value), true
		case "above", "below":
			return b.buildTokenHierarchyExists(param, modifier, value)
		}
		return b.buildTokenExists(param, modifier, value), true
	case "date", "dateTime", "instant", "Period":
		return b.buildDateExists(param, value), true
	case "number":
		return b.buildNumberExists(param, value), true
	case "quantity":
		return b.buildQuantityExists(param, value), true
	case "uri":
		return b.buildURIExists(param, modifier, value), true
	case "reference":
		return b.buildReferenceExists(param, modifier, value), true
	default:
		// special (e.g. Location.near) — not supported. Fail closed rather
		// than silently dropping the predicate (which would broaden results).
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("param %q on %s has type %q which is not yet supported", param, b.rt, paramType)}
		slog.Warn("unsupported search param type; failing request",
			"resourceType", b.rt, "param", param, "paramType", paramType)
		return "", false
	}
}

// tableForType maps a FHIR search param type to its sp_* index table. Returns ""
// for types without a dedicated table (composite, special).
func tableForType(paramType string) string {
	switch paramType {
	case "string":
		return "sp_string"
	case "token":
		return "sp_token"
	case "date", "dateTime", "instant", "Period":
		return "sp_date"
	case "number":
		return "sp_number"
	case "quantity":
		return "sp_quantity"
	case "uri":
		return "sp_uri"
	case "reference":
		return "sp_reference"
	default:
		return ""
	}
}

// buildHeuristicExists is the legacy value-format guess, used only when the
// param type is unknown. Reference/quantity/uri params are never reachable here
// once the registry is loaded.
func (b *queryBuilder) buildHeuristicExists(param, modifier, value string) (string, bool) {
	switch {
	case looksLikeDate(value):
		return b.buildDateExists(param, value), true
	case looksLikeNumber(value):
		return b.buildNumberExists(param, value), true
	case strings.Contains(value, "|"):
		return b.buildTokenExists(param, modifier, value), true
	default:
		// Match against both sp_string and sp_token so plain-code token searches
		// (e.g. gender=female) work alongside string params.
		strQ := b.buildStringExists(param, modifier, value)
		tokQ := b.buildTokenExists(param, modifier, value)
		return strQ + " UNION ALL " + tokQ, true
	}
}

func (b *queryBuilder) buildStringExists(param, modifier, value string) string {
	rtP := b.next(b.rt)
	pP := b.next(param)
	switch modifier {
	case "exact":
		vP := b.next(value)
		return fmt.Sprintf("SELECT 1 FROM sp_string s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_exact = %s", rtP, pP, vP)
	case "contains":
		vP := b.next("%" + strings.ToLower(value) + "%")
		return fmt.Sprintf("SELECT 1 FROM sp_string s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_lower LIKE %s", rtP, pP, vP)
	default:
		vP := b.next(strings.ToLower(value) + "%")
		return fmt.Sprintf("SELECT 1 FROM sp_string s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_lower LIKE %s", rtP, pP, vP)
	}
}

func (b *queryBuilder) buildTokenExists(param, modifier, value string) string {
	rtP := b.next(b.rt)
	pP := b.next(param)
	// :text matches the human-readable display/text of the token (case-insensitive
	// substring), not its code.
	if modifier == "text" {
		vP := b.next("%" + strings.ToLower(value) + "%")
		return fmt.Sprintf("SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND LOWER(s.display) LIKE %s", rtP, pP, vP)
	}
	parts := strings.SplitN(value, "|", 2)
	if len(parts) == 2 {
		sys, code := parts[0], parts[1]
		if sys == "" {
			cP := b.next(code)
			return fmt.Sprintf("SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.code = %s", rtP, pP, cP)
		}
		if code == "" {
			sP := b.next(sys)
			return fmt.Sprintf("SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.system = %s", rtP, pP, sP)
		}
		sP := b.next(sys)
		cP := b.next(code)
		return fmt.Sprintf("SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.system = %s AND s.code = %s", rtP, pP, sP, cP)
	}
	vP := b.next(value)
	return fmt.Sprintf("SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.code = %s", rtP, pP, vP)
}

// buildTokenInExists expands a ValueSet URL and builds an IN/NOT IN subquery
// against sp_token. Requires b.terminology to be set.
func (b *queryBuilder) buildTokenInExists(param, modifier, vsURL string) (string, bool) {
	if b.terminology == nil {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("modifier :%s on param %q requires FHIR_TERMINOLOGY_URL to be configured", modifier, param)}
		return "", false
	}
	codes, err := b.terminology.Expand(b.ctx, vsURL)
	if err != nil {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("ValueSet $expand %s failed: %v", vsURL, err)}
		return "", false
	}
	if len(codes) == 0 {
		// Empty ValueSet: return a subquery that yields no rows. The caller wraps
		// it in EXISTS(...), so :in → EXISTS(∅) = false (match none), and :not-in
		// → NOT EXISTS(∅) = true (match all). Must be a real subquery, not a bare
		// boolean, because EXISTS requires a SELECT.
		return emptyRowSubquery, true
	}

	sub := b.tokenCodeSetExists(param, codes)
	// caller wraps :not-in in NOT EXISTS at the applyParam level.
	return sub, true
}

// emptyRowSubquery is a valid SELECT that returns no rows, used as the body of
// an EXISTS(...) when a token-set helper resolves to no codes.
const emptyRowSubquery = "SELECT 1 WHERE false"

// tokenCodeSetExists builds a SELECT-1 subquery matching sp_token rows for
// param whose (system,code) is in the given code set (OR-joined pairs).
func (b *queryBuilder) tokenCodeSetExists(param string, codes []terminology.CodeEntry) string {
	rtP := b.next(b.rt)
	pP := b.next(param)
	var pairOrs []string
	for _, c := range codes {
		if c.System != "" {
			sP := b.next(c.System)
			cP := b.next(c.Code)
			pairOrs = append(pairOrs, fmt.Sprintf("(s.system = %s AND s.code = %s)", sP, cP))
		} else {
			cP := b.next(c.Code)
			pairOrs = append(pairOrs, fmt.Sprintf("s.code = %s", cP))
		}
	}
	codeFilter := "(" + strings.Join(pairOrs, " OR ") + ")"
	return fmt.Sprintf("SELECT 1 FROM sp_token s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND %s",
		rtP, pP, codeFilter)
}

// buildOfTypeExists implements the token :of-type modifier for Identifiers.
// value is "typeSystem|typeCode|idValue" (system optional). It matches the
// auxiliary "<param>:of-type" rows written by the indexer, which carry the
// Identifier.type coding in system/code and the identifier value in display.
func (b *queryBuilder) buildOfTypeExists(param, value string) string {
	parts := strings.SplitN(value, "|", 3)
	var typeSys, typeCode, idValue string
	switch len(parts) {
	case 3:
		typeSys, typeCode, idValue = parts[0], parts[1], parts[2]
	case 2:
		typeCode, idValue = parts[0], parts[1]
	default:
		idValue = value
	}
	rtP := b.next(b.rt)
	pP := b.next(param + ":of-type") // matches index.OfTypeSuffix
	conds := []string{
		fmt.Sprintf("s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s", rtP, pP),
	}
	if typeSys != "" {
		conds = append(conds, fmt.Sprintf("s.system = %s", b.next(typeSys)))
	}
	if typeCode != "" {
		conds = append(conds, fmt.Sprintf("s.code = %s", b.next(typeCode)))
	}
	if idValue != "" {
		conds = append(conds, fmt.Sprintf("s.display = %s", b.next(idValue)))
	}
	return "SELECT 1 FROM sp_token s WHERE " + strings.Join(conds, " AND ")
}

// buildTokenHierarchyExists implements token :above / :below via the
// terminology server's subsumption filters (:below = is-a descendants,
// :above = generalizes ancestors). value is "system|code".
func (b *queryBuilder) buildTokenHierarchyExists(param, modifier, value string) (string, bool) {
	if b.terminology == nil {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("modifier :%s on param %q requires FHIR_TERMINOLOGY_URL (code-system subsumption)", modifier, param)}
		return "", false
	}
	sys, code := value, ""
	if i := strings.Index(value, "|"); i >= 0 {
		sys, code = value[:i], value[i+1:]
	}
	if sys == "" || code == "" {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("modifier :%s requires a system|code value, got %q", modifier, value)}
		return "", false
	}
	op := "is-a" // :below — the given code and its descendants
	if modifier == "above" {
		op = "generalizes" // the given code and its ancestors
	}
	codes, err := b.terminology.ExpandFilter(b.ctx, sys, op, code)
	if err != nil {
		b.err = &UnsupportedParamError{Msg: fmt.Sprintf("terminology subsumption (:%s) for %s|%s failed: %v", modifier, sys, code, err)}
		return "", false
	}
	if len(codes) == 0 {
		// No codes in the hierarchy → match nothing (valid no-rows subquery for
		// the EXISTS(...) wrapper).
		return emptyRowSubquery, true
	}
	return b.tokenCodeSetExists(param, codes), true
}

func (b *queryBuilder) buildDateExists(param, value string) string {
	prefix, dateStr := extractComparatorPrefix(value)
	low, high := expandDateRange(dateStr)
	rtP := b.next(b.rt)
	pP := b.next(param)
	// Only bind the args actually referenced by each operator to avoid PG arg-count mismatch.
	switch prefix {
	case "gt":
		highP := b.next(high)
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low > %s", rtP, pP, highP)
	case "lt":
		lowP := b.next(low)
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_high < %s", rtP, pP, lowP)
	case "ge":
		lowP := b.next(low)
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_high >= %s", rtP, pP, lowP)
	case "le":
		highP := b.next(high)
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low <= %s", rtP, pP, highP)
	case "ne":
		highP := b.next(high)
		lowP := b.next(low)
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND NOT (s.value_low <= %s AND s.value_high >= %s)", rtP, pP, highP, lowP)
	default: // eq
		highP := b.next(high)
		lowP := b.next(low)
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low <= %s AND s.value_high >= %s", rtP, pP, highP, lowP)
	}
}

func (b *queryBuilder) buildNumberExists(param, value string) string {
	prefix, numStr := extractComparatorPrefix(value)
	f, _ := strconv.ParseFloat(numStr, 64)
	eps := math.Abs(f) * 1e-7
	if eps == 0 {
		eps = 1e-7
	}
	rtP := b.next(b.rt)
	pP := b.next(param)
	switch prefix {
	case "gt":
		vP := b.next(f)
		return fmt.Sprintf("SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_high > %s", rtP, pP, vP)
	case "lt":
		vP := b.next(f)
		return fmt.Sprintf("SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low < %s", rtP, pP, vP)
	default: // eq
		highP := b.next(f + eps)
		lowP := b.next(f - eps)
		return fmt.Sprintf("SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low <= %s AND s.value_high >= %s", rtP, pP, highP, lowP)
	}
}

// buildReferenceExists matches a reference param against sp_reference. It accepts
// "Type/id", a bare "id", or an absolute URL, and supports the :identifier
// modifier (patient:identifier=system|value) and an explicit target-type
// modifier (subject:Patient=123).
func (b *queryBuilder) buildReferenceExists(param, modifier, value string) string {
	rtP := b.next(b.rt)
	pP := b.next(param)

	if modifier == "identifier" {
		system, val := "", value
		if i := strings.Index(value, "|"); i >= 0 {
			system, val = value[:i], value[i+1:]
		}
		if system != "" {
			sP := b.next(system)
			vP := b.next(val)
			return fmt.Sprintf("SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.identifier_system = %s AND s.identifier_value = %s", rtP, pP, sP, vP)
		}
		vP := b.next(val)
		return fmt.Sprintf("SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.identifier_value = %s", rtP, pP, vP)
	}

	typ, id := parseSearchReference(value)
	if typ == "" && modifier != "" {
		// e.g. subject:Patient=123 — the modifier names the target type.
		typ = modifier
	}
	if typ != "" {
		tP := b.next(typ)
		iP := b.next(id)
		return fmt.Sprintf("SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.target_type = %s AND s.target_id = %s", rtP, pP, tP, iP)
	}
	iP := b.next(id)
	return fmt.Sprintf("SELECT 1 FROM sp_reference s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.target_id = %s", rtP, pP, iP)
}

// buildQuantityExists matches a quantity param against sp_quantity. The value is
// "[prefix]number|system|code"; system and code are optional. The third token is
// matched against the coded (UCUM) unit stored in sp_quantity.code.
func (b *queryBuilder) buildQuantityExists(param, value string) string {
	numPart := value
	var system, code string
	if parts := strings.SplitN(value, "|", 3); len(parts) > 1 {
		numPart = parts[0]
		system = parts[1]
		if len(parts) == 3 {
			code = parts[2]
		}
	}
	prefix, numStr := extractComparatorPrefix(numPart)
	f, _ := strconv.ParseFloat(numStr, 64)
	eps := math.Abs(f) * 1e-7
	if eps == 0 {
		eps = 1e-7
	}
	low, high := f-eps, f+eps
	rtP := b.next(b.rt)
	pP := b.next(param)

	// Compare the indexed range against the search range endpoints (mirrors
	// buildDateExists) so boundary values are not matched incorrectly — e.g. an
	// indexed 5 must not satisfy gt5.
	var cond string
	switch prefix {
	case "gt":
		cond = fmt.Sprintf("s.value_low > %s", b.next(high))
	case "lt":
		cond = fmt.Sprintf("s.value_high < %s", b.next(low))
	case "ge":
		cond = fmt.Sprintf("s.value_high >= %s", b.next(low))
	case "le":
		cond = fmt.Sprintf("s.value_low <= %s", b.next(high))
	case "ne":
		hP := b.next(high)
		lP := b.next(low)
		cond = fmt.Sprintf("NOT (s.value_low <= %s AND s.value_high >= %s)", hP, lP)
	default: // eq
		hP := b.next(high)
		lP := b.next(low)
		cond = fmt.Sprintf("s.value_low <= %s AND s.value_high >= %s", hP, lP)
	}

	q := fmt.Sprintf("SELECT 1 FROM sp_quantity s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND %s", rtP, pP, cond)
	if system != "" {
		q += fmt.Sprintf(" AND s.system = %s", b.next(system))
	}
	if code != "" {
		q += fmt.Sprintf(" AND s.code = %s", b.next(code))
	}
	return q
}

// buildURIExists matches a uri param against sp_uri. Default is an exact match.
// :below matches stored URIs at or beneath the search value in the path
// hierarchy (stored value has the search value as a prefix); :above matches
// stored URIs at or above it (the stored value is a prefix of the search value).
func (b *queryBuilder) buildURIExists(param, modifier, value string) string {
	rtP := b.next(b.rt)
	pP := b.next(param)
	switch modifier {
	case "below":
		// Stored value has the search value as a path prefix. LIKE 'prefix%'
		// uses the text_pattern_ops index; escape the literal's metacharacters.
		vP := b.next(escapeLike(value) + "%")
		return fmt.Sprintf("SELECT 1 FROM sp_uri s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value LIKE %s", rtP, pP, vP)
	case "above":
		// Stored value is a prefix of the search value. Compared with left()/
		// length() so the per-row stored value needs no LIKE escaping.
		vP := b.next(value)
		return fmt.Sprintf("SELECT 1 FROM sp_uri s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND left(%s, length(s.value)) = s.value", rtP, pP, vP)
	default:
		vP := b.next(value)
		return fmt.Sprintf("SELECT 1 FROM sp_uri s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value = %s", rtP, pP, vP)
	}
}

// escapeLike escapes the LIKE metacharacters %, _ and \ in a literal so it can
// be used as a prefix in a LIKE pattern without the value's own characters
// acting as wildcards.
func escapeLike(s string) string {
	r := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`)
	return r.Replace(s)
}

// parseSearchReference splits a reference search value into (type, id). It
// accepts "Patient/123", a bare "123", or an absolute URL ending in Type/id,
// and strips any "/_history/x" version suffix. Mirrors index.parseRefString.
func parseSearchReference(value string) (resourceType, id string) {
	value = strings.TrimSpace(value)
	if value == "" {
		return "", ""
	}
	if i := strings.Index(value, "/_history/"); i >= 0 {
		value = value[:i]
	}
	if idx := strings.LastIndex(value, "/"); idx >= 0 {
		pre := value[:idx]
		if slashIdx := strings.LastIndex(pre, "/"); slashIdx >= 0 {
			resourceType = pre[slashIdx+1:]
		} else {
			resourceType = pre
		}
		return resourceType, value[idx+1:]
	}
	return "", value
}

func (b *queryBuilder) applyLastUpdated(value string) {
	prefix, dateStr := extractComparatorPrefix(value)
	low, high := expandDateRange(dateStr)
	switch prefix {
	case "gt":
		highP := b.next(high)
		b.and(fmt.Sprintf("r.last_updated > %s", highP))
	case "lt":
		lowP := b.next(low)
		b.and(fmt.Sprintf("r.last_updated < %s", lowP))
	case "ge":
		lowP := b.next(low)
		b.and(fmt.Sprintf("r.last_updated >= %s", lowP))
	case "le":
		highP := b.next(high)
		b.and(fmt.Sprintf("r.last_updated <= %s", highP))
	default:
		lowP := b.next(low)
		highP := b.next(high)
		b.and(fmt.Sprintf("r.last_updated >= %s AND r.last_updated <= %s", lowP, highP))
	}
}

// addSort parses a _sort value (comma-separated; a leading '-' means
// descending) and appends each component to b.sort, preserving order.
func (b *queryBuilder) addSort(value string) {
	for _, part := range strings.Split(value, ",") {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}
		desc := false
		if strings.HasPrefix(part, "-") {
			desc = true
			part = part[1:]
		}
		b.sort = append(b.sort, sortKey{param: part, desc: desc})
	}
}

// orderByClause builds the SQL ORDER BY body (without the "ORDER BY" keyword)
// from b.sort. Each search-param key becomes a correlated subquery into its
// sp_* table — MIN(value) for ascending, MAX(value) for descending — so a
// resource with multiple values sorts by its lowest/highest, with NULLS LAST
// so unindexed resources sort to the end. _id and _lastUpdated sort directly
// off the resources table. Falls back to last_updated DESC when no usable key
// is supplied.
func (b *queryBuilder) orderByClause() string {
	var clauses []string
	for _, k := range b.sort {
		dir := "ASC"
		if k.desc {
			dir = "DESC"
		}
		switch k.param {
		case "_id":
			clauses = append(clauses, "r.fhir_id "+dir)
			continue
		case "_lastUpdated":
			clauses = append(clauses, "r.last_updated "+dir)
			continue
		case "_score":
			// relevance scoring is not implemented; skip rather than error.
			continue
		}

		table, col := "", ""
		if b.reg != nil {
			if def, ok := b.reg.Lookup(b.rt, k.param); ok {
				table = tableForType(def.ParamType)
				col = sortColumnForTable(table)
			}
		}
		if table == "" || col == "" {
			// Unknown or unsortable param (composite/special): skip it rather
			// than fail the whole search.
			continue
		}
		agg := "MIN"
		if k.desc {
			agg = "MAX"
		}
		pP := b.next(k.param)
		expr := fmt.Sprintf(
			"(SELECT %s(s.%s) FROM %s s WHERE s.resource_id = r.fhir_id AND s.resource_type = r.resource_type AND s.param_name = %s)",
			agg, col, table, pP,
		)
		clauses = append(clauses, expr+" "+dir+" NULLS LAST")
	}
	if len(clauses) == 0 {
		return "r.last_updated DESC"
	}
	return strings.Join(clauses, ", ")
}

// sortColumnForTable returns the value column to sort on for a given sp_* table.
func sortColumnForTable(table string) string {
	switch table {
	case "sp_string":
		return "value_lower"
	case "sp_token":
		return "code"
	case "sp_date":
		return "value_low"
	case "sp_number":
		return "value"
	case "sp_quantity":
		return "value"
	case "sp_uri":
		return "value"
	case "sp_reference":
		return "target_id"
	default:
		return ""
	}
}

// spExists returns a bare SELECT EXISTS subquery (without value filter) for
// the :missing modifier.
func (b *queryBuilder) spExists(table, param, _ string) string {
	rtP := b.next(b.rt)
	pP := b.next(param)
	return fmt.Sprintf("SELECT 1 FROM %s s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s", table, rtP, pP)
}

func (b *queryBuilder) count(ctx context.Context, pool *pgxpool.Pool) (int, error) {
	q := fmt.Sprintf(`SELECT COUNT(*) FROM resources r WHERE %s`, b.where.String())
	var n int
	err := pool.QueryRow(ctx, q, b.args...).Scan(&n)
	return n, err
}

func (b *queryBuilder) fetch(ctx context.Context, pool *pgxpool.Pool, limit, offset int) ([]map[string]any, error) {
	// Build the ORDER BY before binding LIMIT/OFFSET so the positional args line
	// up: [where args…, order-by param args…, limit, offset].
	orderBy := b.orderByClause()
	limitP := b.next(limit)
	offsetP := b.next(offset)
	q := fmt.Sprintf(`
		SELECT r.resource_json, r.version_id, r.last_updated
		FROM resources r
		WHERE %s
		ORDER BY %s
		LIMIT %s OFFSET %s`,
		b.where.String(), orderBy, limitP, offsetP,
	)

	rows, err := pool.Query(ctx, q, b.args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var entries []map[string]any
	for rows.Next() {
		var raw []byte
		var versionID int
		var lastUpdated time.Time
		if err := rows.Scan(&raw, &versionID, &lastUpdated); err != nil {
			return nil, err
		}
		m, err := unmarshalWithMeta(raw, versionID, lastUpdated)
		if err != nil {
			return nil, err
		}
		entries = append(entries, m)
	}
	return entries, rows.Err()
}

// fetchWithCount fetches matching rows and the total result count in a single
// round-trip using COUNT(*) OVER() as a window function. This replaces the
// previous pattern of firing a separate SELECT COUNT(*) query before the
// paginated SELECT, halving database load on every search request.
func (b *queryBuilder) fetchWithCount(ctx context.Context, pool *pgxpool.Pool, limit, offset int) (int, []map[string]any, error) {
	orderBy := b.orderByClause()
	limitP := b.next(limit)
	offsetP := b.next(offset)
	q := fmt.Sprintf(`
		SELECT r.resource_json, r.version_id, r.last_updated, COUNT(*) OVER() AS total_count
		FROM resources r
		WHERE %s
		ORDER BY %s
		LIMIT %s OFFSET %s`,
		b.where.String(), orderBy, limitP, offsetP,
	)

	rows, err := pool.Query(ctx, q, b.args...)
	if err != nil {
		return 0, nil, err
	}
	defer rows.Close()

	var total int
	var entries []map[string]any
	for rows.Next() {
		var raw []byte
		var versionID int
		var lastUpdated time.Time
		var totalCount int
		if err := rows.Scan(&raw, &versionID, &lastUpdated, &totalCount); err != nil {
			return 0, nil, err
		}
		if total == 0 {
			total = totalCount // populated from the first row; same on every row
		}
		m, err := unmarshalWithMeta(raw, versionID, lastUpdated)
		if err != nil {
			return 0, nil, err
		}
		entries = append(entries, m)
	}
	return total, entries, rows.Err()
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func splitModifier(key string) (param, modifier string) {
	if idx := strings.IndexByte(key, ':'); idx >= 0 {
		return key[:idx], key[idx+1:]
	}
	return key, ""
}

func extractComparatorPrefix(s string) (prefix, rest string) {
	for _, p := range []string{"eq", "ne", "gt", "lt", "ge", "le", "sa", "eb", "ap"} {
		if strings.HasPrefix(s, p) && len(s) > 2 {
			return p, s[2:]
		}
	}
	return "eq", s
}

func expandDateRange(s string) (low, high time.Time) {
	low, high, _ = expandDateStringForSearch(s)
	return
}

func expandDateStringForSearch(s string) (low, high time.Time, err error) {
	s = strings.TrimSpace(s)
	switch len(s) {
	case 4:
		y := mustParseInt(s)
		low = time.Date(y, 1, 1, 0, 0, 0, 0, time.UTC)
		high = time.Date(y, 12, 31, 23, 59, 59, 0, time.UTC)
	case 7:
		y, m := mustParseInt(s[:4]), time.Month(mustParseInt(s[5:7]))
		low = time.Date(y, m, 1, 0, 0, 0, 0, time.UTC)
		high = time.Date(y, m+1, 1, 0, 0, 0, 0, time.UTC).Add(-time.Second)
	case 10:
		t, e := time.ParseInLocation("2006-01-02", s, time.UTC)
		if e != nil {
			return time.Time{}, time.Time{}, e
		}
		low = t
		high = t.Add(24*time.Hour - time.Second)
	default:
		t, e := time.Parse(time.RFC3339, s)
		if e != nil {
			t, e = time.Parse("2006-01-02T15:04:05", s)
		}
		if e != nil {
			return time.Time{}, time.Time{}, e
		}
		low, high = t, t
	}
	return
}

func mustParseInt(s string) int {
	n, _ := strconv.Atoi(s)
	return n
}

func looksLikeDate(s string) bool {
	// Strip comparator prefix
	_, rest := extractComparatorPrefix(s)
	return len(rest) >= 4 && rest[0] >= '1' && rest[0] <= '9' &&
		(len(rest) == 4 || (len(rest) > 4 && rest[4] == '-'))
}

func looksLikeNumber(s string) bool {
	_, rest := extractComparatorPrefix(s)
	_, err := strconv.ParseFloat(rest, 64)
	return err == nil
}

// FetchReferences returns resources linked to/from resourceID via sp_reference.
func (s *Store) FetchReferences(ctx context.Context, resourceType, resourceID string, reverse bool) ([]map[string]any, error) {
	var q string
	var args []any
	if !reverse {
		q = `SELECT DISTINCT r.resource_json, r.version_id, r.last_updated
			 FROM sp_reference sr
			 JOIN resources r ON r.fhir_id = sr.target_id AND r.resource_type = sr.target_type
			 WHERE sr.resource_id = $1 AND sr.resource_type = $2 AND r.is_deleted = FALSE`
		args = []any{resourceID, resourceType}
	} else {
		q = `SELECT DISTINCT r.resource_json, r.version_id, r.last_updated
			 FROM sp_reference sr
			 JOIN resources r ON r.fhir_id = sr.resource_id AND r.resource_type = sr.resource_type
			 WHERE sr.target_id = $1 AND sr.target_type = $2 AND r.is_deleted = FALSE`
		args = []any{resourceID, resourceType}
	}

	rows, err := s.pool.Query(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanResourceRows(rows)
}

func scanResourceRows(rows pgx.Rows) ([]map[string]any, error) {
	var results []map[string]any
	for rows.Next() {
		var raw []byte
		var versionID int
		var lastUpdated time.Time
		if err := rows.Scan(&raw, &versionID, &lastUpdated); err != nil {
			return nil, err
		}
		m, err := unmarshalWithMeta(raw, versionID, lastUpdated)
		if err != nil {
			return nil, err
		}
		results = append(results, m)
	}
	return results, rows.Err()
}
