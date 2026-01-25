import 'package:flutter/foundation.dart';
import '../models/generation_parameters.dart';
import '../services/local_storage_service.dart';
import '../services/session_manager.dart';
import '../utils/secure_logger.dart';

class GenerationParametersService extends ChangeNotifier {
  static final GenerationParametersService _instance =
      GenerationParametersService._internal();
  factory GenerationParametersService() => _instance;
  GenerationParametersService._internal();

  final LocalStorageService _storageService = LocalStorageService();

  GenerationParameters _currentParameters = GenerationParameters();

  GenerationParameters get currentParameters {
    // Check for temporary overrides in SessionManager
    final override = SessionManager().temporaryGenerationParameters;
    return override ?? _currentParameters;
  }

  bool _isAdvancedEnabled = false;
  bool get isAdvancedEnabled => _isAdvancedEnabled;

  void init() {
    final settings = _storageService.getAppSettings();
    _currentParameters = settings.generationParameters;
    _isAdvancedEnabled = settings.advancedAiSettingsEnabled;
    notifyListeners();
  }

  Future<void> updateParameters(GenerationParameters params) async {
    _currentParameters = params;
    final settings = _storageService.getAppSettings();
    settings.generationParameters = params;
    await _storageService.saveAppSettings(settings);
    SecureLogger.log(
        "Generation parameters updated: ${params.temperature}, ${params.topP}, ${params.topK}");
    notifyListeners();
  }

  Future<void> toggleAdvancedSettings(bool enabled) async {
    _isAdvancedEnabled = enabled;
    final settings = _storageService.getAppSettings();
    settings.advancedAiSettingsEnabled = enabled;
    await _storageService.saveAppSettings(settings);
    notifyListeners();
  }

  void resetToDefaults() {
    updateParameters(GenerationParameters());
  }

  void applyPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'balanced':
        updateParameters(GenerationParameters.balanced());
        break;
      case 'creative':
        updateParameters(GenerationParameters.creative());
        break;
      case 'precise':
        updateParameters(GenerationParameters.precise());
        break;
      case 'fast':
        updateParameters(GenerationParameters.fast());
        break;
      default:
        SecureLogger.log("Unknown preset: $presetName");
    }
  }

  /// Validates if the parameters are within safe boundaries.
  Map<String, String> validateParameters(GenerationParameters params) {
    final warnings = <String, String>{};

    if (params.temperature > 1.2) {
      warnings['temperature'] =
          "High temperature may cause incoherent or repetitive output.";
    } else if (params.temperature < 0.1) {
      warnings['temperature'] =
          "Very low temperature may cause extremely repetitive output.";
    }

    if (params.topP > 0.95) {
      warnings['topP'] =
          "High Top-P may include very unlikely tokens, increasing randomness.";
    }

    if (params.topK > 100) {
      warnings['topK'] =
          "High Top-K might slow down inference and increase randomness.";
    }

    if (params.maxTokens > 4096) {
      warnings['maxTokens'] =
          "Very high max tokens might exceed model context window or slow down generation.";
    }

    return warnings;
  }
}
