import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'llm_engine.dart';
import 'model_fallback_service.dart';
import 'model_warmup_service.dart';
import 'desktop_notification_service.dart';
import '../models/model_option.dart';
import 'platform_detector.dart';
import 'local_storage_service.dart';
import '../config/app_config.dart';
import 'memory_monitor_service.dart';
import 'session_manager.dart';
import 'ai_analytics_service.dart';
import 'model_quantization_service.dart';
import 'model_verification_service.dart';
import 'model_update_service.dart';

class ModelLoadException implements Exception {
  final String message;
  final bool isStorageIssue;
  final bool isIntegrityIssue;

  ModelLoadException(this.message,
      {this.isStorageIssue = false, this.isIntegrityIssue = false});

  @override
  String toString() => 'ModelLoadException: $message';
}

class ModelManager {
  static final LLMEngine _engine = LLMEngine();
  static DateTime? _lastUsedTime;
  static Timer? _retentionTimer;
  static final MemoryMonitorService _memoryMonitor = MemoryMonitorService();

  static void init() {
    _memoryMonitor.onStatusChanged.listen(_handleMemoryPressure);
  }

  static void _handleMemoryPressure(MemoryStatus status) {
    final settings = LocalStorageService().getAppSettings();
    if (!settings.unloadOnLowMemory) return;

    // On desktop (macOS/Windows/Linux), memory reporting via system_info2 is unreliable
    // because file cache memory is reported as "used". The OS handles memory pressure
    // much better than app-level intervention, so we skip this on desktop.
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return;
    }

