// Package ig loads FHIR Implementation Guide packages (.tgz) and registers
// their SearchParameter and StructureDefinition resources into the server.
//
// # Package specification formats
//
//   - "hl7.fhir.us.core@6.1.0"     → download from packages.fhir.org
//   - "/path/to/package.tgz"        → local filesystem
//   - "https://example.com/pkg.tgz" → arbitrary HTTPS URL
//
// # Loading behaviour
//
// Each package is recorded in ig_packages once loaded. On subsequent startups
// the package is skipped unless ForceReload is set. SearchParameters found in
// the package are upserted into search_param_definitions with
// is_custom=FALSE and ig_source set to "name@version". StructureDefinition
// profiles are recorded in ig_profiles for the capability statement.
//
// The UNIQUE(resource_type, param_name) constraint means an IG param that
// shares a name with a base FHIR R4 param for the same resource type is
// silently skipped (base spec takes precedence).
//
// # Caching
//
// When LoadOptions.CacheDir is set, downloaded .tgz files are written to
// CacheDir/name-version.tgz. On subsequent calls the cached file is used
// instead of re-downloading, which makes container restarts fast even
// before the ig_packages DB check fires.
package ig

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
)

const defaultRegistryURL = "https://packages.fhir.org"

// PackageResult summarises what was loaded from a single package.
type PackageResult struct {
	Name          string
	Version       string
	FHIRVersion   string
	SearchParams  int // new rows inserted
	Profiles      int // profiles registered
	AlreadyLoaded bool
}

// LoadOptions controls loading behaviour.
type LoadOptions struct {
	RegistryURL string        // default: https://packages.fhir.org
	ForceReload bool          // re-load even if already in ig_packages
	HTTPTimeout time.Duration // default: 60s
	CacheDir    string        // local .tgz cache dir; empty = no cache
}

