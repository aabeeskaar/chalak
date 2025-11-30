class StudentEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final DateTime dateOfBirth;
  final String? licenseNumber;
  final String? qrCode;
  final String? packageId;
  final String? instructorId;
  final String status;
  final DateTime enrollmentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    this.licenseNumber,
    this.qrCode,
    this.packageId,
    this.instructorId,
    required this.status,
    required this.enrollmentDate,
    required this.createdAt,
    required this.updatedAt,
  });
}