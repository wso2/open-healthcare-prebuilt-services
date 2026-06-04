package config

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// Config is the resolved server configuration consumed by the rest of the
// application. Values are merged from (in order of precedence, highest first):
//
//  1. Environment variables
//  2. The YAML configuration file (if one is specified)
//  3. Built-in defaults
type Config struct {
	DatabaseURL     string
	Port            int
	BaseURL         string
	LogLevel        string
	IGPackages      []string // e.g. ["hl7.fhir.us.core@6.1.0", "hl7.fhir.us.carin-bb@2.0.0"]
	IGRegistryURL   string   // default: https://packages.fhir.org
	IGForceReload   bool     // re-load IGs even if already recorded in ig_packages
	IGCacheDir      string   // local .tgz cache dir (default: .fhir-ig-cache)
	ValidateOnWrite bool     // enforce profile validation on create/update (default off)
	TerminologyURL  string   // base URL of the FHIR terminology server for :in/:not-in (empty = disabled)

	// HTTP server timeouts. WriteTimeout bounds the WHOLE handler execution in
	// net/http, so it must accommodate the slowest legitimate request (e.g. a
	// large transaction bundle); 0 disables a timeout entirely.
	ReadTimeout  time.Duration // default 30s
	WriteTimeout time.Duration // default 60s
	IdleTimeout  time.Duration // default 120s
}

// FileConfig is the on-disk YAML schema. Each field is optional — anything
// not specified falls through to the env var, then to the built-in default.
type FileConfig struct {
	Server struct {
		Port    int    `yaml:"port"`
		BaseURL string `yaml:"baseUrl"`
		// Go duration strings ("30s", "5m"); "0" disables that timeout.
		ReadTimeout  string `yaml:"readTimeout"`
		WriteTimeout string `yaml:"writeTimeout"`
		IdleTimeout  string `yaml:"idleTimeout"`
	} `yaml:"server"`

	Logging struct {
		Level string `yaml:"level"`
	} `yaml:"logging"`

	Database struct {
		URL      string `yaml:"url"`
		Host     string `yaml:"host"`
		Port     string `yaml:"port"`
		User     string `yaml:"user"`
		Password string `yaml:"password"`
		Name     string `yaml:"name"`
	} `yaml:"database"`

	IG struct {
		Packages    []string `yaml:"packages"`
		RegistryURL string   `yaml:"registryUrl"`
		ForceReload *bool    `yaml:"forceReload"` // pointer so absence is distinguishable from `false`
		CacheDir    string   `yaml:"cacheDir"`
	} `yaml:"ig"`
}

// Load reads configuration using the env-var-based discovery path. The
// optional config file location is taken from FHIR_SERVER_CONFIG.
//
// Callers that parse CLI flags should use LoadFromPath instead.
func Load() (*Config, error) {
	return LoadFromPath(os.Getenv("FHIR_SERVER_CONFIG"))
}

// LoadFromPath reads configuration, optionally seeded from a YAML file at the
// given path. An empty path means "no config file" — only env vars + defaults
// are applied. A non-empty path that cannot be read or parsed returns an
// error; unknown YAML keys are also rejected so typos surface loudly.
func LoadFromPath(path string) (*Config, error) {
	var fc FileConfig
	if path != "" {
		data, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("read config file %q: %w", path, err)
		}
		dec := yaml.NewDecoder(bytes.NewReader(data))
		dec.KnownFields(true)
		if err := dec.Decode(&fc); err != nil && !errors.Is(err, io.EOF) {
			// io.EOF means the file was empty / whitespace-only — that's fine,
			// we just fall through to env vars + defaults.
			return nil, fmt.Errorf("parse config file %q: %w", path, err)
		}
	}
	return resolve(&fc)
}

