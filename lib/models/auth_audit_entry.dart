import 'package:hive/hive.dart';

part 'auth_audit_entry.g.dart';

@HiveType(typeId: 13)
class AuthAuditEntry extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String action; // 'view_recording', 'export_data', 'change_settings'

  @HiveField(2)
  final bool success;

  @HiveField(3)
  final String? failureReason;

  @HiveField(4)
  final String deviceId;

  @HiveField(5)
  final int batteryLevel;

  AuthAuditEntry({
    required this.timestamp,
    required this.action,
    required this.success,
    this.failureReason,
    required this.deviceId,
    required this.batteryLevel,
  });
}
