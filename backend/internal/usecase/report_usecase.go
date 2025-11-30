package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/chalak/backend/internal/domain/report"
)

type ReportUseCase struct {
	reportRepo report.Repository
}

func NewReportUseCase(reportRepo report.Repository) *ReportUseCase {
	return &ReportUseCase{
		reportRepo: reportRepo,
	}
}

// GetAttendanceReport retrieves attendance statistics for a date range
func (uc *ReportUseCase) GetAttendanceReport(ctx context.Context, startDate, endDate time.Time) (*report.AttendanceReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return uc.reportRepo.GetAttendanceReport(ctx, startDate, endDate)
}

// GetStudentAttendanceReport retrieves attendance report for a specific student
func (uc *ReportUseCase) GetStudentAttendanceReport(ctx context.Context, studentID string, startDate, endDate time.Time) (*report.StudentAttendanceStat, error) {
	if studentID == "" {
		return nil, fmt.Errorf("student ID is required")
	}

	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return uc.reportRepo.GetStudentAttendanceReport(ctx, studentID, startDate, endDate)
}

// GetFinancialReport retrieves comprehensive financial report
func (uc *ReportUseCase) GetFinancialReport(ctx context.Context, startDate, endDate time.Time) (*report.FinancialReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return uc.reportRepo.GetFinancialReport(ctx, startDate, endDate)
}

// GetStudentReport retrieves student enrollment and distribution report
func (uc *ReportUseCase) GetStudentReport(ctx context.Context, startDate, endDate time.Time) (*report.StudentReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return uc.reportRepo.GetStudentReport(ctx, startDate, endDate)
}

// GetRevenueReport retrieves detailed revenue analysis
func (uc *ReportUseCase) GetRevenueReport(ctx context.Context, startDate, endDate time.Time) (*report.RevenueReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return uc.reportRepo.GetRevenueReport(ctx, startDate, endDate)
}

// GetExpenseReport retrieves detailed expense analysis
func (uc *ReportUseCase) GetExpenseReport(ctx context.Context, startDate, endDate time.Time) (*report.ExpenseReport, error) {
	if startDate.After(endDate) {
		return nil, fmt.Errorf("start date must be before end date")
	}

	return uc.reportRepo.GetExpenseReport(ctx, startDate, endDate)
}

// GetQuickStats retrieves quick overview statistics for dashboard
func (uc *ReportUseCase) GetQuickStats(ctx context.Context) (map[string]interface{}, error) {
	// Get stats for current month
	now := time.Now()
	startOfMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	endOfMonth := startOfMonth.AddDate(0, 1, 0).Add(-time.Second)

	stats := make(map[string]interface{})

	// Get financial summary
	financial, err := uc.reportRepo.GetFinancialReport(ctx, startOfMonth, endOfMonth)
	if err == nil {
		stats["total_revenue"] = financial.TotalRevenue
		stats["total_expenses"] = financial.TotalExpenses
		stats["net_profit"] = financial.NetProfit
		stats["pending_invoices"] = financial.PendingInvoices
	}

	// Get student summary
	student, err := uc.reportRepo.GetStudentReport(ctx, startOfMonth, endOfMonth)
	if err == nil {
		stats["total_students"] = student.TotalStudents
		stats["active_students"] = student.ActiveStudents
		stats["new_enrollments"] = student.NewEnrollments
	}

	// Get attendance for today
	today := time.Now().Truncate(24 * time.Hour)
	attendance, err := uc.reportRepo.GetAttendanceReport(ctx, today, today)
	if err == nil {
		stats["today_attendance"] = map[string]interface{}{
			"present": attendance.PresentCount,
			"absent":  attendance.AbsentCount,
			"late":    attendance.LateCount,
		}
	}

	return stats, nil
}

// GetDashboardStats retrieves dashboard statistics for today
func (uc *ReportUseCase) GetDashboardStats(ctx context.Context) (map[string]interface{}, error) {
	return uc.reportRepo.GetDashboardStats(ctx)
}
