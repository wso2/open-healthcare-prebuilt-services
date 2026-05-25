package config_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/config"
)

// writeConfig writes a YAML config to a temp file and returns its path.
func writeConfig(t *testing.T, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), "config.yaml")
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatalf("write temp config: %v", err)
	}
	return path
}

func TestLoadFromPath_EmptyPath_UsesDefaults(t *testing.T) {
	clearIGEnv(t)

	cfg, err := config.LoadFromPath("")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != 9090 {
		t.Errorf("Port: got %d, want 9090", cfg.Port)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("LogLevel: got %q, want info", cfg.LogLevel)
	}
	if cfg.IGRegistryURL != "https://packages.fhir.org" {
		t.Errorf("IGRegistryURL: got %q", cfg.IGRegistryURL)
	}
}

func TestLoadFromPath_FullFile(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, `
server:
  port: 8443
  baseUrl: https://fhir.example.com/r4

logging:
  level: debug

database:
  url: postgres://u:p@db.example.com:5432/fhir?sslmode=require

ig:
  packages:
    - hl7.fhir.us.core@6.1.0
    - hl7.fhir.us.carin-bb@2.0.0
  registryUrl: https://registry.example.com
  forceReload: true
  cacheDir: /var/cache/fhir-ig
`)

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if cfg.Port != 8443 {
		t.Errorf("Port: got %d, want 8443", cfg.Port)
	}
	if cfg.BaseURL != "https://fhir.example.com/r4" {
		t.Errorf("BaseURL: got %q", cfg.BaseURL)
	}
	if cfg.LogLevel != "debug" {
		t.Errorf("LogLevel: got %q, want debug", cfg.LogLevel)
	}
	if cfg.DatabaseURL != "postgres://u:p@db.example.com:5432/fhir?sslmode=require" {
		t.Errorf("DatabaseURL: got %q", cfg.DatabaseURL)
	}
	if len(cfg.IGPackages) != 2 || cfg.IGPackages[0] != "hl7.fhir.us.core@6.1.0" {
		t.Errorf("IGPackages: got %v", cfg.IGPackages)
	}
	if cfg.IGRegistryURL != "https://registry.example.com" {
		t.Errorf("IGRegistryURL: got %q", cfg.IGRegistryURL)
	}
	if !cfg.IGForceReload {
		t.Error("IGForceReload: want true from file")
	}
	if cfg.IGCacheDir != "/var/cache/fhir-ig" {
		t.Errorf("IGCacheDir: got %q", cfg.IGCacheDir)
	}
}

func TestLoadFromPath_PartialFile_FallsBackToDefaults(t *testing.T) {
	clearIGEnv(t)

	// Only set port; everything else should fall through to defaults.
	path := writeConfig(t, "server:\n  port: 7777\n")

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != 7777 {
		t.Errorf("Port: got %d, want 7777", cfg.Port)
	}
	// BaseURL default should embed the port from the file.
	if cfg.BaseURL != "http://localhost:7777/fhir/r4" {
		t.Errorf("BaseURL: got %q", cfg.BaseURL)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("LogLevel: got %q, want default info", cfg.LogLevel)
	}
	if cfg.IGCacheDir != ".fhir-ig-cache" {
		t.Errorf("IGCacheDir: got %q, want default", cfg.IGCacheDir)
	}
}

func TestLoadFromPath_DatabaseFromComponents(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, `
database:
  host: db.internal
  port: "6432"
  user: app
  password: secret
  name: clinical
`)

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := "postgres://app:secret@db.internal:6432/clinical?sslmode=disable"
	if cfg.DatabaseURL != want {
		t.Errorf("DatabaseURL:\n got  %q\n want %q", cfg.DatabaseURL, want)
	}
}

