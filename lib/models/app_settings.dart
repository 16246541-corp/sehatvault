import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sehatlocker/models/enhanced_privacy_settings.dart';
import 'package:sehatlocker/models/model_metadata.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool darkMode;

  @HiveField(1)
  bool notificationsEnabled;

  @HiveField(2)
  String language;

  @HiveField(3)
  Set<String> keepAudioIds;

  @HiveField(4)
  int autoDeleteRecordingsDays;

  @HiveField(5)
  int sessionTimeoutMinutes;

  @HiveField(6)
  EnhancedPrivacySettings enhancedPrivacySettings;

  @HiveField(7)
  String selectedModelId;

  @HiveField(8)
  Map<String, ModelMetadata> modelMetadataMap;

  @HiveField(9)
  int autoStopRecordingMinutes;

  @HiveField(10)
  bool enableBatteryWarnings;

  @HiveField(11)
  Set<String> completedEducationIds;

  @HiveField(12)
  Map<String, int> completedEducationVersions;

  @HiveField(13)
  bool enableWellnessLanguageChecks;

  @HiveField(14)
  bool showWellnessDebugInfo;

  @HiveField(15)
  int localAuditRetentionDays;

  @HiveField(16)
  String localAuditChainAnchorHash;

  @HiveField(17)
  bool autoSelectModel;

  AppSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = 'en',
    Set<String>? keepAudioIds,
    this.autoDeleteRecordingsDays = 365,
    this.sessionTimeoutMinutes = 2,
    EnhancedPrivacySettings? enhancedPrivacySettings,
    this.selectedModelId = 'med_gemma_4b',
    Map<String, ModelMetadata>? modelMetadataMap,
    this.autoStopRecordingMinutes = 60,
    this.enableBatteryWarnings = true,
    Set<String>? completedEducationIds,
    Map<String, int>? completedEducationVersions,
    this.enableWellnessLanguageChecks = true,
    this.showWellnessDebugInfo = false,
    this.localAuditRetentionDays = 365,
    this.localAuditChainAnchorHash = '00000000000000000000000000000000',
    this.autoSelectModel = true,
  })  : keepAudioIds = keepAudioIds ?? {},
        enhancedPrivacySettings = enhancedPrivacySettings ??
            EnhancedPrivacySettings.defaultSettings(),
        modelMetadataMap = modelMetadataMap ?? {},
        completedEducationIds = completedEducationIds ?? {},
        completedEducationVersions = completedEducationVersions ?? {};

  factory AppSettings.defaultSettings() {
    return AppSettings();
  }
}
