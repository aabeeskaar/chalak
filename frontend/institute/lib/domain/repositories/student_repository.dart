import '../../core/utils/either.dart';
import '../entities/student_entity.dart';

abstract class StudentRepository {
  Future<EitherFailure<List<StudentEntity>>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
  });
  Future<EitherFailure<StudentEntity>> getStudentById(String id);
  Future<EitherFailure<StudentEntity>> createStudent(Map<String, dynamic> data);
  Future<EitherFailure<StudentEntity>> updateStudent(
    String id,
    Map<String, dynamic> data,
  );
  Future<EitherFailure<void>> deleteStudent(String id);
  Future<EitherFailure<String>> generateQRCode(String id);
}