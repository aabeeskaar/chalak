package report

import (
	"context"
	"time"
)

// Repository defines the interface for report operations
type Repository interface {
	// Attendance Reports
	GetAttendanceReport(ctx context.Context, startDate, endDate time.Time) (*AttendanceReport, error)
	GetStudentAttendanceReport(ctx context.Context, studentID string, startDate, endDate time.Time) (*StudentAttendanceStat, error)

	// Financial Reports
	GetFinancialReport(ctx context.Context, startDate, endDate time.Time) (*FinancialReport, error)

	// Student Reports
	GetStudentReport(ctx context.Context, startDate, endDate time.Time) (*StudentReport, error)

	// Revenue Reports
	GetRevenueReport(ctx context.Context, startDate, endDate time.Time) (*RevenueReport, error)

	// Expense Reports
	GetExpenseReport(ctx context.Context, startDate, endDate time.Time) (*ExpenseReport, error)

	// Dashboard Stats
	GetDashboardStats(ctx context.Context) (map[string]interface{}, error)
}
