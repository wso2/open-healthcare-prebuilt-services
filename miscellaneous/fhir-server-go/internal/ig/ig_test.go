package ig

import (
	"archive/tar"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// ─── parseSpec ────────────────────────────────────────────────────────────────

func TestParseSpec_NameAtVersion(t *testing.T) {
	name, version := parseSpec("hl7.fhir.us.core@6.1.0")
	if name != "hl7.fhir.us.core" || version != "6.1.0" {
		t.Fatalf("got (%q, %q)", name, version)
	}
}

func TestParseSpec_NoVersion_DefaultsToLatest(t *testing.T) {
	name, version := parseSpec("hl7.fhir.us.core")
	if name != "hl7.fhir.us.core" || version != "latest" {
		t.Fatalf("got (%q, %q)", name, version)
	}
}

func TestParseSpec_MultipleAtSigns_UsesLast(t *testing.T) {
	// Edge case: "foo@bar@1.0.0" — LastIndex splits at the last @
	name, version := parseSpec("foo@bar@1.0.0")
	if name != "foo@bar" || version != "1.0.0" {
		t.Fatalf("got (%q, %q)", name, version)
	}
}

func TestParseSpec_LocalPath_NoVersion(t *testing.T) {
	name, version := parseSpec("/path/to/package.tgz")
	if name != "/path/to/package.tgz" || version != "latest" {
		t.Fatalf("got (%q, %q)", name, version)
	}
}

func TestParseSpec_EmptyString(t *testing.T) {
	name, version := parseSpec("")
	if name != "" || version != "latest" {
		t.Fatalf("got (%q, %q)", name, version)
	}
}

// ─── parsePackage ─────────────────────────────────────────────────────────────

func TestParsePackage_FullPackage(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{
			"name":        "hl7.fhir.us.core",
			"version":     "6.1.0",
			"fhirVersion": "4.0.1",
		}),
		"package/SearchParameter-us-core-patient-name.json": mustJSON(map[string]any{
			"resourceType": "SearchParameter",
			"code":         "name",
			"type":         "string",
			"base":         []string{"Patient"},
			"expression":   "Patient.name",
		}),
		"package/StructureDefinition-us-core-patient.json": mustJSON(map[string]any{
			"resourceType": "StructureDefinition",
			"url":          "http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient",
			"kind":         "resource",
			"derivation":   "constraint",
			"type":         "Patient",
		}),
	})

	pkg, err := parsePackage(tgz)
	if err != nil {
		t.Fatalf("parsePackage error: %v", err)
	}
	if pkg.Meta.Name != "hl7.fhir.us.core" {
		t.Errorf("unexpected name: %q", pkg.Meta.Name)
	}
	if pkg.Meta.FHIRVersion != "4.0.1" {
		t.Errorf("unexpected fhirVersion: %q", pkg.Meta.FHIRVersion)
	}
	if len(pkg.SearchParams) != 1 {
		t.Errorf("want 1 SearchParam, got %d", len(pkg.SearchParams))
	}
	if len(pkg.Profiles) != 1 {
		t.Errorf("want 1 Profile, got %d", len(pkg.Profiles))
	}
}

func TestParsePackage_SkipsNonPackageDir(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"other/SearchParameter-foo.json": mustJSON(map[string]any{
			"resourceType": "SearchParameter",
			"code":         "foo",
		}),
		"package/package.json": mustJSON(map[string]any{
			"name": "test", "version": "1.0.0",
		}),
	})

	pkg, err := parsePackage(tgz)
	if err != nil {
		t.Fatalf("parsePackage error: %v", err)
	}
	if len(pkg.SearchParams) != 0 {
		t.Errorf("expected no search params from non-package/ dir, got %d", len(pkg.SearchParams))
	}
}

func TestParsePackage_SkipsSearchParamWithNoBase(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
		"package/SearchParameter-empty.json": mustJSON(map[string]any{
			"resourceType": "SearchParameter",
			"code":         "orphan",
			"type":         "string",
			// no "base" field
		}),
	})

	pkg, err := parsePackage(tgz)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(pkg.SearchParams) != 0 {
		t.Errorf("expected 0 params, got %d", len(pkg.SearchParams))
	}
}

// parsePackage stores all StructureDefinitions with URLs regardless of derivation.
// The constraint/specialization filter is applied later in LoadPackage when persisting.
func TestParsePackage_StoresAllProfilesWithURL(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
		"package/StructureDefinition-base-patient.json": mustJSON(map[string]any{
			"resourceType": "StructureDefinition",
			"url":          "http://example.com/base",
			"kind":         "resource",
			"derivation":   "specialization",
			"type":         "Patient",
		}),
	})

	pkg, err := parsePackage(tgz)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// parsePackage includes it; LoadPackage filters by derivation="constraint"
	if len(pkg.Profiles) != 1 {
		t.Errorf("expected 1 profile (filtering happens in LoadPackage), got %d", len(pkg.Profiles))
	}
	if pkg.Profiles[0].Derivation != "specialization" {
		t.Errorf("unexpected derivation: %q", pkg.Profiles[0].Derivation)
	}
}

func TestParsePackage_FHIRVersionsArray(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{
			"name":         "test",
			"version":      "1.0.0",
			"fhirVersions": []string{"4.0.1"},
		}),
	})

	pkg, err := parsePackage(tgz)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if pkg.Meta.FHIRVersion != "4.0.1" {
		t.Errorf("expected fhirVersion=4.0.1 from array, got %q", pkg.Meta.FHIRVersion)
	}
}

