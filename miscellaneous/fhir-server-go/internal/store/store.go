// Package store implements FHIR CRUD operations against the normalized schema.
package store

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/index"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
)

type Store struct {
	pool      *pgxpool.Pool
	extractor *index.Extractor
	registry  *searchparam.Registry
}

func New(pool *pgxpool.Pool, registry *searchparam.Registry) *Store {
	return &Store{
		pool:      pool,
		extractor: index.New(registry),
		registry:  registry,
	}
}

// ─── Create ───────────────────────────────────────────────────────────────────

func (s *Store) Create(ctx context.Context, resourceType string, body map[string]any) (map[string]any, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	result, err := s.createInTx(ctx, tx, resourceType, body)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	id, _ := result["id"].(string)
	slog.Info("created resource", "type", resourceType, "id", id)
	return result, nil
}

// createInTx performs a create within an existing transaction. It is the shared
// implementation behind the public Create and behind transaction/batch Bundle
// processing, where many writes must commit or roll back together.
func (s *Store) createInTx(ctx context.Context, tx pgx.Tx, resourceType string, body map[string]any) (map[string]any, error) {
	resourceID, _ := body["id"].(string)
	if resourceID == "" {
		resourceID = uuid.NewString()
	}
	body["id"] = resourceID
	body["resourceType"] = resourceType

	now := time.Now().UTC()
	body = setMeta(body, 1, now)

	raw, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("marshal resource: %w", err)
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO resources (fhir_id, resource_type, version_id, last_updated, is_deleted, resource_json)
		VALUES ($1, $2, 1, $3, FALSE, $4)`,
		resourceID, resourceType, now, raw,
	); err != nil {
		return nil, fmt.Errorf("insert resource: %w", err)
	}

	if err := s.extractor.Index(ctx, tx, resourceType, resourceID, body); err != nil {
		return nil, fmt.Errorf("index resource: %w", err)
	}

	if err := saveHistory(ctx, tx, resourceType, resourceID, 1, "POST", raw, now); err != nil {
		return nil, err
	}

	return body, nil
}

// ─── Read ─────────────────────────────────────────────────────────────────────

func (s *Store) Read(ctx context.Context, resourceType, resourceID string) (map[string]any, error) {
	var raw []byte
	var versionID int
	var lastUpdated time.Time
	var isDeleted bool

	err := s.pool.QueryRow(ctx, `
		SELECT resource_json, version_id, last_updated, is_deleted
		FROM resources
		WHERE fhir_id = $1 AND resource_type = $2`,
		resourceID, resourceType,
	).Scan(&raw, &versionID, &lastUpdated, &isDeleted)
	if err != nil {
		if isNoRows(err) {
			return nil, NotFoundError{resourceType, resourceID}
		}
		return nil, err
	}
	if isDeleted {
		return nil, GoneError{resourceType, resourceID}
	}

	return unmarshalWithMeta(raw, versionID, lastUpdated)
}

// ─── Update (PUT) ─────────────────────────────────────────────────────────────

// Update replaces a resource. ifMatchVersion = -1 means no version check;
// any value >= 0 is compared to the current version_id and a ConflictError
// (412) is returned if they differ.
func (s *Store) Update(ctx context.Context, resourceType, resourceID string, body map[string]any, ifMatchVersion int) (map[string]any, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	result, err := s.updateInTx(ctx, tx, resourceType, resourceID, body, ifMatchVersion)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	slog.Info("updated resource", "type", resourceType, "id", resourceID, "version", metaVersionID(result))
	return result, nil
}

// updateInTx performs an update within an existing transaction. Shared by the
// public Update and by transaction/batch Bundle processing.
func (s *Store) updateInTx(ctx context.Context, tx pgx.Tx, resourceType, resourceID string, body map[string]any, ifMatchVersion int) (map[string]any, error) {
	body["id"] = resourceID
	body["resourceType"] = resourceType

	newVersion, currentVersion, lastUpdated, err := bumpVersion(ctx, tx, resourceType, resourceID)
	if err != nil {
		return nil, err
	}
	if ifMatchVersion >= 0 && currentVersion != ifMatchVersion {
		return nil, ConflictError{fmt.Sprintf("version conflict: current=%d, if-match=%d", currentVersion, ifMatchVersion)}
	}

	body = setMeta(body, newVersion, lastUpdated)
	raw, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE resources SET version_id = $1, last_updated = $2, resource_json = $3, is_deleted = FALSE
		WHERE fhir_id = $4 AND resource_type = $5`,
		newVersion, lastUpdated, raw, resourceID, resourceType,
	); err != nil {
		return nil, err
	}

	if err := index.Delete(ctx, tx, resourceType, resourceID); err != nil {
		return nil, err
	}
	if err := s.extractor.Index(ctx, tx, resourceType, resourceID, body); err != nil {
		return nil, err
	}
	if err := saveHistory(ctx, tx, resourceType, resourceID, newVersion, "PUT", raw, lastUpdated); err != nil {
		return nil, err
	}

	return body, nil
}

