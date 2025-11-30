import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/invoice_entity.dart';

class AddPaymentDialog extends StatefulWidget {
  final InvoiceEntity invoice;

  const AddPaymentDialog({Key? key, required this.invoice}) : super(key: key);

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'cash';

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingAmount = widget.invoice.remainingAmount;

    return AlertDialog(
      title: const Text('Add Payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice details
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Invoice Number:'),
                          Text(
                            widget.invoice.invoiceNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:'),
                          Text(
                            _currencyFormat.format(widget.invoice.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid Amount:'),
                          Text(
                            _currencyFormat.format(widget.invoice.paidAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Remaining Amount:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currencyFormat.format(remainingAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Payment amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount *',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                  helperText: 'Enter amount to pay',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter payment amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > remainingAmount) {
                    return 'Amount exceeds remaining balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quick amount buttons
              Wrap(
                spacing: 8,
                children: [
                  if (remainingAmount >= 100)
                    _QuickAmountChip(
                      label: 'Rs. 100',
                      amount: 100,
                      onTap: () => _amountController.text = '100',
                    ),
                  if (remainingAmount >= 500)
                    _QuickAmountChip(
                      label: 'Rs. 500',
                      amount: 500,
                      onTap: () => _amountController.text = '500',
                    ),
                  if (remainingAmount >= 1000)
                    _QuickAmountChip(
                      label: 'Rs. 1000',
                      amount: 1000,
                      onTap: () => _amountController.text = '1000',
                    ),
                  _QuickAmountChip(
                    label: 'Full Amount',
                    amount: remainingAmount,
                    onTap: () => _amountController.text = remainingAmount.toStringAsFixed(2),
                    isPrimary: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment method
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'online', child: Text('Online Payment')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add any notes about this payment',
                ),
                maxLines: 3,
                maxLength: 200,
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
          onPressed: _submitPayment,
          child: const Text('Add Payment'),
        ),
      ],
    );
  }

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      Navigator.pop(context, {
        'amount': amount,
        'payment_method': _paymentMethod,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      });
    }
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickAmountChip({
    Key? key,
    required this.label,
    required this.amount,
    required this.onTap,
    this.isPrimary = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isPrimary ? Colors.blue[100] : Colors.grey[200],
      labelStyle: TextStyle(
        color: isPrimary ? Colors.blue[900] : Colors.black87,
        fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
