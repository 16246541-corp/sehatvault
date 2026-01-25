import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:io';
import '../models/auth_audit_entry.dart';
import 'local_storage_service.dart';
import 'local_audit_service.dart';
import 'session_manager.dart';

class AuthAuditService {
  final LocalStorageService _storageService;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();

  AuthAuditService(this._storageService);

  // Constants
  static const int _maxEntries = 100;

  /// Log an authentication event
  Future<void> logEvent({
    required String action,
    required bool success,
    String? failureReason,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final batteryLevel = await _getBatteryLevel();

      final entry = AuthAuditEntry(
        timestamp: DateTime.now(),
        action: action,
        success: success,
        failureReason: failureReason,
        deviceId: deviceId,
        batteryLevel: batteryLevel,
      );

      await _storageService.saveAuthAuditEntry(entry);
      await _pruneEntries();

      final localAuditService =
          LocalAuditService(_storageService, SessionManager());
      await localAuditService.log(
        action: action,
        details: {
          'success': success.toString(),
          'failureReason': failureReason ?? '',
          'deviceId': deviceId,
          'batteryLevel': batteryLevel.toString(),
        },
        sensitivity: success ? 'info' : 'warning',
      );

      if (!success) {
        _checkSuspiciousActivity();
      }
    } catch (e) {
      debugPrint('Failed to log auth event: $e');
    }
  }

  /// Get recent events
  List<AuthAuditEntry> getRecentEvents() {
    final events = _storageService.getAllAuthAuditEntries();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  /// Prune entries to keep only the last 100
  Future<void> _pruneEntries() async {
    final allEntries = _storageService.getAllAuthAuditEntries();
    if (allEntries.length > _maxEntries) {
      // Sort by timestamp descending (newest first)
      allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Keep first 100, delete the rest
      final entriesToDelete = allEntries.sublist(_maxEntries);
      for (var entry in entriesToDelete) {
        await entry.delete();
      }
    }
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id; // unique ID on Android
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }
      return 'unknown_platform';
    } catch (e) {
      return 'error_getting_device_id';
    }
  }

  Future<int> _getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return -1;
    }
  }

  void _checkSuspiciousActivity() {
    // Logic to check for multiple failures
    final events = getRecentEvents();
    // Filter failures in the last 10 minutes
    final recentFailures = events
        .where((e) =>
            !e.success &&
            e.timestamp
                .isAfter(DateTime.now().subtract(const Duration(minutes: 10))))
        .toList();

    if (recentFailures.length >= 3) {
      // Trigger alert
      debugPrint(
          'ALERT: ${recentFailures.length} failed auth attempts in last 10 minutes');
    }

    // Off-hours access (e.g., 11 PM to 5 AM)
    final now = DateTime.now();
    if (now.hour < 5 || now.hour > 23) {
      debugPrint('ALERT: Off-hours access detected');
    }
  }
}