// ─── Patch (JSON Merge Patch) ─────────────────────────────────────────────────

// Patch applies a JSON Merge Patch (RFC 7396) atomically. The read and write
// happen inside a single transaction with a FOR UPDATE lock so concurrent
// PATCHes to the same resource cannot produce a lost update.
func (s *Store) Patch(ctx context.Context, resourceType, resourceID string, patch map[string]any) (map[string]any, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	merged, newVersion, err := s.patchInTx(ctx, tx, resourceType, resourceID, patch)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	slog.Info("patched resource", "type", resourceType, "id", resourceID, "version", newVersion)
	return merged, nil
}

// patchInTx applies a JSON Merge Patch within an existing transaction, taking a
// FOR UPDATE lock on the row. Shared by the public Patch and by Bundle processing.
func (s *Store) patchInTx(ctx context.Context, tx pgx.Tx, resourceType, resourceID string, patch map[string]any) (map[string]any, int, error) {
	var raw []byte
	var versionID int
	var lastUpdated time.Time
	var isDeleted bool
	if err := tx.QueryRow(ctx, `
		SELECT resource_json, version_id, last_updated, is_deleted
		FROM resources WHERE fhir_id = $1 AND resource_type = $2 FOR UPDATE`,
		resourceID, resourceType,
	).Scan(&raw, &versionID, &lastUpdated, &isDeleted); err != nil {
		if isNoRows(err) {
			return nil, 0, NotFoundError{resourceType, resourceID}
		}
		return nil, 0, err
	}
	if isDeleted {
		return nil, 0, GoneError{resourceType, resourceID}
	}

	existing, err := unmarshalWithMeta(raw, versionID, lastUpdated)
	if err != nil {
		return nil, 0, err
	}
	merged := mergePatch(existing, patch)
	merged["id"] = resourceID
	merged["resourceType"] = resourceType

	newVersion := versionID + 1
	now := time.Now().UTC()
	merged = setMeta(merged, newVersion, now)
	mergedRaw, err := json.Marshal(merged)
	if err != nil {
		return nil, 0, err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE resources SET version_id = $1, last_updated = $2, resource_json = $3, is_deleted = FALSE
		WHERE fhir_id = $4 AND resource_type = $5`,
		newVersion, now, mergedRaw, resourceID, resourceType,
	); err != nil {
		return nil, 0, err
	}
	if err := index.Delete(ctx, tx, resourceType, resourceID); err != nil {
		return nil, 0, err
	}
	if err := s.extractor.Index(ctx, tx, resourceType, resourceID, merged); err != nil {
		return nil, 0, err
	}
	if err := saveHistory(ctx, tx, resourceType, resourceID, newVersion, "PATCH", mergedRaw, now); err != nil {
		return nil, 0, err
	}

	return merged, newVersion, nil
}

// mergePatch applies a JSON Merge Patch (RFC 7396).
func mergePatch(target, patch map[string]any) map[string]any {
	result := make(map[string]any, len(target))
	for k, v := range target {
		result[k] = v
	}
	for k, v := range patch {
		if v == nil {
			delete(result, k)
		} else if subPatch, ok := v.(map[string]any); ok {
			if subTarget, ok := result[k].(map[string]any); ok {
				result[k] = mergePatch(subTarget, subPatch)
			} else {
				result[k] = v
			}
		} else {
			result[k] = v
		}
	}
	return result
}

// ─── Delete ───────────────────────────────────────────────────────────────────

func (s *Store) Delete(ctx context.Context, resourceType, resourceID string) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if err := s.deleteInTx(ctx, tx, resourceType, resourceID); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return err
	}

	slog.Info("deleted resource", "type", resourceType, "id", resourceID)
	return nil
}

// deleteInTx soft-deletes a resource within an existing transaction. Shared by
// the public Delete and by Bundle processing. Idempotent: deleting an already
// deleted or non-existent resource returns nil.
func (s *Store) deleteInTx(ctx context.Context, tx pgx.Tx, resourceType, resourceID string) error {
	// Lock the row first to prevent a concurrent Update from bumping the version
	// between our read and our soft-delete write, which would produce a UNIQUE
	// constraint violation on resource_history(fhir_id, resource_type, version_id).
	var raw []byte
	var versionID int
	var lastUpdated time.Time
	var isDeleted bool
	if err := tx.QueryRow(ctx, `
		SELECT resource_json, version_id, last_updated, is_deleted
		FROM resources WHERE fhir_id = $1 AND resource_type = $2 FOR UPDATE`,
		resourceID, resourceType,
	).Scan(&raw, &versionID, &lastUpdated, &isDeleted); err != nil {
		if isNoRows(err) {
			return NotFoundError{resourceType, resourceID}
		}
		return err
	}
	if isDeleted {
		return nil // idempotent: already deleted
	}

	// DELETE is a new version in FHIR — bump to avoid UNIQUE(fhir_id, resource_type, version_id) conflict.
	deleteVersion := versionID + 1
	now := time.Now().UTC()
	if err := saveHistory(ctx, tx, resourceType, resourceID, deleteVersion, "DELETE", raw, now); err != nil {
		return err
	}

	if err := index.Delete(ctx, tx, resourceType, resourceID); err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE resources SET is_deleted = TRUE, version_id = $1, last_updated = $2
		WHERE fhir_id = $3 AND resource_type = $4`,
		deleteVersion, now, resourceID, resourceType,
	); err != nil {
		return err
	}

	return nil
}

