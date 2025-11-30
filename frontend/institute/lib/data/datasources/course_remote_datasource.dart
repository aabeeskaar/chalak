import '../../core/network/http_client.dart';
import '../models/course_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  });
  Future<CourseModel> getCourseById(String id);
  Future<CourseModel> getCourseByCode(String code);
  Future<CourseModel> createCourse(Map<String, dynamic> data);
  Future<CourseModel> updateCourse(String id, Map<String, dynamic> data);
  Future<void> deleteCourse(String id);
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final HttpClient httpClient;

  CourseRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<List<CourseModel>> getCourses({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await httpClient.get('/courses?$queryString');

    // Backend returns paginated response with 'data' field
    final List<dynamic> coursesJson = response['data'] ?? [];
    return coursesJson.map((json) => CourseModel.fromJson(json)).toList();
  }

  @override
  Future<CourseModel> getCourseById(String id) async {
    final response = await httpClient.get('/courses/$id');
    return CourseModel.fromJson(response['data']);
  }

  @override
  Future<CourseModel> getCourseByCode(String code) async {
    final response = await httpClient.get('/courses/code/$code');
    return CourseModel.fromJson(response['data']);
  }

  @override
  Future<CourseModel> createCourse(Map<String, dynamic> data) async {
    final response = await httpClient.post('/courses', data);
    return CourseModel.fromJson(response['data']);
  }

  @override
  Future<CourseModel> updateCourse(String id, Map<String, dynamic> data) async {
    final response = await httpClient.put('/courses/$id', data);
    return CourseModel.fromJson(response['data']);
  }

  @override
  Future<void> deleteCourse(String id) async {
    await httpClient.delete('/courses/$id');
  }
}