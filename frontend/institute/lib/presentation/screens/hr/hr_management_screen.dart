import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/utils/currency_formatter.dart';

class HRManagementScreen extends StatefulWidget {
  const HRManagementScreen({Key? key}) : super(key: key);

  @override
  State<HRManagementScreen> createState() => _HRManagementScreenState();
}

class _HRManagementScreenState extends State<HRManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<StaffMember> _staff = [
    StaffMember(
      id: '1',
      name: 'John Smith',
      role: UserRoles.instructor,
      email: 'john.smith@chalak.com',
      phone: '+1234567890',
      salary: 3500.00,
      isActive: true,
      joinDate: DateTime(2023, 1, 15),
    ),
    StaffMember(
      id: '2',
      name: 'Sarah Johnson',
      role: UserRoles.instructor,
      email: 'sarah.johnson@chalak.com',
      phone: '+1234567891',
      salary: 3200.00,
      isActive: true,
      joinDate: DateTime(2023, 3, 20),
    ),
    StaffMember(
      id: '3',
      name: 'Mike Wilson',
      role: UserRoles.staff,
      email: 'mike.wilson@chalak.com',
      phone: '+1234567892',
      salary: 2800.00,
      isActive: true,
      joinDate: DateTime(2023, 6, 10),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? '';

    // Check if user has permission to view HR management
    if (!RolePermissions.hasPermission(userRole, 'hr_management')) {
      return const Scaffold(
        body: Center(
          child: Text(
            'You do not have permission to access HR Management.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Staff', icon: Icon(Icons.people)),
            Tab(text: 'Attendance', icon: Icon(Icons.access_time)),
            Tab(text: 'Payroll', icon: Icon(Icons.payments)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showAddStaffDialog,
            icon: const Icon(Icons.person_add),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStaffTab(),
          _buildAttendanceTab(),
          _buildPayrollTab(),
        ],
      ),
    );
  }

  Widget _buildStaffTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Staff Members',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Chip(
                label: Text('${_staff.length} Active'),
                backgroundColor: Colors.green[100],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _staff.length,
              itemBuilder: (context, index) {
                final staff = _staff[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(staff.role),
                      child: Text(
                        staff.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(staff.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff.role.toUpperCase()),
                        Text(
                          staff.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          CurrencyFormatter.formatNPR(staff.salary),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          staff.isActive ? Icons.check_circle : Icons.cancel,
                          color: staff.isActive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                      ],
                    ),
                    onTap: () => _showStaffDetails(staff),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Staff Attendance Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTab() {
    final totalPayroll = _staff.fold<double>(
      0,
      (sum, staff) => sum + staff.salary,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Monthly Payroll',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatNPR(totalPayroll),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Salary Breakdown',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _staff.length,
              itemBuilder: (context, index) {
                final staff = _staff[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(staff.role),
                      child: Text(
                        staff.name.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(staff.name),
                    subtitle: Text(staff.role.toUpperCase()),
                    trailing: Text(
                      CurrencyFormatter.formatNPR(staff.salary),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case UserRoles.instructor:
        return Colors.blue;
      case UserRoles.accountant:
        return Colors.green;
      case UserRoles.staff:
        return Colors.orange;
      case UserRoles.admin:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showStaffDetails(StaffMember staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(staff.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: ${staff.role.toUpperCase()}'),
            Text('Email: ${staff.email}'),
            Text('Phone: ${staff.phone}'),
            Text('Salary: ${CurrencyFormatter.formatNPR(staff.salary)}'),
            Text('Join Date: ${_formatDate(staff.joinDate)}'),
            Text('Status: ${staff.isActive ? 'Active' : 'Inactive'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement edit staff functionality
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff Member'),
        content: const Text('Add staff functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class StaffMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  final double salary;
  final bool isActive;
  final DateTime joinDate;

  StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.salary,
    required this.isActive,
    required this.joinDate,
  });
}