// ─── History ──────────────────────────────────────────────────────────────────

type HistoryEntry struct {
	VersionID int
	Operation string
	Resource  map[string]any
}

func (s *Store) GetHistory(ctx context.Context, resourceType, resourceID string) ([]HistoryEntry, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT version_id, operation, resource_json, recorded_at
		FROM resource_history
		WHERE resource_type = $1 AND fhir_id = $2
		ORDER BY version_id DESC`,
		resourceType, resourceID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanHistoryRows(rows)
}

// HistoryParams controls pagination and filtering for type-level history.
type HistoryParams struct {
	ResourceType string
	Since        time.Time // zero ⇒ no lower bound
	Page         int       // 1-based; 0 treated as 1
	PageSize     int       // 0 treated as 20
}

// HistoryResult is the paged result of a type-level history query.
type HistoryResult struct {
	Total   int
	Entries []HistoryEntry
}

func (s *Store) GetTypeHistory(ctx context.Context, p HistoryParams) (HistoryResult, error) {
	if p.PageSize <= 0 {
		p.PageSize = 20
	}
	if p.Page <= 0 {
		p.Page = 1
	}
	offset := (p.Page - 1) * p.PageSize

	var (
		total  int
		countQ string
		fetchQ string
		args   []any
	)

	if p.Since.IsZero() {
		countQ = `SELECT COUNT(*) FROM resource_history WHERE resource_type = $1`
		fetchQ = `SELECT version_id, operation, resource_json, recorded_at
		           FROM resource_history WHERE resource_type = $1
		           ORDER BY recorded_at DESC LIMIT $2 OFFSET $3`
		args = []any{p.ResourceType}
	} else {
		countQ = `SELECT COUNT(*) FROM resource_history WHERE resource_type = $1 AND recorded_at > $2`
		fetchQ = `SELECT version_id, operation, resource_json, recorded_at
		           FROM resource_history WHERE resource_type = $1 AND recorded_at > $2
		           ORDER BY recorded_at DESC LIMIT $3 OFFSET $4`
		args = []any{p.ResourceType, p.Since}
	}

	if err := s.pool.QueryRow(ctx, countQ, args...).Scan(&total); err != nil {
		return HistoryResult{}, err
	}

	fetchArgs := append(args, p.PageSize, offset)
	rows, err := s.pool.Query(ctx, fetchQ, fetchArgs...)
	if err != nil {
		return HistoryResult{}, err
	}
	defer rows.Close()

	entries, err := scanHistoryRows(rows)
	if err != nil {
		return HistoryResult{}, err
	}
	return HistoryResult{Total: total, Entries: entries}, nil
}

func (s *Store) GetVersion(ctx context.Context, resourceType, resourceID string, versionID int) (map[string]any, error) {
	var raw []byte
	var recordedAt time.Time
	err := s.pool.QueryRow(ctx, `
		SELECT resource_json, recorded_at FROM resource_history
		WHERE resource_type = $1 AND fhir_id = $2 AND version_id = $3`,
		resourceType, resourceID, versionID,
	).Scan(&raw, &recordedAt)
	if err != nil {
		if isNoRows(err) {
			return nil, NotFoundError{resourceType, fmt.Sprintf("%s/_history/%d", resourceID, versionID)}
		}
		return nil, err
	}
	return unmarshalWithMeta(raw, versionID, recordedAt)
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

func saveHistory(ctx context.Context, tx pgx.Tx, resourceType, resourceID string, versionID int, op string, raw []byte, ts time.Time) error {
	_, err := tx.Exec(ctx, `
		INSERT INTO resource_history (fhir_id, resource_type, version_id, operation, resource_json, recorded_at)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		resourceID, resourceType, versionID, op, raw, ts,
	)
	return err
}

