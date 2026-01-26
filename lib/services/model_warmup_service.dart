import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/model_option.dart';
import 'llm_engine.dart';
import 'model_manager.dart';
import 'platform_detector.dart';
import 'analytics_service.dart';
import 'ai_analytics_service.dart';
import 'local_storage_service.dart';

enum WarmupStatus {
  idle,
  initializing,
  loading,
  verifying,
  completed,
  failed,
  cancelled,
}

class WarmupState {
  final WarmupStatus status;
  final double progress;
  final Duration estimatedTimeRemaining;
  final String? errorMessage;

  WarmupState({
    required this.status,
    required this.progress,
    required this.estimatedTimeRemaining,
    this.errorMessage,
  });

  factory WarmupState.initial() => WarmupState(
        status: WarmupStatus.idle,
        progress: 0.0,
        estimatedTimeRemaining: Duration.zero,
      );

  WarmupState copyWith({
    WarmupStatus? status,
    double? progress,
    Duration? estimatedTimeRemaining,
    String? errorMessage,
  }) {
    return WarmupState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ModelWarmupService {
  static final ModelWarmupService _instance = ModelWarmupService._internal();
  factory ModelWarmupService() => _instance;
  ModelWarmupService._internal();

  final LLMEngine _engine = LLMEngine();
  final AnalyticsService _analytics = AnalyticsService();
  final AIAnalyticsService _aiAnalytics = AIAnalyticsService();
  final LocalStorageService _storage = LocalStorageService();

  final _stateController = StreamController<WarmupState>.broadcast();
  Stream<WarmupState> get stateStream => _stateController.stream;

  WarmupState _currentState = WarmupState.initial();
  WarmupState get currentState => _currentState;

  bool get isWarmupActive =>
      _currentState.status == WarmupStatus.initializing ||
      _currentState.status == WarmupStatus.loading ||
      _currentState.status == WarmupStatus.verifying;

  Stopwatch? _warmupTimer;
  ModelOption? _currentModel;
  StreamSubscription<double>? _progressSubscription;

  void _updateState(WarmupState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  bool isModelWarmedUp(String modelId) {
    final settings = _storage.getAppSettings();
    return settings.warmedUpModelIds.contains(modelId);
  }

  Future<void> startWarmup(ModelOption model) async {
    if (isWarmupActive) {
      return;
    }

    if (isModelWarmedUp(model.id)) {
      _updateState(_currentState.copyWith(
        status: WarmupStatus.completed,
        progress: 1.0,
        estimatedTimeRemaining: Duration.zero,
      ));
      return;
    }

    _currentModel = model;
    _warmupTimer = Stopwatch()..start();

    final initialEstimate = await _estimateTotalTime(model);
    _updateState(WarmupState(
      status: WarmupStatus.initializing,
      progress: 0.0,
      estimatedTimeRemaining: initialEstimate,
    ));

    _analytics.logEvent(
      'model_warmup_started',
      parameters: {'model_id': model.id},
    );

    _aiAnalytics.logMetric(
      ModelMetrics(loadTimeMs: 0),
      model.id,
      operationType: 'warmup_start',
      isSuccessful: true,
    );

    // Ensure model is downloaded before starting warmup
    try {
      final settings = _storage.getAppSettings();
      final installedVersion = settings.modelMetadataMap[model.id]?.version;
      await ModelManager.downloadModelIfNotExists(
        model,
        installedVersion: installedVersion,
      );
    } catch (e) {
      _updateState(_currentState.copyWith(
        status: WarmupStatus.failed,
        errorMessage: "Failed to ensure model download: $e",
      ));
      return;
    }

    try {
      _progressSubscription?.cancel();
      _progressSubscription = _engine.initializationProgress.listen((progress) {
        _onProgressUpdate(progress);
      });

      await _engine.initialize(model);

      _progressSubscription?.cancel();
      _warmupTimer?.stop();

      _updateState(_currentState.copyWith(
        status: WarmupStatus.completed,
        progress: 1.0,
        estimatedTimeRemaining: Duration.zero,
      ));

      _analytics.logEvent(
        'model_warmup_completed',
        parameters: {
          'model_id': model.id,
          'duration_ms': _warmupTimer?.elapsedMilliseconds,
        },
      );

      _aiAnalytics.logMetric(
        _engine.metrics ??
            ModelMetrics(
                loadTimeMs:
                    _warmupTimer?.elapsedMilliseconds.toDouble() ?? 0.0),
        model.id,
        operationType: 'warmup_complete',
        isSuccessful: true,
      );

      // We'll handle persistence via AppSettings in a separate step
    } catch (e) {
      _warmupTimer?.stop();
      _progressSubscription?.cancel();

      _updateState(_currentState.copyWith(
        status: WarmupStatus.failed,
        errorMessage: e.toString(),
      ));

      _analytics.logEvent(
        'model_warmup_failed',
        parameters: {
          'model_id': model.id,
          'error': e.toString(),
          'duration_ms': _warmupTimer?.elapsedMilliseconds,
        },
      );

      _aiAnalytics.logMetric(
        ModelMetrics(
            loadTimeMs: _warmupTimer?.elapsedMilliseconds.toDouble() ?? 0.0),
        model.id,
        operationType: 'warmup_failed',
        isSuccessful: false,
      );
    }
  }

  void _onProgressUpdate(double progress) {
    WarmupStatus status = WarmupStatus.loading;
    if (progress < 0.2) {
      status = WarmupStatus.initializing;
    } else if (progress < 0.8) {
      status = WarmupStatus.loading;
    } else {
      status = WarmupStatus.verifying;
    }

    final remaining = _calculateRemainingTime(progress);

    _updateState(_currentState.copyWith(
      status: status,
      progress: progress,
      estimatedTimeRemaining: remaining,
    ));
  }

  Future<Duration> _estimateTotalTime(ModelOption model) async {
    final capabilities = await PlatformDetector().getCapabilities();

    // Base estimate: 10 seconds for 1GB model on 8GB RAM
    double baseSeconds = 10.0;
    double ramFactor =
        8.0 / (capabilities.ramGB > 0 ? capabilities.ramGB : 4.0);
    double modelSizeFactor = model.ramRequired / 1.0;

    int totalSeconds = (baseSeconds * ramFactor * modelSizeFactor).round();
    return Duration(seconds: totalSeconds.clamp(5, 60));
  }

  Duration _calculateRemainingTime(double progress) {
    if (_warmupTimer == null || progress <= 0)
      return _currentState.estimatedTimeRemaining;

    final elapsed = _warmupTimer!.elapsed;
    if (progress >= 1.0) return Duration.zero;

    // (elapsed / progress) = total_estimated
    final totalEstimatedMs = elapsed.inMilliseconds / progress;
    final remainingMs = totalEstimatedMs - elapsed.inMilliseconds;

    return Duration(milliseconds: remainingMs.round());
  }

  Future<void> cancelWarmup() async {
    if (_currentState.status == WarmupStatus.completed ||
        _currentState.status == WarmupStatus.failed ||
        _currentState.status == WarmupStatus.idle) {
      return;
    }

    _warmupTimer?.stop();
    _progressSubscription?.cancel();
    _updateState(_currentState.copyWith(status: WarmupStatus.cancelled));

    _analytics.logEvent(
      'model_warmup_cancelled',
      parameters: {
        'model_id': _currentModel?.id,
        'progress': _currentState.progress,
        'duration_ms': _warmupTimer?.elapsedMilliseconds,
      },
    );

    _aiAnalytics.logMetric(
      ModelMetrics(
          loadTimeMs: _warmupTimer?.elapsedMilliseconds.toDouble() ?? 0.0),
      _currentModel?.id ?? 'unknown',
      operationType: 'warmup_cancelled',
      isSuccessful: false,
    );
  }

  void dispose() {
    _progressSubscription?.cancel();
    _stateController.close();
  }
}
