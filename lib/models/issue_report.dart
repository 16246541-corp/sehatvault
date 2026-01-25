import 'package:hive/hive.dart';

part 'issue_report.g.dart';

@HiveType(typeId: 15)
class IssueReport extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final Map<String, dynamic> deviceMetrics;

  @HiveField(4)
  final List<String> logLines;

  @HiveField(5)
  final bool isRedacted;

  @HiveField(6)
  final String status; // 'pending', 'submitted', 'exported'

  @HiveField(7)
  final String originalHash; // For ZKP/Verification

  @HiveField(8)
  final String redactedHash; // For ZKP/Verification

  IssueReport({
    required this.id,
    required this.timestamp,
    required this.description,
    required this.deviceMetrics,
    required this.logLines,
    this.isRedacted = true,
    this.status = 'pending',
    required this.originalHash,
    required this.redactedHash,
  });
}
