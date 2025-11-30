import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_card.dart';
import 'add_student_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    try {
      await Provider.of<StudentProvider>(context, listen: false).getStudents(refresh: true);
    } catch (e) {
      if (e.toString().contains('Unauthorized') || e.toString().contains('401')) {
        // Navigate back to login if unauthorized
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    Provider.of<StudentProvider>(context, listen: false)
                        .getStudents(refresh: true);
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  Provider.of<StudentProvider>(context, listen: false)
                      .getStudents(refresh: true);
                } else {
                  Provider.of<StudentProvider>(context, listen: false)
                      .searchStudents(value);
                }
              },
            ),
          ),
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, studentProvider, child) {
                if (studentProvider.isLoading && studentProvider.students.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (studentProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${studentProvider.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            studentProvider.getStudents(refresh: true);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (studentProvider.students.isEmpty) {
                  return const Center(
                    child: Text('No students found'),
                  );
                }

                return ListView.builder(
                  itemCount: studentProvider.students.length +
                      (studentProvider.hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == studentProvider.students.length) {
                      if (studentProvider.hasMoreData) {
                        studentProvider.getStudents();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final student = studentProvider.students[index];
                    return StudentCard(student: student);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddStudentScreen(),
            ),
          ).then((_) {
            // Refresh the list after adding a new student
            Provider.of<StudentProvider>(context, listen: false)
                .getStudents(refresh: true);
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Student',
      ),
    );
  }
}