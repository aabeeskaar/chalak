import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../students/students_screen.dart';
import '../attendance/attendance_screen.dart';
import '../courses/courses_screen.dart';
import '../packages/packages_screen.dart';
import '../invoices/invoices_screen.dart';
import '../auth/login_screen.dart';
import '../expenses/expenses_screen.dart';
import '../hr/hr_management_screen.dart';
import '../reports/reports_screen.dart';
import '../../../core/constants/role_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  List<NavigationItem> _navigationItems = [];
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavigationItems();
    });
  }

  void _updateNavigationItems() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.user?.role ?? '';

    setState(() {
      _navigationItems = NavigationItems.getNavigationItems(userRole);
      _screens = _getScreensForRole(userRole);
      _selectedIndex = 0; // Reset to first available tab
    });
  }

  List<Widget> _getScreensForRole(String userRole) {
    final Map<String, Widget> allScreens = {
      NavigationItems.dashboard: DashboardTab(userRole: userRole),
      NavigationItems.students: const StudentsScreen(),
      NavigationItems.attendance: const AttendanceScreen(),
      NavigationItems.courses: const CoursesScreen(),
      NavigationItems.packages: const PackagesScreen(),
      NavigationItems.invoices: const InvoicesScreen(),
      NavigationItems.expenses: const ExpensesScreen(),
      NavigationItems.reports: const ReportsScreen(),
      NavigationItems.hrManagement: const HRManagementScreen(),
    };

    return _navigationItems
        .map((item) => allScreens[item.key] ?? const Center(child: Text('Screen not found')))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chalak Institute'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.user?.name.isNotEmpty == true
                        ? authProvider.user!.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (context) => <PopupMenuEntry<dynamic>>[
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(authProvider.user?.name ?? 'User'),
                      subtitle: Text(authProvider.user?.role ?? 'Role'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    onTap: () async {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    child: const ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _navigationItems.isNotEmpty ? _buildDrawer() : null,
      body: _screens.isNotEmpty && _selectedIndex < _screens.length
          ? _screens[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Drawer(
          child: Column(
            children: [
              // Drawer Header
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                accountName: Text(
                  authProvider.user?.name ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(authProvider.user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    authProvider.user?.name.isNotEmpty == true
                        ? authProvider.user!.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    final isSelected = _selectedIndex == index;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: ListTile(
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                          Navigator.of(context).pop(); // Close drawer
                        },
                      ),
                    );
                  },
                ),
              ),
              // Logout Button
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.of(context).pop(); // Close drawer
                  await authProvider.logout();
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class DashboardTab extends StatefulWidget {
  final String userRole;

  const DashboardTab({Key? key, required this.userRole}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.token;

      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/v1/reports/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _dashboardStats = data['data'];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load dashboard stats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final vehicleAttendance = _dashboardStats?['vehicle_attendance'] as List<dynamic>? ?? [];
    final newStudentsToday = _dashboardStats?['new_students_today'] ?? 0;
    final moneyCollectionToday = _dashboardStats?['money_collection_today'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text(
                    widget.userRole.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 1: Today's Attendance by Vehicle Type
            _buildSectionHeader(context, 'Today\'s Attendance', Icons.directions_car),
            const SizedBox(height: 12),
            if (vehicleAttendance.isEmpty)
              _buildEmptyCard('No attendance records for today')
            else
              ...vehicleAttendance.map((v) => _buildVehicleAttendanceCard(
                    context,
                    v['course_name'] ?? '',
                    v['present'] ?? 0,
                    v['absent'] ?? 0,
                    v['late'] ?? 0,
                    v['total'] ?? 0,
                  )),

            const SizedBox(height: 24),

            // Section 2: Today's New Students
            _buildSectionHeader(context, 'Today\'s New Students', Icons.person_add),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'New Enrollments',
              newStudentsToday.toString(),
              Icons.school,
              Colors.green,
            ),

            const SizedBox(height: 24),

            // Section 3: Today's Money Collection
            _buildSectionHeader(context, 'Today\'s Revenue', Icons.attach_money),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Money Collected',
              'Rs. ${moneyCollectionToday.toStringAsFixed(2)}',
              Icons.account_balance_wallet,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  Widget _buildVehicleAttendanceCard(
    BuildContext context,
    String vehicleType,
    int present,
    int absent,
    int late,
    int total,
  ) {
    final presentPercent = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0';

    IconData vehicleIcon;
    Color vehicleColor;

    if (vehicleType.toLowerCase().contains('scooter') || vehicleType.toLowerCase().contains('bike')) {
      vehicleIcon = Icons.two_wheeler;
      vehicleColor = Colors.blue;
    } else if (vehicleType.toLowerCase().contains('car')) {
      vehicleIcon = Icons.directions_car;
      vehicleColor = Colors.orange;
    } else {
      vehicleIcon = Icons.local_shipping;
      vehicleColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(vehicleIcon, color: vehicleColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  vehicleType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Chip(
                  label: Text('$presentPercent%'),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceStat(
                    'Present',
                    present.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceStat(
                    'Absent',
                    absent.toString(),
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceStat(
                    'Late',
                    late.toString(),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceStat(
                    'Total',
                    total.toString(),
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}