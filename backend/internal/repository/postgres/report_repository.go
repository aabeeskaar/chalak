package postgres

import (
	"context"
	"time"

	"github.com/chalak/backend/internal/domain/report"
	"gorm.io/gorm"
)

type reportRepository struct {
	db *gorm.DB
}

// NewReportRepository creates a new report repository
func NewReportRepository(db *gorm.DB) report.Repository {
	return &reportRepository{db: db}
}

// GetAttendanceReport generates attendance statistics for a date range
func (r *reportRepository) GetAttendanceReport(ctx context.Context, startDate, endDate time.Time) (*report.AttendanceReport, error) {
	rep := &report.AttendanceReport{
		StartDate: startDate,
		EndDate:   endDate,
	}

	// Get overall statistics using GORM raw query
	type AttendanceStats struct {
		TotalStudents int
		TotalRecords  int
		PresentCount  int
		AbsentCount   int
		LateCount     int
		ExcusedCount  int
	}

	var stats AttendanceStats
	err := r.db.WithContext(ctx).Raw(`
		SELECT
			COUNT(DISTINCT student_id) as total_students,
			COUNT(*) as total_records,
			SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present_count,
			SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent_count,
			SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late_count,
			SUM(CASE WHEN status = 'excused' THEN 1 ELSE 0 END) as excused_count
		FROM attendances
		WHERE date >= ? AND date <= ? AND deleted_at IS NULL
	`, startDate, endDate).Scan(&stats).Error

	if err != nil {
		return nil, err
	}

	rep.TotalStudents = stats.TotalStudents
	rep.PresentCount = stats.PresentCount
	rep.AbsentCount = stats.AbsentCount
	rep.LateCount = stats.LateCount
	rep.ExcusedCount = stats.ExcusedCount

	// Calculate attendance rate
	if stats.TotalRecords > 0 {
		rep.AttendanceRate = float64(rep.PresentCount) / float64(stats.TotalRecords) * 100
	}

	rep.TotalDays = int(endDate.Sub(startDate).Hours()/24) + 1
	rep.DailyStats = make([]report.DailyAttendanceStat, 0)

	return rep, nil
}

// GetStudentAttendanceReport generates attendance report for a specific student
func (r *reportRepository) GetStudentAttendanceReport(ctx context.Context, studentID string, startDate, endDate time.Time) (*report.StudentAttendanceStat, error) {
	var stat report.StudentAttendanceStat

	err := r.db.WithContext(ctx).Raw(`
		SELECT
			s.id as student_id,
			s.name as student_name,
			s.phone,
			COALESCE(SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END), 0) as present,
			COALESCE(SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END), 0) as absent,
			COALESCE(SUM(CASE WHEN a.status = 'late' THEN 1 ELSE 0 END), 0) as late,
			COALESCE(SUM(CASE WHEN a.status = 'excused' THEN 1 ELSE 0 END), 0) as excused,
			COUNT(a.id) as total
		FROM students s
		LEFT JOIN attendances a ON s.id = a.student_id
			AND a.date >= ? AND a.date <= ?
			AND a.deleted_at IS NULL
		WHERE s.id = ? AND s.deleted_at IS NULL
		GROUP BY s.id, s.name, s.phone
	`, startDate, endDate, studentID).Scan(&stat).Error

	if err != nil {
		return nil, err
	}

	if stat.Total > 0 {
		stat.AttendanceRate = float64(stat.Present) / float64(stat.Total) * 100
	}

	return &stat, nil
}

