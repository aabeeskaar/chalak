import '../../../core/utils/either.dart';
import '../../entities/student_entity.dart';
import '../../repositories/student_repository.dart';

class CreateStudentUseCase {
  final StudentRepository repository;

  CreateStudentUseCase(this.repository);

  Future<EitherFailure<StudentEntity>> call(Map<String, dynamic> data) async {
    return await repository.createStudent(data);
  }
}