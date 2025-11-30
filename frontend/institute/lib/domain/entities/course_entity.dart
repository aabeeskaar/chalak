class CourseEntity {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int duration; // Duration in hours
  final double fee;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const CourseEntity({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.duration,
    required this.fee,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}