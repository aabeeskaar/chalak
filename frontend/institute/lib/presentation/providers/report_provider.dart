import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/report_entity.dart';

class ReportProvider with ChangeNotifier {
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Quick stats
  QuickStats? _quickStats;

  // Reports
  AttendanceReport? _attendanceReport;
  FinancialReport? _financialReport;
  StudentReport? _studentReport;

  bool get isLoading => _isLoading;
  String? get error => _error;
  QuickStats? get quickStats => _quickStats;
  AttendanceReport? get attendanceReport => _attendanceReport;
  FinancialReport? get financialReport => _financialReport;
  StudentReport? get studentReport => _studentReport;

  void setToken(String token) {
    _token = token;
  }

  // Format date for API
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Get Quick Stats (for dashboard)
  Future<void> getQuickStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/reports/quick-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _quickStats = QuickStats.fromJson(data['data']);
        } else {
          _error = data['message'] ?? 'Failed to load quick stats';
        }
      } else {
        _error = 'Failed to load quick stats: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Attendance Report
  Future<void> getAttendanceReport(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reports/attendance').replace(
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _attendanceReport = AttendanceReport.fromJson(data['data']);
        } else {
          _error = data['message'] ?? 'Failed to load attendance report';
        }
      } else {
        _error = 'Failed to load attendance report: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Financial Report
  Future<void> getFinancialReport(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reports/financial').replace(
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _financialReport = FinancialReport.fromJson(data['data']);
        } else {
          _error = data['message'] ?? 'Failed to load financial report';
        }
      } else {
        _error = 'Failed to load financial report: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Student Report
  Future<void> getStudentReport(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reports/students').replace(
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _studentReport = StudentReport.fromJson(data['data']);
        } else {
          _error = data['message'] ?? 'Failed to load student report';
        }
      } else {
        _error = 'Failed to load student report: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all reports
  void clearReports() {
    _quickStats = null;
    _attendanceReport = null;
    _financialReport = null;
    _studentReport = null;
    _error = null;
    notifyListeners();
  }
}
