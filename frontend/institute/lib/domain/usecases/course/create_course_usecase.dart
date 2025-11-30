import '../../../core/utils/either.dart';
import '../../entities/course_entity.dart';
import '../../repositories/course_repository.dart';

class CreateCourseUseCase {
  final CourseRepository repository;

  CreateCourseUseCase(this.repository);

  Future<EitherFailure<CourseEntity>> call(Map<String, dynamic> data) async {
    return await repository.createCourse(data);
  }
}