import 'platform_service.dart';

class WebPlatformService implements PlatformService {
  @override
  String get platformName => 'Web';

  @override
  bool get isDesktop => true;
}

PlatformService getPlatformService() => WebPlatformService();
