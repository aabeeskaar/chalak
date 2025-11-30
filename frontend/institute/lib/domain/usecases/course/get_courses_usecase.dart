import '../../../core/utils/either.dart';
import '../../entities/course_entity.dart';
import '../../repositories/course_repository.dart';

class GetCoursesUseCase {
  final CourseRepository repository;

  GetCoursesUseCase(this.repository);

  Future<EitherFailure<List<CourseEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    return await repository.getCourses(
      page: page,
      limit: limit,
      search: search,
      isActive: isActive,
    );
  }
}