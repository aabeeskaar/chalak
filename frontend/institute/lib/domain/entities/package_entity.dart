import 'course_entity.dart';

class PackageEntity {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int duration; // Duration in days
  final double price;
  final double discountPercentage;
  final bool isActive;
  final List<CourseEntity> courses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PackageEntity({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.duration,
    required this.price,
    required this.discountPercentage,
    required this.isActive,
    required this.courses,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  double get finalPrice {
    if (discountPercentage > 0) {
      return price - (price * discountPercentage / 100);
    }
    return price;
  }

  bool get hasDiscount => discountPercentage > 0;
}
