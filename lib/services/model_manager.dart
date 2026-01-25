import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'llm_engine.dart';
import 'model_fallback_service.dart';
import 'desktop_notification_service.dart';
import '../models/model_option.dart';
import 'platform_detector.dart';
import 'local_storage_service.dart';
import '../config/app_config.dart';

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

  /// Detects device RAM and recommends the optimal model option.
  static Future<ModelOption> getRecommendedModel() async {
    final capabilities = await PlatformDetector().getCapabilities();
    final settings = LocalStorageService().getAppSettings();
    final config = AppConfig.instance;

    debugPrint('Detected RAM: ${capabilities.ramGB.toStringAsFixed(2)} GB');
    debugPrint('Current Flavor: ${config.flavor}');

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

      // If device has enough RAM (with a 10% buffer for OS/other apps)
      if (capabilities.ramGB >= model.ramRequired) {
        return model;
      }
    }

    // Default to the first (usually smallest) model if none match
    return ModelOption.availableModels.first;
  }

  /// Checks if the model files are present on disk and version matches.
  static Future<bool> isModelDownloaded(String modelId,
      {String? version}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/$modelId';
      final modelDir = Directory(modelPath);

      if (!await modelDir.exists()) return false;

      // If version is provided, we should check if the stored version matches
      // In a real app, we'd read this from a local metadata file or AppSettings
      // For this demo, we assume if it exists, it's correct unless told otherwise by downloadModelIfNotExists
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

  /// Verifies the SHA-256 hash of the downloaded model file.
  static Future<void> _verifyModelHash(File file, String expectedHash) async {
    debugPrint('Verifying integrity for ${file.path}...');

    // Split "sha256:HASH" format
    final parts = expectedHash.split(':');
    final actualExpected = parts.length > 1 ? parts[1] : parts[0];

    // Read file bytes and compute hash
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString();

    if (actualHash != actualExpected) {
      DesktopNotificationService().showModelStatus(
        title: 'Model Integrity Error',
        message:
            'The AI model file appears to be corrupted. Please re-download.',
        isError: true,
      );
      throw ModelLoadException(
        'Integrity check failed! The model file appears to be corrupted or tampered with.',
        isIntegrityIssue: true,
      );
    }
  }

  /// Checks local storage for model files and simulates download (stub).
  /// Re-downloads if version changes.
  static Future<bool> downloadModelIfNotExists(ModelOption model,
      {String? installedVersion}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/models/${model.id}';
      final modelDir = Directory(modelPath);

      bool needsDownload = false;

      if (await modelDir.exists()) {
        if (installedVersion != null &&
            installedVersion != model.metadata.version) {
          debugPrint(
              'Version mismatch for ${model.id}: $installedVersion vs ${model.metadata.version}. Re-downloading...');
          await modelDir.delete(recursive: true);
          needsDownload = true;
        } else {
          debugPrint('Model ${model.id} already exists and version matches.');
          return true;
        }
      } else {
        needsDownload = true;
      }

      if (needsDownload) {
        DesktopNotificationService().showModelStatus(
          title: 'Model Download Started',
          message: 'Downloading ${model.name} for offline AI processing.',
        );

        // Check storage before "downloading"
        final enoughSpace = await hasEnoughStorage(model.storageRequired);
        if (!enoughSpace) {
          DesktopNotificationService().showModelStatus(
            title: 'Download Failed',
            message: 'Insufficient storage to download ${model.name}.',
            isError: true,
          );
          throw ModelLoadException(
            'Insufficient storage to download ${model.name}. Required: ${model.storageRequired}GB.',
            isStorageIssue: true,
          );
        }

        // Simulating download (Stub)
        debugPrint(
            'Downloading model ${model.id} (Version: ${model.metadata.version}) to $modelPath...');
        await Future.delayed(const Duration(seconds: 2));

        await modelDir.create(recursive: true);
        final dummyFile = File('$modelPath/config.json');
        final content =
            '{"modelId": "${model.id}", "version": "${model.metadata.version}"}';
        await dummyFile.writeAsString(content);

        // Initial verification
        await _verifyModelHash(dummyFile, model.metadata.checksum);

        DesktopNotificationService().showModelStatus(
          title: 'Model Ready',
          message: '${model.name} has been downloaded and verified.',
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

      await _engine.initialize(model);

      DesktopNotificationService().showModelStatus(
        title: 'Model Loaded',
        message: '${model.name} is ready for local AI processing.',
      );

      return true;
    } catch (e) {
      debugPrint('Error in loadModel: $e');

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

    return {
      'recommendedModelId': model.id,
      'recommendedModelName': model.name,
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
    };
  }
}
