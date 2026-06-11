// Package index extracts search parameter values from a FHIR resource JSON
// and writes them to the sp_* tables.
package index

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
	"github.com/wso2/open-healthcare-fhir-server-go/internal/fhirpath"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
)

// Extractor extracts and persists search index rows for a resource.
type Extractor struct {
	registry *searchparam.Registry
}

func New(registry *searchparam.Registry) *Extractor {
	return &Extractor{registry: registry}
}

// Index extracts all search parameter values from resource and inserts them
// into the sp_* tables within tx using a single batched round-trip.
func (e *Extractor) Index(ctx context.Context, tx pgx.Tx, resourceType, resourceID string, resource map[string]any) error {
	batch := &pgx.Batch{}

	defs := e.registry.ForResource(resourceType)
	for _, d := range defs {
		e.queueParam(batch, resourceType, resourceID, resource, d)
	}
	// Universal meta.* params (_tag/_security/_profile/_source) and the
	// resource-level language. These live on Resource/DomainResource and so
	// aren't in the per-resource registry; index them uniformly for every type.
	queueMeta(batch, resourceType, resourceID, resource)

	if batch.Len() == 0 {
		return nil
	}

	br := tx.SendBatch(ctx, batch)
	n := batch.Len()
	for i := 0; i < n; i++ {
		if _, err := br.Exec(); err != nil {
			slog.Warn("index batch exec failed", "type", resourceType, "i", i, "err", err)
			// Non-fatal — continue draining the batch
		}
	}
	return br.Close()
}

// queueMeta queues sp_* rows for the universal meta search params:
//
//	_tag, _security  → sp_token  (Codings from meta.tag / meta.security)
//	_profile, _source → sp_uri   (meta.profile URLs, meta.source URI)
//	_language        → sp_token  (top-level language code)
func queueMeta(batch *pgx.Batch, rt, rid string, resource map[string]any) {
	if meta, ok := resource["meta"].(map[string]any); ok {
		for _, m := range []struct{ field, param string }{{"tag", "_tag"}, {"security", "_security"}} {
			if arr, ok := meta[m.field].([]any); ok {
				for _, c := range arr {
					queueToken(batch, rt, rid, m.param, c)
				}
			}
		}
		if arr, ok := meta["profile"].([]any); ok {
			for _, p := range arr {
				queueURIValue(batch, rt, rid, "_profile", asString(p))
			}
		}
		queueURIValue(batch, rt, rid, "_source", asString(meta["source"]))
	}
	if lang := asString(resource["language"]); lang != "" {
		batch.Queue(
			`INSERT INTO sp_token (resource_id, resource_type, param_name, system, code, display)
			 VALUES ($1, $2, '_language', '', $3, '')`,
			rid, rt, lang,
		)
	}
}

// queueURIValue queues a single sp_uri row, skipping empty values.
func queueURIValue(batch *pgx.Batch, rt, rid, param, value string) {
	if value == "" {
		return
	}
	batch.Queue(
		`INSERT INTO sp_uri (resource_id, resource_type, param_name, value)
		 VALUES ($1, $2, $3, $4)`,
		rid, rt, param, value,
	)
}

// Delete removes all sp_* rows for a resource in a single batched round-trip.
func Delete(ctx context.Context, tx pgx.Tx, resourceType, resourceID string) error {
	tables := []string{"sp_string", "sp_token", "sp_date", "sp_number", "sp_quantity", "sp_uri", "sp_reference"}
	batch := &pgx.Batch{}
	for _, tbl := range tables {
		batch.Queue(
			fmt.Sprintf(`DELETE FROM %s WHERE resource_id = $1 AND resource_type = $2`, tbl),
			resourceID, resourceType,
		)
	}
	br := tx.SendBatch(ctx, batch)
	for _, tbl := range tables {
		if _, err := br.Exec(); err != nil {
			_ = br.Close()
			return fmt.Errorf("delete from %s: %w", tbl, err)
		}
	}
	return br.Close()
}

