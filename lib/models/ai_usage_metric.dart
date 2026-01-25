import 'package:hive/hive.dart';

part 'ai_usage_metric.g.dart';

@HiveType(typeId: 32)
class AIUsageMetric extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String modelId;

  @HiveField(2)
  final double tokensPerSecond;

  @HiveField(3)
  final int totalTokens;

  @HiveField(4)
  final double loadTimeMs;

  @HiveField(5)
  final double peakMemoryMb;

  @HiveField(6)
  final String? operationType; // e.g., 'inference', 'warmup', 'load'

  @HiveField(7)
  final bool isSuccessful;

  @HiveField(8)
  final Map<String, String>? metadata;

  AIUsageMetric({
    required this.timestamp,
    required this.modelId,
    this.tokensPerSecond = 0,
    this.totalTokens = 0,
    this.loadTimeMs = 0,
    this.peakMemoryMb = 0,
    this.operationType,
    this.isSuccessful = true,
    this.metadata,
  });
}