func TestParsePackage_MultipleBase(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
		"package/SearchParameter-multi.json": mustJSON(map[string]any{
			"resourceType": "SearchParameter",
			"code":         "status",
			"type":         "token",
			"base":         []string{"Patient", "Practitioner"},
			"expression":   "Patient.active | Practitioner.active",
		}),
	})

	pkg, err := parsePackage(tgz)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(pkg.SearchParams) != 1 {
		t.Fatalf("want 1 SearchParam, got %d", len(pkg.SearchParams))
	}
	if len(pkg.SearchParams[0].Base) != 2 {
		t.Errorf("want 2 base resources, got %d", len(pkg.SearchParams[0].Base))
	}
}

// ─── fetchPackage — disk cache ────────────────────────────────────────────────

func TestFetchPackage_LocalFile(t *testing.T) {
	// Write a test tgz to disk
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
	})
	f, err := os.CreateTemp(t.TempDir(), "test-*.tgz")
	if err != nil {
		t.Fatal(err)
	}
	f.Write(tgz)
	f.Close()

	opts := LoadOptions{RegistryURL: defaultRegistryURL, HTTPTimeout: 5 * time.Second}
	data, err := fetchPackage(f.Name(), "", "", opts)
	if err != nil {
		t.Fatalf("fetchPackage error: %v", err)
	}
	if !bytes.Equal(data, tgz) {
		t.Fatal("returned data doesn't match file contents")
	}
}

func TestFetchPackage_CacheHit(t *testing.T) {
	cacheDir := t.TempDir()
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
	})

	// Pre-populate cache
	cachePath := filepath.Join(cacheDir, "mypackage-1.0.0.tgz")
	os.WriteFile(cachePath, tgz, 0o644)

	opts := LoadOptions{
		RegistryURL: "http://should-not-be-called",
		HTTPTimeout: 5 * time.Second,
		CacheDir:    cacheDir,
	}

	data, err := fetchPackage("mypackage@1.0.0", "mypackage", "1.0.0", opts)
	if err != nil {
		t.Fatalf("fetchPackage error: %v", err)
	}
	if !bytes.Equal(data, tgz) {
		t.Fatal("cache hit should return cached bytes")
	}
}

func TestFetchPackage_CacheMiss_WritesCache(t *testing.T) {
	cacheDir := t.TempDir()
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
	})

	// Serve the tgz from a test HTTP server
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write(tgz)
	}))
	defer srv.Close()

	opts := LoadOptions{
		RegistryURL: srv.URL,
		HTTPTimeout: 5 * time.Second,
		CacheDir:    cacheDir,
	}

	data, err := fetchPackage("mypkg@2.0.0", "mypkg", "2.0.0", opts)
	if err != nil {
		t.Fatalf("fetchPackage error: %v", err)
	}
	if !bytes.Equal(data, tgz) {
		t.Fatal("returned data should match served bytes")
	}

	// Cache file should now exist
	cachePath := filepath.Join(cacheDir, "mypkg-2.0.0.tgz")
	cached, err := os.ReadFile(cachePath)
	if err != nil {
		t.Fatalf("cache file not written: %v", err)
	}
	if !bytes.Equal(cached, tgz) {
		t.Fatal("cached file contents don't match")
	}
}

func TestFetchPackage_ExplicitURL(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "t", "version": "1"}),
	})
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Write(tgz)
	}))
	defer srv.Close()

	// Use a URL path that ends in .tgz — this previously triggered the local-file
	// path by accident; the fix checks for http:// prefix first.
	opts := LoadOptions{HTTPTimeout: 5 * time.Second}
	data, err := fetchPackage(srv.URL+"/download/pkg.tgz", "", "", opts)
	if err != nil {
		t.Fatalf("fetchPackage error: %v", err)
	}
	if !bytes.Equal(data, tgz) {
		t.Fatal("returned data mismatch")
	}
}

func TestFetchPackage_RegistryLookup(t *testing.T) {
	tgz := buildTestTgz(t, map[string][]byte{
		"package/package.json": mustJSON(map[string]any{"name": "testpkg", "version": "1.0.0"}),
	})
	var capturedPath string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedPath = r.URL.Path
		w.Write(tgz)
	}))
	defer srv.Close()

	opts := LoadOptions{RegistryURL: srv.URL, HTTPTimeout: 5 * time.Second}
	data, err := fetchPackage("testpkg@1.0.0", "testpkg", "1.0.0", opts)
	if err != nil {
		t.Fatalf("fetchPackage error: %v", err)
	}
	if !bytes.Equal(data, tgz) {
		t.Fatal("returned data mismatch")
	}
	if capturedPath != "/testpkg/1.0.0" {
		t.Errorf("unexpected registry path: %q", capturedPath)
	}
}

func TestFetchPackage_HTTP404_Error(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer srv.Close()

	opts := LoadOptions{RegistryURL: srv.URL, HTTPTimeout: 5 * time.Second}
	_, err := fetchPackage("no@exist", "no", "exist", opts)
	if err == nil {
		t.Fatal("expected error for HTTP 404")
	}
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

func buildTestTgz(t *testing.T, files map[string][]byte) []byte {
	t.Helper()
	var buf bytes.Buffer
	gw := gzip.NewWriter(&buf)
	tw := tar.NewWriter(gw)
	for name, content := range files {
		hdr := &tar.Header{
			Name:    name,
			Mode:    0o644,
			Size:    int64(len(content)),
			Typeflag: tar.TypeReg,
		}
		if err := tw.WriteHeader(hdr); err != nil {
			t.Fatalf("tar write header: %v", err)
		}
		if _, err := tw.Write(content); err != nil {
			t.Fatalf("tar write: %v", err)
		}
	}
	tw.Close()
	gw.Close()
	return buf.Bytes()
}

func mustJSON(v any) []byte {
	b, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return b
}
