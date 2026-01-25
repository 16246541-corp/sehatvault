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

  EnhancedPrivacySettings({
    this.requireBiometricsForSensitiveData = true,
    this.requireBiometricsForExport = true,
    this.requireBiometricsForModelChange = false,
    this.requireBiometricsForSettings = false,
    this.tempFileRetentionMinutes = 0,
    this.maskNotifications = false,
  });

  factory EnhancedPrivacySettings.defaultSettings() {
    return EnhancedPrivacySettings(
      requireBiometricsForSensitiveData: true,
      requireBiometricsForExport: true,
      requireBiometricsForModelChange: false,
      requireBiometricsForSettings: false,
      tempFileRetentionMinutes: 0,
      maskNotifications: false,
    );
  }
}
