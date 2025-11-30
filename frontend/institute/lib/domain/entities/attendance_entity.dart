class AttendanceEntity {
  final String id;
  final String studentId;
  final String? studentFirstName;
  final String? studentLastName;
  final String? instructorId;
  final DateTime date;
  final String status;
  final String? remarks;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime createdAt;

  const AttendanceEntity({
    required this.id,
    required this.studentId,
    this.studentFirstName,
    this.studentLastName,
    this.instructorId,
    required this.date,
    required this.status,
    this.remarks,
    this.checkInTime,
    this.checkOutTime,
    required this.createdAt,
  });

  String get fullName {
    if (studentFirstName != null && studentLastName != null) {
      return '$studentFirstName $studentLastName';
    }
    return studentId; // Fallback to ID if names not available
  }
}