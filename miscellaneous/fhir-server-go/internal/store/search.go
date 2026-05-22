package store

import (
	"context"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// SearchParams are the parsed query parameters from the HTTP request.
type SearchParams struct {
	ResourceType string
	Params       map[string][]string // raw query params
	Page         int
	PageSize     int
}

type SearchResult struct {
	Total   int
	Entries []map[string]any
}

// Search executes a FHIR search against the resources + sp_* tables.
func (s *Store) Search(ctx context.Context, sp SearchParams) (SearchResult, error) {
	if sp.PageSize <= 0 {
		sp.PageSize = 20
	}
	if sp.Page <= 0 {
		sp.Page = 1
	}
	offset := (sp.Page - 1) * sp.PageSize

	b := &queryBuilder{rt: sp.ResourceType}
	b.writeBase()

	for rawKey, values := range sp.Params {
		if len(values) == 0 {
			continue
		}
		b.applyParam(rawKey, values[0])
	}

	total, err := b.count(ctx, s.pool)
	if err != nil {
		return SearchResult{}, err
	}

	entries, err := b.fetch(ctx, s.pool, sp.PageSize, offset)
	if err != nil {
		return SearchResult{}, err
	}

	return SearchResult{Total: total, Entries: entries}, nil
}

// ─── Query builder ────────────────────────────────────────────────────────────

type queryBuilder struct {
	rt     string
	where  strings.Builder
	args   []any
	argN   int
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
	case "_count", "_page", "_sort", "_include", "_revinclude", "_format", "_summary":
		// control params — handled at the HTTP layer
	default:
		b.applySearchParam(paramName, modifier, value)
	}
}

func (b *queryBuilder) applySearchParam(param, modifier, value string) {
	if modifier == "missing" {
		exists := b.spExists("sp_string", param, "")
		if value == "true" {
			b.and(fmt.Sprintf("NOT EXISTS (%s)", exists))
		} else {
			b.and(fmt.Sprintf("EXISTS (%s)", exists))
		}
		return
	}

	// OR: comma-separated
	parts := strings.Split(value, ",")
	if len(parts) > 1 {
		var ors []string
		for _, p := range parts {
			cond, ok := b.buildExistsForValue(param, modifier, strings.TrimSpace(p))
			if ok {
				ors = append(ors, fmt.Sprintf("EXISTS (%s)", cond))
			}
		}
		if len(ors) > 0 {
			b.and("(" + strings.Join(ors, " OR ") + ")")
		}
		return
	}

	cond, ok := b.buildExistsForValue(param, modifier, value)
	if ok {
		b.and(fmt.Sprintf("EXISTS (%s)", cond))
	}
}

// buildExistsForValue builds an EXISTS subquery for a single value.
// Without knowing the param type at query-build time, we do a best-effort
// guess from the value format. In practice the handler layer can inject
// the registry lookup; for now string/token cover the common cases.
func (b *queryBuilder) buildExistsForValue(param, modifier, value string) (string, bool) {
	// Heuristic type detection from value format
	switch {
	case looksLikeDate(value):
		return b.buildDateExists(param, value), true
	case looksLikeNumber(value):
		return b.buildNumberExists(param, value), true
	case strings.Contains(value, "|"):
		return b.buildTokenExists(param, modifier, value), true
	default:
		return b.buildStringExists(param, modifier, value), true
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
	lowP := b.next(low)
	highP := b.next(high)
	switch prefix {
	case "gt":
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low > %s", rtP, pP, highP)
	case "lt":
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_high < %s", rtP, pP, lowP)
	case "ge":
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_high >= %s", rtP, pP, lowP)
	case "le":
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low <= %s", rtP, pP, highP)
	case "ne":
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND NOT (s.value_low <= %s AND s.value_high >= %s)", rtP, pP, highP, lowP)
	default: // eq
		return fmt.Sprintf("SELECT 1 FROM sp_date s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low <= %s AND s.value_high >= %s", rtP, pP, highP, lowP)
	}
}

func (b *queryBuilder) buildNumberExists(param, value string) string {
	prefix, numStr := extractComparatorPrefix(value)
	f, _ := strconv.ParseFloat(numStr, 64)
	eps := math.Abs(f) * 1e-7
	rtP := b.next(b.rt)
	pP := b.next(param)
	vP := b.next(f)
	lowP := b.next(f - eps)
	highP := b.next(f + eps)
	_ = lowP
	switch prefix {
	case "gt":
		return fmt.Sprintf("SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_high > %s", rtP, pP, vP)
	case "lt":
		return fmt.Sprintf("SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low < %s", rtP, pP, vP)
	default:
		return fmt.Sprintf("SELECT 1 FROM sp_number s WHERE s.resource_id = r.fhir_id AND s.resource_type = %s AND s.param_name = %s AND s.value_low <= %s AND s.value_high >= %s", rtP, pP, highP, vP)
	}
}

func (b *queryBuilder) applyLastUpdated(value string) {
	prefix, dateStr := extractComparatorPrefix(value)
	low, high := expandDateRange(dateStr)
	lowP := b.next(low)
	highP := b.next(high)
	switch prefix {
	case "gt":
		b.and(fmt.Sprintf("r.last_updated > %s", highP))
	case "lt":
		b.and(fmt.Sprintf("r.last_updated < %s", lowP))
	case "ge":
		b.and(fmt.Sprintf("r.last_updated >= %s", lowP))
	case "le":
		b.and(fmt.Sprintf("r.last_updated <= %s", highP))
	default:
		b.and(fmt.Sprintf("r.last_updated >= %s AND r.last_updated <= %s", lowP, highP))
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
	limitP := b.next(limit)
	offsetP := b.next(offset)
	q := fmt.Sprintf(`
		SELECT r.resource_json, r.version_id, r.last_updated
		FROM resources r
		WHERE %s
		ORDER BY r.last_updated DESC
		LIMIT %s OFFSET %s`,
		b.where.String(), limitP, offsetP,
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
