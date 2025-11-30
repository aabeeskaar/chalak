import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/invoice_provider.dart';
import '../../widgets/invoice_card.dart';
import 'invoice_detail_screen.dart';

class StudentInvoicesScreen extends StatefulWidget {
  final String studentId;
  final String? studentName;

  const StudentInvoicesScreen({
    Key? key,
    required this.studentId,
    this.studentName,
  }) : super(key: key);

  @override
  State<StudentInvoicesScreen> createState() => _StudentInvoicesScreenState();
}

class _StudentInvoicesScreenState extends State<StudentInvoicesScreen> {
  final _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoices();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInvoices() {
    context.read<InvoiceProvider>().getInvoices(
          refresh: true,
          studentId: widget.studentId,
          status: _selectedStatus,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final provider = context.read<InvoiceProvider>();
      if (!provider.isLoading && provider.hasMoreData) {
        provider.getInvoices(studentId: widget.studentId, status: _selectedStatus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName != null
            ? 'Invoices - ${widget.studentName}'
            : 'Student Invoices'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'all' ? null : value;
              });
              _loadInvoices();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'paid', child: Text('Paid')),
              const PopupMenuItem(value: 'overdue', child: Text('Overdue')),
              const PopupMenuItem(value: 'canceled', child: Text('Canceled')),
            ],
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          if (provider.state == InvoiceState.loading &&
              provider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == InvoiceState.error &&
              provider.invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInvoices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Filter invoices for this specific student
          final studentInvoices = provider.invoices
              .where((invoice) => invoice.studentId == widget.studentId)
              .toList();

          if (studentInvoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No invoices found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This student has no invoices yet',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.getInvoices(
                refresh: true,
                studentId: widget.studentId,
                status: _selectedStatus,
              );
            },
            child: Column(
              children: [
                // Summary Card
                _buildSummaryCard(studentInvoices),

                // Invoice List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: studentInvoices.length +
                        (provider.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= studentInvoices.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final invoice = studentInvoices[index];
                      return InvoiceCard(
                        invoice: invoice,
                        onTap: () => _showInvoiceDetails(invoice),
                        onMarkPaid: invoice.isPending
                            ? () => _confirmMarkAsPaid(invoice.id, invoice.invoiceNumber)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List invoices) {
    final totalAmount = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalAmount,
    );
    final paidAmount = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.paidAmount,
    );
    final pendingAmount = invoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.remainingAmount,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total',
                    CurrencyFormatter.formatNPR(totalAmount),
                    Colors.blue,
                    Icons.receipt_long,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Paid',
                    CurrencyFormatter.formatNPR(paidAmount),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pending',
                    CurrencyFormatter.formatNPR(pendingAmount),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showInvoiceDetails(invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    ).then((_) {
      // Refresh the list when coming back
      _loadInvoices();
    });
  }

  void _confirmMarkAsPaid(String invoiceId, String invoiceNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Are you sure you want to mark invoice $invoiceNumber as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<InvoiceProvider>().markAsPaid(invoiceId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Invoice $invoiceNumber marked as paid'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(invoice) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment - ${invoice.invoiceNumber}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining: ${CurrencyFormatter.formatNPR(invoice.remainingAmount)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'NPR ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Invalid amount';
                    }
                    if (amount > invoice.remainingAmount) {
                      return 'Amount exceeds remaining balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'online', child: Text('Online Payment')),
                  ],
                  onChanged: (value) {
                    if (value != null) paymentMethod = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                final amount = double.parse(amountController.text);
                final success = await context.read<InvoiceProvider>().addPayment(
                      invoiceId: invoice.id,
                      amount: amount,
                      paymentMethod: paymentMethod,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ${CurrencyFormatter.formatNPR(amount)} added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadInvoices();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to add payment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Payment'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceDetailsDialog extends StatelessWidget {
  final invoice;
  final VoidCallback onAddPayment;
  final VoidCallback onMarkAsPaid;

  const _InvoiceDetailsDialog({
    required this.invoice,
    required this.onAddPayment,
    required this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invoice Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(invoice.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getStatusColor(invoice.status)),
                        ),
                        child: Text(
                          invoice.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(invoice.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dates
                    _buildInfoRow(Icons.calendar_today, 'Due Date', _formatDate(invoice.dueDate)),
                    if (invoice.paidAt != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.check_circle, 'Paid At', _formatDate(invoice.paidAt!)),
                    ],
                    const SizedBox(height: 24),

                    // Invoice Items
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...invoice.items.map<Widget>((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} × ${CurrencyFormatter.formatNPR(item.unitPrice)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatNPR(item.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Amount Summary
                    _buildAmountRow('Subtotal', invoice.amount),
                    const SizedBox(height: 8),
                    _buildAmountRow('Tax', invoice.taxAmount),
                    const SizedBox(height: 8),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),
                    _buildAmountRow('Total', invoice.totalAmount, isBold: true),
                    const SizedBox(height: 8),
                    _buildAmountRow('Paid', invoice.paidAmount, color: Colors.green),
                    const SizedBox(height: 8),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),
                    _buildAmountRow('Remaining', invoice.remainingAmount, isBold: true, color: Colors.orange),

                    // Notes
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          invoice.notes!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (!invoice.isPaid)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onAddPayment();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (invoice.paidAmount == 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onMarkAsPaid();
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark Paid'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: color,
          ),
        ),
        Text(
          CurrencyFormatter.formatNPR(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
