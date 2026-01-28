import 'package:hive/hive.dart';

part 'generation_parameters.g.dart';

@HiveType(typeId: 31)
class GenerationParameters extends HiveObject {
  @HiveField(0, defaultValue: 0.7)
  double temperature;

  @HiveField(1, defaultValue: 0.9)
  double topP;

  @HiveField(2, defaultValue: 40)
  int topK;

  @HiveField(3, defaultValue: 1024)
  int maxTokens;

  @HiveField(4, defaultValue: 0.0)
  double presencePenalty;

  @HiveField(5, defaultValue: 0.0)
  double frequencyPenalty;

  @HiveField(6, defaultValue: -1)
  int seed;

  @HiveField(7, defaultValue: false)
  bool enablePatternContext;

  GenerationParameters({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.maxTokens = 1024,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.seed = -1,
    this.enablePatternContext = false,
  });

  GenerationParameters copyWith({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    int? seed,
    bool? enablePatternContext,
  }) {
    return GenerationParameters(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      maxTokens: maxTokens ?? this.maxTokens,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      seed: seed ?? this.seed,
      enablePatternContext: enablePatternContext ?? this.enablePatternContext,
    );
  }

  factory GenerationParameters.balanced() => GenerationParameters(
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxTokens: 1024,
      );

  factory GenerationParameters.creative() => GenerationParameters(
        temperature: 0.9,
        topP: 0.95,
        topK: 50,
        maxTokens: 1024,
      );

  factory GenerationParameters.precise() => GenerationParameters(
        temperature: 0.2,
        topP: 0.5,
        topK: 20,
        maxTokens: 1024,
      );

  factory GenerationParameters.fast() => GenerationParameters(
        temperature: 0.6,
        topP: 0.9,
        topK: 40,
        maxTokens: 512,
      );
}
