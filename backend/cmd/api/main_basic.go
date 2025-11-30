package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/chalak/backend/internal/config"
	"github.com/chalak/backend/internal/delivery/http/handler"
	"github.com/chalak/backend/internal/delivery/http/router"
	"github.com/chalak/backend/internal/repository/postgres"
	"github.com/chalak/backend/internal/usecase"
	"github.com/chalak/backend/pkg/auth"
	"github.com/chalak/backend/pkg/cache"
	"github.com/chalak/backend/pkg/database"
	"github.com/chalak/backend/pkg/logger"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	log := logger.New(cfg.Logging.Level)
	log.Info(context.Background(), "starting chalak api server", map[string]interface{}{
		"env":  cfg.Server.Env,
		"port": cfg.Server.Port,
	})

	db, err := database.NewPostgres(
		cfg.GetDSN(),
		cfg.Database.MaxOpenConns,
		cfg.Database.MaxIdleConns,
	)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()
	log.Info(context.Background(), "database connection established", nil)

	redisCache, err := cache.NewRedis(
		cfg.GetRedisAddr(),
		cfg.Redis.Password,
		cfg.Redis.DB,
	)
	if err != nil {
		log.Warn(context.Background(), "redis connection failed, continuing without cache", map[string]interface{}{
			"error": err.Error(),
		})
	} else {
		defer redisCache.Close()
		log.Info(context.Background(), "redis connection established", nil)
	}

	tokenService := auth.NewJWTService(
		cfg.JWT.Secret,
		cfg.GetJWTExpiry(),
		cfg.GetRefreshExpiry(),
	)

	studentRepo := postgres.NewStudentRepository(db.DB)
	studentUseCase := usecase.NewStudentUseCase(studentRepo, log)
	studentHandler := handler.NewStudentHandler(studentUseCase, log)

	rt := router.New(studentHandler, tokenService, log)
	httpHandler := rt.Setup()

	server := &http.Server{
		Addr:         fmt.Sprintf("%s:%s", cfg.Server.Host, cfg.Server.Port),
		Handler:      httpHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	serverErrors := make(chan error, 1)
	go func() {
		log.Info(context.Background(), "server listening", map[string]interface{}{
			"addr": server.Addr,
		})
		serverErrors <- server.ListenAndServe()
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		return fmt.Errorf("server error: %w", err)
	case sig := <-shutdown:
		log.Info(context.Background(), "shutdown signal received", map[string]interface{}{
			"signal": sig.String(),
		})

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			server.Close()
			return fmt.Errorf("graceful shutdown failed: %w", err)
		}
	}

	log.Info(context.Background(), "server stopped", nil)
	return nil
}