import 'package:flutter/material.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/usecases/student/get_students_usecase.dart';
import '../../domain/usecases/student/create_student_usecase.dart';

enum StudentState { initial, loading, loaded, error }

class StudentProvider extends ChangeNotifier {
  final GetStudentsUseCase getStudentsUseCase;
  final CreateStudentUseCase createStudentUseCase;

  StudentState _state = StudentState.initial;
  List<StudentEntity> _students = [];
  String? _errorMessage;
  bool _hasMoreData = true;
  int _currentPage = 1;

  StudentState get state => _state;
  List<StudentEntity> get students => _students;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isLoading => _state == StudentState.loading;

  StudentProvider({
    required this.getStudentsUseCase,
    required this.createStudentUseCase,
  });

  Future<void> getStudents({bool refresh = false, String? search}) async {
    if (refresh) {
      _currentPage = 1;
      _students.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    _setState(StudentState.loading);
    _errorMessage = null;

    final result = await getStudentsUseCase(
      page: _currentPage,
      search: search,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(StudentState.error);
      },
      (newStudents) {
        if (refresh) {
          _students = newStudents;
        } else {
          _students.addAll(newStudents);
        }

        if (newStudents.length < 20) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }

        _setState(StudentState.loaded);
      },
    );
  }

  Future<void> createStudent(Map<String, dynamic> data) async {
    _setState(StudentState.loading);
    _errorMessage = null;

    final result = await createStudentUseCase(data);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(StudentState.error);
      },
      (student) {
        _students.insert(0, student);
        _setState(StudentState.loaded);
      },
    );
  }

  void searchStudents(String query) {
    getStudents(refresh: true, search: query);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(StudentState newState) {
    _state = newState;
    notifyListeners();
  }
}