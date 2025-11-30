import '../../../core/utils/either.dart';
import '../../entities/student_entity.dart';
import '../../repositories/student_repository.dart';

class GetStudentsUseCase {
  final StudentRepository repository;

  GetStudentsUseCase(this.repository);

  Future<EitherFailure<List<StudentEntity>>> call({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    return await repository.getStudents(
      page: page,
      limit: limit,
      search: search,
    );
  }
}