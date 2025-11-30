import '../../../core/utils/either.dart';
import '../../entities/course_entity.dart';
import '../../repositories/course_repository.dart';

class UpdateCourseUseCase {
  final CourseRepository repository;

  UpdateCourseUseCase(this.repository);

  Future<EitherFailure<CourseEntity>> call(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await repository.updateCourse(id, data);
  }
}