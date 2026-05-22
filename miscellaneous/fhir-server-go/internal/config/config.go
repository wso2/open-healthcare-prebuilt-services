package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	DatabaseURL   string
	Port          int
	BaseURL       string
	LogLevel      string
	IGPackages    []string // e.g. ["hl7.fhir.us.core@6.1.0", "hl7.fhir.us.carin-bb@2.0.0"]
	IGRegistryURL string   // default: https://packages.fhir.org
	IGForceReload bool     // re-load IGs even if already recorded in ig_packages
}

func Load() (*Config, error) {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		host := getenv("DB_HOST", "localhost")
		port := getenv("DB_PORT", "5432")
		user := getenv("DB_USER", "fhir")
		pass := getenv("DB_PASSWORD", "fhir")
		name := getenv("DB_NAME", "fhirdb")
		dbURL = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable", user, pass, host, port, name)
	}

	serverPort := 9090
	if p := os.Getenv("SERVER_PORT"); p != "" {
		n, err := strconv.Atoi(p)
		if err != nil {
			return nil, fmt.Errorf("invalid SERVER_PORT: %w", err)
		}
		serverPort = n
	}

	// IG_PACKAGES: comma-separated list, e.g. "hl7.fhir.us.core@6.1.0,hl7.fhir.us.carin-bb@2.0.0"
	var igPackages []string
	if raw := os.Getenv("IG_PACKAGES"); raw != "" {
		for _, p := range strings.Split(raw, ",") {
			if p = strings.TrimSpace(p); p != "" {
				igPackages = append(igPackages, p)
			}
		}
	}

	return &Config{
		DatabaseURL:   dbURL,
		Port:          serverPort,
		BaseURL:       getenv("BASE_URL", fmt.Sprintf("http://localhost:%d/fhir/r4", serverPort)),
		LogLevel:      getenv("LOG_LEVEL", "info"),
		IGPackages:    igPackages,
		IGRegistryURL: getenv("IG_REGISTRY_URL", "https://packages.fhir.org"),
		IGForceReload: os.Getenv("IG_FORCE_RELOAD") == "true",
	}, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
