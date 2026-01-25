import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'consent_entry.g.dart';

@HiveType(typeId: 16)
class ConsentEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String templateId;

  @HiveField(2)
  final String version;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String userId;

  @HiveField(5)
  final String scope;

  @HiveField(6)
  final bool granted;

  @HiveField(7)
  final String contentHash;

  @HiveField(8)
  final String? deviceId;

  @HiveField(9)
  final String? ipAddress;

  @HiveField(10)
  final DateTime? revocationDate;

  @HiveField(11)
  final String? revocationReason;

  @HiveField(12)
  final String syncStatus;

  @HiveField(13)
  final DateTime? syncedAt;

  @HiveField(14)
  final DateTime? lastSyncAttempt;

  ConsentEntry({
    required this.id,
    required this.templateId,
    required this.version,
    required this.timestamp,
    required this.userId,
    required this.scope,
    required this.granted,
    required this.contentHash,
    this.deviceId,
    this.ipAddress,
    this.revocationDate,
    this.revocationReason,
    this.syncStatus = 'pending',
    this.syncedAt,
    this.lastSyncAttempt,
  });

  factory ConsentEntry.create({
    required String templateId,
    required String version,
    required String userId,
    required String scope,
    required bool granted,
    required String contentHash,
    String? deviceId,
    String? ipAddress,
    String syncStatus = 'pending',
    DateTime? syncedAt,
    DateTime? lastSyncAttempt,
  }) {
    return ConsentEntry(
      id: const Uuid().v4(),
      templateId: templateId,
      version: version,
      timestamp: DateTime.now(),
      userId: userId,
      scope: scope,
      granted: granted,
      contentHash: contentHash,
      deviceId: deviceId,
      ipAddress: ipAddress,
      syncStatus: syncStatus,
      syncedAt: syncedAt,
      lastSyncAttempt: lastSyncAttempt,
    );
  }

  ConsentEntry revoke(String reason) {
    return ConsentEntry(
      id: id,
      templateId: templateId,
      version: version,
      timestamp: timestamp,
      userId: userId,
      scope: scope,
      granted: false,
      contentHash: contentHash,
      deviceId: deviceId,
      ipAddress: ipAddress,
      revocationDate: DateTime.now(),
      revocationReason: reason,
      syncStatus: syncStatus,
      syncedAt: syncedAt,
      lastSyncAttempt: lastSyncAttempt,
    );
  }

  ConsentEntry markSynced(DateTime timestamp) {
    return ConsentEntry(
      id: id,
      templateId: templateId,
      version: version,
      timestamp: timestamp,
      userId: userId,
      scope: scope,
      granted: granted,
      contentHash: contentHash,
      deviceId: deviceId,
      ipAddress: ipAddress,
      revocationDate: revocationDate,
      revocationReason: revocationReason,
      syncStatus: 'synced',
      syncedAt: timestamp,
      lastSyncAttempt: timestamp,
    );
  }

  ConsentEntry markSyncAttempt(DateTime timestamp) {
    return ConsentEntry(
      id: id,
      templateId: templateId,
      version: version,
      timestamp: timestamp,
      userId: userId,
      scope: scope,
      granted: granted,
      contentHash: contentHash,
      deviceId: deviceId,
      ipAddress: ipAddress,
      revocationDate: revocationDate,
      revocationReason: revocationReason,
      syncStatus: syncStatus,
      syncedAt: syncedAt,
      lastSyncAttempt: timestamp,
    );
  }
}
