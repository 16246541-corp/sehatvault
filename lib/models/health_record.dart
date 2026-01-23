import 'package:hive/hive.dart';

part 'health_record.g.dart';

/// Base model for health record storage
@HiveType(typeId: 0)
class HealthRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? updatedAt;

  @HiveField(5)
  final String? filePath;

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final Map<String, dynamic>? metadata;

  HealthRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.filePath,
    this.notes,
    this.metadata,
  });

  HealthRecord copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? filePath,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      filePath: filePath ?? this.filePath,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Health record categories
enum HealthCategory {
  medicalRecords,
  labResults,
  prescriptions,
  vaccinations,
  insurance,
  other,
}

extension HealthCategoryExtension on HealthCategory {
  String get displayName {
    switch (this) {
      case HealthCategory.medicalRecords:
        return 'Medical Records';
      case HealthCategory.labResults:
        return 'Lab Results';
      case HealthCategory.prescriptions:
        return 'Prescriptions';
      case HealthCategory.vaccinations:
        return 'Vaccinations';
      case HealthCategory.insurance:
        return 'Insurance';
      case HealthCategory.other:
        return 'Other';
    }
  }
}
