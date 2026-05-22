package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/config"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/db"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/searchparam"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/seed"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/store"
)

func main() {
	if err := run(); err != nil {
		slog.Error("startup failed", "err", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}

	setupLogging(cfg.LogLevel)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Database
	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("connect db: %w", err)
	}
	defer pool.Close()
	slog.Info("connected to database")

	if err := db.Migrate(ctx, pool); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	// Seed standard FHIR R4 search parameters (idempotent — ON CONFLICT DO NOTHING)
	if err := seed.SeedSearchParams(ctx, pool); err != nil {
		slog.Warn("search param seed failed (non-fatal)", "err", err)
	}

	// Search param registry
	registry := searchparam.NewRegistry()
	if err := registry.Load(ctx, pool); err != nil {
		return fmt.Errorf("load search params: %w", err)
	}

	// Store + HTTP
	s := store.New(pool, registry)
	router := handler.NewRouter(s, cfg.BaseURL)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		slog.Info("server listening", "addr", srv.Addr, "baseURL", cfg.BaseURL)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server error", "err", err)
			cancel()
		}
	}()

	select {
	case <-quit:
		slog.Info("shutdown signal received")
	case <-ctx.Done():
	}

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer shutdownCancel()
	return srv.Shutdown(shutdownCtx)
}

func setupLogging(level string) {
	var l slog.Level
	switch level {
	case "debug":
		l = slog.LevelDebug
	case "warn":
		l = slog.LevelWarn
	case "error":
		l = slog.LevelError
	default:
		l = slog.LevelInfo
	}
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: l})))
}