// Queue adds all search parameter insert statements for the given resource to
// an external batch without sending it. The caller is responsible for sending
// and draining the batch. This allows callers to merge index inserts with other
// write operations into a single round-trip.
func (e *Extractor) Queue(batch *pgx.Batch, resourceType, resourceID string, resource map[string]any) {
	defs := e.registry.ForResource(resourceType)
	for _, d := range defs {
		e.queueParam(batch, resourceType, resourceID, resource, d)
	}
	queueMeta(batch, resourceType, resourceID, resource)
}

// QueueDelete adds one DELETE statement per sp_* table for the given resource
// to an external batch without sending it. Seven statements total.
func QueueDelete(batch *pgx.Batch, resourceType, resourceID string) {
	for _, tbl := range []string{"sp_string", "sp_token", "sp_date", "sp_number", "sp_quantity", "sp_uri", "sp_reference"} {
		batch.Queue(
			fmt.Sprintf(`DELETE FROM %s WHERE resource_id = $1 AND resource_type = $2`, tbl),
			resourceID, resourceType,
		)
	}
}

// DeleteWithPool removes all sp_* rows using a pool (for soft-delete paths
// where no transaction is provided yet).
func DeleteWithPool(ctx context.Context, pool *pgxpool.Pool, resourceType, resourceID string) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	if err := Delete(ctx, tx, resourceType, resourceID); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func (e *Extractor) queueParam(batch *pgx.Batch, resourceType, resourceID string, resource map[string]any, d searchparam.Definition) {
	vals, err := fhirpath.EvaluatePolymorphic(d.FHIRPath, resource)
	if err != nil || len(vals) == 0 {
		return
	}

	switch d.ParamType {
	case "string":
		queueString(batch, resourceType, resourceID, d.ParamName, vals)
	case "token":
		queueTokenValues(batch, resourceType, resourceID, d.ParamName, vals)
	case "date", "dateTime", "instant", "Period":
		queueDate(batch, resourceType, resourceID, d.ParamName, vals)
	case "number":
		queueNumber(batch, resourceType, resourceID, d.ParamName, vals)
	case "quantity":
		queueQuantity(batch, resourceType, resourceID, d.ParamName, vals)
	case "uri":
		queueURI(batch, resourceType, resourceID, d.ParamName, vals)
	case "reference":
		queueReference(batch, resourceType, resourceID, d.ParamName, vals)
	}
}

// ─── sp_string ────────────────────────────────────────────────────────────────

func queueString(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		s := asString(v)
		if s == "" {
			continue
		}
		batch.Queue(
			`INSERT INTO sp_string (resource_id, resource_type, param_name, value_exact, value_lower)
			 VALUES ($1, $2, $3, $4, $5)`,
			rid, rt, param, s, strings.ToLower(s),
		)
	}
}

// ─── sp_token ─────────────────────────────────────────────────────────────────

func queueTokenValues(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		switch val := v.(type) {
		case map[string]any: // Coding or CodeableConcept
			if codings, ok := val["coding"].([]any); ok {
				for _, c := range codings {
					queueToken(batch, rt, rid, param, c)
				}
			} else {
				// Plain Coding
				queueToken(batch, rt, rid, param, val)
			}
		case bool:
			code := "false"
			if val {
				code = "true"
			}
			batch.Queue(
				`INSERT INTO sp_token (resource_id, resource_type, param_name, system, code, display)
				 VALUES ($1, $2, $3, '', $4, '')`,
				rid, rt, param, code,
			)
		case string:
			batch.Queue(
				`INSERT INTO sp_token (resource_id, resource_type, param_name, system, code, display)
				 VALUES ($1, $2, $3, '', $4, '')`,
				rid, rt, param, val,
			)
		}
	}
}

// OfTypeSuffix is appended to a token param name to store the auxiliary index
// row used by the :of-type modifier. The row carries the Identifier.type
// coding (system, code) plus the identifier value in the display column.
const OfTypeSuffix = ":of-type"

