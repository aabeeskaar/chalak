import 'package:flutter/material.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/usecases/attendance/get_attendance_usecase.dart';
import '../../domain/usecases/attendance/mark_attendance_usecase.dart';

enum AttendanceState { initial, loading, loaded, error }

class AttendanceProvider extends ChangeNotifier {
  final GetAttendanceUseCase getAttendanceUseCase;
  final MarkAttendanceUseCase markAttendanceUseCase;

  AttendanceState _state = AttendanceState.initial;
  List<AttendanceEntity> _attendance = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMoreData = true;

  AttendanceState get state => _state;
  List<AttendanceEntity> get attendance => _attendance;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AttendanceState.loading;
  bool get hasMoreData => _hasMoreData;

  AttendanceProvider({
    required this.getAttendanceUseCase,
    required this.markAttendanceUseCase,
  });

  Future<void> getAttendance({
    bool refresh = false,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _attendance.clear();
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    _setState(AttendanceState.loading);
    _errorMessage = null;

    final result = await getAttendanceUseCase(
      page: _currentPage,
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AttendanceState.error);
      },
      (newAttendance) {
        if (refresh) {
          _attendance = newAttendance;
        } else {
          _attendance.addAll(newAttendance);
        }

        // If less than 20 records returned, no more data
        if (newAttendance.length < 20) {
          _hasMoreData = false;
        } else {
          _currentPage++;
        }

        _setState(AttendanceState.loaded);
      },
    );
  }

  Future<void> markAttendance(
    String studentId,
    String status, {
    String? remarks,
  }) async {
    _setState(AttendanceState.loading);
    _errorMessage = null;

    final result = await markAttendanceUseCase(
      studentId,
      status,
      remarks: remarks,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(AttendanceState.error);
      },
      (attendance) {
        _attendance.insert(0, attendance);
        _setState(AttendanceState.loaded);
      },
    );
  }

  void filterByStudent(String studentId) {
    getAttendance(refresh: true, studentId: studentId);
  }

  void filterByDateRange(DateTime startDate, DateTime endDate) {
    getAttendance(refresh: true, startDate: startDate, endDate: endDate);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setState(AttendanceState newState) {
    _state = newState;
    notifyListeners();
  }
}