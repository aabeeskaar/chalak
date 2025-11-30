import '../../core/utils/either.dart';
import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<EitherFailure<List<CourseEntity>>> getCourses({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  });
  Future<EitherFailure<CourseEntity>> getCourseById(String id);
  Future<EitherFailure<CourseEntity>> getCourseByCode(String code);
  Future<EitherFailure<CourseEntity>> createCourse(Map<String, dynamic> data);
  Future<EitherFailure<CourseEntity>> updateCourse(
    String id,
    Map<String, dynamic> data,
  );
  Future<EitherFailure<void>> deleteCourse(String id);
}