// resolve materializes a Config from a (possibly empty) FileConfig, layering
// env vars on top and falling back to defaults.
func resolve(fc *FileConfig) (*Config, error) {
	dbURL, err := resolveDatabaseURL(fc)
	if err != nil {
		return nil, err
	}

	serverPort, err := resolveServerPort(fc)
	if err != nil {
		return nil, err
	}

	baseURL := pick(os.Getenv("BASE_URL"), fc.Server.BaseURL, fmt.Sprintf("http://localhost:%d/fhir/r4", serverPort))
	logLevel := pick(os.Getenv("LOG_LEVEL"), fc.Logging.Level, "info")

	igPackages := resolveIGPackages(fc)
	igRegistry := pick(os.Getenv("IG_REGISTRY_URL"), fc.IG.RegistryURL, "https://packages.fhir.org")
	igCacheDir := pick(os.Getenv("IG_CACHE_DIR"), fc.IG.CacheDir, ".fhir-ig-cache")

	igForceReload := false
	if fc.IG.ForceReload != nil {
		igForceReload = *fc.IG.ForceReload
	}
	if v := os.Getenv("IG_FORCE_RELOAD"); v != "" {
		igForceReload = strings.EqualFold(v, "true")
	}

	validateOnWrite := strings.EqualFold(os.Getenv("FHIR_VALIDATE_ON_WRITE"), "true")
	terminologyURL := os.Getenv("FHIR_TERMINOLOGY_URL")

	readTimeout, err := resolveTimeout("SERVER_READ_TIMEOUT", "server.readTimeout", fc.Server.ReadTimeout, 30*time.Second)
	if err != nil {
		return nil, err
	}
	writeTimeout, err := resolveTimeout("SERVER_WRITE_TIMEOUT", "server.writeTimeout", fc.Server.WriteTimeout, 60*time.Second)
	if err != nil {
		return nil, err
	}
	idleTimeout, err := resolveTimeout("SERVER_IDLE_TIMEOUT", "server.idleTimeout", fc.Server.IdleTimeout, 120*time.Second)
	if err != nil {
		return nil, err
	}

	return &Config{
		DatabaseURL:     dbURL,
		Port:            serverPort,
		BaseURL:         baseURL,
		LogLevel:        logLevel,
		IGPackages:      igPackages,
		IGRegistryURL:   igRegistry,
		IGForceReload:   igForceReload,
		IGCacheDir:      igCacheDir,
		ValidateOnWrite: validateOnWrite,
		TerminologyURL:  terminologyURL,
		ReadTimeout:     readTimeout,
		WriteTimeout:    writeTimeout,
		IdleTimeout:     idleTimeout,
	}, nil
}

// resolveTimeout resolves one HTTP server timeout: env var > config file >
// default. Values are Go duration strings ("30s", "5m"); "0" disables the
// timeout (net/http treats zero as no timeout). Negative values are rejected.
// Validation errors name the source that actually supplied the bad value
// (the env var or the config-file key), so startup failures point at the
// right place.
func resolveTimeout(envVar, fileKey, fileVal string, def time.Duration) (time.Duration, error) {
	raw, source := os.Getenv(envVar), envVar
	if raw == "" {
		raw, source = fileVal, fileKey
	}
	if raw == "" {
		return def, nil
	}
	d, err := time.ParseDuration(raw)
	if err != nil {
		return 0, fmt.Errorf("invalid %s %q: %w", source, raw, err)
	}
	if d < 0 {
		return 0, fmt.Errorf("invalid %s %q: must not be negative", source, raw)
	}
	return d, nil
}

func resolveDatabaseURL(fc *FileConfig) (string, error) {
	if v := os.Getenv("DATABASE_URL"); v != "" {
		return v, nil
	}
	if fc.Database.URL != "" {
		return fc.Database.URL, nil
	}
	host := pick(os.Getenv("DB_HOST"), fc.Database.Host, "localhost")
	port := pick(os.Getenv("DB_PORT"), fc.Database.Port, "5432")
	user := pick(os.Getenv("DB_USER"), fc.Database.User, "fhir")
	pass := pick(os.Getenv("DB_PASSWORD"), fc.Database.Password, "fhir")
	name := pick(os.Getenv("DB_NAME"), fc.Database.Name, "fhirdb")
	u := &url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(user, pass),
		Host:     net.JoinHostPort(host, port),
		Path:     "/" + name,
		RawQuery: "sslmode=disable",
	}
	return u.String(), nil
}

func resolveServerPort(fc *FileConfig) (int, error) {
	if v := os.Getenv("SERVER_PORT"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil {
			return 0, fmt.Errorf("invalid SERVER_PORT: %w", err)
		}
		return n, nil
	}
	if fc.Server.Port != 0 {
		return fc.Server.Port, nil
	}
	return 9090, nil
}

func resolveIGPackages(fc *FileConfig) []string {
	// IG_PACKAGES is comma-separated: "hl7.fhir.us.core@6.1.0,hl7.fhir.us.carin-bb@2.0.0".
	// A non-empty value fully replaces the file's list. Empty / unset → fall back to file.
	if raw := os.Getenv("IG_PACKAGES"); raw != "" {
		var pkgs []string
		for _, p := range strings.Split(raw, ",") {
			if p = strings.TrimSpace(p); p != "" {
				pkgs = append(pkgs, p)
			}
		}
		return pkgs
	}
	if len(fc.IG.Packages) > 0 {
		// Defensive copy + trim, so the resolved Config isn't aliased to FileConfig.
		out := make([]string, 0, len(fc.IG.Packages))
		for _, p := range fc.IG.Packages {
			if p = strings.TrimSpace(p); p != "" {
				out = append(out, p)
			}
		}
		return out
	}
	return nil
}

// pick returns the first non-empty value. Useful for env > file > default chains.
func pick(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}
