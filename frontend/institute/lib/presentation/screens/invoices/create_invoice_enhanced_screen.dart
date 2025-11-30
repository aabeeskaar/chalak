import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/student_entity.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/course_entity.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/package_provider.dart';
import '../../providers/course_provider.dart';

enum InvoiceItemType { custom, package, course }

class CreateInvoiceEnhancedScreen extends StatefulWidget {
  final String? preSelectedStudentId;

  const CreateInvoiceEnhancedScreen({
    Key? key,
    this.preSelectedStudentId,
  }) : super(key: key);

  @override
  State<CreateInvoiceEnhancedScreen> createState() => _CreateInvoiceEnhancedScreenState();
}

class _CreateInvoiceEnhancedScreenState extends State<CreateInvoiceEnhancedScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late TabController _tabController;

  StudentEntity? _selectedStudent;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  List<InvoiceItemData> _items = [];
  double _taxRate = 0.0; // Tax inclusive in packages

  // Payment options
  String _paymentType = 'pending'; // 'pending', 'paid', or 'partial'
  final _partialAmountController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // If student is pre-selected, start at step 1 (items)
    if (widget.preSelectedStudentId != null) {
      _currentStep = 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load all necessary data
      final studentProvider = context.read<StudentProvider>();
      final packageProvider = context.read<PackageProvider>();
      final courseProvider = context.read<CourseProvider>();

      // Load students first if needed
      if (studentProvider.students.isEmpty) {
        studentProvider.getStudents(refresh: true).then((_) {
          _trySelectStudent();
        });
      } else {
        _trySelectStudent();
      }

      if (packageProvider.packages.isEmpty) {
        packageProvider.getPackages(refresh: true, isActive: true);
      }
      if (courseProvider.courses.isEmpty) {
        courseProvider.getCourses(refresh: true, isActive: true);
      }
    });
  }

  void _trySelectStudent() {
    if (widget.preSelectedStudentId != null && mounted) {
      final studentProvider = context.read<StudentProvider>();
      try {
        final student = studentProvider.students.firstWhere(
          (s) => s.id == widget.preSelectedStudentId,
        );
        setState(() {
          _selectedStudent = student;
        });
      } catch (e) {
        // Student not found, user will need to select manually
        setState(() {
          _currentStep = 0; // Go back to step 0
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _partialAmountController.dispose();
    _tabController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addCustomItem() {
    setState(() {
      _items.add(InvoiceItemData(
        type: InvoiceItemType.custom,
      ));
    });
  }

  void _addPackageItem(PackageEntity package) {
    setState(() {
      _items.add(InvoiceItemData(
        type: InvoiceItemType.package,
        packageEntity: package,
        descriptionController: TextEditingController(text: package.name),
        quantityController: TextEditingController(text: '1'),
        unitPriceController: TextEditingController(text: package.finalPrice.toString()),
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${package.name} added to invoice'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addCourseItem(CourseEntity course) {
    setState(() {
      _items.add(InvoiceItemData(
        type: InvoiceItemType.course,
        courseEntity: course,
        descriptionController: TextEditingController(text: course.name),
        quantityController: TextEditingController(text: '1'),
        unitPriceController: TextEditingController(text: course.fee.toString()),
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.name} added to invoice'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeItem(int index) {
    if (_items.isNotEmpty) {
      setState(() {
        _items[index].dispose();
        _items.removeAt(index);
      });
    }
  }

  double _calculateSubtotal() {
    return _items.fold(0.0, (sum, item) {
      final quantity = int.tryParse(item.quantityController.text) ?? 0;
      final unitPrice = double.tryParse(item.unitPriceController.text) ?? 0.0;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateTax() {
    return _calculateSubtotal() * (_taxRate / 100);
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a student'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format the due date to ISO 8601 format without milliseconds
      final dueDateFormatted = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
      ).toUtc().toIso8601String();

      final invoiceData = {
        'student_id': _selectedStudent!.id,
        'institute_id': '550e8400-e29b-41d4-a716-446655440100',
        'due_date': dueDateFormatted,
        'notes': _notesController.text.trim(),
        'items': _items.map((item) {
          return {
            'description': item.descriptionController.text.trim(),
            'quantity': int.parse(item.quantityController.text),
            'unit_price': double.parse(item.unitPriceController.text),
          };
        }).toList(),
      };

      final provider = context.read<InvoiceProvider>();
      final createdInvoice = await provider.createInvoice(invoiceData);

      if (mounted) {
        // Check if the creation was successful
        if (provider.state == InvoiceState.error || createdInvoice == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create invoice: ${provider.errorMessage ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          String successMessage = 'Invoice created successfully';

          // If payment type is 'paid', mark the invoice as paid immediately
          if (_paymentType == 'paid') {
            await provider.markAsPaid(createdInvoice.id);

            if (provider.state == InvoiceState.error) {
              successMessage = 'Invoice created but failed to mark as paid';
            } else {
              successMessage = 'Invoice created and marked as paid';
            }
          } else if (_paymentType == 'partial') {
            // Add partial payment
            final partialAmount = double.tryParse(_partialAmountController.text);
            print('DEBUG: Payment type is partial, amount text: ${_partialAmountController.text}');
            print('DEBUG: Parsed partial amount: $partialAmount');

            if (partialAmount != null && partialAmount > 0) {
              print('DEBUG: Adding payment to invoice ${createdInvoice.id} with amount $partialAmount');
              final paymentSuccess = await provider.addPayment(
                invoiceId: createdInvoice.id,
                amount: partialAmount,
                paymentMethod: 'cash', // Default to cash, can be made configurable
                notes: 'Initial partial payment',
              );

              print('DEBUG: Payment success: $paymentSuccess');
              print('DEBUG: Provider error message: ${provider.errorMessage}');

              if (paymentSuccess) {
                successMessage = 'Invoice created with partial payment of ${CurrencyFormatter.formatNPR(partialAmount)}';
              } else {
                successMessage = 'Invoice created but failed to add partial payment: ${provider.errorMessage ?? "Unknown error"}';
              }
            } else {
              print('DEBUG: Invalid partial amount, text was: ${_partialAmountController.text}');
              successMessage = 'Invoice created but partial payment amount is invalid';
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: successMessage.contains('failed') || successMessage.contains('invalid')
                ? Colors.red
                : Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createInvoice,
              tooltip: 'Create Invoice',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _createInvoice();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          onStepTapped: (step) => setState(() => _currentStep = step),
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  if (_currentStep < 3)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 3 ? 'Create' : 'Continue'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createInvoice,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Create Invoice'),
                    ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Select Student
            Step(
              title: const Text('Select Student'),
              content: _buildStudentSelection(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            // Step 2: Add Items
            Step(
              title: const Text('Add Items'),
              content: _buildItemsSelection(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            // Step 3: Payment Options
            Step(
              title: const Text('Payment'),
              content: _buildPaymentSection(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            // Step 4: Finalize
            Step(
              title: const Text('Finalize'),
              content: _buildFinalizeSection(),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentSelection() {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.students.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.students.isEmpty) {
          return const Text('No students available');
        }

        // If student was pre-selected, show read-only card
        if (widget.preSelectedStudentId != null && _selectedStudent != null) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invoice for:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _selectedStudent!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.email, 'Email', _selectedStudent!.email.isEmpty ? 'Not provided' : _selectedStudent!.email),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone, 'Phone', _selectedStudent!.phone),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.info, 'Status', _selectedStudent!.status.toUpperCase()),
                ],
              ),
            ),
          );
        }

        // Otherwise, show dropdown for selection
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<StudentEntity>(
              value: _selectedStudent,
              decoration: const InputDecoration(
                labelText: 'Select Student',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: provider.students.map((student) {
                return DropdownMenuItem(
                  value: student,
                  child: Text(student.name),
                );
              }).toList(),
              onChanged: (student) {
                setState(() {
                  _selectedStudent = student;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a student';
                }
                return null;
              },
            ),
            if (_selectedStudent != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedStudent!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Email: ${_selectedStudent!.email}'),
                      Text('Phone: ${_selectedStudent!.phone}'),
                      Text('Status: ${_selectedStudent!.status.toUpperCase()}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selection
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.card_giftcard), text: 'Packages'),
            Tab(icon: Icon(Icons.school), text: 'Courses'),
            Tab(icon: Icon(Icons.edit), text: 'Custom'),
          ],
        ),
        const SizedBox(height: 16),
        // Tab content
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPackagesTab(),
              _buildCoursesTab(),
              _buildCustomItemForm(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Current items
        if (_items.isNotEmpty) ...[
          const Divider(),
          Text(
            'Added Items (${_items.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    item.type == InvoiceItemType.package
                        ? Icons.card_giftcard
                        : item.type == InvoiceItemType.course
                            ? Icons.school
                            : Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(item.descriptionController.text),
                  subtitle: Text(
                    'Qty: ${item.quantityController.text} × ${CurrencyFormatter.formatNPR(double.tryParse(item.unitPriceController.text) ?? 0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.formatNPR(_calculateItemAmount(item)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPackagesTab() {
    return Consumer<PackageProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.packages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final activePackages = provider.packages.where((p) => p.isActive).toList();

        if (activePackages.isEmpty) {
          return const Center(child: Text('No packages available'));
        }

        return ListView.builder(
          itemCount: activePackages.length,
          itemBuilder: (context, index) {
            final package = activePackages[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.card_giftcard),
                ),
                title: Text(package.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${package.duration} days'),
                    const SizedBox(height: 4),
                    if (package.hasDiscount)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                CurrencyFormatter.formatNPR(package.price),
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${package.discountPercentage.toInt()}% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.formatNPR(package.finalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        CurrencyFormatter.formatNPR(package.price),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addPackageItem(package),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoursesTab() {
    return Consumer<CourseProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.courses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeCourses = provider.courses.where((c) => c.isActive).toList();

        if (activeCourses.isEmpty) {
          return const Center(child: Text('No courses available'));
        }

        return ListView.builder(
          itemCount: activeCourses.length,
          itemBuilder: (context, index) {
            final course = activeCourses[index];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.school),
                ),
                title: Text(course.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${course.duration} hours'),
                    Text(
                      CurrencyFormatter.formatNPR(course.fee),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () => _addCourseItem(course),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomItemForm() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Add Custom Item',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a custom line item with your own description and price',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addCustomItem,
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Item'),
          ),
        ],
      ),
    );
  }


  Widget _buildPaymentSection() {
    final totalAmount = _calculateTotal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose payment status for this invoice',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Payment type selection
        Card(
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Pending Payment'),
                subtitle: const Text('Invoice will be marked as unpaid'),
                value: 'pending',
                groupValue: _paymentType,
                onChanged: (value) {
                  setState(() {
                    _paymentType = value!;
                    _partialAmountController.clear();
                  });
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('Full Payment'),
                subtitle: const Text('Mark invoice as fully paid'),
                value: 'paid',
                groupValue: _paymentType,
                onChanged: (value) {
                  setState(() {
                    _paymentType = value!;
                    _partialAmountController.clear();
                  });
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: const Text('Partial Payment'),
                subtitle: const Text('Customer paid part of the invoice'),
                value: 'partial',
                groupValue: _paymentType,
                onChanged: (value) {
                  setState(() => _paymentType = value!);
                },
              ),
            ],
          ),
        ),

        // Partial payment amount input
        if (_paymentType == 'partial') ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Paid Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _partialAmountController,
                    decoration: InputDecoration(
                      labelText: 'Paid Amount',
                      hintText: '0.00',
                      prefixText: 'Rs. ',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      helperText: 'Amount must be less than Rs. ${totalAmount.toStringAsFixed(2)}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (_paymentType == 'partial') {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the paid amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (amount >= totalAmount) {
                          return 'Partial amount must be less than total';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],

        // Payment summary
        const SizedBox(height: 24),
        Card(
          color: _paymentType == 'paid'
              ? Colors.green[50]
              : _paymentType == 'partial'
                  ? Colors.orange[50]
                  : Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Invoice Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyFormatter.formatNPR(totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                if (_paymentType == 'partial' && _partialAmountController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paid Amount:', style: TextStyle(color: Colors.grey)),
                      Text(
                        CurrencyFormatter.formatNPR(double.tryParse(_partialAmountController.text) ?? 0),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining:', style: TextStyle(color: Colors.grey)),
                      Text(
                        CurrencyFormatter.formatNPR(totalAmount - (double.tryParse(_partialAmountController.text) ?? 0)),
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _paymentType == 'paid'
                            ? Colors.green
                            : _paymentType == 'partial'
                                ? Colors.orange
                                : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _paymentType == 'paid'
                            ? 'PAID'
                            : _paymentType == 'partial'
                                ? 'PARTIAL'
                                : 'PENDING',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notes
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Add any additional notes...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // Final Summary
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invoice Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildSummaryRow('Student', _selectedStudent?.name ?? 'Not selected'),
                _buildSummaryRow('Total Items', '${_items.length}'),
                const Divider(),
                _buildAmountRow('Subtotal', _calculateSubtotal()),
                _buildAmountRow('Tax', _calculateTax()),
                const Divider(thickness: 2),
                _buildAmountRow('Total Amount', _calculateTotal(), isBold: true),
                // Show payment breakdown if partial payment is selected
                if (_paymentType == 'partial') ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildAmountRow(
                    'Paid Amount',
                    double.tryParse(_partialAmountController.text) ?? 0.0,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  _buildAmountRow(
                    'Remaining',
                    _calculateTotal() - (double.tryParse(_partialAmountController.text) ?? 0.0),
                    color: Colors.orange,
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
          Text(
            CurrencyFormatter.formatNPR(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateItemAmount(InvoiceItemData item) {
    final quantity = int.tryParse(item.quantityController.text) ?? 0;
    final unitPrice = double.tryParse(item.unitPriceController.text) ?? 0.0;
    return quantity * unitPrice;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class InvoiceItemData {
  final InvoiceItemType type;
  final PackageEntity? packageEntity;
  final CourseEntity? courseEntity;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  InvoiceItemData({
    required this.type,
    this.packageEntity,
    this.courseEntity,
    TextEditingController? descriptionController,
    TextEditingController? quantityController,
    TextEditingController? unitPriceController,
  })  : descriptionController = descriptionController ?? TextEditingController(),
        quantityController = quantityController ?? TextEditingController(text: '1'),
        unitPriceController = unitPriceController ?? TextEditingController(text: '0');

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
