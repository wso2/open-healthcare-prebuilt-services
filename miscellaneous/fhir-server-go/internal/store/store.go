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
}

func New(pool *pgxpool.Pool, registry *searchparam.Registry) *Store {
	return &Store{
		pool:      pool,
		extractor: index.New(registry),
	}
}

// ─── Create ───────────────────────────────────────────────────────────────────

func (s *Store) Create(ctx context.Context, resourceType string, body map[string]any) (map[string]any, error) {
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

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

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

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	slog.Info("created resource", "type", resourceType, "id", resourceID)
	return body, nil
}

// ─── Read ─────────────────────────────────────────────────────────────────────

func (s *Store) Read(ctx context.Context, resourceType, resourceID string) (map[string]any, error) {
	var raw []byte
	var versionID int
	var lastUpdated time.Time

	err := s.pool.QueryRow(ctx, `
		SELECT resource_json, version_id, last_updated
		FROM resources
		WHERE fhir_id = $1 AND resource_type = $2 AND is_deleted = FALSE`,
		resourceID, resourceType,
	).Scan(&raw, &versionID, &lastUpdated)
	if err != nil {
		if isNoRows(err) {
			return nil, NotFoundError{resourceType, resourceID}
		}
		return nil, err
	}

	return unmarshalWithMeta(raw, versionID, lastUpdated)
}

// ─── Update (PUT) ─────────────────────────────────────────────────────────────

func (s *Store) Update(ctx context.Context, resourceType, resourceID string, body map[string]any) (map[string]any, error) {
	body["id"] = resourceID
	body["resourceType"] = resourceType

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	newVersion, lastUpdated, err := bumpVersion(ctx, tx, resourceType, resourceID)
	if err != nil {
		return nil, err
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

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	slog.Info("updated resource", "type", resourceType, "id", resourceID, "version", newVersion)
	return body, nil
}

// ─── Patch (JSON Merge Patch) ─────────────────────────────────────────────────

func (s *Store) Patch(ctx context.Context, resourceType, resourceID string, patch map[string]any) (map[string]any, error) {
	existing, err := s.Read(ctx, resourceType, resourceID)
	if err != nil {
		return nil, err
	}
	merged := mergePatch(existing, patch)
	return s.Update(ctx, resourceType, resourceID, merged)
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

	// Read for history snapshot
	var raw []byte
	var versionID int
	var lastUpdated time.Time
	if err := tx.QueryRow(ctx, `
		SELECT resource_json, version_id, last_updated
		FROM resources WHERE fhir_id = $1 AND resource_type = $2`,
		resourceID, resourceType,
	).Scan(&raw, &versionID, &lastUpdated); err != nil {
		if isNoRows(err) {
			return NotFoundError{resourceType, resourceID}
		}
		return err
	}

	now := time.Now().UTC()
	if err := saveHistory(ctx, tx, resourceType, resourceID, versionID, "DELETE", raw, now); err != nil {
		return err
	}

	if err := index.Delete(ctx, tx, resourceType, resourceID); err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE resources SET is_deleted = TRUE, last_updated = $1
		WHERE fhir_id = $2 AND resource_type = $3`,
		now, resourceID, resourceType,
	); err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return err
	}

	slog.Info("deleted resource", "type", resourceType, "id", resourceID)
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

func bumpVersion(ctx context.Context, tx pgx.Tx, resourceType, resourceID string) (newVersion int, lastUpdated time.Time, err error) {
	var currentVersion int
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

// NotFoundError is returned when a resource does not exist.
type NotFoundError struct {
	ResourceType string
	ResourceID   string
}

func (e NotFoundError) Error() string {
	return fmt.Sprintf("%s/%s not found", e.ResourceType, e.ResourceID)
}
