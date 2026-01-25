import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/platform_detector.dart';
import 'package:sehatlocker/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformDetector Tests', () {
    test('getCapabilities returns valid capabilities', () async {
      final detector = PlatformDetector();
      final caps = await detector.getCapabilities();

      expect(caps.platformName, isNotEmpty);
      expect(caps.ramGB, greaterThan(0));
      expect(caps.supportedCapabilities, isNotEmpty);
      expect(caps.performanceMetrics, contains('detectionTimeMs'));
    });

    test('applyPlatformDefaults modifies settings correctly', () async {
      final detector = PlatformDetector();
      await detector.getCapabilities(); // Ensure cached
      
      final settings = AppSettings.defaultSettings();
      detector.applyPlatformDefaults(settings);

      // Verify some defaults were applied based on the current platform
      // Since we don't know the test platform, we check if it matches one of the expected sets
      final isDesktop = capsMatchDesktop(await detector.getCapabilities());
      
      if (isDesktop) {
        expect(settings.sessionTimeoutMinutes, 30);
        expect(settings.autoStopRecordingMinutes, 120);
      } else {
        expect(settings.sessionTimeoutMinutes, 5);
        expect(settings.autoStopRecordingMinutes, 60);
      }
    });

    test('PlatformCapabilities toJson works', () async {
      final detector = PlatformDetector();
      final caps = await detector.getCapabilities();
      final json = caps.toJson();

      expect(json['platformName'], caps.platformName);
      expect(json['ramGB'], caps.ramGB.toStringAsFixed(2));
      expect(json['capabilities'], isA<List>());
    });
  });
}

bool capsMatchDesktop(PlatformCapabilities caps) {
  return caps.isDesktop;
}
