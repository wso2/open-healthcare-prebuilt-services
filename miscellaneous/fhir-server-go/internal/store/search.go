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

	b := &queryBuilder{rt: sp.ResourceType, reg: s.registry}
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

	// _total=none skips the count for performance; _summary=count always needs
	// it. Total stays -1 (sentinel "not computed") when skipped.
	total := -1
	if sp.Total != "none" || sp.CountOnly {
		n, err := b.count(ctx, s.pool)
		if err != nil {
			slog.Error("search count failed", "resourceType", sp.ResourceType, "err", err)
			return SearchResult{}, err
		}
		total = n
	}

	// _summary=count returns only the total — skip fetching matches and includes.
	if sp.CountOnly {
		return SearchResult{Total: total}, nil
	}

	entries, err := b.fetch(ctx, s.pool, sp.PageSize, offset)
	if err != nil {
		return SearchResult{}, err
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
	rt    string
	reg   *searchparam.Registry
	where strings.Builder
	args  []any
	argN  int
	sort  []sortKey
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

	switch paramName {
	case "_id":
		p := b.next(value)
		b.and(fmt.Sprintf("r.fhir_id = %s", p))
	case "_lastUpdated":
		b.applyLastUpdated(value)
	case "_text", "_content":
		p := b.next(value)
		b.and(fmt.Sprintf("r.search_text @@ plainto_tsquery('english', %s)", p))
	case "_sort":
		b.addSort(value)
	case "_count", "_page", "_include", "_revinclude", "_format", "_summary", "_elements", "_total":
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
		if b.reg != nil {
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

	// :not negates the match: the resource must have NO value satisfying the
	// (comma-OR'd) criteria. Build the positive condition with the modifier
	// cleared, then negate the whole thing.
	if modifier == "not" {
		if expr := b.combinedExists(param, "", value); expr != "" {
			b.and("NOT " + expr)
		}
		return
	}

	if expr := b.combinedExists(param, modifier, value); expr != "" {
		b.and(expr)
	}
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
	if b.reg != nil {
		if def, ok := b.reg.Lookup(b.rt, param); ok {
			return b.buildTypedExists(def.ParamType, param, modifier, value)
		}
	}
	return b.buildHeuristicExists(param, modifier, value)
}

// buildTypedExists routes a value match to the sp_* table for the given FHIR
// search param type. Returns (subquery, false) for types we don't yet support
// (composite, special) so the caller can skip the filter rather than misroute it.
func (b *queryBuilder) buildTypedExists(paramType, param, modifier, value string) (string, bool) {
	switch paramType {
	case "string":
		return b.buildStringExists(param, modifier, value), true
	case "token":
		// :above/:below/:in/:not-in walk a code-system or ValueSet hierarchy and
		// :of-type matches Identifier.type — all of which need terminology or
		// type indexing we don't have here. Fail closed rather than mismatch.
		switch modifier {
		case "above", "below", "in", "not-in", "of-type":
			b.err = &UnsupportedParamError{Msg: fmt.Sprintf("modifier :%s on token param %q is not supported by the repository (needs a terminology server)", modifier, param)}
			return "", false
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
		// composite / special — not yet supported. Fail the request rather
		// than silently dropping the predicate (which would broaden results
		// and could surprise callers).
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