func queueToken(batch *pgx.Batch, rt, rid, param string, v any) {
	m, ok := v.(map[string]any)
	if !ok {
		return
	}
	sys := asString(m["system"])
	code := asString(m["code"])
	display := asString(m["display"])
	value := asString(m["value"])
	// Identifier and ContactPoint carry their token in "value" rather than
	// "code"; fall back to it so identifier/telecom token searches match.
	if code == "" {
		code = value
	}
	if code == "" {
		return
	}
	batch.Queue(
		`INSERT INTO sp_token (resource_id, resource_type, param_name, system, code, display)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		rid, rt, param, sys, code, display,
	)

	// :of-type support — only for Identifiers that carry a type.coding and a value.
	// Store an auxiliary row keyed by "<param>:of-type" with the type's
	// system/code and the identifier value in display.
	if value != "" {
		if typ, ok := m["type"].(map[string]any); ok {
			if codings, ok := typ["coding"].([]any); ok {
				for _, c := range codings {
					cm, _ := c.(map[string]any)
					if cm == nil {
						continue
					}
					tSys := asString(cm["system"])
					tCode := asString(cm["code"])
					if tCode == "" {
						continue
					}
					batch.Queue(
						`INSERT INTO sp_token (resource_id, resource_type, param_name, system, code, display)
						 VALUES ($1, $2, $3, $4, $5, $6)`,
						rid, rt, param+OfTypeSuffix, tSys, tCode, value,
					)
				}
			}
		}
	}
}

// ─── sp_date ──────────────────────────────────────────────────────────────────

func queueDate(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		low, high, err := parseDateRange(v)
		if err != nil {
			continue
		}
		batch.Queue(
			`INSERT INTO sp_date (resource_id, resource_type, param_name, value_low, value_high)
			 VALUES ($1, $2, $3, $4, $5)`,
			rid, rt, param, low, high,
		)
	}
}

func parseDateRange(v any) (low, high time.Time, err error) {
	switch val := v.(type) {
	case string:
		return expandDateString(val)
	case map[string]any:
		// Period: {start, end}
		startStr := asString(val["start"])
		endStr := asString(val["end"])
		if startStr == "" && endStr == "" {
			return time.Time{}, time.Time{}, fmt.Errorf("empty period")
		}
		if startStr != "" {
			low, _, err = expandDateString(startStr)
			if err != nil {
				return
			}
		} else {
			low = time.Time{}
		}
		if endStr != "" {
			_, high, err = expandDateString(endStr)
			if err != nil {
				return
			}
		} else {
			high = time.Date(9999, 12, 31, 23, 59, 59, 0, time.UTC)
		}
		return
	}
	return time.Time{}, time.Time{}, fmt.Errorf("unsupported date type %T", v)
}

var dateLayouts = []string{
	time.RFC3339,
	"2006-01-02T15:04:05",
	"2006-01-02",
	"2006-01",
	"2006",
}

func expandDateString(s string) (low, high time.Time, err error) {
	s = strings.TrimSpace(s)
	switch len(s) {
	case 4: // YYYY
		y, e := strconv.Atoi(s[0:4])
		if e != nil {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid year %q: %w", s, e)
		}
		low = time.Date(y, 1, 1, 0, 0, 0, 0, time.UTC)
		high = time.Date(y, 12, 31, 23, 59, 59, 0, time.UTC)
	case 7: // YYYY-MM
		if s[4] != '-' {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid year-month %q", s)
		}
		y, e1 := strconv.Atoi(s[0:4])
		mi, e2 := strconv.Atoi(s[5:7])
		if e1 != nil || e2 != nil || mi < 1 || mi > 12 {
			return time.Time{}, time.Time{}, fmt.Errorf("invalid year-month %q", s)
		}
		m := time.Month(mi)
		low = time.Date(y, m, 1, 0, 0, 0, 0, time.UTC)
		high = time.Date(y, m+1, 1, 0, 0, 0, 0, time.UTC).Add(-time.Second)
	case 10: // YYYY-MM-DD
		t, e := time.ParseInLocation("2006-01-02", s, time.UTC)
		if e != nil {
			return time.Time{}, time.Time{}, e
		}
		low = t
		high = t.Add(24*time.Hour - time.Second)
	default:
		// Full datetime
		for _, layout := range dateLayouts {
			t, e := time.Parse(layout, s)
			if e == nil {
				return t, t, nil
			}
		}
		return time.Time{}, time.Time{}, fmt.Errorf("cannot parse date %q", s)
	}
	return
}

// ─── sp_number ────────────────────────────────────────────────────────────────

func queueNumber(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		f, ok := toFloat(v)
		if !ok {
			continue
		}
		// ±5 ULP as implicit precision range
		eps := math.Abs(f) * 1e-7
		batch.Queue(
			`INSERT INTO sp_number (resource_id, resource_type, param_name, value_low, value_high)
			 VALUES ($1, $2, $3, $4, $5)`,
			rid, rt, param, f-eps, f+eps,
		)
	}
}

// ─── sp_quantity ──────────────────────────────────────────────────────────────

func queueQuantity(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		m, ok := v.(map[string]any)
		if !ok {
			continue
		}
		f, ok := toFloat(m["value"])
		if !ok {
			continue
		}
		sys := asString(m["system"])
		code := asString(m["code"])
		eps := math.Abs(f) * 1e-7
		batch.Queue(
			`INSERT INTO sp_quantity (resource_id, resource_type, param_name, value, value_low, value_high, system, code)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
			rid, rt, param, f, f-eps, f+eps, sys, code,
		)
	}
}

