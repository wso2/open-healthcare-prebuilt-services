package config_test

import (
	"testing"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/config"
)

func TestLoad_Defaults(t *testing.T) {
	clearIGEnv(t)

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != 9090 {
		t.Errorf("default Port: got %d, want 9090", cfg.Port)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("default LogLevel: got %q, want %q", cfg.LogLevel, "info")
	}
	if cfg.IGRegistryURL != "https://packages.fhir.org" {
		t.Errorf("default IGRegistryURL: got %q", cfg.IGRegistryURL)
	}
	if cfg.IGCacheDir != ".fhir-ig-cache" {
		t.Errorf("default IGCacheDir: got %q, want %q", cfg.IGCacheDir, ".fhir-ig-cache")
	}
	if cfg.IGForceReload {
		t.Error("default IGForceReload should be false")
	}
	if len(cfg.IGPackages) != 0 {
		t.Errorf("default IGPackages should be empty, got %v", cfg.IGPackages)
	}
}

func TestLoad_ServerPort(t *testing.T) {
	t.Setenv("SERVER_PORT", "8080")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != 8080 {
		t.Errorf("got Port %d, want 8080", cfg.Port)
	}
}

func TestLoad_InvalidServerPort(t *testing.T) {
	t.Setenv("SERVER_PORT", "not-a-number")

	_, err := config.Load()
	if err == nil {
		t.Fatal("expected error for invalid SERVER_PORT")
	}
}

func TestLoad_DatabaseURL_Direct(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://user:pass@host:5432/db")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.DatabaseURL != "postgres://user:pass@host:5432/db" {
		t.Errorf("got DatabaseURL %q", cfg.DatabaseURL)
	}
}

func TestLoad_DatabaseURL_FromComponents(t *testing.T) {
	// Ensure DATABASE_URL is not set
	t.Setenv("DATABASE_URL", "")
	t.Setenv("DB_HOST", "myhost")
	t.Setenv("DB_PORT", "5433")
	t.Setenv("DB_USER", "myuser")
	t.Setenv("DB_PASSWORD", "mypass")
	t.Setenv("DB_NAME", "mydb")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := "postgres://myuser:mypass@myhost:5433/mydb?sslmode=disable"
	if cfg.DatabaseURL != want {
		t.Errorf("got %q, want %q", cfg.DatabaseURL, want)
	}
}

func TestLoad_IGPackages_CommaSeparated(t *testing.T) {
	t.Setenv("IG_PACKAGES", "hl7.fhir.us.core@6.1.0, hl7.fhir.us.carin-bb@2.0.0, ")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(cfg.IGPackages) != 2 {
		t.Fatalf("want 2 packages, got %d: %v", len(cfg.IGPackages), cfg.IGPackages)
	}
	if cfg.IGPackages[0] != "hl7.fhir.us.core@6.1.0" {
		t.Errorf("pkg[0]: got %q", cfg.IGPackages[0])
	}
	if cfg.IGPackages[1] != "hl7.fhir.us.carin-bb@2.0.0" {
		t.Errorf("pkg[1]: got %q", cfg.IGPackages[1])
	}
}

func TestLoad_IGPackages_Empty(t *testing.T) {
	t.Setenv("IG_PACKAGES", "")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(cfg.IGPackages) != 0 {
		t.Errorf("expected empty IGPackages, got %v", cfg.IGPackages)
	}
}

func TestLoad_IGForceReload(t *testing.T) {
	t.Setenv("IG_FORCE_RELOAD", "true")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !cfg.IGForceReload {
		t.Error("expected IGForceReload=true")
	}
}

func TestLoad_IGCacheDir_Custom(t *testing.T) {
	t.Setenv("IG_CACHE_DIR", "/data/my-ig-cache")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.IGCacheDir != "/data/my-ig-cache" {
		t.Errorf("got IGCacheDir %q", cfg.IGCacheDir)
	}
}

func TestLoad_LogLevel_Variants(t *testing.T) {
	for _, level := range []string{"debug", "info", "warn", "error"} {
		t.Run(level, func(t *testing.T) {
			t.Setenv("LOG_LEVEL", level)
			cfg, err := config.Load()
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if cfg.LogLevel != level {
				t.Errorf("got %q, want %q", cfg.LogLevel, level)
			}
		})
	}
}

func TestLoad_BaseURL_Custom(t *testing.T) {
	t.Setenv("BASE_URL", "https://fhir.example.com/r4")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.BaseURL != "https://fhir.example.com/r4" {
		t.Errorf("got BaseURL %q", cfg.BaseURL)
	}
}

func TestLoad_BaseURL_DefaultIncludesPort(t *testing.T) {
	t.Setenv("BASE_URL", "")
	t.Setenv("SERVER_PORT", "8888")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := "http://localhost:8888/fhir/r4"
	if cfg.BaseURL != want {
		t.Errorf("got %q, want %q", cfg.BaseURL, want)
	}
}

// clearIGEnv removes env vars that might be set from outer test runs.
func clearIGEnv(t *testing.T) {
	t.Helper()
	for _, k := range []string{
		"DATABASE_URL", "DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME",
		"SERVER_PORT", "BASE_URL", "LOG_LEVEL",
		"IG_PACKAGES", "IG_REGISTRY_URL", "IG_FORCE_RELOAD", "IG_CACHE_DIR",
		"FHIR_SERVER_CONFIG",
	} {
		t.Setenv(k, "")
	}
}
