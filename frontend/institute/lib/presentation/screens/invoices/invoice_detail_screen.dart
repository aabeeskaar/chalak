import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../providers/invoice_provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceEntity invoice;

  const InvoiceDetailScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  List<PaymentEntity> _payments = [];
  bool _isLoadingPayments = false;
  String? _paymentsError;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });

    try {
      final payments = await context.read<InvoiceProvider>().getPaymentsByInvoiceId(widget.invoice.id);
      setState(() {
        _payments = payments;
        _isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        _paymentsError = e.toString();
        _isLoadingPayments = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}'),
        actions: [
          if (!widget.invoice.isPaid)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Payment',
              onPressed: () => _showAddPaymentDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            _buildStatusBadge(),
            const SizedBox(height: 24),

            // Invoice Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Invoice Number', widget.invoice.invoiceNumber),
                    _buildInfoRow('Status', _getStatusText(widget.invoice.status)),
                    _buildInfoRow('Issue Date', _formatDate(widget.invoice.createdAt)),
                    _buildInfoRow('Due Date', _formatDate(widget.invoice.dueDate)),
                    if (widget.invoice.paidAt != null)
                      _buildInfoRow('Paid Date', _formatDate(widget.invoice.paidAt!)),
                    if (widget.invoice.notes != null && widget.invoice.notes!.isNotEmpty)
                      ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Notes',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.invoice.notes!),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    ...widget.invoice.items.map((item) => _buildItemRow(item)).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildAmountRow('Subtotal', widget.invoice.amount),
                    const SizedBox(height: 8),
                    _buildAmountRow('Tax', widget.invoice.taxAmount),
                    const Divider(height: 16),
                    _buildAmountRow(
                      'Total Amount',
                      widget.invoice.totalAmount,
                      isBold: true,
                      fontSize: 18,
                    ),
                    if (widget.invoice.paidAmount > 0) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildAmountRow(
                        'Paid Amount',
                        widget.invoice.paidAmount,
                        color: Colors.green,
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildAmountRow(
                        'Remaining',
                        widget.invoice.remainingAmount,
                        color: Colors.orange,
                        isBold: true,
                        fontSize: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment History Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isLoadingPayments)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_isLoadingPayments && _payments.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_paymentsError != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Error loading payments',
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadPayments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_payments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No payments yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ..._payments.map((payment) => _buildPaymentRow(payment)).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!widget.invoice.isPaid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(context),
                  icon: const Icon(Icons.payment),
                  label: const Text('Add Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;

    if (widget.invoice.isPaid) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      text = 'PAID';
    } else if (widget.invoice.isOverdue || widget.invoice.isOverdueDate) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      text = 'OVERDUE';
    } else if (widget.invoice.isPartiallyPaid) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      text = 'PARTIALLY PAID';
    } else {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      text = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(InvoiceItemEntity item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${CurrencyFormatter.formatNPR(item.unitPrice)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatNPR(item.amount),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
          Text(
            CurrencyFormatter.formatNPR(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(PaymentEntity payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.formatNPR(payment.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payment.formattedPaymentMethod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatDate(payment.paymentDate),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              payment.notes!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'overdue':
        return 'Overdue';
      case 'canceled':
        return 'Canceled';
      default:
        return status;
    }
  }

  void _showAddPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Payment - ${widget.invoice.invoiceNumber}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining: ${CurrencyFormatter.formatNPR(widget.invoice.remainingAmount)}',
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
                    if (amount > widget.invoice.remainingAmount) {
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
                  items: ['cash', 'card', 'bank_transfer', 'other']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                final amount = double.parse(amountController.text);
                final success = await context.read<InvoiceProvider>().addPayment(
                      invoiceId: widget.invoice.id,
                      amount: amount,
                      paymentMethod: paymentMethod,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Payment of ${CurrencyFormatter.formatNPR(amount)} added successfully'
                            : 'Failed to add payment',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );

                  if (success) {
                    // Reload payments
                    await _loadPayments();

                    // Check if invoice is now fully paid and pop back
                    try {
                      final updatedInvoice = context.read<InvoiceProvider>().invoices
                          .firstWhere((inv) => inv.id == widget.invoice.id);

                      if (updatedInvoice.isPaid && context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      // Invoice not found in list, no need to check
                    }
                  }
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
