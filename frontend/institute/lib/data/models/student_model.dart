import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String address,
    required DateTime dateOfBirth,
    String? licenseNumber,
    String? qrCode,
    String? packageId,
    String? instructorId,
    required String status,
    required DateTime enrollmentDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          name: name,
          email: email,
          phone: phone,
          address: address,
          dateOfBirth: dateOfBirth,
          licenseNumber: licenseNumber,
          qrCode: qrCode,
          packageId: packageId,
          instructorId: instructorId,
          status: status,
          enrollmentDate: enrollmentDate,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    try {
      print('STUDENT_MODEL DEBUG: Parsing JSON: $json');

      final id = json['id']?.toString() ?? '';
      final firstName = json['first_name']?.toString() ?? '';
      final lastName = json['last_name']?.toString() ?? '';
      final name = '$firstName $lastName'.trim();
      final email = json['email']?.toString() ?? '';
      final phone = json['phone']?.toString() ?? '';
      final address = json['address']?.toString() ?? '';
      final status = json['status']?.toString() ?? 'active';

      print('STUDENT_MODEL DEBUG: Parsed basic fields - id: $id, name: $name, email: $email');

      final dateOfBirthStr = json['date_of_birth']?.toString();
      final enrolledAtStr = json['enrolled_at']?.toString();
      final createdAtStr = json['created_at']?.toString();
      final updatedAtStr = json['updated_at']?.toString();

      print('STUDENT_MODEL DEBUG: Date strings - dob: $dateOfBirthStr, enrolled: $enrolledAtStr');

      final dateOfBirth = dateOfBirthStr != null ? DateTime.parse(dateOfBirthStr) : DateTime.now();
      final enrollmentDate = enrolledAtStr != null ? DateTime.parse(enrolledAtStr) : DateTime.now();
      final createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
      final updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now();

      print('STUDENT_MODEL DEBUG: About to create StudentModel instance');

      return StudentModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        licenseNumber: json['license_number']?.toString(),
        qrCode: json['qr_code']?.toString(),
        packageId: json['package_id']?.toString(),
        instructorId: json['instructor_id']?.toString(),
        status: status,
        enrollmentDate: enrollmentDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('STUDENT_MODEL DEBUG: Error creating StudentModel: $e');
      print('STUDENT_MODEL DEBUG: JSON was: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'license_number': licenseNumber,
      'qr_code': qrCode,
      'package_id': packageId,
      'instructor_id': instructorId,
      'status': status,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}