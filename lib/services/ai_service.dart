import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/model_option.dart';
import 'llm_engine.dart';
import '../utils/secure_logger.dart';
import 'citation_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';
import 'model_manager.dart';
import 'validation/validation_rule.dart';
import 'validation/rules/treatment_recommendation_rule.dart';
import 'validation/rules/triage_advice_rule.dart';
import 'validation/rules/diagnostic_language_rule.dart';
import 'prompt_template_service.dart';
import 'model_fallback_service.dart';
import 'medical_field_extractor.dart';
import 'ai_middleware/output_pipeline.dart';
import 'ai_middleware/pipeline_stage.dart';
import 'ai_middleware/stages/safety_filter_stage.dart';
import 'ai_middleware/stages/validation_stage.dart';
import 'ai_middleware/stages/citation_stage.dart';
import 'ai_middleware/pipeline_debugger.dart';
import 'safety_filter_service.dart';

class AIService {
  static final AIService _instance = AIService.internal();
  factory AIService() => _instance;

  @protected
  AIService.internal() {
    _initRules();
    _initPipeline();
  }

  final List<ValidationRule> _rules = [];
  final SessionManager _sessionManager = SessionManager();
  final CitationService _citationService =
      CitationService(LocalStorageService());
  final PromptTemplateService _promptTemplateService = PromptTemplateService();
  final OutputPipeline _pipeline = OutputPipeline();

  void _initRules() {
    // In a real app, load from JSON. For now, add manually.
    _rules.add(TreatmentRecommendationRule());
    _rules.add(TriageAdviceRule());
    _rules.add(DiagnosticLanguageRule());
    _rules.sort((a, b) => a.priority.compareTo(b.priority));
  }

  void _initPipeline() {
    // Stage 1: Initial Sanitization (Sequential)
    _pipeline.addStage(SafetyFilterStage(SafetyFilterService()));

    // Stage 2: Independent Validation Stages (Parallel)
    // We can run multiple validation rules or other independent checks here
    _pipeline.addStage(ParallelPipelineStage(
      'parallel_validation',
      [
        ValidationStage(_rules),
        // Add other independent stages here if needed
      ],
      priority: 20,
    ));

    // Stage 3: Post-processing (Sequential)
    _pipeline.addStage(CitationStage(_citationService));
  }

  /// Generates a response from the AI model (LLMEngine) and applies validation middleware.
  ///
  /// The [prompt] is the user's input.
  /// [history] is the conversation history for context.
  /// Returns a Stream of [ValidationResult].
  Stream<ValidationResult> generateResponse(String prompt,
      {List<Map<String, String>> history = const []}) async* {
    // 1. Get current model and ensure it's loaded
    ModelOption activeModel = await ModelManager.getRecommendedModel();
    final llmEngine = LLMEngine();

    try {
      await llmEngine.initialize(activeModel);
    } catch (e) {
      SecureLogger.log(
          "Failed to initialize LLMEngine in generateResponse: $e");
      yield ValidationResult.blocked(
          "AI engine failed to initialize. Please check device storage and memory.");
      return;
    }

    // Update activeModel in case of fallback during initialization
    if (llmEngine.currentModel != null) {
      activeModel = llmEngine.currentModel!;
    }

    // 2. Prepare Context using PromptTemplateService
    final medicalData = MedicalFieldExtractor.extractLabValues(prompt);
    final contextString = medicalData['values'].isNotEmpty
        ? "Extracted medical data: ${json.encode(medicalData['values'])}"
        : "No specific medical data extracted from current input.";

    final systemPrompt = _promptTemplateService.generatePrompt(
      templateId: 'medical_assistant',
      variables: {
        'context': contextString,
        'user_input': prompt,
      },
    );

    final managedPrompt =
        llmEngine.manageContext(systemPrompt, history, prompt);

    // 3. Stream generation from LLMEngine
    Stream<String>? llmStream;
    try {
      llmStream = llmEngine.generate(managedPrompt);
    } catch (e) {
      if (e is LLMEngineException) {
        final fallbackModel = await ModelFallbackService().evaluateFallback(
          activeModel,
          error: e,
        );

        if (fallbackModel != null) {
          _sessionManager.preserveModelContext(
              ModelFallbackService().captureContext(llmEngine));
          // Recursive call with fallback model already initialized in evaluateFallback logic if integrated?
          // Actually ModelManager.loadModel handles the fallback.
          // For simplicity, we re-trigger generation which will pick up the new model via initialize()
          yield* generateResponse(prompt, history: history);
          return;
        }
      }
      rethrow;
    }

    String accumulatedResponse = "";

    await for (final chunk in llmStream) {
      accumulatedResponse += chunk;

      // Run pipeline for real-time processing
      final context = await _pipeline.process(
        prompt,
        accumulatedResponse,
        history: history,
      );

      // Performance and Debugging
      PipelineDebugger.logPipelineExecution(context);

      if (context.isBlocked) {
        _sessionManager.trackValidationFailure();
        yield ValidationResult.blocked(
            context.blockReason ?? "Content blocked by safety policy");
        return; // Interrupt stream
      }

      if (context.content != accumulatedResponse) {
        // Content was modified (e.g. by safety filter or validation rule)
        // For streaming, if it was modified, we might need to update what's shown
        // In this implementation, we yield the modified result which replaces the whole content.
        yield ValidationResult.modified(context.content);

        // If it was a major modification (like a rewrite), we might want to stop streaming
        // and just show the final rewritten content.
        if (context.metadata['safety_triggered'] == true) {
          return;
        }
      } else {
        // If valid and unmodified, yield the chunk
        yield ValidationResult.valid(chunk);
      }
    }
  }

  /// Processes existing content through the output pipeline.
  Future<String> processContent(String content, {String prompt = ""}) async {
    final context = await _pipeline.process(prompt, content);
    PipelineDebugger.logPipelineExecution(context);
    return context.content;
  }

  Stream<String> _getSimulatedResponseStream(String prompt) async* {
    // Simple simulation based on keywords in prompt for testing
    if (prompt.contains("medicine") || prompt.contains("take")) {
      yield "You ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "should ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "take ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "500mg ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "of ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "Amoxicillin.";
    } else if (prompt.contains("pain") || prompt.contains("hurt")) {
      yield "You ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "have ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "a ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "fracture.";
    } else if (prompt.contains("emergency")) {
      yield "Go ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "to ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "the ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "ER.";
    } else {
      yield "I ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "am ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "analyzing ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "your ";
      await Future.delayed(const Duration(milliseconds: 50));
      yield "data.";
    }
  }
}