// GetFinancialReport generates comprehensive financial report
func (r *reportRepository) GetFinancialReport(ctx context.Context, startDate, endDate time.Time) (*report.FinancialReport, error) {
	rep := &report.FinancialReport{
		StartDate: startDate,
		EndDate:   endDate,
	}

	// Get revenue from payments
	r.db.WithContext(ctx).Raw(`
		SELECT COALESCE(SUM(amount), 0)
		FROM payments
		WHERE payment_date >= ? AND payment_date <= ? AND deleted_at IS NULL
	`, startDate, endDate).Scan(&rep.TotalRevenue)

	// Get expenses
	r.db.WithContext(ctx).Raw(`
		SELECT COALESCE(SUM(amount), 0)
		FROM expenses
		WHERE date >= ? AND date <= ? AND deleted_at IS NULL
	`, startDate, endDate).Scan(&rep.TotalExpenses)

	rep.NetProfit = rep.TotalRevenue - rep.TotalExpenses

	// Get invoice statistics
	type InvoiceStats struct {
		PaidInvoices    int
		PendingInvoices int
		OverdueInvoices int
		TotalInvoices   int
	}

	var invoiceStats InvoiceStats
	r.db.WithContext(ctx).Raw(`
		SELECT
			SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) as paid_invoices,
			SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_invoices,
			SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue_invoices,
			COUNT(*) as total_invoices
		FROM invoices
		WHERE created_at >= ? AND created_at <= ? AND deleted_at IS NULL
	`, startDate, endDate).Scan(&invoiceStats)

	rep.PaidInvoices = invoiceStats.PaidInvoices
	rep.PendingInvoices = invoiceStats.PendingInvoices
	rep.OverdueInvoices = invoiceStats.OverdueInvoices
	rep.TotalInvoices = invoiceStats.TotalInvoices

	// Initialize empty slices
	rep.PaymentMethodStats = make([]report.PaymentMethodStat, 0)
	rep.MonthlyRevenue = make([]report.MonthlyRevenueStat, 0)
	rep.ExpenseCategories = make([]report.ExpenseCategoryStat, 0)

	return rep, nil
}

// GetStudentReport generates student enrollment and distribution report
func (r *reportRepository) GetStudentReport(ctx context.Context, startDate, endDate time.Time) (*report.StudentReport, error) {
	rep := &report.StudentReport{
		StartDate: startDate,
		EndDate:   endDate,
	}

	// Get student counts
	type StudentCounts struct {
		TotalStudents    int
		ActiveStudents   int
		InactiveStudents int
		NewEnrollments   int
	}

	var counts StudentCounts
	r.db.WithContext(ctx).Raw(`
		SELECT
			COUNT(*) as total_students,
			SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as active_students,
			SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END) as inactive_students,
			SUM(CASE WHEN enrollment_date >= ? AND enrollment_date <= ? THEN 1 ELSE 0 END) as new_enrollments
		FROM students
		WHERE deleted_at IS NULL
	`, startDate, endDate).Scan(&counts)

	rep.TotalStudents = counts.TotalStudents
	rep.ActiveStudents = counts.ActiveStudents
	rep.InactiveStudents = counts.InactiveStudents
	rep.NewEnrollments = counts.NewEnrollments

	// Initialize empty slices
	rep.CourseDistribution = make([]report.CourseDistStat, 0)
	rep.PackageDistribution = make([]report.PackageDistStat, 0)
	rep.GenderDistribution = make([]report.GenderDistStat, 0)

	return rep, nil
}

// GetRevenueReport generates detailed revenue analysis
func (r *reportRepository) GetRevenueReport(ctx context.Context, startDate, endDate time.Time) (*report.RevenueReport, error) {
	rep := &report.RevenueReport{
		StartDate: startDate,
		EndDate:   endDate,
	}

	// Get total revenue
	type RevenueStats struct {
		TotalRevenue  float64
		TotalPayments int
	}

	var stats RevenueStats
	r.db.WithContext(ctx).Raw(`
		SELECT
			COALESCE(SUM(amount), 0) as total_revenue,
			COUNT(*) as total_payments
		FROM payments
		WHERE payment_date >= ? AND payment_date <= ? AND deleted_at IS NULL
	`, startDate, endDate).Scan(&stats)

	rep.TotalRevenue = stats.TotalRevenue
	rep.TotalPayments = stats.TotalPayments

	if rep.TotalPayments > 0 {
		rep.AveragePayment = rep.TotalRevenue / float64(rep.TotalPayments)
	}

	// Initialize empty slices
	rep.CourseRevenue = make([]report.CourseRevenueStat, 0)
	rep.PackageRevenue = make([]report.PackageRevenueStat, 0)
	rep.DailyRevenue = make([]report.DailyRevenueStat, 0)

	return rep, nil
}

