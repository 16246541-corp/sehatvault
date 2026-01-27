import 'package:hive/hive.dart';

part 'enhanced_privacy_settings.g.dart';

@HiveType(typeId: 12)
class EnhancedPrivacySettings extends HiveObject {
  @HiveField(0)
  bool requireBiometricsForSensitiveData;

  @HiveField(1)
  bool requireBiometricsForExport;

  @HiveField(2)
  bool requireBiometricsForModelChange;

  @HiveField(3)
  bool requireBiometricsForSettings;

  @HiveField(4)
  int tempFileRetentionMinutes;

  @HiveField(5)
  bool maskNotifications;

  @HiveField(6)
  bool showHealthInsights;

  @HiveField(7)
  int userPrivacyThreshold;

  EnhancedPrivacySettings({
    this.requireBiometricsForSensitiveData = true,
    this.requireBiometricsForExport = true,
    this.requireBiometricsForModelChange = false,
    this.requireBiometricsForSettings = false,
    this.tempFileRetentionMinutes = 0,
    this.maskNotifications = false,
    this.showHealthInsights = false,
    this.userPrivacyThreshold = 0,
  });

  factory EnhancedPrivacySettings.defaultSettings() {
    return EnhancedPrivacySettings(
      requireBiometricsForSensitiveData: true,
      requireBiometricsForExport: true,
      requireBiometricsForModelChange: false,
      requireBiometricsForSettings: false,
      tempFileRetentionMinutes: 0,
      maskNotifications: false,
      showHealthInsights: false,
      userPrivacyThreshold: 0,
    );
  }
}
