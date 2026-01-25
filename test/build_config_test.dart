import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/config/app_config.dart';
import 'package:sehatlocker/services/platform_service.dart';

void main() {
  group('Build Configuration Tests', () {
    test('AppConfig singleton initialization', () {
      final config = AppConfig(
        appTitle: 'Test App',
        apiBaseUrl: 'https://test.com',
        flavor: AppFlavor.dev,
      );
      
      AppConfig.setConfig(config);
      expect(AppConfig.instance.appTitle, 'Test App');
      expect(AppConfig.instance.flavor, AppFlavor.dev);
    });

    test('Flavor checks', () {
      final devConfig = AppConfig(
        appTitle: 'Dev',
        apiBaseUrl: 'https://dev.com',
        flavor: AppFlavor.dev,
      );
      expect(devConfig.isDev, isTrue);
      expect(devConfig.isProd, isFalse);

      final prodConfig = AppConfig(
        appTitle: 'Prod',
        apiBaseUrl: 'https://prod.com',
        flavor: AppFlavor.prod,
      );
      expect(prodConfig.isProd, isTrue);
      expect(prodConfig.isDev, isFalse);
    });

    test('PlatformService returns instance', () {
      // This will return the platform-specific implementation depending on where the test runs
      // In the test environment (dart:io), it should be MobilePlatformService (since it uses Platform.isAndroid/iOS)
      // or DesktopPlatformService if it's running on a desktop host.
      final platform = PlatformService.instance;
      expect(platform, isNotNull);
      print('Running on platform: ${platform.platformName}');
    });
  });
}
