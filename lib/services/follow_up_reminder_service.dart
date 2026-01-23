import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/follow_up_item.dart';

class FollowUpReminderService {
  static final FollowUpReminderService _instance =
      FollowUpReminderService._internal();

  factory FollowUpReminderService() => _instance;

  FollowUpReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iOSImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iOSImplementation != null) {
      await iOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final macOSImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>();

    if (macOSImplementation != null) {
      await macOSImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleReminder(FollowUpItem item) async {
    if (item.dueDate == null || item.isCompleted) {
      await cancelReminder(item.id);
      return;
    }

    final dueDate = item.dueDate!;
    if (dueDate.isBefore(DateTime.now())) {
      // Don't schedule for past dates unless it's recurring?
      // For now, skip past dates for one-time events.
      if (item.frequency == null) return;
    }

    // Schedule on due date
    await _scheduleNotification(
      id: item.id.hashCode,
      title: 'Reminder: ${item.structuredTitle}',
      body: item.description,
      scheduledDate: dueDate,
      payload: item.id,
      matchComponents: _getMatchComponents(item.frequency),
    );

    // Schedule 1 day before (only if not recurring daily, as that would be redundant/confusing)
    // Actually, requirement says "Remind 1 day before and on due date".
    // If it's daily, 1 day before is just today for tomorrow's event.
    // Let's exclude "daily" frequency from "1 day before" reminder to avoid double spam.
    if (!_isDaily(item.frequency)) {
      final dayBefore = dueDate.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: '${item.id}_before'.hashCode,
          title: 'Upcoming: ${item.structuredTitle}',
          body: 'Due tomorrow: ${item.description}',
          scheduledDate: dayBefore,
          payload: item.id,
          matchComponents: _getMatchComponents(item.frequency),
        );
      }
    }
  }

  Future<void> cancelReminder(String itemId) async {
    await _notificationsPlugin.cancel(itemId.hashCode);
    await _notificationsPlugin.cancel('${itemId}_before'.hashCode);
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
    DateTimeComponents? matchComponents,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'follow_up_reminders',
          'Follow Up Reminders',
          channelDescription: 'Reminders for medical follow-ups',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  DateTimeComponents? _getMatchComponents(String? frequency) {
    if (frequency == null) return null;

    final lowerFreq = frequency.toLowerCase();

    if (lowerFreq.contains('daily') || lowerFreq.contains('every day')) {
      return DateTimeComponents.time;
    }

    if (lowerFreq.contains('weekly') || lowerFreq.contains('every week')) {
      return DateTimeComponents.dayOfWeekAndTime;
    }

    if (lowerFreq.contains('monthly') || lowerFreq.contains('every month')) {
      return DateTimeComponents.dayOfMonthAndTime;
    }

    // Default to one-time if pattern not matched or complex
    return null;
  }

  bool _isDaily(String? frequency) {
    if (frequency == null) return false;
    final lowerFreq = frequency.toLowerCase();
    return lowerFreq.contains('daily') || lowerFreq.contains('every day');
  }
}
