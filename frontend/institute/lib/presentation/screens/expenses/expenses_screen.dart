import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/role_constants.dart';
import '../../../core/utils/currency_formatter.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final List<ExpenseItem> _expenses = [
    ExpenseItem(
      id: '1',
      title: 'Fuel Costs',
      amount: 450.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Vehicle',
      description: 'Monthly fuel for training vehicles',
    ),
    ExpenseItem(
      id: '2',
      title: 'Insurance Premium',
      amount: 1200.00,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Insurance',
      description: 'Vehicle insurance renewal',
    ),
    ExpenseItem(
      id: '3',
      title: 'Office Supplies',
      amount: 85.50,
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Office',
      description: 'Stationery and printing materials',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? '';

    // Check if user has permission to view expenses
    if (!RolePermissions.hasPermission(userRole, 'expenses')) {
      return const Scaffold(
        body: Center(
          child: Text(
            'You do not have permission to view expenses.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          if (userRole == UserRoles.admin || userRole == UserRoles.accountant)
            IconButton(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpenseSummary(),
            const SizedBox(height: 24),
            Text(
              'Recent Expenses',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final expense = _expenses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(expense.category),
                        child: Icon(
                          _getCategoryIcon(expense.category),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(expense.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.description),
                          Text(
                            _formatDate(expense.date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        CurrencyFormatter.formatNPR(expense.amount),
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
      ),
    );
  }

  Widget _buildExpenseSummary() {
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_down,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Expenses This Month',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                CurrencyFormatter.formatNPR(totalExpenses),
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
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vehicle':
        return Colors.blue;
      case 'insurance':
        return Colors.orange;
      case 'office':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vehicle':
        return Icons.directions_car;
      case 'insurance':
        return Icons.security;
      case 'office':
        return Icons.business;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: const Text('Add expense functionality will be implemented here.'),
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
}

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String description;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
  });
}