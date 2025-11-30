import '../../../core/utils/either.dart';
import '../../entities/attendance_entity.dart';
import '../../repositories/attendance_repository.dart';

class MarkAttendanceUseCase {
  final AttendanceRepository repository;

  MarkAttendanceUseCase(this.repository);

  Future<EitherFailure<AttendanceEntity>> call(
    String studentId,
    String status, {
    String? remarks,
  }) async {
    return await repository.markAttendance(
      studentId,
      status,
      remarks: remarks,
    );
  }
}