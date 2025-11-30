import '../../domain/entities/package_entity.dart';
import '../../domain/entities/course_entity.dart';
import 'course_model.dart';

class PackageModel extends PackageEntity {
  const PackageModel({
    required String id,
    required String name,
    required String code,
    String? description,
    required int duration,
    required double price,
    required double discountPercentage,
    required bool isActive,
    required List<CourseEntity> courses,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super(
          id: id,
          name: name,
          code: code,
          description: description,
          duration: duration,
          price: price,
          discountPercentage: discountPercentage,
          isActive: isActive,
          courses: courses,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        );

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    List<CourseEntity> coursesList = [];
    if (json['courses'] != null) {
      final coursesJson = json['courses'] as List;
      coursesList = coursesJson.map((c) => CourseModel.fromJson(c)).toList();
    }

    return PackageModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      duration: json['duration'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      discountPercentage: (json['discount_percentage'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      courses: coursesList,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final courseIds = courses.map((c) => c.id).toList();

    return {
      'name': name,
      'code': code,
      'description': description,
      'duration': duration,
      'price': price,
      'discount_percentage': discountPercentage,
      'is_active': isActive,
      'course_ids': courseIds,
    };
  }
}
