import '../../domain/entities/attendance_entity.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required String id,
    required String studentId,
    String? studentFirstName,
    String? studentLastName,
    String? instructorId,
    required DateTime date,
    required String status,
    String? remarks,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    required DateTime createdAt,
  }) : super(
          id: id,
          studentId: studentId,
          studentFirstName: studentFirstName,
          studentLastName: studentLastName,
          instructorId: instructorId,
          date: date,
          status: status,
          remarks: remarks,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
          createdAt: createdAt,
        );

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      studentId: json['student_id'] ?? '',
      studentFirstName: json['student_first_name'],
      studentLastName: json['student_last_name'],
      instructorId: json['instructor_id'],
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'absent',
      remarks: json['notes'], // Backend uses 'notes' not 'remarks'
      checkInTime: json['check_in_at'] != null
          ? DateTime.parse(json['check_in_at'])
          : null,
      checkOutTime: json['check_out_at'] != null
          ? DateTime.parse(json['check_out_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'instructor_id': instructorId,
      'date': date.toIso8601String(),
      'status': status,
      'notes': remarks, // Backend uses 'notes' not 'remarks'
      'check_in_at': checkInTime?.toIso8601String(),
      'check_out_at': checkOutTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}