// metaVersionID returns the meta.versionId string of a resource, or "" if absent.
func metaVersionID(body map[string]any) string {
	if meta, ok := body["meta"].(map[string]any); ok {
		if v, ok := meta["versionId"].(string); ok {
			return v
		}
	}
	return ""
}

// readInTx reads a live (non-deleted) resource within an existing transaction,
// so a GET inside a transaction Bundle observes writes made earlier in the same
// Bundle. Mirrors the public Read but uses the supplied tx instead of the pool.
func (s *Store) readInTx(ctx context.Context, tx pgx.Tx, resourceType, resourceID string) (map[string]any, error) {
	var raw []byte
	var versionID int
	var lastUpdated time.Time
	var isDeleted bool
	if err := tx.QueryRow(ctx, `
		SELECT resource_json, version_id, last_updated, is_deleted
		FROM resources WHERE fhir_id = $1 AND resource_type = $2`,
		resourceID, resourceType,
	).Scan(&raw, &versionID, &lastUpdated, &isDeleted); err != nil {
		if isNoRows(err) {
			return nil, NotFoundError{resourceType, resourceID}
		}
		return nil, err
	}
	if isDeleted {
		return nil, GoneError{resourceType, resourceID}
	}
	return unmarshalWithMeta(raw, versionID, lastUpdated)
}