    if (status.level == MemoryPressureLevel.critical) {
      debugPrint(
          'ModelManager: Critical memory pressure! Attempting fallback...');
      final currentModel = _engine.currentModel;
      if (currentModel != null) {
        ModelFallbackService()
            .evaluateFallback(currentModel,
                error: LLMEngineException('Critical memory pressure',
                    code: 'OUT_OF_MEMORY'))
            .then((fallbackModel) {
          if (fallbackModel != null) {
            loadModel(fallbackModel);
          } else {
            unloadModel(reason: 'Critical memory pressure');
          }
        });
      }
    } else if (status.level == MemoryPressureLevel.warning) {
      // If we haven't used the model in a while, unload it
      if (!isModelInUse()) {
        debugPrint(
            'ModelManager: Warning memory pressure and idle. Unloading model...');
        unloadModel(reason: 'Memory warning & idle');
      }
    }
  }

  /// Checks if the model is currently being used or predicted to be used.
  static bool isModelInUse() {
    if (_engine.currentModel == null) return false;

    // Prediction: Is user on AI screen?
    final session = SessionManager();
    if (session.currentSessionId != null) {
      final lastUsed = _lastUsedTime;
      if (lastUsed != null) {
        final idleTime = DateTime.now().difference(lastUsed);
        // If used within last 2 minutes, consider it "in use"
        if (idleTime < const Duration(minutes: 2)) return true;
      }
    }

    return false;
  }

  /// Unloads the model from memory.
  static Future<void> unloadModel({String reason = 'Requested'}) async {
    if (_engine.currentModel == null) return;

    debugPrint(
        'ModelManager: Unloading model (${_engine.currentModel?.name}). Reason: $reason');
    await _engine.dispose();
    _lastUsedTime = null;
    _retentionTimer?.cancel();

    DesktopNotificationService().showModelStatus(
      title: 'Model Unloaded',
      message: 'AI resources released: $reason',
    );
  }

  /// Updates the last used timestamp and resets retention timer.
  static void markAsUsed() {
    _lastUsedTime = DateTime.now();
    _resetRetentionTimer();
  }

  static void _resetRetentionTimer() {
    _retentionTimer?.cancel();

    final settings = LocalStorageService().getAppSettings();
    final retentionMinutes = settings.modelRetentionMinutes;

    if (retentionMinutes <= 0) return; // Never unload if set to 0

    _retentionTimer = Timer(Duration(minutes: retentionMinutes), () {
      if (!isModelInUse()) {
        unloadModel(reason: 'Inactivity retention policy');
      } else {
        _resetRetentionTimer(); // Check again later
      }
    });
  }

  /// Detects device RAM and recommends the optimal model option.
  static Future<ModelOption> getRecommendedModel() async {
    final capabilities = await PlatformDetector().getCapabilities();
    final settings = LocalStorageService().getAppSettings();
    final config = AppConfig.instance;
    final quantizationService = ModelQuantizationService();

    debugPrint('Detected RAM: ${capabilities.ramGB.toStringAsFixed(2)} GB');
    debugPrint('Current Flavor: ${config.flavor}');

    // Detect recommended quantization level for this device
    final recommendedFormat = await quantizationService.getRecommendedFormat();
    debugPrint('Recommended Quantization: ${recommendedFormat.label}');

    // Recommendation Logic based on ModelOption.availableModels
    // We prioritize the most capable model the device can comfortably run.

    // Sort models by RAM requirement descending to find the best fit
    final sortedModels = List<ModelOption>.from(ModelOption.availableModels)
      ..sort((a, b) => b.ramRequired.compareTo(a.ramRequired));

    for (var model in sortedModels) {
      // In dev mode, we might want to skip the heaviest models unless explicitly enabled
      if (config.isDev && model.ramRequired > 8.0) {
        continue;
      }

      // If it's a desktop-only model, ensure we are on desktop
      if (model.isDesktopOnly && !capabilities.isDesktop) continue;

      // Desktop specific: if gpu acceleration is disabled, we avoid very heavy models (>8GB RAM required)
      if (capabilities.isDesktop &&
          model.ramRequired > 8 &&
          !settings.enableGpuAcceleration) {
        continue;
      }

      // Check if the recommended quantization for this model fits in RAM
      final assessment = await quantizationService.assessCompatibility(
        model.ramRequired,
        recommendedFormat,
      );

      // If device has enough RAM for this model at the recommended quantization
      if (assessment.isCompatible) {
        return model;
      }
    }

    // Default to the first (usually smallest) model if none match
    return ModelOption.availableModels.first;
  }

  /// Checks if the model files are present on disk and version matches.
  static Future<bool> isModelDownloaded(String modelId,
      {String? version, QuantizationFormat? format}) async {
    try {
      final settings = LocalStorageService().getAppSettings();
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/$modelId';
      final modelDir = Directory(modelPath);
      final modelFile = File('$modelPath/model.gguf');

      if (!await modelDir.exists() || !await modelFile.exists()) return false;

      // Check if the requested format matches what is stored
      if (format != null) {
        final storedFormat = settings.modelQuantizationMap[modelId];
        if (storedFormat != format.name) {
          debugPrint(
              'Format mismatch for $modelId: Stored $storedFormat vs Requested ${format.name}');
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Checks if there is enough storage available (simulated for demo).
  static Future<bool> hasEnoughStorage(double requiredGB) async {
    // In a real app, use a package like 'storage_space' or 'disk_space_2'
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Simplified for demo flow
  }

  /// Verifies the SHA-256 hash and cryptographic signature of the downloaded model file.
  static Future<void> _verifyModelHash(File file, ModelOption model) async {
    final verificationService = ModelVerificationService();
    final updateService = ModelUpdateService();

    debugPrint('Verifying integrity and signature for ${file.path}...');

    // 1. Integrity Check (SHA-256)
    final isIntact = await verificationService.verifyIntegrity(
        file, model.metadata.checksum);
    if (!isIntact) {
      DesktopNotificationService().showModelStatus(
        title: 'Model Integrity Error',
        message:
            'The AI model file appears to be corrupted. Attempting recovery...',
        isError: true,
      );

      await verificationService.recoverModel(model, file);

      throw ModelLoadException(
        'Integrity check failed! The model file appears to be corrupted or tampered with.',
        isIntegrityIssue: true,
      );
    }

    // 2. Signature Verification
    final isAuthentic = await verificationService.verifySignature(
      file,
      model.metadata.signature ?? '',
      model.metadata.publicKey ?? '',
    );

    if (!isAuthentic) {
      DesktopNotificationService().showModelStatus(
        title: 'Security Alert',
        message: 'Model signature verification failed. Possible tampering.',
        isError: true,
      );
      throw ModelLoadException(
        'Signature verification failed! The model source cannot be verified.',
        isIntegrityIssue: true,
      );
    }

    // 3. Save Manifest for offline-first update tracking
    await updateService.saveModelManifest(model.id, model.metadata);
  }

  /// Checks local storage for model files and simulates download (stub).
  /// Re-downloads if version or quantization changes.
  static Future<bool> downloadModelIfNotExists(ModelOption model,
      {String? installedVersion, QuantizationFormat? format}) async {
    try {
      final settings = LocalStorageService().getAppSettings();
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/${model.id}';
      final modelDir = Directory(modelPath);
      final quantizationService = ModelQuantizationService();

      // Determine which format to download
      final selectedFormat = format ??
          (settings.preferredQuantization != null
              ? QuantizationFormat.values.firstWhere(
                  (f) => f.name == settings.preferredQuantization,
                  orElse: () => QuantizationFormat.q4_k_m)
              : await quantizationService.getRecommendedFormat());

      bool needsDownload = false;

      if (await modelDir.exists()) {
        final modelFile = File('${modelDir.path}/model.gguf');
        final storedFormat = settings.modelQuantizationMap[model.id];
        final versionMismatch = installedVersion != null &&
            installedVersion != model.metadata.version;
        final formatMismatch = storedFormat != selectedFormat.name;
        final fileMissing = !await modelFile.exists();

        if (versionMismatch || formatMismatch || fileMissing) {
          debugPrint(
              'Version/Format mismatch or file missing for ${model.id}. Re-downloading...');
          if (await modelDir.exists()) await modelDir.delete(recursive: true);
          needsDownload = true;
        } else {
          debugPrint('Model ${model.id} already exists with correct format.');
          return true;
        }
      } else {
        needsDownload = true;
      }

      if (needsDownload) {
        DesktopNotificationService().showModelStatus(
          title: 'Model Download Started',
          message:
              'Downloading ${model.name} (${selectedFormat.label}) for offline AI processing.',
        );

        // Check compatibility (RAM & Storage)
        final assessment = await quantizationService.assessCompatibility(
            model.storageRequired, selectedFormat);

        if (!assessment.isCompatible) {
          final error = assessment.storageWarning ?? assessment.ramWarning!;
          DesktopNotificationService().showModelStatus(
            title: 'Download Failed',
            message: error,
            isError: true,
          );
          throw ModelLoadException(error, isStorageIssue: true);
        }

        // Simulating download (Stub)
        debugPrint(
            'Downloading model ${model.id} (${selectedFormat.name}) to $modelPath...');
        await Future.delayed(const Duration(seconds: 2));

        await modelDir.create(recursive: true);
        final dummyFile = File('$modelPath/model.gguf');
        final content =
            'DUMMY_MODEL_DATA:${model.id}:${model.metadata.version}:${selectedFormat.name}';
        await dummyFile.writeAsString(content);

        // Store quantization format in settings
        settings.modelQuantizationMap[model.id] = selectedFormat.name;
        await LocalStorageService().saveAppSettings(settings);

        // Initial verification
        await _verifyModelHash(dummyFile, model);

        DesktopNotificationService().showModelStatus(
          title: 'Model Ready',
          message:
              '${model.name} (${selectedFormat.label}) has been downloaded and verified.',
        );
        debugPrint('Model ${model.id} downloaded and verified.');
      }

      return true;
    } catch (e) {
      if (e is ModelLoadException) rethrow;
      debugPrint('Error in downloadModelIfNotExists: $e');
      throw ModelLoadException('Failed to load model: ${e.toString()}');
    }
  }

  /// Loads the model into memory using LLMEngine.
  static Future<bool> loadModel(ModelOption model) async {
    try {
      debugPrint('Loading model ${model.id} into memory via LLMEngine...');

      // If we are already warming up this model, we should wait or return
      final warmupService = ModelWarmupService();
      if (warmupService.isWarmupActive &&
          warmupService.currentState.status != WarmupStatus.failed) {
        debugPrint('Model warmup already in progress for ${model.id}');
        // In a real app, we might wait for the stream to complete
        // For now, we'll let it proceed as initialize is idempotent or handles concurrency
      }

      await _engine.initialize(model);
      markAsUsed();

      // Log success to analytics
      AIAnalyticsService().logMetric(
        _engine.metrics ?? ModelMetrics(loadTimeMs: 0),
        model.id,
        operationType: 'load',
        isSuccessful: true,
      );

      DesktopNotificationService().showModelStatus(
        title: 'Model Loaded',
        message: '${model.name} is ready for local AI processing.',
      );

      return true;
    } catch (e) {
      debugPrint('Error in loadModel: $e');

      // Log failure to analytics
      AIAnalyticsService().logMetric(
        ModelMetrics(loadTimeMs: 0),
        model.id,
        operationType: 'load',
        isSuccessful: false,
      );

      if (e is LLMEngineException) {
        // Attempt fallback if possible
        final fallbackModel = await ModelFallbackService().evaluateFallback(
          model,
          error: e,
        );

        if (fallbackModel != null) {
          debugPrint(
              'Attempting fallback from ${model.name} to ${fallbackModel.name}');
          return loadModel(fallbackModel);
        }

        DesktopNotificationService().showModelStatus(
          title: 'Loading Failed',
          message: 'Failed to load ${model.name}. ${e.message}',
          isError: true,
        );

        throw ModelLoadException(e.message,
            isIntegrityIssue: e.code == 'CHECKSUM_MISMATCH');
      }

      DesktopNotificationService().showModelStatus(
        title: 'Loading Failed',
        message: 'Failed to load ${model.name}. Check device resources.',
        isError: true,
      );

      throw ModelLoadException('Failed to load model: ${e.toString()}');
    }
  }

  /// Returns detailed information about the recommended model configuration.
  static Future<Map<String, dynamic>> getDeviceInfoReport() async {
    final model = await getRecommendedModel();
    final capabilities = await PlatformDetector().getCapabilities();
    final quantizationService = ModelQuantizationService();
    final recommendedFormat = await quantizationService.getRecommendedFormat();

    return {
      'recommendedModelId': model.id,
      'recommendedModelName': model.name,
      'recommendedQuantization': recommendedFormat.label,
      'modelDescription': model.description,
      'ramRequiredGB': model.ramRequired,
      'storageRequiredGB': model.storageRequired,
      'totalRamGB': capabilities.ramGB.toStringAsFixed(2),
      'isDesktop': capabilities.isDesktop,
      'platform': capabilities.platformName,
      'capabilities': capabilities.supportedCapabilities
          .map((e) => e.toString().split('.').last)
          .toList(),
      'metrics': capabilities.performanceMetrics,
      'quantizationTradeoff': {
        'quality': recommendedFormat.qualityImpact,
        'speed': recommendedFormat.speedMultiplier,
        'sizeMultiplier': recommendedFormat.sizeMultiplier,
      }
    };
  }
}