func TestLoadFromPath_EnvOverridesFile(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, `
server:
  port: 8080
logging:
  level: warn
database:
  url: postgres://file/db
ig:
  packages: [hl7.fhir.us.core@6.1.0]
  forceReload: false
`)

	t.Setenv("SERVER_PORT", "9999")
	t.Setenv("LOG_LEVEL", "error")
	t.Setenv("DATABASE_URL", "postgres://env/db")
	t.Setenv("IG_FORCE_RELOAD", "true")

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != 9999 {
		t.Errorf("Port: env should win, got %d", cfg.Port)
	}
	if cfg.LogLevel != "error" {
		t.Errorf("LogLevel: env should win, got %q", cfg.LogLevel)
	}
	if cfg.DatabaseURL != "postgres://env/db" {
		t.Errorf("DatabaseURL: env should win, got %q", cfg.DatabaseURL)
	}
	if !cfg.IGForceReload {
		t.Error("IGForceReload: env true should win over file false")
	}
}

func TestLoadFromPath_EnvIGPackagesReplacesFileList(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, `
ig:
  packages:
    - file-only@1.0.0
`)

	t.Setenv("IG_PACKAGES", "env-pkg@2.0.0,other@3.0.0")

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(cfg.IGPackages) != 2 {
		t.Fatalf("expected 2 packages from env, got %v", cfg.IGPackages)
	}
	if cfg.IGPackages[0] != "env-pkg@2.0.0" || cfg.IGPackages[1] != "other@3.0.0" {
		t.Errorf("env IG_PACKAGES should fully replace file list, got %v", cfg.IGPackages)
	}
}

func TestLoadFromPath_FileMissing(t *testing.T) {
	clearIGEnv(t)

	_, err := config.LoadFromPath("/nonexistent/does-not-exist.yaml")
	if err == nil {
		t.Fatal("expected error for missing file")
	}
	if !strings.Contains(err.Error(), "read config file") {
		t.Errorf("error message should mention reading the file, got: %v", err)
	}
}

func TestLoadFromPath_InvalidYAML(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, "server:\n  port: [not, a, number\n")

	_, err := config.LoadFromPath(path)
	if err == nil {
		t.Fatal("expected error for malformed YAML")
	}
	if !strings.Contains(err.Error(), "parse config file") {
		t.Errorf("error message should mention parsing, got: %v", err)
	}
}

func TestLoadFromPath_UnknownFieldRejected(t *testing.T) {
	clearIGEnv(t)

	// Typo: `baseURL` vs `baseUrl` — strict mode should catch this so users
	// don't silently get the default.
	path := writeConfig(t, "server:\n  baseURL: https://fhir.example.com\n")

	_, err := config.LoadFromPath(path)
	if err == nil {
		t.Fatal("expected strict-mode rejection of unknown YAML field")
	}
}

func TestLoad_RespectsFHIRServerConfigEnv(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, "server:\n  port: 4242\n")
	t.Setenv("FHIR_SERVER_CONFIG", path)

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != 4242 {
		t.Errorf("Load() should honour FHIR_SERVER_CONFIG path, got Port=%d", cfg.Port)
	}
}

func TestLoadFromPath_EmptyFile(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, "")

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("empty file should parse to defaults, got: %v", err)
	}
	if cfg.Port != 9090 {
		t.Errorf("Port: got %d, want default 9090", cfg.Port)
	}
}

func TestLoadFromPath_IGPackagesWhitespaceTrimmed(t *testing.T) {
	clearIGEnv(t)

	path := writeConfig(t, `
ig:
  packages:
    - "  hl7.fhir.us.core@6.1.0  "
    - ""
    - "hl7.fhir.us.carin-bb@2.0.0"
`)

	cfg, err := config.LoadFromPath(path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(cfg.IGPackages) != 2 {
		t.Fatalf("expected 2 non-empty packages, got %v", cfg.IGPackages)
	}
	if cfg.IGPackages[0] != "hl7.fhir.us.core@6.1.0" {
		t.Errorf("pkg[0] should be trimmed, got %q", cfg.IGPackages[0])
	}
}
