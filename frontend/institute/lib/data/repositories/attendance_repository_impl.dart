import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<EitherFailure<List<AttendanceEntity>>> getAttendance({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final attendance = await remoteDataSource.getAttendance(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
      return Right(attendance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<AttendanceEntity>> getAttendanceById(String id) async {
    try {
      final attendance = await remoteDataSource.getAttendanceById(id);
      return Right(attendance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<EitherFailure<AttendanceEntity>> markAttendance(
    String studentId,
    String status, {
    String? remarks,
  }) async {
    try {
      final attendance = await remoteDataSource.markAttendance(
        studentId,
        status,
        remarks: remarks,
      );
      return Right(attendance);
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
  Future<EitherFailure<List<AttendanceEntity>>> getAttendanceByStudent(
    String studentId,
  ) async {
    try {
      final attendance = await remoteDataSource.getAttendanceByStudent(studentId);
      return Right(attendance);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}