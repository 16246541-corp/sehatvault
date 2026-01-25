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
  List<String> keepAudioIds;

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
  List<String> completedEducationIds;

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

  @HiveField(18)
  double? desktopWindowWidth;

  @HiveField(19)
  double? desktopWindowHeight;

  @HiveField(20)
  double? desktopWindowX;

  @HiveField(21)
  double? desktopWindowY;

  @HiveField(22)
  bool isMaximized;

  @HiveField(23)
  bool enableGpuAcceleration;

  @HiveField(24)
  int increasedCacheLimitMB;

  @HiveField(25)
  bool showDesktopDebugTools;

  @HiveField(26)
  int maxFileUploadSizeMB;

  @HiveField(27)
  String? lastExportDirectory;

  @HiveField(28)
  bool hasSeenBiometricEnrollmentPrompt;

  @HiveField(29)
  bool enableKeyboardShortcuts;

  @HiveField(30)
  bool persistWindowState;

  @HiveField(31)
  bool restoreWindowPosition;

  @HiveField(32)
  bool accessibilityEnabled;

  AppSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = 'en',
    List<String>? keepAudioIds,
    this.autoDeleteRecordingsDays = 365,
    this.sessionTimeoutMinutes = 2,
    EnhancedPrivacySettings? enhancedPrivacySettings,
    this.selectedModelId = 'med_gemma_4b',
    Map<String, ModelMetadata>? modelMetadataMap,
    this.autoStopRecordingMinutes = 60,
    this.enableBatteryWarnings = true,
    List<String>? completedEducationIds,
    Map<String, int>? completedEducationVersions,
    this.enableWellnessLanguageChecks = true,
    this.showWellnessDebugInfo = false,
    this.localAuditRetentionDays = 90,
    this.localAuditChainAnchorHash = '',
    this.autoSelectModel = true,
    this.desktopWindowWidth,
    this.desktopWindowHeight,
    this.desktopWindowX,
    this.desktopWindowY,
    this.isMaximized = false,
    this.enableGpuAcceleration = false,
    this.increasedCacheLimitMB = 512,
    this.showDesktopDebugTools = false,
    this.maxFileUploadSizeMB = 50,
    this.lastExportDirectory,
    this.hasSeenBiometricEnrollmentPrompt = false,
    this.enableKeyboardShortcuts = true,
    this.persistWindowState = true,
    this.restoreWindowPosition = true,
    this.accessibilityEnabled = false,
  })  : keepAudioIds = keepAudioIds ?? [],
        enhancedPrivacySettings =
            enhancedPrivacySettings ?? EnhancedPrivacySettings(),
        modelMetadataMap = modelMetadataMap ?? {},
        completedEducationIds = completedEducationIds ?? [],
        completedEducationVersions = completedEducationVersions ?? {};

  factory AppSettings.defaultSettings() {
    return AppSettings();
  }
}
