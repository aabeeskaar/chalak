import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/report_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set default date range (current month)
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final reportProvider = context.read<ReportProvider>();
      final token = await authProvider.token;
      if (token != null) {
        reportProvider.setToken(token);
        _loadCurrentReport();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentReport() {
    if (_startDate == null || _endDate == null) return;

    final reportProvider = context.read<ReportProvider>();
    switch (_tabController.index) {
      case 0:
        reportProvider.getQuickStats();
        break;
      case 1:
        reportProvider.getAttendanceReport(_startDate!, _endDate!);
        break;
      case 2:
        reportProvider.getFinancialReport(_startDate!, _endDate!);
        break;
      case 3:
        reportProvider.getStudentReport(_startDate!, _endDate!);
        break;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadCurrentReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => _loadCurrentReport(),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Attendance'),
            Tab(text: 'Financial'),
            Tab(text: 'Students'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_startDate != null && _endDate != null && _tabController.index != 0)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAttendanceTab(),
                _buildFinancialTab(),
                _buildStudentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getQuickStats(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = provider.quickStats;
        if (stats == null) {
          return const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: () => provider.getQuickStats(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Current Month Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Financial Summary
              _buildSectionTitle('Financial Summary'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Revenue',
                      'NPR ${_formatCurrency(stats.totalRevenue)}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Expenses',
                      'NPR ${_formatCurrency(stats.totalExpenses)}',
                      Icons.trending_down,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Net Profit',
                      'NPR ${_formatCurrency(stats.netProfit)}',
                      Icons.account_balance_wallet,
                      stats.netProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Invoices',
                      stats.pendingInvoices.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Student Summary
              _buildSectionTitle('Student Summary'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      stats.totalStudents.toString(),
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Students',
                      stats.activeStudents.toString(),
                      Icons.check_circle,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'New Enrollments',
                stats.newEnrollments.toString(),
                Icons.person_add,
                Colors.purple,
              ),

              const SizedBox(height: 24),

              // Today's Attendance
              _buildSectionTitle('Today\'s Attendance'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Present',
                      stats.todayAttendance['present'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Absent',
                      stats.todayAttendance['absent'].toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Late',
                      stats.todayAttendance['late'].toString(),
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCurrentReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final report = provider.attendanceReport;
        if (report == null) {
          return const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadCurrentReport();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Overall Statistics'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      report.totalStudents.toString(),
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Attendance Rate',
                      '${report.attendanceRate.toStringAsFixed(1)}%',
                      Icons.percent,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Present',
                      report.presentCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Absent',
                      report.absentCount.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Late',
                      report.lateCount.toString(),
                      Icons.access_time,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Excused',
                      report.excusedCount.toString(),
                      Icons.event_busy,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              if (report.dailyStats.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Daily Breakdown'),
                const SizedBox(height: 8),
                ...report.dailyStats.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        DateFormat('dd').format(stat.date),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(DateFormat('EEEE, MMM dd').format(stat.date)),
                    subtitle: Text('Present: ${stat.present} | Absent: ${stat.absent}'),
                    trailing: Text(
                      '${stat.totalRecords} records',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                )).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCurrentReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final report = provider.financialReport;
        if (report == null) {
          return const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadCurrentReport();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Financial Overview'),
              const SizedBox(height: 8),
              _buildStatCard(
                'Total Revenue',
                'NPR ${_formatCurrency(report.totalRevenue)}',
                Icons.account_balance,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Total Expenses',
                'NPR ${_formatCurrency(report.totalExpenses)}',
                Icons.money_off,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Net Profit',
                'NPR ${_formatCurrency(report.netProfit)}',
                Icons.trending_up,
                report.netProfit >= 0 ? Colors.green : Colors.red,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Invoice Statistics'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Paid',
                      report.paidInvoices.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      report.pendingInvoices.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Overdue',
                      report.overdueInvoices.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      report.totalInvoices.toString(),
                      Icons.receipt,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              if (report.paymentMethodStats.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Payment Methods'),
                const SizedBox(height: 8),
                ...report.paymentMethodStats.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(Icons.payment, color: Colors.white),
                    ),
                    title: Text(stat.paymentMethod),
                    subtitle: Text('${stat.count} transactions'),
                    trailing: Text(
                      'NPR ${_formatCurrency(stat.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )).toList(),
              ],

              if (report.expenseCategories.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Expense Categories'),
                const SizedBox(height: 8),
                ...report.expenseCategories.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.category, color: Colors.white),
                    ),
                    title: Text(stat.category),
                    subtitle: LinearProgressIndicator(
                      value: stat.percentage / 100,
                      backgroundColor: Colors.grey[200],
                      color: Colors.red,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NPR ${_formatCurrency(stat.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${stat.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentTab() {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCurrentReport,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final report = provider.studentReport;
        if (report == null) {
          return const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadCurrentReport();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Student Overview'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Students',
                      report.totalStudents.toString(),
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'New Enrollments',
                      report.newEnrollments.toString(),
                      Icons.person_add,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Active',
                      report.activeStudents.toString(),
                      Icons.check_circle,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Inactive',
                      report.inactiveStudents.toString(),
                      Icons.remove_circle,
                      Colors.grey,
                    ),
                  ),
                ],
              ),

              if (report.courseDistribution.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Course Distribution'),
                const SizedBox(height: 8),
                ...report.courseDistribution.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(Icons.school, color: Colors.white),
                    ),
                    title: Text(stat.courseName),
                    subtitle: LinearProgressIndicator(
                      value: stat.percentage / 100,
                      backgroundColor: Colors.grey[200],
                      color: AppTheme.primaryColor,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${stat.count} students',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${stat.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ],

              if (report.genderDistribution.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Gender Distribution'),
                const SizedBox(height: 8),
                ...report.genderDistribution.map((stat) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: stat.gender.toLowerCase() == 'male'
                          ? Colors.blue
                          : stat.gender.toLowerCase() == 'female'
                              ? Colors.pink
                              : Colors.grey,
                      child: Icon(
                        stat.gender.toLowerCase() == 'male'
                            ? Icons.male
                            : stat.gender.toLowerCase() == 'female'
                                ? Icons.female
                                : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(stat.gender),
                    subtitle: LinearProgressIndicator(
                      value: stat.percentage / 100,
                      backgroundColor: Colors.grey[200],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${stat.count} students',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${stat.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }
}
