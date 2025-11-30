import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/course_entity.dart';
import '../../providers/course_provider.dart';

class CourseFormScreen extends StatefulWidget {
  final CourseEntity? course;

  const CourseFormScreen({Key? key, this.course}) : super(key: key);

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _feeController;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.course?.name ?? '');
    _codeController = TextEditingController(text: widget.course?.code ?? '');
    _descriptionController = TextEditingController(text: widget.course?.description ?? '');
    _durationController = TextEditingController(text: widget.course?.duration.toString() ?? '');
    _feeController = TextEditingController(text: widget.course?.fee.toString() ?? '');
    _isActive = widget.course?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.course != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Course' : 'Add Course'),
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
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course name';
                  }
                  if (value.trim().length < 3) {
                    return 'Course name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'e.g., DRV-101',
                ),
                enabled: !isEdit, // Code cannot be changed after creation
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course code';
                  }
                  if (value.trim().length < 2) {
                    return 'Course code must be at least 2 characters';
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
                  labelText: 'Duration (hours)',
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
                controller: _feeController,
                decoration: const InputDecoration(
                  labelText: 'Fee',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter fee';
                  }
                  final fee = double.tryParse(value);
                  if (fee == null || fee < 0) {
                    return 'Fee must be a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Course is available for enrollment'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCourse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update Course' : 'Create Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = {
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'duration': int.parse(_durationController.text),
      'fee': double.parse(_feeController.text),
      'is_active': _isActive,
    };

    final provider = context.read<CourseProvider>();

    if (widget.course != null) {
      await provider.updateCourse(widget.course!.id, data);
    } else {
      await provider.createCourse(data);
    }

    setState(() {
      _isLoading = false;
    });

    if (provider.state == CourseState.error) {
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
            content: Text(widget.course != null
                ? 'Course updated successfully'
                : 'Course created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
