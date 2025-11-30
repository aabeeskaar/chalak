import '../../../core/utils/either.dart';
import '../../entities/attendance_entity.dart';
import '../../repositories/attendance_repository.dart';

class GetAttendanceUseCase {
  final AttendanceRepository repository;

  GetAttendanceUseCase(this.repository);

  Future<EitherFailure<List<AttendanceEntity>>> call({
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getAttendance(
      studentId: studentId,
      startDate: startDate,
      endDate: endDate,
      page: page,
      limit: limit,
    );
  }
}