// ─── sp_uri ───────────────────────────────────────────────────────────────────

func queueURI(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		s := asString(v)
		if s == "" {
			continue
		}
		batch.Queue(
			`INSERT INTO sp_uri (resource_id, resource_type, param_name, value)
			 VALUES ($1, $2, $3, $4)`,
			rid, rt, param, s,
		)
	}
}

// ─── sp_reference ─────────────────────────────────────────────────────────────

func queueReference(batch *pgx.Batch, rt, rid, param string, vals []any) {
	for _, v := range vals {
		m, ok := v.(map[string]any)
		if !ok {
			// May be a plain reference string
			if s := asString(v); s != "" {
				tType, tID := parseRefString(s)
				batch.Queue(
					`INSERT INTO sp_reference (resource_id, resource_type, param_name, target_type, target_id, identifier_system, identifier_value)
					 VALUES ($1, $2, $3, $4, $5, '', '')`,
					rid, rt, param, tType, tID,
				)
			}
			continue
		}
		ref := asString(m["reference"])
		tType, tID := parseRefString(ref)

		var idSys, idVal string
		if id, ok := m["identifier"].(map[string]any); ok {
			idSys = asString(id["system"])
			idVal = asString(id["value"])
		}

		batch.Queue(
			`INSERT INTO sp_reference (resource_id, resource_type, param_name, target_type, target_id, identifier_system, identifier_value)
			 VALUES ($1, $2, $3, $4, $5, $6, $7)`,
			rid, rt, param, tType, tID, idSys, idVal,
		)
	}
}

// parseRefString splits "Patient/123" into ("Patient", "123"). Versioned
// references like "Patient/123/_history/2" have the history suffix stripped
// before splitting so the parser doesn't treat "_history" as the id segment.
func parseRefString(ref string) (resourceType, id string) {
	ref = strings.TrimSpace(ref)
	if ref == "" {
		return "", ""
	}
	if i := strings.Index(ref, "/_history/"); i >= 0 {
		ref = ref[:i]
	}
	if idx := strings.LastIndex(ref, "/"); idx >= 0 {
		pre := ref[:idx]
		if slashIdx := strings.LastIndex(pre, "/"); slashIdx >= 0 {
			resourceType = pre[slashIdx+1:]
		} else {
			resourceType = pre
		}
		id = ref[idx+1:]
		return
	}
	return "", ref
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func asString(v any) string {
	if v == nil {
		return ""
	}
	switch s := v.(type) {
	case string:
		return s
	default:
		return fmt.Sprintf("%v", v)
	}
}

func toFloat(v any) (float64, bool) {
	switch n := v.(type) {
	case float64:
		return n, true
	case int:
		return float64(n), true
	case int64:
		return float64(n), true
	case string:
		f, err := strconv.ParseFloat(n, 64)
		return f, err == nil
	}
	return 0, false
}