// GetExpenseReport generates detailed expense analysis
func (r *reportRepository) GetExpenseReport(ctx context.Context, startDate, endDate time.Time) (*report.ExpenseReport, error) {
	rep := &report.ExpenseReport{
		StartDate: startDate,
		EndDate:   endDate,
	}

	// Get total expenses
	type ExpenseStats struct {
		TotalExpenses      float64
		TotalTransactions  int
	}

	var stats ExpenseStats
	r.db.WithContext(ctx).Raw(`
		SELECT
			COALESCE(SUM(amount), 0) as total_expenses,
			COUNT(*) as total_transactions
		FROM expenses
		WHERE date >= ? AND date <= ? AND deleted_at IS NULL
	`, startDate, endDate).Scan(&stats)

	rep.TotalExpenses = stats.TotalExpenses
	rep.TotalTransactions = stats.TotalTransactions

	if rep.TotalTransactions > 0 {
		rep.AverageExpense = rep.TotalExpenses / float64(rep.TotalTransactions)
	}

	// Initialize empty slices
	rep.CategoryBreakdown = make([]report.ExpenseCategoryStat, 0)
	rep.MonthlyExpenses = make([]report.MonthlyExpenseStat, 0)
	rep.TopExpenses = make([]report.TopExpenseStat, 0)

	return rep, nil
}

// GetDashboardStats retrieves dashboard statistics including attendance by vehicle type
func (r *reportRepository) GetDashboardStats(ctx context.Context) (map[string]interface{}, error) {
	stats := make(map[string]interface{})
	today := time.Now().Truncate(24 * time.Hour)

	// Get today's attendance by vehicle type
	type VehicleAttendance struct {
		CourseName string
		Present    int
		Absent     int
		Late       int
		Total      int
	}

	var vehicleAttendance []VehicleAttendance
	err := r.db.WithContext(ctx).Raw(`
		SELECT
			c.name as course_name,
			SUM(CASE WHEN a.status = 'present' THEN 1 ELSE 0 END) as present,
			SUM(CASE WHEN a.status = 'absent' THEN 1 ELSE 0 END) as absent,
			SUM(CASE WHEN a.status = 'late' THEN 1 ELSE 0 END) as late,
			COUNT(*) as total
		FROM attendances a
		INNER JOIN students s ON a.student_id = s.id
		INNER JOIN student_courses sc ON s.id = sc.student_id
		INNER JOIN courses c ON sc.course_id = c.id
		WHERE a.date = ? AND a.deleted_at IS NULL
		GROUP BY c.name
		ORDER BY c.name
	`, today).Scan(&vehicleAttendance).Error

	if err == nil {
		stats["vehicle_attendance"] = vehicleAttendance
	}

	// Get today's new students
	var newStudentsToday int
	r.db.WithContext(ctx).Raw(`
		SELECT COUNT(*)
		FROM students
		WHERE DATE(enrolled_at) = ? AND deleted_at IS NULL
	`, today).Scan(&newStudentsToday)
	stats["new_students_today"] = newStudentsToday

	// Get today's money collection
	var moneyCollectionToday float64
	r.db.WithContext(ctx).Raw(`
		SELECT COALESCE(SUM(amount), 0)
		FROM payments
		WHERE DATE(payment_date) = ? AND deleted_at IS NULL
	`, today).Scan(&moneyCollectionToday)
	stats["money_collection_today"] = moneyCollectionToday

	return stats, nil
}
