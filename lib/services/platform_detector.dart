import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:system_info2/system_info2.dart';
import '../models/app_settings.dart';

/// Capabilities that the device may support.
enum DeviceCapability {
  highRam,
  gpuAcceleration,
  biometrics,
  highPerformance,
  offlineStorage,
  localAIInference,
  advancedMedicalReasoning,
}

/// Represents the platform and device capabilities.
class PlatformCapabilities {
  final String platformName;
  final bool isDesktop;
  final bool isMobile;
  final double ramGB;
  final bool hasGpuSupport;
  final String deviceModel;
  final Set<DeviceCapability> supportedCapabilities;
  final Map<String, dynamic> performanceMetrics;

  PlatformCapabilities({
    required this.platformName,
    required this.isDesktop,
    required this.isMobile,
    required this.ramGB,
    required this.hasGpuSupport,
    required this.deviceModel,
    required this.supportedCapabilities,
    this.performanceMetrics = const {},
  });

  bool supports(DeviceCapability capability) =>
      supportedCapabilities.contains(capability);

  /// Helper to check if the device can run a specific model based on RAM.
  bool canRunModel(double requiredRamGB) => ramGB >= requiredRamGB;

  Map<String, dynamic> toJson() {
    return {
      'platformName': platformName,
      'isDesktop': isDesktop,
      'isMobile': isMobile,
      'ramGB': ramGB.toStringAsFixed(2),
      'hasGpuSupport': hasGpuSupport,
      'deviceModel': deviceModel,
      'capabilities': supportedCapabilities.map((e) => e.toString()).toList(),
      'performanceMetrics': performanceMetrics,
    };
  }
}

/// Service for detecting platform and device capabilities.
class PlatformDetector with WidgetsBindingObserver {
  static final PlatformDetector _instance = PlatformDetector._internal();
  factory PlatformDetector() => _instance;
  PlatformDetector._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PlatformCapabilities? _cachedCapabilities;
  final Stopwatch _initTimer = Stopwatch();

  final StreamController<PlatformCapabilities> _capabilityController =
      StreamController<PlatformCapabilities>.broadcast();
  Stream<PlatformCapabilities> get onCapabilitiesChanged =>
      _capabilityController.stream;

  /// Returns the current platform capabilities, detecting them if necessary.
  Future<PlatformCapabilities> getCapabilities() async {
    if (_cachedCapabilities != null) return _cachedCapabilities!;
    _cachedCapabilities = await _detectCapabilities();
    return _cachedCapabilities!;
  }

  Future<PlatformCapabilities> _detectCapabilities() async {
    _initTimer.reset();
    _initTimer.start();

    final platformName = kIsWeb ? 'web' : Platform.operatingSystem;
    final isDesktop =
        !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    double ramGB = 0;
    try {
      if (!kIsWeb) {
        ramGB = SysInfo.getTotalPhysicalMemory() / (1024 * 1024 * 1024);
      } else {
        ramGB = 4.0; // Web fallback
      }
    } catch (e) {
      debugPrint('Error detecting RAM: $e');
      ramGB = 2.0; // Safe fallback
    }

    String deviceModel = 'Unknown';
    bool hasGpuSupport = false;
    final Set<DeviceCapability> capabilities = {};

    try {
      if (!kIsWeb) {
        if (Platform.isMacOS) {
          final info = await _deviceInfo.macOsInfo;
          deviceModel = info.model;
          if (info.model.contains('Apple') || info.arch == 'arm64') {
            hasGpuSupport = true;
          }
        } else if (Platform.isIOS) {
          final info = await _deviceInfo.iosInfo;
          deviceModel = info.utsname.machine;
          hasGpuSupport = true;
        } else if (Platform.isAndroid) {
          final info = await _deviceInfo.androidInfo;
          deviceModel = info.model;
          if (info.hardware.toLowerCase().contains('qcom') ||
              info.hardware.toLowerCase().contains('mali') ||
              info.hardware.toLowerCase().contains('tensor')) {
            hasGpuSupport = true;
          }
        } else if (Platform.isWindows) {
          final info = await _deviceInfo.windowsInfo;
          deviceModel = info.computerName;
          hasGpuSupport = true;
        }
      }
    } catch (e) {
      debugPrint('Error detecting device info: $e');
    }

    // Capability logic
    if (ramGB >= 8) capabilities.add(DeviceCapability.highRam);
    if (hasGpuSupport) capabilities.add(DeviceCapability.gpuAcceleration);
    if (ramGB >= 4) capabilities.add(DeviceCapability.highPerformance);

    capabilities.add(DeviceCapability.offlineStorage);
    capabilities.add(DeviceCapability.localAIInference);

    if (isDesktop || (isMobile && ramGB >= 8)) {
      capabilities.add(DeviceCapability.advancedMedicalReasoning);
    }

    _initTimer.stop();

    return PlatformCapabilities(
      platformName: platformName,
      isDesktop: isDesktop,
      isMobile: isMobile,
      ramGB: ramGB,
      hasGpuSupport: hasGpuSupport,
      deviceModel: deviceModel,
      supportedCapabilities: capabilities,
      performanceMetrics: {
        'detectionTimeMs': _initTimer.elapsedMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCapabilities();
    }
  }

  Future<void> _refreshCapabilities() async {
    final newCaps = await _detectCapabilities();
    if (_cachedCapabilities == null ||
        _cachedCapabilities!.ramGB != newCaps.ramGB ||
        _cachedCapabilities!.supportedCapabilities.length !=
            newCaps.supportedCapabilities.length) {
      _cachedCapabilities = newCaps;
      _capabilityController.add(newCaps);
    }
  }

  /// Applies platform-specific defaults to the provided settings.
  void applyPlatformDefaults(AppSettings settings) {
    if (_cachedCapabilities == null) return;

    if (_cachedCapabilities!.isDesktop) {
      // Desktop defaults
      settings.sessionTimeoutMinutes = 30; // Longer timeout on desktop
      settings.autoStopRecordingMinutes = 120; // Longer recordings on desktop
    } else {
      // Mobile defaults
      settings.sessionTimeoutMinutes = 5;
      settings.autoStopRecordingMinutes = 60;
    }

    // Advanced model availability
    if (!_cachedCapabilities!.supports(DeviceCapability.highRam)) {
      settings.autoSelectModel = true; // Force auto-select if RAM is low
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _capabilityController.close();
  }
}
