import 'dart:io';
import 'platform_service.dart';

class DesktopPlatformService implements PlatformService {
  @override
  String get platformName {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Desktop';
  }

  @override
  bool get isDesktop => true;
}

PlatformService getPlatformService() => DesktopPlatformService();
