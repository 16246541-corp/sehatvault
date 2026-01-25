import 'platform_service_stub.dart'
    if (dart.library.io) 'platform_service_mobile.dart'
    if (dart.library.html) 'platform_service_web.dart'; // Just in case

abstract class PlatformService {
  String get platformName;
  bool get isDesktop;

  static PlatformService get instance => getPlatformService();
}
