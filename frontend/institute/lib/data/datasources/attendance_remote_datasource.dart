import '../../core/constants/api_constants.dart';
import '../../core/network/http_client.dart';
import '../models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceModel>> getAttendance({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  Future<AttendanceModel> getAttendanceById(String id);
  Future<AttendanceModel> markAttendance(
    String studentId,
    String status, {
    String? remarks,
  });
  Future<List<AttendanceModel>> getAttendanceByStudent(String studentId);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final HttpClient httpClient;

  AttendanceRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<AttendanceModel>> getAttendance({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (studentId != null) queryParams['student_id'] = studentId;
    if (startDate != null) {
      // Format date as YYYY-MM-DD to match backend expectations
      final dateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      queryParams['date_from'] = dateStr;
    }
    if (endDate != null) {
      // Format date as YYYY-MM-DD to match backend expectations
      final dateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      queryParams['date_to'] = dateStr;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await httpClient.get('${ApiConstants.attendance}?$queryString');

    final List<dynamic> attendanceJson = response['data'] ?? [];
    return attendanceJson.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  @override
  Future<AttendanceModel> getAttendanceById(String id) async {
    final response = await httpClient.get(ApiConstants.getAttendanceById(id));
    return AttendanceModel.fromJson(response);
  }

  @override
  Future<AttendanceModel> markAttendance(
    String studentId,
    String status, {
    String? remarks,
  }) async {
    final now = DateTime.now();
    final data = {
      'student_id': studentId,
      'class_id': '550e8400-e29b-41d4-a716-446655440000', // Default class ID
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T00:00:00Z',
      'status': status,
      if (remarks != null && remarks.isNotEmpty) 'notes': remarks,
    };

    final response = await httpClient.post(ApiConstants.markAttendance, data);
    return AttendanceModel.fromJson(response);
  }

  @override
  Future<List<AttendanceModel>> getAttendanceByStudent(String studentId) async {
    final response = await httpClient.get(ApiConstants.getAttendanceByStudent(studentId));

    final List<dynamic> attendanceJson = response['data'] ?? [];
    return attendanceJson.map((json) => AttendanceModel.fromJson(json)).toList();
  }
}