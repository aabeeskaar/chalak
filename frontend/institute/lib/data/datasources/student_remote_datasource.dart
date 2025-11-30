import '../../core/constants/api_constants.dart';
import '../../core/network/http_client.dart';
import '../models/student_model.dart';

abstract class StudentRemoteDataSource {
  Future<List<StudentModel>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
  });
  Future<StudentModel> getStudentById(String id);
  Future<StudentModel> createStudent(Map<String, dynamic> data);
  Future<StudentModel> updateStudent(String id, Map<String, dynamic> data);
  Future<void> deleteStudent(String id);
  Future<String> generateQRCode(String id);
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  final HttpClient httpClient;

  StudentRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<StudentModel>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    print('STUDENT_REMOTE_DATASOURCE DEBUG: getStudents() called with page: $page, limit: $limit, search: $search');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final endpoint = '${ApiConstants.students}?$queryString';
    print('STUDENT_REMOTE_DATASOURCE DEBUG: Making GET request to: $endpoint');

    try {
      final response = await httpClient.get(endpoint);
      print('STUDENT_REMOTE_DATASOURCE DEBUG: HTTP client returned response: $response');

      final List<dynamic> studentsJson = response['data'] ?? [];
      print('STUDENT_REMOTE_DATASOURCE DEBUG: Found ${studentsJson.length} students in response');

      final students = studentsJson.map((json) => StudentModel.fromJson(json)).toList();
      print('STUDENT_REMOTE_DATASOURCE DEBUG: Successfully parsed ${students.length} student models');

      return students;
    } catch (e) {
      print('STUDENT_REMOTE_DATASOURCE DEBUG: Exception in getStudents: $e');
      rethrow;
    }
  }

  @override
  Future<StudentModel> getStudentById(String id) async {
    final response = await httpClient.get(ApiConstants.getStudentById(id));
    return StudentModel.fromJson(response['data']);
  }

  @override
  Future<StudentModel> createStudent(Map<String, dynamic> data) async {
    final response = await httpClient.post(ApiConstants.students, data);
    return StudentModel.fromJson(response['data']);
  }

  @override
  Future<StudentModel> updateStudent(String id, Map<String, dynamic> data) async {
    final response = await httpClient.put(ApiConstants.getStudentById(id), data);
    return StudentModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await httpClient.delete(ApiConstants.getStudentById(id));
  }

  @override
  Future<String> generateQRCode(String id) async {
    final response = await httpClient.post('${ApiConstants.getStudentById(id)}/qr', {});
    return response['qr_code'];
  }
}