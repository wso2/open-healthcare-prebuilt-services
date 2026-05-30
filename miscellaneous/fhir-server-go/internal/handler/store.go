package handler

import (
	"context"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

// StoreAPI is satisfied by *store.Store; extracted here so handlers can be
// tested without a real database.
type StoreAPI interface {
	Read(ctx context.Context, resourceType, resourceID string) (map[string]any, error)
	GetVersion(ctx context.Context, resourceType, resourceID string, versionID int) (map[string]any, error)
	Create(ctx context.Context, resourceType string, body map[string]any) (map[string]any, error)
	Update(ctx context.Context, resourceType, resourceID string, body map[string]any, ifMatchVersion int) (map[string]any, error)
	Patch(ctx context.Context, resourceType, resourceID string, patch map[string]any) (map[string]any, error)
	Delete(ctx context.Context, resourceType, resourceID string) error
	GetHistory(ctx context.Context, resourceType, resourceID string) ([]store.HistoryEntry, error)
	GetTypeHistory(ctx context.Context, p store.HistoryParams) (store.HistoryResult, error)
	Search(ctx context.Context, sp store.SearchParams) (store.SearchResult, error)
	FetchReferences(ctx context.Context, resourceType, resourceID string, reverse bool) ([]map[string]any, error)
	SyncSearchParameter(ctx context.Context, body map[string]any) error
	DeleteSearchParameter(ctx context.Context, resourceID string) error
	ExecuteBundle(ctx context.Context, bundleType, baseURL string, entries []store.BundleEntryRequest) ([]store.BundleEntryResult, error)
}
