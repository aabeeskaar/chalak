class UserEntity {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    required this.createdAt,
  });
}