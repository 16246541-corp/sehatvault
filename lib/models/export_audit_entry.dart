import 'package:hive/hive.dart';

part 'export_audit_entry.g.dart';

@HiveType(typeId: 11)
class ExportAuditEntry extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String exportType; // 'transcript', 'follow_ups'

  @HiveField(2)
  final String format; // 'pdf', 'txt', 'json_enc'

  @HiveField(3)
  final String recipientType; // 'self', 'external'

  @HiveField(4)
  final String entityId; // Conversation ID or 'summary'

  ExportAuditEntry({
    required this.timestamp,
    required this.exportType,
    required this.format,
    required this.recipientType,
    required this.entityId,
  });
}
