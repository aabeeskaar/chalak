class AttendanceReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalStudents;
  final int totalDays;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final double attendanceRate;
  final List<DailyAttendanceStat> dailyStats;

  AttendanceReport({
    required this.startDate,
    required this.endDate,
    required this.totalStudents,
    required this.totalDays,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.excusedCount,
    required this.attendanceRate,
    required this.dailyStats,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalStudents: json['total_students'] ?? 0,
      totalDays: json['total_days'] ?? 0,
      presentCount: json['present_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
      lateCount: json['late_count'] ?? 0,
      excusedCount: json['excused_count'] ?? 0,
      attendanceRate: (json['attendance_rate'] ?? 0).toDouble(),
      dailyStats: (json['daily_stats'] as List? ?? [])
          .map((e) => DailyAttendanceStat.fromJson(e))
          .toList(),
    );
  }
}

class DailyAttendanceStat {
  final DateTime date;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int totalRecords;

  DailyAttendanceStat({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.totalRecords,
  });

  factory DailyAttendanceStat.fromJson(Map<String, dynamic> json) {
    return DailyAttendanceStat(
      date: DateTime.parse(json['date']),
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
      excused: json['excused'] ?? 0,
      totalRecords: json['total_records'] ?? 0,
    );
  }
}

class FinancialReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int paidInvoices;
  final int pendingInvoices;
  final int overdueInvoices;
  final int totalInvoices;
  final List<PaymentMethodStat> paymentMethodStats;
  final List<MonthlyRevenueStat> monthlyRevenue;
  final List<ExpenseCategoryStat> expenseCategories;

  FinancialReport({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.overdueInvoices,
    required this.totalInvoices,
    required this.paymentMethodStats,
    required this.monthlyRevenue,
    required this.expenseCategories,
  });

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
      paidInvoices: json['paid_invoices'] ?? 0,
      pendingInvoices: json['pending_invoices'] ?? 0,
      overdueInvoices: json['overdue_invoices'] ?? 0,
      totalInvoices: json['total_invoices'] ?? 0,
      paymentMethodStats: (json['payment_method_stats'] as List? ?? [])
          .map((e) => PaymentMethodStat.fromJson(e))
          .toList(),
      monthlyRevenue: (json['monthly_revenue'] as List? ?? [])
          .map((e) => MonthlyRevenueStat.fromJson(e))
          .toList(),
      expenseCategories: (json['expense_categories'] as List? ?? [])
          .map((e) => ExpenseCategoryStat.fromJson(e))
          .toList(),
    );
  }
}

class PaymentMethodStat {
  final String paymentMethod;
  final int count;
  final double totalAmount;

  PaymentMethodStat({
    required this.paymentMethod,
    required this.count,
    required this.totalAmount,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStat(
      paymentMethod: json['payment_method'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
    );
  }
}

class MonthlyRevenueStat {
  final String month;
  final int year;
  final double revenue;
  final double expenses;
  final double netProfit;
  final int invoices;

  MonthlyRevenueStat({
    required this.month,
    required this.year,
    required this.revenue,
    required this.expenses,
    required this.netProfit,
    required this.invoices,
  });

  factory MonthlyRevenueStat.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueStat(
      month: json['month'] ?? '',
      year: json['year'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
      invoices: json['invoices'] ?? 0,
    );
  }
}

class ExpenseCategoryStat {
  final String category;
  final int count;
  final double totalAmount;
  final double percentage;

  ExpenseCategoryStat({
    required this.category,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });

  factory ExpenseCategoryStat.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryStat(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class StudentReport {
  final DateTime startDate;
  final DateTime endDate;
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int newEnrollments;
  final List<CourseDistStat> courseDistribution;
  final List<PackageDistStat> packageDistribution;
  final List<GenderDistStat> genderDistribution;

  StudentReport({
    required this.startDate,
    required this.endDate,
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.newEnrollments,
    required this.courseDistribution,
    required this.packageDistribution,
    required this.genderDistribution,
  });

  factory StudentReport.fromJson(Map<String, dynamic> json) {
    return StudentReport(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalStudents: json['total_students'] ?? 0,
      activeStudents: json['active_students'] ?? 0,
      inactiveStudents: json['inactive_students'] ?? 0,
      newEnrollments: json['new_enrollments'] ?? 0,
      courseDistribution: (json['course_distribution'] as List? ?? [])
          .map((e) => CourseDistStat.fromJson(e))
          .toList(),
      packageDistribution: (json['package_distribution'] as List? ?? [])
          .map((e) => PackageDistStat.fromJson(e))
          .toList(),
      genderDistribution: (json['gender_distribution'] as List? ?? [])
          .map((e) => GenderDistStat.fromJson(e))
          .toList(),
    );
  }
}

class CourseDistStat {
  final String courseId;
  final String courseName;
  final int count;
  final double percentage;

  CourseDistStat({
    required this.courseId,
    required this.courseName,
    required this.count,
    required this.percentage,
  });

  factory CourseDistStat.fromJson(Map<String, dynamic> json) {
    return CourseDistStat(
      courseId: json['course_id'] ?? '',
      courseName: json['course_name'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PackageDistStat {
  final String packageId;
  final String packageName;
  final int count;
  final double percentage;

  PackageDistStat({
    required this.packageId,
    required this.packageName,
    required this.count,
    required this.percentage,
  });

  factory PackageDistStat.fromJson(Map<String, dynamic> json) {
    return PackageDistStat(
      packageId: json['package_id'] ?? '',
      packageName: json['package_name'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class GenderDistStat {
  final String gender;
  final int count;
  final double percentage;

  GenderDistStat({
    required this.gender,
    required this.count,
    required this.percentage,
  });

  factory GenderDistStat.fromJson(Map<String, dynamic> json) {
    return GenderDistStat(
      gender: json['gender'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class QuickStats {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int pendingInvoices;
  final int totalStudents;
  final int activeStudents;
  final int newEnrollments;
  final Map<String, int> todayAttendance;

  QuickStats({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.pendingInvoices,
    required this.totalStudents,
    required this.activeStudents,
    required this.newEnrollments,
    required this.todayAttendance,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    final attendance = json['today_attendance'] as Map<String, dynamic>? ?? {};
    return QuickStats(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] ?? 0).toDouble(),
      netProfit: (json['net_profit'] ?? 0).toDouble(),
      pendingInvoices: json['pending_invoices'] ?? 0,
      totalStudents: json['total_students'] ?? 0,
      activeStudents: json['active_students'] ?? 0,
      newEnrollments: json['new_enrollments'] ?? 0,
      todayAttendance: {
        'present': attendance['present'] ?? 0,
        'absent': attendance['absent'] ?? 0,
        'late': attendance['late'] ?? 0,
      },
    );
  }
}
