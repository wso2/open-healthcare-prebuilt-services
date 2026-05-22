package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	DatabaseURL string
	Port        int
	BaseURL     string
	LogLevel    string
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

	return &Config{
		DatabaseURL: dbURL,
		Port:        serverPort,
		BaseURL:     getenv("BASE_URL", fmt.Sprintf("http://localhost:%d/fhir/r4", serverPort)),
		LogLevel:    getenv("LOG_LEVEL", "info"),
	}, nil
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}
