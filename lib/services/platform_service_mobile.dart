import 'dart:io';
import 'platform_service.dart';

class MobilePlatformService implements PlatformService {
  @override
  String get platformName => Platform.isAndroid ? 'Android' : 'iOS';

  @override
  bool get isDesktop => false;
}

PlatformService getPlatformService() => MobilePlatformService();
