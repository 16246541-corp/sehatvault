import 'package:hive/hive.dart';

part 'enhanced_privacy_settings.g.dart';

@HiveType(typeId: 12)
class EnhancedPrivacySettings extends HiveObject {
  @HiveField(0, defaultValue: true)
  bool requireBiometricsForSensitiveData;

  @HiveField(1, defaultValue: true)
  bool requireBiometricsForExport;

  @HiveField(2, defaultValue: false)
  bool requireBiometricsForModelChange;

  @HiveField(3, defaultValue: false)
  bool requireBiometricsForSettings;

  @HiveField(4, defaultValue: 0)
  int tempFileRetentionMinutes;

  @HiveField(5, defaultValue: false)
  bool maskNotifications;

  @HiveField(6, defaultValue: false)
  bool showHealthInsights;

  @HiveField(7, defaultValue: 0)
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
