import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

part 'local_audit_entry.g.dart';

@HiveType(typeId: 17)
class LocalAuditEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String action;

  @HiveField(3)
  final Map<String, String> details;

  @HiveField(4)
  final String previousHash;

  @HiveField(5)
  final String hash;

  @HiveField(6)
  final String? sessionId;

  @HiveField(7)
  final String sensitivity;

  LocalAuditEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.details,
    required this.previousHash,
    required this.hash,
    this.sessionId,
    this.sensitivity = 'info',
  });

  static String generateHash({
    required String id,
    required DateTime timestamp,
    required String action,
    required Map<String, String> details,
    required String previousHash,
    String? sessionId,
  }) {
    final sortedKeys = details.keys.toList()..sort();
    final normalizedDetails = <String, String>{
      for (final key in sortedKeys) key: details[key] ?? ''
    };
    final content =
        '$id|${timestamp.toIso8601String()}|$action|${jsonEncode(normalizedDetails)}|$previousHash|$sessionId';
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  bool verifyHash() {
    final calculatedHash = generateHash(
      id: id,
      timestamp: timestamp,
      action: action,
      details: details,
      previousHash: previousHash,
      sessionId: sessionId,
    );
    return calculatedHash == hash;
  }
}
