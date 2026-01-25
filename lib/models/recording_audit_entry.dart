import 'package:hive/hive.dart';

part 'recording_audit_entry.g.dart';

@HiveType(typeId: 10)
class RecordingAuditEntry extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final Duration duration;

  @HiveField(2)
  final bool consentConfirmed;

  @HiveField(3)
  final String doctorName;

  @HiveField(4)
  final int fileSizeBytes;

  @HiveField(5)
  final String deviceId;

  RecordingAuditEntry({
    required this.timestamp,
    required this.duration,
    required this.consentConfirmed,
    required this.doctorName,
    required this.fileSizeBytes,
    required this.deviceId,
  });
}
