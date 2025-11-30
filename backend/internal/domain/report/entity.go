package report

import "time"

// ReportType represents the type of report
type ReportType string

const (
	ReportTypeAttendance ReportType = "attendance"
	ReportTypeFinancial  ReportType = "financial"
	ReportTypeStudent    ReportType = "student"
	ReportTypeRevenue    ReportType = "revenue"
	ReportTypeExpense    ReportType = "expense"
)

// AttendanceReport represents attendance statistics
type AttendanceReport struct {
	StartDate       time.Time              `json:"start_date"`
	EndDate         time.Time              `json:"end_date"`
	TotalStudents   int                    `json:"total_students"`
	TotalDays       int                    `json:"total_days"`
	PresentCount    int                    `json:"present_count"`
	AbsentCount     int                    `json:"absent_count"`
	LateCount       int                    `json:"late_count"`
	ExcusedCount    int                    `json:"excused_count"`
	AttendanceRate  float64                `json:"attendance_rate"`
	DailyStats      []DailyAttendanceStat  `json:"daily_stats"`
	StudentStats    []StudentAttendanceStat `json:"student_stats,omitempty"`
}

// DailyAttendanceStat represents attendance for a specific day
type DailyAttendanceStat struct {
	Date         time.Time `json:"date"`
	Present      int       `json:"present"`
	Absent       int       `json:"absent"`
	Late         int       `json:"late"`
	Excused      int       `json:"excused"`
	TotalRecords int       `json:"total_records"`
}

// StudentAttendanceStat represents attendance stats for a specific student
type StudentAttendanceStat struct {
	StudentID      string  `json:"student_id"`
	StudentName    string  `json:"student_name"`
	Phone          string  `json:"phone"`
	Present        int     `json:"present"`
	Absent         int     `json:"absent"`
	Late           int     `json:"late"`
	Excused        int     `json:"excused"`
	Total          int     `json:"total"`
	AttendanceRate float64 `json:"attendance_rate"`
}

// FinancialReport represents financial overview
type FinancialReport struct {
	StartDate         time.Time              `json:"start_date"`
	EndDate           time.Time              `json:"end_date"`
	TotalRevenue      float64                `json:"total_revenue"`
	TotalExpenses     float64                `json:"total_expenses"`
	NetProfit         float64                `json:"net_profit"`
	PaidInvoices      int                    `json:"paid_invoices"`
	PendingInvoices   int                    `json:"pending_invoices"`
	OverdueInvoices   int                    `json:"overdue_invoices"`
	TotalInvoices     int                    `json:"total_invoices"`
	PaymentMethodStats []PaymentMethodStat   `json:"payment_method_stats"`
	MonthlyRevenue    []MonthlyRevenueStat   `json:"monthly_revenue"`
	ExpenseCategories []ExpenseCategoryStat  `json:"expense_categories"`
}

// PaymentMethodStat represents payment statistics by method
type PaymentMethodStat struct {
	PaymentMethod string  `json:"payment_method"`
	Count         int     `json:"count"`
	TotalAmount   float64 `json:"total_amount"`
}

// MonthlyRevenueStat represents revenue for a specific month
type MonthlyRevenueStat struct {
	Month       string  `json:"month"`
	Year        int     `json:"year"`
	Revenue     float64 `json:"revenue"`
	Expenses    float64 `json:"expenses"`
	NetProfit   float64 `json:"net_profit"`
	Invoices    int     `json:"invoices"`
}

// ExpenseCategoryStat represents expenses by category
type ExpenseCategoryStat struct {
	Category    string  `json:"category"`
	Count       int     `json:"count"`
	TotalAmount float64 `json:"total_amount"`
	Percentage  float64 `json:"percentage"`
}

// StudentReport represents student enrollment and performance
type StudentReport struct {
	StartDate           time.Time           `json:"start_date"`
	EndDate             time.Time           `json:"end_date"`
	TotalStudents       int                 `json:"total_students"`
	ActiveStudents      int                 `json:"active_students"`
	InactiveStudents    int                 `json:"inactive_students"`
	NewEnrollments      int                 `json:"new_enrollments"`
	CourseDistribution  []CourseDistStat    `json:"course_distribution"`
	PackageDistribution []PackageDistStat   `json:"package_distribution"`
	GenderDistribution  []GenderDistStat    `json:"gender_distribution"`
}

// CourseDistStat represents student distribution by course
type CourseDistStat struct {
	CourseID   string `json:"course_id"`
	CourseName string `json:"course_name"`
	Count      int    `json:"count"`
	Percentage float64 `json:"percentage"`
}

// PackageDistStat represents student distribution by package
type PackageDistStat struct {
	PackageID   string  `json:"package_id"`
	PackageName string  `json:"package_name"`
	Count       int     `json:"count"`
	Percentage  float64 `json:"percentage"`
}

// GenderDistStat represents student distribution by gender
type GenderDistStat struct {
	Gender     string  `json:"gender"`
	Count      int     `json:"count"`
	Percentage float64 `json:"percentage"`
}

// RevenueReport represents detailed revenue analysis
type RevenueReport struct {
	StartDate          time.Time            `json:"start_date"`
	EndDate            time.Time            `json:"end_date"`
	TotalRevenue       float64              `json:"total_revenue"`
	TotalPayments      int                  `json:"total_payments"`
	AveragePayment     float64              `json:"average_payment"`
	CourseRevenue      []CourseRevenueStat  `json:"course_revenue"`
	PackageRevenue     []PackageRevenueStat `json:"package_revenue"`
	DailyRevenue       []DailyRevenueStat   `json:"daily_revenue"`
}

// CourseRevenueStat represents revenue by course
type CourseRevenueStat struct {
	CourseID   string  `json:"course_id"`
	CourseName string  `json:"course_name"`
	Revenue    float64 `json:"revenue"`
	Students   int     `json:"students"`
	Percentage float64 `json:"percentage"`
}

// PackageRevenueStat represents revenue by package
type PackageRevenueStat struct {
	PackageID   string  `json:"package_id"`
	PackageName string  `json:"package_name"`
	Revenue     float64 `json:"revenue"`
	Students    int     `json:"students"`
	Percentage  float64 `json:"percentage"`
}

// DailyRevenueStat represents revenue for a specific day
type DailyRevenueStat struct {
	Date     time.Time `json:"date"`
	Revenue  float64   `json:"revenue"`
	Payments int       `json:"payments"`
}

// ExpenseReport represents detailed expense analysis
type ExpenseReport struct {
	StartDate          time.Time               `json:"start_date"`
	EndDate            time.Time               `json:"end_date"`
	TotalExpenses      float64                 `json:"total_expenses"`
	TotalTransactions  int                     `json:"total_transactions"`
	AverageExpense     float64                 `json:"average_expense"`
	CategoryBreakdown  []ExpenseCategoryStat   `json:"category_breakdown"`
	MonthlyExpenses    []MonthlyExpenseStat    `json:"monthly_expenses"`
	TopExpenses        []TopExpenseStat        `json:"top_expenses"`
}

// MonthlyExpenseStat represents expenses for a specific month
type MonthlyExpenseStat struct {
	Month      string  `json:"month"`
	Year       int     `json:"year"`
	Expenses   float64 `json:"expenses"`
	Count      int     `json:"count"`
}

// TopExpenseStat represents the highest expenses
type TopExpenseStat struct {
	ID          string    `json:"id"`
	Category    string    `json:"category"`
	Description string    `json:"description"`
	Amount      float64   `json:"amount"`
	Date        time.Time `json:"date"`
}