// LoadPackage downloads (or reads) a FHIR IG package, extracts its
// SearchParameters and StructureDefinitions, and persists them.
func LoadPackage(
	ctx context.Context,
	pool *pgxpool.Pool,
	registry *searchparam.Registry,
	spec string,
	opts LoadOptions,
) (*PackageResult, error) {
	if opts.RegistryURL == "" {
		opts.RegistryURL = defaultRegistryURL
	}
	if opts.HTTPTimeout == 0 {
		opts.HTTPTimeout = 60 * time.Second
	}

	name, version := parseSpec(spec)
	source := name + "@" + version

	// Check if already loaded (unless forced)
	if !opts.ForceReload {
		var exists bool
		err := pool.QueryRow(ctx,
			`SELECT EXISTS(SELECT 1 FROM ig_packages WHERE package_name=$1 AND package_version=$2)`,
			name, version,
		).Scan(&exists)
		if err != nil {
			slog.Warn("IG package existence check failed, proceeding to load", "package", source, "err", err)
		} else if exists {
			slog.Info("IG package already loaded, skipping", "package", source)
			return &PackageResult{Name: name, Version: version, AlreadyLoaded: true}, nil
		}
	}

	slog.Info("loading IG package", "package", source)

	// Fetch package bytes (cache-aware)
	tgzData, err := fetchPackage(spec, name, version, opts)
	if err != nil {
		return nil, fmt.Errorf("fetch %s: %w", source, err)
	}

	// Parse the tgz
	pkg, err := parsePackage(tgzData)
	if err != nil {
		return nil, fmt.Errorf("parse %s: %w", source, err)
	}
	if pkg.Meta.FHIRVersion == "" {
		pkg.Meta.FHIRVersion = "4.0.1"
	}

	result := &PackageResult{
		Name:        name,
		Version:     version,
		FHIRVersion: pkg.Meta.FHIRVersion,
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Record the package itself
	if _, err := tx.Exec(ctx, `
		INSERT INTO ig_packages (package_name, package_version, fhir_version)
		VALUES ($1, $2, $3)
		ON CONFLICT (package_name, package_version) DO UPDATE
		SET fhir_version = EXCLUDED.fhir_version, loaded_at = NOW()`,
		name, version, pkg.Meta.FHIRVersion,
	); err != nil {
		return nil, fmt.Errorf("record ig_packages: %w", err)
	}

	// Persist SearchParameters
	for _, sp := range pkg.SearchParams {
		for _, baseRes := range sp.Base {
			if baseRes == "" {
				continue
			}
			tag, err := tx.Exec(ctx, `
				INSERT INTO search_param_definitions
					(resource_type, param_name, param_type, fhirpath_expr, is_custom, ig_source)
				VALUES ($1, $2, $3, $4, FALSE, $5)
				ON CONFLICT (resource_type, param_name) DO NOTHING`,
				baseRes, sp.Code, sp.Type, sp.Expression, source,
			)
			if err != nil {
				return nil, fmt.Errorf("insert search_param_definitions (%s/%s): %w", baseRes, sp.Code, err)
			}
			if tag.RowsAffected() > 0 {
				result.SearchParams++
				if registry != nil {
					registry.Upsert(searchparam.Definition{
						ResourceType: baseRes,
						ParamName:    sp.Code,
						ParamType:    sp.Type,
						FHIRPath:     sp.Expression,
						IsCustom:     false,
						IGSource:     source,
					})
				}
			}
		}
	}

	// Persist StructureDefinition profiles
	for _, profile := range pkg.Profiles {
		if profile.URL == "" || profile.Kind != "resource" || profile.Derivation != "constraint" {
			continue
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO ig_profiles (package_name, profile_url, resource_type)
			VALUES ($1, $2, $3)
			ON CONFLICT (profile_url) DO NOTHING`,
			name, profile.URL, profile.BaseType,
		); err != nil {
			return nil, fmt.Errorf("insert ig_profiles (%s): %w", profile.URL, err)
		}
		result.Profiles++
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	slog.Info("IG package loaded",
		"package", source,
		"searchParams", result.SearchParams,
		"profiles", result.Profiles,
	)
	return result, nil
}

// LoadedPackages returns a summary of all packages currently in the DB.
func LoadedPackages(ctx context.Context, pool *pgxpool.Pool) ([]PackageResult, error) {
	rows, err := pool.Query(ctx, `
		SELECT package_name, package_version, fhir_version FROM ig_packages ORDER BY loaded_at
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var results []PackageResult
	for rows.Next() {
		var r PackageResult
		if err := rows.Scan(&r.Name, &r.Version, &r.FHIRVersion); err != nil {
			return nil, err
		}
		results = append(results, r)
	}
	return results, rows.Err()
}

// SupportedProfiles returns all profile URLs registered across all loaded IGs,
// grouped by resource type.
func SupportedProfiles(ctx context.Context, pool *pgxpool.Pool) (map[string][]string, error) {
	rows, err := pool.Query(ctx, `SELECT resource_type, profile_url FROM ig_profiles ORDER BY resource_type`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	m := make(map[string][]string)
	for rows.Next() {
		var rt, url string
		if err := rows.Scan(&rt, &url); err != nil {
			return nil, err
		}
		m[rt] = append(m[rt], url)
	}
	return m, rows.Err()
}

// ─── Spec parsing ─────────────────────────────────────────────────────────────

func parseSpec(spec string) (name, version string) {
	if idx := strings.LastIndex(spec, "@"); idx > 0 {
		return spec[:idx], spec[idx+1:]
	}
	return spec, "latest"
}

// ─── Package fetching ─────────────────────────────────────────────────────────

func fetchPackage(spec, name, version string, opts LoadOptions) ([]byte, error) {
	// Explicit HTTP/HTTPS URL — must be checked before the .tgz suffix check
	// because a URL like "https://host/pkg.tgz" ends with .tgz.
	if strings.HasPrefix(spec, "http://") || strings.HasPrefix(spec, "https://") {
		return fetchURL(spec, name, version, opts)
	}

	// Local file — no caching needed (already on disk)
	if strings.HasPrefix(spec, "/") || strings.HasPrefix(spec, "./") || strings.HasSuffix(spec, ".tgz") {
		return os.ReadFile(spec)
	}

	// Registry lookup: name@version → https://packages.fhir.org/{name}/{version}
	registryURL := fmt.Sprintf("%s/%s/%s", strings.TrimRight(opts.RegistryURL, "/"), name, version)
	return fetchURL(registryURL, name, version, opts)
}

// fetchURL downloads from a URL, using the disk cache if configured.
func fetchURL(url, name, version string, opts LoadOptions) ([]byte, error) {
	// Determine cache path
	cachePath := ""
	if opts.CacheDir != "" && name != "" && version != "" {
		if err := os.MkdirAll(opts.CacheDir, 0o755); err == nil {
			safe := strings.ReplaceAll(name, "/", "_")
			cachePath = filepath.Join(opts.CacheDir, safe+"-"+version+".tgz")
		}
	}

	// Serve from cache if available
	if cachePath != "" {
		if data, err := os.ReadFile(cachePath); err == nil {
			slog.Debug("serving IG from cache", "path", cachePath)
			return data, nil
		}
	}

	data, err := httpGet(url, opts.HTTPTimeout)
	if err != nil {
		return nil, err
	}

	// Write to cache (best-effort)
	if cachePath != "" {
		if werr := os.WriteFile(cachePath, data, 0o644); werr != nil {
			slog.Warn("failed to write IG cache", "path", cachePath, "err", werr)
		} else {
			slog.Debug("cached IG package", "path", cachePath)
		}
	}

	return data, nil
}

func httpGet(url string, timeout time.Duration) ([]byte, error) {
	client := &http.Client{Timeout: timeout}
	resp, err := client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d from %s", resp.StatusCode, url)
	}
	return io.ReadAll(resp.Body)
}

// ─── Package parsing ──────────────────────────────────────────────────────────

type fhirPackage struct {
	Meta         packageMeta
	SearchParams []fhirSearchParam
	Profiles     []fhirProfile
}

type packageMeta struct {
	Name        string `json:"name"`
	Version     string `json:"version"`
	FHIRVersion string `json:"fhirVersions"` // may be array in real packages
}

type fhirSearchParam struct {
	Code       string   `json:"code"`
	Type       string   `json:"type"`
	Base       []string `json:"base"`
	Expression string   `json:"expression"`
}

type fhirProfile struct {
	URL        string `json:"url"`
	Kind       string `json:"kind"`       // "resource", "complex-type", etc.
	Derivation string `json:"derivation"` // "constraint" = a profile
	BaseType   string `json:"type"`       // e.g. "Patient"
}

func parsePackage(data []byte) (*fhirPackage, error) {
	gr, err := gzip.NewReader(bytes.NewReader(data))
	if err != nil {
		return nil, fmt.Errorf("gzip: %w", err)
	}
	defer gr.Close()

	tr := tar.NewReader(gr)
	pkg := &fhirPackage{}

	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("tar: %w", err)
		}

		name := hdr.Name
		// Only care about files in the package/ directory
		if !strings.HasPrefix(name, "package/") {
			continue
		}
		base := strings.TrimPrefix(name, "package/")

		raw, err := io.ReadAll(tr)
		if err != nil {
			continue
		}

		switch {
		case base == "package.json":
			var meta packageMeta
			if err := json.Unmarshal(raw, &meta); err == nil {
				pkg.Meta = meta
			}
			// Also try fhirVersions as array
			var rawMap map[string]any
			if json.Unmarshal(raw, &rawMap) == nil {
				if vers, ok := rawMap["fhirVersions"].([]any); ok && len(vers) > 0 {
					pkg.Meta.FHIRVersion, _ = vers[0].(string)
				}
				if ver, ok := rawMap["fhirVersion"].(string); ok && ver != "" {
					pkg.Meta.FHIRVersion = ver
				}
			}

		case strings.HasPrefix(base, "SearchParameter-") && strings.HasSuffix(base, ".json"):
			var sp fhirSearchParam
			// Parse via generic map to handle resourceType check
			var m map[string]any
			if err := json.Unmarshal(raw, &m); err != nil {
				continue
			}
			if rt, _ := m["resourceType"].(string); rt != "SearchParameter" {
				continue
			}
			sp.Code, _ = m["code"].(string)
			sp.Type, _ = m["type"].(string)
			sp.Expression, _ = m["expression"].(string)
			if baseArr, ok := m["base"].([]any); ok {
				for _, b := range baseArr {
					if s, ok := b.(string); ok {
						sp.Base = append(sp.Base, s)
					}
				}
			}
			if sp.Code != "" && len(sp.Base) > 0 {
				pkg.SearchParams = append(pkg.SearchParams, sp)
			}

		case strings.HasPrefix(base, "StructureDefinition-") && strings.HasSuffix(base, ".json"):
			var m map[string]any
			if err := json.Unmarshal(raw, &m); err != nil {
				continue
			}
			if rt, _ := m["resourceType"].(string); rt != "StructureDefinition" {
				continue
			}
			profile := fhirProfile{}
			profile.URL, _ = m["url"].(string)
			profile.Kind, _ = m["kind"].(string)
			profile.Derivation, _ = m["derivation"].(string)
			profile.BaseType, _ = m["type"].(string)
			if profile.URL != "" {
				pkg.Profiles = append(pkg.Profiles, profile)
			}
		}
	}
	return pkg, nil
}
