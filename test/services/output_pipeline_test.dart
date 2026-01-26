import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/ai_middleware/output_pipeline.dart';
import 'package:sehatlocker/services/ai_middleware/pipeline_context.dart';
import 'package:sehatlocker/services/ai_middleware/pipeline_stage.dart';
import 'package:sehatlocker/services/ai_middleware/stages/safety_filter_stage.dart';
import 'package:sehatlocker/services/ai_middleware/stages/validation_stage.dart';
import 'package:sehatlocker/services/ai_middleware/stages/citation_stage.dart';
import 'package:sehatlocker/services/safety_filter_service.dart';
import 'package:sehatlocker/services/citation_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';
import 'package:sehatlocker/services/validation/rules/treatment_recommendation_rule.dart';
import 'package:sehatlocker/models/ai_usage_metric.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late OutputPipeline pipeline;
  late SafetyFilterService safetyFilter;
  late CitationService citationService;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(AIUsageMetricAdapter());
    }
    if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
    if (!Hive.isBoxOpen('citations')) await Hive.openBox('citations');
    if (!Hive.isBoxOpen('ai_usage_metrics')) {
      await Hive.openBox<AIUsageMetric>('ai_usage_metrics');
    }
  });

  setUp(() {
    pipeline = OutputPipeline();
    safetyFilter = SafetyFilterService();
    citationService = CitationService(LocalStorageService());
  });

  group('Output Processing Pipeline Tests', () {
    test('Pipeline runs stages in correct priority order', () async {
      final stage1 = _MockStage('low_priority', priority: 100);
      final stage2 = _MockStage('high_priority', priority: 10);

      pipeline.addStage(stage1);
      pipeline.addStage(stage2);

      final context = await pipeline.process('prompt', 'content');

      final stages = context.performanceMetrics.keys.toList();
      expect(stages[0], 'high_priority');
      expect(stages[1], 'low_priority');
    });

    test('SafetyFilterStage sanitizes prohibited language', () async {
      pipeline.addStage(SafetyFilterStage(safetyFilter));

      const input = 'You have a fracture.';
      final context = await pipeline.process('check', input);

      expect(context.content, contains('Some people with similar concerns'));
      expect(context.metadata['safety_triggered'], isTrue);
    });

    test('ValidationStage blocks invalid content', () async {
      pipeline.addStage(ValidationStage([TreatmentRecommendationRule()]));

      const input = 'You should take 500mg of Amoxicillin.';
      final context = await pipeline.process('advice', input);

      expect(context.isBlocked, isTrue);
      expect(context.blockReason, contains('Treatment recommendation blocked'));
    });

    test('ParallelPipelineStage runs sub-stages', () async {
      final s1 = _MockStage('s1');
      final s2 = _MockStage('s2');
      pipeline.addStage(ParallelPipelineStage('parallel', [s1, s2]));

      final context = await pipeline.process('p', 'c');

      expect(context.performanceMetrics.containsKey('s1'), isTrue);
      expect(context.performanceMetrics.containsKey('s2'), isTrue);
    });
  });
}

class _MockStage extends PipelineStage {
  final String _id;
  final int _priority;

  _MockStage(this._id, {int priority = 100}) : _priority = priority;

  @override
  String get id => _id;

  @override
  int get priority => _priority;

  @override
  Future<void> process(PipelineContext context) async {
    // Do nothing
  }
}
