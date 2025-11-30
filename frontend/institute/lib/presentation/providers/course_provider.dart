import 'package:flutter/material.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/course/get_courses_usecase.dart';
import '../../domain/usecases/course/create_course_usecase.dart';
import '../../domain/usecases/course/update_course_usecase.dart';

enum CourseState { initial, loading, loaded, error }

class CourseProvider extends ChangeNotifier {
  final GetCoursesUseCase getCoursesUseCase;
  final CreateCourseUseCase createCourseUseCase;
  final UpdateCourseUseCase updateCourseUseCase;

  CourseState _state = CourseState.initial;
  List<CourseEntity> _courses = [];
  String? _errorMessage;
  bool _hasMoreData = true;
  int _currentPage = 1;

  CourseState get state => _state;
  List<CourseEntity> get courses => _courses;
  String? get errorMessage => _errorMessage;
  bool get hasMoreData => _hasMoreData;
  bool get isLoading => _state == CourseState.loading;

  CourseProvider({
    required this.getCoursesUseCase,
    required this.createCourseUseCase,
    required this.updateCourseUseCase,
  });

  Future<void> getCourses({
    bool refresh = false,
    String? search,
    bool? isActive,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _courses.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    _setState(CourseState.loading);
    _errorMessage = null;

    final result = await getCoursesUseCase(
      page: _currentPage,
      search: search,
      isActive: isActive,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(CourseState.error);
      },
      (newCourses) {
        if (refresh) {
          _courses = newCourses;
        } else {
          _courses.addAll(newCourses);
        }

        if (newCourses.length < 20) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }

        _setState(CourseState.loaded);
      },
    );
  }

  Future<void> createCourse(Map<String, dynamic> data) async {
    _setState(CourseState.loading);
    _errorMessage = null;

    final result = await createCourseUseCase(data);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(CourseState.error);
      },
      (course) {
        _courses.insert(0, course);
        _setState(CourseState.loaded);
      },
    );
  }

  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    _setState(CourseState.loading);
    _errorMessage = null;

    final result = await updateCourseUseCase(id, data);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(CourseState.error);
      },
      (updatedCourse) {
        final index = _courses.indexWhere((course) => course.id == id);
        if (index != -1) {
          _courses[index] = updatedCourse;
        }
        _setState(CourseState.loaded);
      },
    );
  }

  void searchCourses(String query) {
    getCourses(refresh: true, search: query);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(CourseState newState) {
    _state = newState;
    notifyListeners();
  }
}