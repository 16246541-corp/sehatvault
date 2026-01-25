import 'package:hive/hive.dart';

part 'generation_parameters.g.dart';

@HiveType(typeId: 31)
class GenerationParameters extends HiveObject {
  @HiveField(0)
  double temperature;

  @HiveField(1)
  double topP;

  @HiveField(2)
  int topK;

  @HiveField(3)
  int maxTokens;

  @HiveField(4)
  double presencePenalty;

  @HiveField(5)
  double frequencyPenalty;

  @HiveField(6)
  int seed;

  GenerationParameters({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.maxTokens = 1024,
    this.presencePenalty = 0.0,
    this.frequencyPenalty = 0.0,
    this.seed = -1,
  });

  GenerationParameters copyWith({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    double? presencePenalty,
    double? frequencyPenalty,
    int? seed,
  }) {
    return GenerationParameters(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      maxTokens: maxTokens ?? this.maxTokens,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      seed: seed ?? this.seed,
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
