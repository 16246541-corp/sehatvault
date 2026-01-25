import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'follow_up_reminder_service.dart';
import '../models/app_settings.dart';
import 'local_storage_service.dart';

/// Service for managing desktop-specific notifications with grouping, actions, and rate limiting.
class DesktopNotificationService extends FollowUpReminderService {
  static final DesktopNotificationService _instance =
      DesktopNotificationService.internal();

  factory DesktopNotificationService() => _instance;

  @visibleForTesting
  DesktopNotificationService.internal() : super.internal();

  static const MethodChannel _desktopChannel =
      MethodChannel('com.sehatlocker/desktop_notifications');

  // Rate limiting state
  final Map<String, DateTime> _lastNotificationTimes = {};
  static const Duration _rateLimitWindow = Duration(seconds: 5);
  final Map<String, VoidCallback> _actionCallbacks = {};

  // Grouping keys (Thread Identifiers for macOS/iOS, Group Keys for Android)
  static const String groupStorage = 'storage_alerts';
  static const String groupModel = 'model_status';
  static const String groupRecording = 'recording_status';
  static const String groupGeneral = 'general_alerts';

  @override
  Future<void> initialize() async {
    if (isInitialized) return;

    // Initialize the base local notifications service
    await super.initialize();

    // Set up action callback handling
    _setupActionHandlers();

    isInitialized = true;
  }

  /// Sets up handlers for notification actions.
  void _setupActionHandlers() {
    notificationsPlugin.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        macOS: DarwinInitializationSettings(
          notificationCategories: [
            DarwinNotificationCategory(
              'desktop_actions',
              actions: [], // Actions are added dynamically in showDesktopNotification
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final actionId = response.actionId;
        if (actionId != null && _actionCallbacks.containsKey(actionId)) {
          _actionCallbacks[actionId]!();
        }
      },
    );
  }

  /// Registers a callback for a specific notification action.
  void registerActionCallback(String actionId, VoidCallback callback) {
    _actionCallbacks[actionId] = callback;
  }

  /// Checks if the system is in "Do Not Disturb" mode.
  /// Uses platform-specific implementation via MethodChannel.
  Future<bool> isDoNotDisturbEnabled() async {
    if (kIsWeb) return false;
    try {
      final bool? isDnd =
          await _desktopChannel.invokeMethod<bool>('isDoNotDisturbEnabled');
      return isDnd ?? false;
    } catch (e) {
      debugPrint('Error detecting DND mode: $e');
      return false;
    }
  }

  @visibleForTesting
  AppSettings? debugSettings;

  /// Shows a desktop notification with advanced features.
  Future<void> showDesktopNotification({
    required String id,
    required String title,
    required String body,
    String groupKey = groupGeneral,
    List<NotificationAction>? actions,
    bool sensitive = false,
    Importance importance = Importance.max,
    Priority priority = Priority.high,
  }) async {
    final settings = debugSettings ?? LocalStorageService().getAppSettings();
    if (!settings.notificationsEnabled) return;

    if (await isDoNotDisturbEnabled()) return;

    final now = DateTime.now();
    if (_lastNotificationTimes.containsKey(id) &&
        now.difference(_lastNotificationTimes[id]!) < _rateLimitWindow) {
      return;
    }
    _lastNotificationTimes[id] = now;

    String displayTitle = title;
    String displayBody = body;

    if (sensitive && settings.enhancedPrivacySettings.maskNotifications) {
      displayTitle = 'Sehat Locker Notification';
      displayBody = 'Privacy mode is active. Open app to view details.';
    }

    final List<DarwinNotificationAction> darwinActions = actions
            ?.map((a) => DarwinNotificationAction.plain(a.id, a.label))
            .toList() ??
        [];

    final DarwinNotificationDetails macOSDetails = DarwinNotificationDetails(
      threadIdentifier: groupKey,
      categoryIdentifier: darwinActions.isNotEmpty ? 'desktop_actions' : null,
    );

    final List<AndroidNotificationAction> androidActions = actions
            ?.map((a) => AndroidNotificationAction(a.id, a.label))
            .toList() ??
        [];

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'desktop_notifications',
      'Desktop Notifications',
      groupKey: groupKey,
      actions: androidActions,
    );

    final NotificationDetails details = NotificationDetails(
      macOS: macOSDetails,
      android: androidDetails,
    );

    // Register macOS category if actions exist
    if (darwinActions.isNotEmpty) {
      final DarwinInitializationSettings macOS = DarwinInitializationSettings(
        notificationCategories: [
          DarwinNotificationCategory(
            'desktop_actions',
            actions: darwinActions,
          ),
        ],
      );
      // Note: Re-initializing plugin just to update categories might be overkill,
      // but DarwinInitializationSettings doesn't have a way to update categories dynamically easily
      // without re-requesting permissions usually.
      // For now, we assume it's set up or we'd need a more global initialization.
    }

    await notificationsPlugin.show(
      id.hashCode,
      displayTitle,
      displayBody,
      details,
      payload: id,
    );

    // Accessibility support
    if (settings.accessibilityEnabled) {
      SemanticsService.announce(
          '$displayTitle: $displayBody', TextDirection.ltr);
    }

    debugPrint('Notification shown: $id');
  }

  /// Specialized notification for storage alerts.
  Future<void> showStorageAlert({
    required String title,
    required String message,
    bool isCritical = false,
  }) async {
    await showDesktopNotification(
      id: 'storage_alert',
      title: title,
      body: message,
      groupKey: groupStorage,
      importance: isCritical ? Importance.max : Importance.defaultImportance,
      priority: isCritical ? Priority.high : Priority.defaultPriority,
    );
  }

  /// Specialized notification for recording status.
  Future<void> showRecordingNotification({
    required String title,
    required String message,
    bool sensitive = true,
  }) async {
    await showDesktopNotification(
      id: 'recording_status',
      title: title,
      body: message,
      groupKey: groupRecording,
      sensitive: sensitive,
    );
  }

  /// Specialized notification for AI model status.
  Future<void> showModelStatus({
    required String title,
    required String message,
    bool isError = false,
  }) async {
    await showDesktopNotification(
      id: 'model_status',
      title: title,
      body: message,
      groupKey: groupModel,
      importance: isError ? Importance.high : Importance.low,
    );
  }
}

/// Helper class for notification actions.
class NotificationAction {
  final String id;
  final String label;

  NotificationAction({
    required this.id,
    required this.label,
  });
}
