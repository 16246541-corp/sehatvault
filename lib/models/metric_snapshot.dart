import 'package:hive/hive.dart';

part 'metric_snapshot.g.dart';

/// Represents a snapshot of a health metric with source attribution.
/// 
/// This model stores the latest verified value for a specific health metric
/// with complete audit trail information for FDA compliance.
@HiveType(typeId: 68)
class MetricSnapshot extends HiveObject {
  @HiveField(0)
  final String metricName; // e.g., "ldl_cholesterol"

  @HiveField(1)
  final double value;

  @HiveField(2)
  final String unit;

  @HiveField(3)
  final DateTime measuredAt; // From document date

  @HiveField(4)
  final String sourceRecordId; // HealthRecord.id for audit trail

  @HiveField(5)
  final bool isOutsideReference; // From ReferenceRangeService ONLY – no interpretation

  @HiveField(6)
  final DateTime createdAt;

  MetricSnapshot({
    required this.metricName,
    required this.value,
    required this.unit,
    required this.measuredAt,
    required this.sourceRecordId,
    required this.isOutsideReference,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  MetricSnapshot copyWith({
    String? metricName,
    double? value,
    String? unit,
    DateTime? measuredAt,
    String? sourceRecordId,
    bool? isOutsideReference,
    DateTime? createdAt,
  }) {
    return MetricSnapshot(
      metricName: metricName ?? this.metricName,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      measuredAt: measuredAt ?? this.measuredAt,
      sourceRecordId: sourceRecordId ?? this.sourceRecordId,
      isOutsideReference: isOutsideReference ?? this.isOutsideReference,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}