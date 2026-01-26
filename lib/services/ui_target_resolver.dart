import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum UiTarget {
  mobile,
  desktop,
}

class UiTargetResolver {
  static Future<UiTarget> resolve() async {
    if (kIsWeb) return UiTarget.desktop;

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return UiTarget.desktop;
    }

    if (Platform.isAndroid) return UiTarget.mobile;

    if (Platform.isIOS) {
      try {
        final info = await DeviceInfoPlugin().iosInfo;
        final machine = info.utsname.machine.toLowerCase();
        if (machine.startsWith('ipad')) return UiTarget.desktop;
      } catch (_) {}
      return UiTarget.mobile;
    }

    return UiTarget.mobile;
  }
}
