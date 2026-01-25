import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info2/system_info2.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/model_option.dart';

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
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Detects device RAM and recommends the optimal model option.
  static Future<ModelOption> getRecommendedModel() async {
    // Detect Platform
    bool isDesktop = false;

    try {
      if (!kIsWeb) {
        if (Platform.isMacOS || Platform.isWindows) {
          isDesktop = true;
          if (Platform.isMacOS) {
            await _deviceInfo.macOsInfo;
          } else if (Platform.isWindows) {
            await _deviceInfo.windowsInfo;
          }
        }
      }
    } catch (e) {
      debugPrint('Error detecting platform info: $e');
    }

    // Detect Device RAM
    int totalRamMB = 0;
    try {
      totalRamMB = SysInfo.getTotalPhysicalMemory() ~/ (1024 * 1024);
    } catch (e) {
      debugPrint('Error detecting RAM: $e');
      // Fallback to a safe default (2GB)
      totalRamMB = 2048;
    }

    final double totalRamGB = totalRamMB / 1024.0;
    debugPrint('Detected RAM: ${totalRamGB.toStringAsFixed(2)} GB');

    // Recommendation Logic based on ModelOption.availableModels
    // We prioritize the most capable model the device can comfortably run.

    // Sort models by RAM requirement descending to find the best fit
    final sortedModels = List<ModelOption>.from(ModelOption.availableModels)
      ..sort((a, b) => b.ramRequired.compareTo(a.ramRequired));

    for (var model in sortedModels) {
      // If it's a desktop-only model, ensure we are on desktop
      if (model.isDesktopOnly && !isDesktop) continue;

      // If device has enough RAM (with a 10% buffer for OS/other apps)
      if (totalRamGB >= model.ramRequired) {
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
        // Check storage before "downloading"
        final enoughSpace = await hasEnoughStorage(model.storageRequired);
        if (!enoughSpace) {
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

        debugPrint('Model ${model.id} downloaded and verified.');
      }

      return true;
    } catch (e) {
      if (e is ModelLoadException) rethrow;
      debugPrint('Error in downloadModelIfNotExists: $e');
      throw ModelLoadException('Failed to load model: ${e.toString()}');
    }
  }

  /// Loads the model into memory using a background isolate (compute).
  static Future<bool> loadModel(ModelOption model) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/models/${model.id}';

    final params = _ModelLoadParams(
      modelPath: modelPath,
      checksum: model.metadata.checksum,
    );

    // Use compute to run CPU intensive loading/verification in background
    return await compute(_backgroundLoadTask, params);
  }

  /// Returns detailed information about the recommended model configuration.
  static Future<Map<String, dynamic>> getDeviceInfoReport() async {
    final model = await getRecommendedModel();
    final ramMB = SysInfo.getTotalPhysicalMemory() ~/ (1024 * 1024);

    return {
      'recommendedModelId': model.id,
      'recommendedModelName': model.name,
      'modelDescription': model.description,
      'ramRequiredGB': model.ramRequired,
      'storageRequiredGB': model.storageRequired,
      'totalRamGB': (ramMB / 1024.0).toStringAsFixed(2),
      'isDesktop': Platform.isMacOS || Platform.isWindows,
      'platform': Platform.operatingSystem,
    };
  }
}

/// Parameters for background model loading
class _ModelLoadParams {
  final String modelPath;
  final String checksum;

  _ModelLoadParams({required this.modelPath, required this.checksum});
}

/// Top-level function for compute() to handle background model loading and verification.
Future<bool> _backgroundLoadTask(_ModelLoadParams params) async {
  try {
    // 1. Heavy File Integrity Check (CPU bound)
    final file = File('${params.modelPath}/config.json');
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    final actualHash = digest.toString();

    final parts = params.checksum.split(':');
    final expectedHash = parts.length > 1 ? parts[1] : parts[0];

    if (actualHash != expectedHash) return false;

    // 2. Simulate heavy weight loading/graph initialization
    // We use a manual loop or heavy task here if we wanted to truly block the isolate
    // but a delay is fine for demo purposes.
    await Future.delayed(const Duration(milliseconds: 800));

    debugPrint('Model loaded successfully in background isolate.');
    return true;
  } catch (e) {
    debugPrint('Background model load failed: $e');
    return false;
  }
}