func bumpVersion(ctx context.Context, tx pgx.Tx, resourceType, resourceID string) (newVersion, currentVersion int, lastUpdated time.Time, err error) {
	if err = tx.QueryRow(ctx, `
		SELECT version_id FROM resources WHERE fhir_id = $1 AND resource_type = $2 FOR UPDATE`,
		resourceID, resourceType,
	).Scan(&currentVersion); err != nil {
		if isNoRows(err) {
			err = NotFoundError{resourceType, resourceID}
		}
		return
	}
	newVersion = currentVersion + 1
	lastUpdated = time.Now().UTC()
	return
}

func setMeta(body map[string]any, versionID int, lastUpdated time.Time) map[string]any {
	meta, _ := body["meta"].(map[string]any)
	if meta == nil {
		meta = make(map[string]any)
	}
	meta["versionId"] = fmt.Sprintf("%d", versionID)
	meta["lastUpdated"] = lastUpdated.Format(time.RFC3339)
	body["meta"] = meta
	return body
}

func unmarshalWithMeta(raw []byte, versionID int, lastUpdated time.Time) (map[string]any, error) {
	var m map[string]any
	if err := json.Unmarshal(raw, &m); err != nil {
		return nil, err
	}
	return setMeta(m, versionID, lastUpdated), nil
}

func scanHistoryRows(rows pgx.Rows) ([]HistoryEntry, error) {
	var entries []HistoryEntry
	for rows.Next() {
		var versionID int
		var op string
		var raw []byte
		var recordedAt time.Time
		if err := rows.Scan(&versionID, &op, &raw, &recordedAt); err != nil {
			return nil, err
		}
		res, err := unmarshalWithMeta(raw, versionID, recordedAt)
		if err != nil {
			return nil, err
		}
		entries = append(entries, HistoryEntry{VersionID: versionID, Operation: op, Resource: res})
	}
	return entries, rows.Err()
}

func isNoRows(err error) bool {
	return err == pgx.ErrNoRows || strings.Contains(err.Error(), "no rows")
}

// ─── SearchParameter sync ─────────────────────────────────────────────────────

