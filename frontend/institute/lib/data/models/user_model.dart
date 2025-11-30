import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    required String name,
    required String role,
    String? phone,
    required DateTime createdAt,
  }) : super(
          id: id,
          email: email,
          name: name,
          role: role,
          phone: phone,
          createdAt: createdAt,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Combine first_name and last_name to create name
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';
    final name = '$firstName $lastName'.trim();

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: name.isNotEmpty ? name : (json['name'] ?? 'User'),
      role: json['role'] ?? '',
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }
}