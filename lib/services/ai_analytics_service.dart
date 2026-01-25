import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ai_usage_metric.dart';
import '../models/app_settings.dart';
import '../utils/secure_logger.dart';
import 'local_storage_service.dart';
import 'llm_engine.dart';

class AIAnalyticsService {
  static final AIAnalyticsService _instance = AIAnalyticsService._internal();
  factory AIAnalyticsService() => _instance;
  AIAnalyticsService._internal();

  static const String boxName = 'ai_usage_metrics';
  Box<AIUsageMetric>? _box;

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<AIUsageMetric>(boxName);
    await _purgeOldData();

    // Listen to LLMEngine metrics if available
    LLMEngine().metricsStream.listen((metrics) {
      logMetric(
        metrics,
        LLMEngine().currentModel?.id ?? 'unknown',
        operationType: 'inference',
      );
    });
  }

  /// Logs a performance metric securely and only if opted-in
  Future<void> logMetric(
    ModelMetrics metrics,
    String modelId, {
    String? operationType,
    bool isSuccessful = true,
    Map<String, String>? metadata,
  }) async {
    final settings = LocalStorageService().getAppSettings();
    if (!settings.enableAiAnalytics) return;

    if (_box == null) await init();

    final metric = AIUsageMetric(
      timestamp: DateTime.now(),
      modelId: modelId,
      tokensPerSecond: metrics.tokensPerSecond,
      totalTokens: metrics.totalTokens,
      loadTimeMs: metrics.loadTimeMs,
      peakMemoryMb: metrics.peakMemoryMb,
      operationType: operationType,
      isSuccessful: isSuccessful,
      metadata: metadata,
    );

    await _box?.add(metric);
    SecureLogger.log(
        'AI Analytics: Logged metric for $modelId ($operationType)');
  }

  /// Retrieves metrics within a time range
  List<AIUsageMetric> getMetrics({DateTime? start, DateTime? end}) {
    if (_box == null) return [];

    return _box!.values.where((m) {
      if (start != null && m.timestamp.isBefore(start)) return false;
      if (end != null && m.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// Calculates average tokens per second per model
  Map<String, double> getAverageTps() {
    if (_box == null) return {};

    final Map<String, List<double>> modelTps = {};
    for (var metric in _box!.values) {
      if (metric.tokensPerSecond > 0) {
        modelTps
            .putIfAbsent(metric.modelId, () => [])
            .add(metric.tokensPerSecond);
      }
    }

    return modelTps.map((id, list) => MapEntry(
          id,
          list.reduce((a, b) => a + b) / list.length,
        ));
  }

  /// Automatically purges data older than the retention policy
  Future<void> _purgeOldData() async {
    if (_box == null) return;

    final settings = LocalStorageService().getAppSettings();
    final retentionDays = settings.aiAnalyticsRetentionDays;
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));

    final keysToDelete = <dynamic>[];
    for (var key in _box!.keys) {
      final metric = _box!.get(key);
      if (metric != null && metric.timestamp.isBefore(cutoff)) {
        keysToDelete.add(key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _box?.deleteAll(keysToDelete);
      SecureLogger.log(
          'AI Analytics: Purged ${keysToDelete.length} old records');
    }
  }

  /// Exports anonymized analytics data
  Future<void> exportAnonymizedData() async {
    if (_box == null) return;

    final metrics = _box!.values
        .map((m) => {
              'timestamp': m.timestamp.toIso8601String(),
              'modelId': m.modelId,
              'tps': m.tokensPerSecond,
              'totalTokens': m.totalTokens,
              'loadTimeMs': m.loadTimeMs,
              'peakMemoryMb': m.peakMemoryMb,
              'operation': m.operationType,
              'success': m.isSuccessful,
            })
        .toList();

    final jsonString = jsonEncode({
      'exportDate': DateTime.now().toIso8601String(),
      'deviceType': kIsWeb ? 'Web' : Platform.operatingSystem,
      'metrics': metrics,
    });

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/ai_analytics_export.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Sehat Locker AI Analytics Export',
    );
  }

  /// Clears all analytics data
  Future<void> clearAllData() async {
    await _box?.clear();
    SecureLogger.log('AI Analytics: All data cleared');
  }
}