// SyncSearchParameter persists a custom SearchParameter into search_param_definitions
// and updates the in-memory registry. Called after Create/Update of SearchParameter.
func (s *Store) SyncSearchParameter(ctx context.Context, body map[string]any) error {
	code, _ := body["code"].(string)
	paramType, _ := body["type"].(string)
	expression, _ := body["expression"].(string)
	baseArr, _ := body["base"].([]any)
	if code == "" || len(baseArr) == 0 {
		return nil
	}

	// Build the new set of bases to keep.
	newBases := make(map[string]struct{}, len(baseArr))
	for _, b := range baseArr {
		if rt, ok := b.(string); ok && rt != "" {
			newBases[rt] = struct{}{}
		}
	}
	if len(newBases) == 0 {
		return nil
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Read previously persisted resource_types for this code so we can drop
	// any that have been removed from base in this update. Without this,
	// narrowing a SearchParameter (e.g. [Patient, Observation] → [Patient])
	// would leave the Observation definition behind.
	rows, err := tx.Query(ctx,
		`SELECT resource_type FROM search_param_definitions
		 WHERE param_name = $1 AND is_custom = TRUE FOR UPDATE`,
		code,
	)
	if err != nil {
		return fmt.Errorf("read existing search param bases for %s: %w", code, err)
	}
	var oldBases []string
	for rows.Next() {
		var rt string
		if err := rows.Scan(&rt); err != nil {
			rows.Close()
			return err
		}
		oldBases = append(oldBases, rt)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return err
	}

	var defs []searchparam.Definition
	for rt := range newBases {
		if _, err := tx.Exec(ctx, `
			INSERT INTO search_param_definitions (resource_type, param_name, param_type, fhirpath_expr, is_custom)
			VALUES ($1, $2, $3, $4, TRUE)
			ON CONFLICT (resource_type, param_name)
			DO UPDATE SET param_type = EXCLUDED.param_type,
			              fhirpath_expr = EXCLUDED.fhirpath_expr
			WHERE search_param_definitions.is_custom = TRUE`,
			rt, code, paramType, expression,
		); err != nil {
			return fmt.Errorf("upsert search param %s.%s: %w", rt, code, err)
		}
		defs = append(defs, searchparam.Definition{
			ResourceType: rt,
			ParamName:    code,
			ParamType:    paramType,
			FHIRPath:     expression,
			IsCustom:     true,
		})
	}

	// Remove definitions for resource_types that were previously persisted but
	// are no longer in base.
	var dropped []string
	for _, rt := range oldBases {
		if _, keep := newBases[rt]; !keep {
			dropped = append(dropped, rt)
		}
	}
	if len(dropped) > 0 {
		if _, err := tx.Exec(ctx,
			`DELETE FROM search_param_definitions
			 WHERE param_name = $1 AND is_custom = TRUE AND resource_type = ANY($2)`,
			code, dropped,
		); err != nil {
			return fmt.Errorf("delete stale search param defs for %s: %w", code, err)
		}
	}

	// Commit DB changes before updating the in-memory registry so that a
	// failure or rollback never leaves the registry ahead of the database.
	if err := tx.Commit(ctx); err != nil {
		return err
	}
	for _, def := range defs {
		s.registry.Upsert(def)
	}
	for _, rt := range dropped {
		s.registry.Remove(rt, code)
	}
	return nil
}

// DeleteSearchParameter removes a custom SearchParameter by resource ID.
func (s *Store) DeleteSearchParameter(ctx context.Context, resourceID string) error {
	var raw []byte
	err := s.pool.QueryRow(ctx,
		`SELECT resource_json FROM resources WHERE fhir_id = $1 AND resource_type = 'SearchParameter'`,
		resourceID,
	).Scan(&raw)
	if err != nil {
		if isNoRows(err) {
			return nil // nothing to clean up
		}
		return err
	}

	var body map[string]any
	if err := json.Unmarshal(raw, &body); err != nil {
		return err
	}
	code, _ := body["code"].(string)
	if code == "" {
		return nil
	}

	// Collect base resource types from the payload so we only delete custom
	// definitions whose base matches — a SearchParameter on Patient must not
	// remove a same-code custom definition on Observation.
	var bases []string
	if baseArr, ok := body["base"].([]any); ok {
		for _, b := range baseArr {
			if rt, ok := b.(string); ok && rt != "" {
				bases = append(bases, rt)
			}
		}
	}
	if len(bases) == 0 {
		return nil
	}

	if _, err := s.pool.Exec(ctx,
		`DELETE FROM search_param_definitions WHERE param_name = $1 AND is_custom = TRUE AND resource_type = ANY($2)`,
		code, bases,
	); err != nil {
		return err
	}

	// Update the in-memory registry only after the DB delete commits so the
	// two stores never diverge in the direction of "registry missing, DB has it."
	for _, rt := range bases {
		s.registry.Remove(rt, code)
	}
	slog.Info("removed custom search parameter", "code", code)
	return nil
}

// NotFoundError is returned when a resource does not exist.
type NotFoundError struct {
	ResourceType string
	ResourceID   string
}

func (e NotFoundError) Error() string {
	return fmt.Sprintf("%s/%s not found", e.ResourceType, e.ResourceID)
}

// GoneError is returned when a resource existed but has been deleted.
type GoneError struct {
	ResourceType string
	ResourceID   string
}

func (e GoneError) Error() string {
	return fmt.Sprintf("%s/%s has been deleted", e.ResourceType, e.ResourceID)
}

// ConflictError is returned when an If-Match version check fails.
type ConflictError struct {
	Message string
}

func (e ConflictError) Error() string {
	return e.Message
}
