import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';

class WidgetDataService {
  static const String _groupId =
      'group.com.sehatlocker.widget'; // Must match iOS App Group
  static const String _iosWidgetName = 'SehatLockerWidget';
  static const String _androidWidgetName = 'SehatLockerWidget';

  static const String keyIceData = 'ice_data';
  static const String keyIsLocked = 'is_locked';

  Future<void> updateWidgetData(AppSettings settings) async {
    final showIce = settings.showIceOnLockScreen;
    final iceName = settings.iceContactName;
    final icePhone = settings.iceContactPhone;

    String displayText = 'Locked • Tap to authenticate';

    if (showIce &&
        iceName != null &&
        icePhone != null &&
        iceName.isNotEmpty &&
        icePhone.isNotEmpty) {
      final redactedPhone = _redactPhone(icePhone);
      final redactedName = _redactName(iceName);
      displayText = 'ICE: $redactedPhone • $redactedName';
    }

    try {
      await HomeWidget.saveWidgetData<String>(keyIceData, displayText);
      // We can also save a boolean if we want to toggle visibility logic on the native side
      // but the requirement says "Show app icon only when locked", so maybe we don't need complex logic there.
      // The text itself changes.

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget data: $e');
    }
  }

  String _redactPhone(String phone) {
    // Remove non-digits to count length? No, preserve formatting but mask.
    // Let's just take the last 4 characters and mask the rest.
    if (phone.length <= 4) return phone;

    final last4 = phone.substring(phone.length - 4);
    // Estimate length of masked part
    return '***-***-$last4';
  }

  String _redactName(String name) {
    if (name.isEmpty) return '';
    if (name.length <= 1) return name;

    // Show first letter and mask the rest
    final firstLetter = name[0];
    return '$firstLetter***';
  }
}
