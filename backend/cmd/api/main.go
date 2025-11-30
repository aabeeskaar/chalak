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
	"github.com/chalak/backend/pkg/queue"
	"github.com/chalak/backend/pkg/validator"
)

type App struct {
	cfg         *config.Config
	logger      logger.Logger
	db          *database.PostgresDB
	cache       *cache.RedisCache
	queueClient *queue.Client
	queueServer *queue.Server
	validator   *validator.Validator
	jwtService  *auth.JWTService
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	app, err := initializeApp()
	if err != nil {
		return fmt.Errorf("failed to initialize app: %w", err)
	}
	defer app.cleanup()

	handlers := app.initializeHandlers()

	rt := router.New(
		handlers,
		app.jwtService,
		app.logger,
	)
	httpHandler := rt.Setup()

	server := &http.Server{
		Addr:         fmt.Sprintf("%s:%s", app.cfg.Server.Host, app.cfg.Server.Port),
		Handler:      httpHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	return app.startServer(server)
}

func initializeApp() (*App, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, fmt.Errorf("failed to load config: %w", err)
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
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	log.Info(context.Background(), "database connection established", nil)

	var redisCache *cache.RedisCache
	var queueClient *queue.Client
	var queueServer *queue.Server

	redisCache, err = cache.NewRedis(
		cfg.GetRedisAddr(),
		cfg.Redis.Password,
		cfg.Redis.DB,
	)
	if err != nil {
		log.Warn(context.Background(), "redis connection failed, continuing without cache", map[string]interface{}{
			"error": err.Error(),
		})
	} else {
		log.Info(context.Background(), "redis connection established", nil)

		queueClient = queue.NewClient(
			cfg.GetRedisAddr(),
			cfg.Redis.Password,
			cfg.Redis.DB,
		)
		log.Info(context.Background(), "queue client initialized", nil)

		queueServer = queue.NewServer(
			cfg.GetRedisAddr(),
			cfg.Redis.Password,
			cfg.Redis.DB,
			10,
		)
		log.Info(context.Background(), "queue server initialized", nil)
	}

	validatorInstance := validator.New()
	jwtService := auth.NewJWTService(
		cfg.JWT.Secret,
		cfg.GetJWTExpiry(),
		cfg.GetRefreshExpiry(),
	)

	return &App{
		cfg:         cfg,
		logger:      log,
		db:          db,
		cache:       redisCache,
		queueClient: queueClient,
		queueServer: queueServer,
		validator:   validatorInstance,
		jwtService:  jwtService,
	}, nil
}

// Handlers type now defined in router package

func (app *App) initializeHandlers() *router.Handlers {
	// Auth module
	userRepo := postgres.NewUserRepository(app.db.DB)
	authUseCase := usecase.NewAuthUseCase(
		userRepo,
		app.jwtService,
		app.logger,
		app.cfg.GetJWTExpiry(),
	)
	authHandler := handler.NewAuthHandler(authUseCase, app.validator, app.logger)

	// Student module
	studentRepo := postgres.NewStudentRepository(app.db.DB)
	studentUseCase := usecase.NewStudentUseCase(studentRepo, app.logger)
	studentHandler := handler.NewStudentHandler(studentUseCase, app.logger)

	// Attendance module
	attendanceRepo := postgres.NewAttendanceRepository(app.db.DB)
	attendanceUseCase := usecase.NewAttendanceUseCase(attendanceRepo, app.logger)
	attendanceHandler := handler.NewAttendanceHandler(attendanceUseCase, app.validator, app.logger)

	// Invoice module
	invoiceRepo := postgres.NewInvoiceRepository(app.db.DB)
	invoiceUseCase := usecase.NewInvoiceUseCase(invoiceRepo, app.logger)
	invoiceHandler := handler.NewInvoiceHandler(invoiceUseCase, app.validator, app.logger)

	// Payment module
	paymentRepo := postgres.NewPaymentRepository(app.db.DB)
	paymentUseCase := usecase.NewPaymentUseCase(paymentRepo, invoiceRepo)
	paymentHandler := handler.NewPaymentHandler(paymentUseCase, app.validator, app.logger)

	// Employee module
	employeeRepo := postgres.NewEmployeeRepository(app.db.DB)
	employeeUseCase := usecase.NewEmployeeUseCase(employeeRepo, app.logger)
	employeeHandler := handler.NewEmployeeHandler(employeeUseCase, app.validator, app.logger)

	// Expense module
	expenseRepo := postgres.NewExpenseRepository(app.db.DB)
	expenseUseCase := usecase.NewExpenseUseCase(expenseRepo, app.logger)
	expenseHandler := handler.NewExpenseHandler(expenseUseCase, app.validator, app.logger)

	// Notification module
	notificationRepo := postgres.NewNotificationRepository(app.db.DB)
	notificationUseCase := usecase.NewNotificationUseCase(notificationRepo, app.logger)
	notificationHandler := handler.NewNotificationHandler(notificationUseCase, app.validator, app.logger)

	// Course module
	courseRepo := postgres.NewCourseRepository(app.db.DB)
	courseUseCase := usecase.NewCourseUseCase(courseRepo, app.logger)
	courseHandler := handler.NewCourseHandler(courseUseCase, app.validator, app.logger)

	// Package module
	packageRepo := postgres.NewPackageRepository(app.db.DB)
	packageUseCase := usecase.NewPackageUseCase(packageRepo, app.logger)
	packageHandler := handler.NewPackageHandler(packageUseCase, app.validator, app.logger)

	// Report module
	reportRepo := postgres.NewReportRepository(app.db.DB)
	reportUseCase := usecase.NewReportUseCase(reportRepo)
	reportHandler := handler.NewReportHandler(reportUseCase)

	return &router.Handlers{
		Auth:         authHandler,
		Student:      studentHandler,
		Attendance:   attendanceHandler,
		Invoice:      invoiceHandler,
		Payment:      paymentHandler,
		Employee:     employeeHandler,
		Expense:      expenseHandler,
		Notification: notificationHandler,
		Course:       courseHandler,
		Package:      packageHandler,
		Report:       reportHandler,
	}
}

func (app *App) startServer(server *http.Server) error {
	serverErrors := make(chan error, 1)
	go func() {
		app.logger.Info(context.Background(), "server listening", map[string]interface{}{
			"addr": server.Addr,
		})
		serverErrors <- server.ListenAndServe()
	}()

	if app.queueServer != nil {
		go func() {
			if err := app.queueServer.Start(); err != nil {
				app.logger.Error(context.Background(), "queue server error", err, map[string]interface{}{})
			}
		}()
	}

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		return fmt.Errorf("server error: %w", err)
	case sig := <-shutdown:
		app.logger.Info(context.Background(), "shutdown signal received", map[string]interface{}{
			"signal": sig.String(),
		})

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			server.Close()
			return fmt.Errorf("graceful shutdown failed: %w", err)
		}
	}

	app.logger.Info(context.Background(), "server stopped", nil)
	return nil
}

func (app *App) cleanup() {
	if app.db != nil {
		app.db.Close()
	}
	if app.cache != nil {
		app.cache.Close()
	}
	if app.queueClient != nil {
		app.queueClient.Close()
	}
	if app.queueServer != nil {
		app.queueServer.Stop()
	}
}