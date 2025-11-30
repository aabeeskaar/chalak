import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_remote_datasource.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentRemoteDataSource remoteDataSource;

  StudentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<EitherFailure<List<StudentEntity>>> getStudents({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final students = await remoteDataSource.getStudents(
        page: page,
        limit: limit,
        search: search,
      );
      return Right(students);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<StudentEntity>> getStudentById(String id) async {
    try {
      final student = await remoteDataSource.getStudentById(id);
      return Right(student);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<StudentEntity>> createStudent(Map<String, dynamic> data) async {
    try {
      final student = await remoteDataSource.createStudent(data);
      return Right(student);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<StudentEntity>> updateStudent(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final student = await remoteDataSource.updateStudent(id, data);
      return Right(student);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<void>> deleteStudent(String id) async {
    try {
      await remoteDataSource.deleteStudent(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<String>> generateQRCode(String id) async {
    try {
      final qrCode = await remoteDataSource.generateQRCode(id);
      return Right(qrCode);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}