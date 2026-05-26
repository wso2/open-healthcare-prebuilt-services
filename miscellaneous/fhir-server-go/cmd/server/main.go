package main

import (
	"context"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"sync/atomic"
	"syscall"
	"time"

	"golang.org/x/sync/errgroup"

	"github.com/wso2/open-healthcare-fhir-server-go/internal/config"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/db"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/handler"
	"github.com/wso2/open-healthcare-fhir-server-go/internal/ig"
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
	var configPath string
	flag.StringVar(&configPath, "config", "", "Path to YAML config file (overrides FHIR_SERVER_CONFIG env var)")
	flag.StringVar(&configPath, "c", "", "Path to YAML config file (shorthand for -config)")
	flag.Parse()
	if configPath == "" {
		configPath = os.Getenv("FHIR_SERVER_CONFIG")
	}

	cfg, err := config.LoadFromPath(configPath)
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}

	setupLogging(cfg.LogLevel)

	if configPath != "" {
		slog.Info("loaded config file", "path", configPath)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Database
	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("connect db: %w", err)
	}
	defer pool.Close()
	slog.Info("connected to database")

	slog.Info("starting database migration")
	if err := db.Migrate(ctx, pool); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	// Seed standard FHIR R4 search parameters (idempotent — ON CONFLICT DO NOTHING)
	if err := seed.SeedSearchParams(ctx, pool); err != nil {
		slog.Warn("search param seed failed (non-fatal)", "err", err)
	}

	// Search param registry — loads base + already-recorded IG params from DB
	registry := searchparam.NewRegistry()
	if err := registry.Load(ctx, pool); err != nil {
		return fmt.Errorf("load search params: %w", err)
	}

	// Store + HTTP (server starts immediately; IGs load in background)
	s := store.New(pool, registry)

	// igReady is set to 1 once all IGs finish loading.
	var igReady atomic.Int32
	if len(cfg.IGPackages) == 0 {
		igReady.Store(1)
	}

	router := handler.NewRouter(s, pool, registry, cfg.BaseURL, &igReady)

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Start listening before IGs are loaded so liveness probes pass immediately
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		slog.Info("server listening", "addr", srv.Addr, "baseURL", cfg.BaseURL)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server error", "err", err)
			cancel()
		}
	}()

	// Load IGs in the background — parallel downloads, one DB tx per package
	if len(cfg.IGPackages) > 0 {
		go func() {
			igOpts := ig.LoadOptions{
				RegistryURL: cfg.IGRegistryURL,
				ForceReload: cfg.IGForceReload,
				CacheDir:    cfg.IGCacheDir,
			}

			g, gctx := errgroup.WithContext(ctx)
			for _, spec := range cfg.IGPackages {
				spec := spec // capture
				g.Go(func() error {
					result, err := ig.LoadPackage(gctx, pool, registry, spec, igOpts)
					if err != nil {
						slog.Warn("IG package load failed (non-fatal)", "package", spec, "err", err)
						return nil // non-fatal: don't block other packages
					}
					if !result.AlreadyLoaded {
						slog.Info("IG package loaded",
							"package", spec,
							"searchParams", result.SearchParams,
							"profiles", result.Profiles,
						)
					}
					return nil
				})
			}

			if err := g.Wait(); err != nil {
				slog.Warn("IG loading encountered errors", "err", err)
			}

			igReady.Store(1)
			slog.Info("all IG packages ready")
		}()
	}

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
