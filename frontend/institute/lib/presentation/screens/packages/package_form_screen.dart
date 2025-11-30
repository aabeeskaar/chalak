import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/course_entity.dart';
import '../../providers/package_provider.dart';
import '../../providers/course_provider.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageEntity? package;

  const PackageFormScreen({Key? key, this.package}) : super(key: key);

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  bool _isActive = true;
  bool _isLoading = false;
  List<String> _selectedCourseIds = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name ?? '');
    _codeController = TextEditingController(text: widget.package?.code ?? '');
    _descriptionController = TextEditingController(text: widget.package?.description ?? '');
    _durationController = TextEditingController(text: widget.package?.duration.toString() ?? '');
    _priceController = TextEditingController(text: widget.package?.price.toString() ?? '');
    _discountController = TextEditingController(text: widget.package?.discountPercentage.toString() ?? '0');
    _isActive = widget.package?.isActive ?? true;
    _selectedCourseIds = widget.package?.courses.map((c) => c.id).toList() ?? [];

    // Load courses for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().getCourses(refresh: true);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.package != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Package' : 'Add Package'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Package Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter package name';
                  }
                  if (value.trim().length < 3) {
                    return 'Package name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Package Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'e.g., PKG-001',
                ),
                enabled: !isEdit, // Code cannot be changed after creation
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter package code';
                  }
                  if (value.trim().length < 2) {
                    return 'Package code must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter duration';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Duration must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return 'Price must be a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount Percentage',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                  hintText: '0-100',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Optional field
                  }
                  final discount = double.tryParse(value);
                  if (discount == null || discount < 0 || discount > 100) {
                    return 'Discount must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Consumer<CourseProvider>(
                builder: (context, courseProvider, child) {
                  if (courseProvider.courses.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No courses available. Please add courses first.'),
                      ),
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Courses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...courseProvider.courses.map((course) {
                            final isSelected = _selectedCourseIds.contains(course.id);
                            return CheckboxListTile(
                              title: Text(course.name),
                              subtitle: Text(course.code),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedCourseIds.add(course.id);
                                  } else {
                                    _selectedCourseIds.remove(course.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Package is available for purchase'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePackage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update Package' : 'Create Package'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = {
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'duration': int.parse(_durationController.text),
      'price': double.parse(_priceController.text),
      'discount_percentage': double.parse(_discountController.text.isEmpty ? '0' : _discountController.text),
      'is_active': _isActive,
      'course_ids': _selectedCourseIds,
    };

    final provider = context.read<PackageProvider>();

    if (widget.package != null) {
      await provider.updatePackage(widget.package!.id, data);
    } else {
      await provider.createPackage(data);
    }

    setState(() {
      _isLoading = false;
    });

    if (provider.state == PackageState.error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.package != null
                ? 'Package updated successfully'
                : 'Package created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
