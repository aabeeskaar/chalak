package router

import (
	"net/http"

	"github.com/chalak/backend/internal/delivery/http/handler"
	"github.com/chalak/backend/internal/delivery/http/middleware"
	"github.com/chalak/backend/pkg/auth"
	"github.com/chalak/backend/pkg/logger"
	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

type Handlers struct {
	Auth         *handler.AuthHandler
	Student      *handler.StudentHandler
	Attendance   *handler.AttendanceHandler
	Invoice      *handler.InvoiceHandler
	Payment      *handler.PaymentHandler
	Employee     *handler.EmployeeHandler
	Expense      *handler.ExpenseHandler
	Notification *handler.NotificationHandler
	Course       *handler.CourseHandler
	Package      *handler.PackageHandler
	Report       *handler.ReportHandler
}

type Router struct {
	mux          *chi.Mux
	handlers     *Handlers
	tokenService auth.TokenService
	logger       logger.Logger
}

func New(
	handlers *Handlers,
	tokenService auth.TokenService,
	log logger.Logger,
) *Router {
	return &Router{
		mux:          chi.NewRouter(),
		handlers:     handlers,
		tokenService: tokenService,
		logger:       log,
	}
}

func (rt *Router) Setup() http.Handler {
	rt.mux.Use(chimiddleware.RequestID)
	rt.mux.Use(chimiddleware.RealIP)
	rt.mux.Use(chimiddleware.Recoverer)
	rt.mux.Use(middleware.LoggerMiddleware(rt.logger))

	rt.mux.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	rt.mux.Get("/health", rt.healthCheck)

	rt.mux.Route("/api/v1", func(r chi.Router) {
		// Authentication routes (no auth required)
		r.Route("/auth", func(r chi.Router) {
			r.Post("/register", rt.handlers.Auth.Register)
			r.Post("/login", rt.handlers.Auth.Login)
			r.Post("/refresh", rt.handlers.Auth.RefreshToken)

			// Protected auth routes
			r.Group(func(r chi.Router) {
				r.Use(middleware.AuthMiddleware(rt.tokenService))
				r.Get("/me", rt.handlers.Auth.GetMe)
			})
		})

		// Protected routes (all require authentication)
		r.Group(func(r chi.Router) {
			r.Use(middleware.AuthMiddleware(rt.tokenService))

			// Students
			r.Route("/students", func(r chi.Router) {
				r.Post("/", rt.handlers.Student.Create)
				r.Get("/", rt.handlers.Student.List)
				r.Get("/{id}", rt.handlers.Student.GetByID)
				r.Put("/{id}", rt.handlers.Student.Update)
				r.Delete("/{id}", rt.handlers.Student.Delete)
			})

			// Attendance
			r.Route("/attendance", func(r chi.Router) {
				r.Post("/", rt.handlers.Attendance.MarkAttendance)
				r.Get("/", rt.handlers.Attendance.List)
				r.Get("/{id}", rt.handlers.Attendance.GetByID)
				r.Put("/{id}", rt.handlers.Attendance.Update)
				r.Delete("/{id}", rt.handlers.Attendance.Delete)
				r.Get("/students/{student_id}/stats", rt.handlers.Attendance.GetStudentStats)
			})

			// Invoices
			r.Route("/invoices", func(r chi.Router) {
				r.Post("/", rt.handlers.Invoice.Create)
				r.Get("/", rt.handlers.Invoice.List)
				r.Get("/{id}", rt.handlers.Invoice.GetByID)
				r.Put("/{id}/pay", rt.handlers.Invoice.MarkAsPaid)
				r.Delete("/{id}", rt.handlers.Invoice.Delete)
				r.Get("/institutes/{institute_id}/revenue", rt.handlers.Invoice.GetRevenue)
			})

			// Payments
			r.Route("/payments", func(r chi.Router) {
				r.Post("/", rt.handlers.Payment.AddPayment)
				r.Get("/invoice/{invoice_id}", rt.handlers.Payment.GetPaymentsByInvoice)
				r.Get("/{id}", rt.handlers.Payment.GetPaymentByID)
			})

			// Employees
			r.Route("/employees", func(r chi.Router) {
				r.Post("/", rt.handlers.Employee.Create)
				r.Get("/", rt.handlers.Employee.List)
				r.Get("/{id}", rt.handlers.Employee.GetByID)
				r.Put("/{id}", rt.handlers.Employee.Update)
				r.Delete("/{id}", rt.handlers.Employee.Delete)
				r.Put("/{id}/terminate", rt.handlers.Employee.Terminate)
			})

			// Expenses
			r.Route("/expenses", func(r chi.Router) {
				r.Post("/", rt.handlers.Expense.Create)
				r.Get("/", rt.handlers.Expense.List)
				r.Get("/{id}", rt.handlers.Expense.GetByID)
				r.Put("/{id}", rt.handlers.Expense.Update)
				r.Delete("/{id}", rt.handlers.Expense.Delete)
				r.Put("/{id}/approve", rt.handlers.Expense.Approve)
				r.Put("/{id}/reject", rt.handlers.Expense.Reject)
				// Analytics endpoint will be implemented later
			})

			// Notifications
			r.Route("/notifications", func(r chi.Router) {
				r.Post("/", rt.handlers.Notification.Create)
				r.Get("/", rt.handlers.Notification.List)
				r.Get("/{id}", rt.handlers.Notification.GetByID)
				r.Put("/{id}/read", rt.handlers.Notification.MarkAsRead)
				r.Delete("/{id}", rt.handlers.Notification.Delete)
				r.Put("/read-all", rt.handlers.Notification.MarkAllAsRead)
				r.Get("/unread-count", rt.handlers.Notification.GetUnreadCount)
			})

			// Courses
			r.Route("/courses", func(r chi.Router) {
				r.Post("/", rt.handlers.Course.Create)
				r.Get("/", rt.handlers.Course.List)
				r.Get("/{id}", rt.handlers.Course.GetByID)
				r.Get("/code/{code}", rt.handlers.Course.GetByCode)
				r.Put("/{id}", rt.handlers.Course.Update)
				r.Delete("/{id}", rt.handlers.Course.Delete)
			})

			// Packages
			r.Route("/packages", func(r chi.Router) {
				r.Post("/", rt.handlers.Package.Create)
				r.Get("/", rt.handlers.Package.List)
				r.Get("/{id}", rt.handlers.Package.GetByID)
				r.Get("/code/{code}", rt.handlers.Package.GetByCode)
				r.Put("/{id}", rt.handlers.Package.Update)
				r.Delete("/{id}", rt.handlers.Package.Delete)
			})

			// Reports
			r.Route("/reports", func(r chi.Router) {
				r.Get("/quick-stats", rt.handlers.Report.GetQuickStats)
				r.Get("/dashboard-stats", rt.handlers.Report.GetDashboardStats)
				r.Get("/attendance", rt.handlers.Report.GetAttendanceReport)
				r.Get("/attendance/student/{student_id}", rt.handlers.Report.GetStudentAttendanceReport)
				r.Get("/financial", rt.handlers.Report.GetFinancialReport)
				r.Get("/students", rt.handlers.Report.GetStudentReport)
				r.Get("/revenue", rt.handlers.Report.GetRevenueReport)
				r.Get("/expenses", rt.handlers.Report.GetExpenseReport)
			})
		})
	})

	return rt.mux
}

func (rt *Router) healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok","service":"chalak-api","version":"1.0.0"}`))
}