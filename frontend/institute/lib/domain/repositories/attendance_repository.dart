import '../../core/utils/either.dart';
import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  Future<EitherFailure<List<AttendanceEntity>>> getAttendance({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });
  Future<EitherFailure<AttendanceEntity>> getAttendanceById(String id);
  Future<EitherFailure<AttendanceEntity>> markAttendance(
    String studentId,
    String status, {
    String? remarks,
  });
  Future<EitherFailure<List<AttendanceEntity>>> getAttendanceByStudent(
    String studentId,
  );
}