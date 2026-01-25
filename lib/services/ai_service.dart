import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/secure_logger.dart';
import 'citation_service.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';
import 'validation/validation_rule.dart';
import 'validation/rules/treatment_recommendation_rule.dart';
import 'validation/rules/triage_advice_rule.dart';
import 'validation/rules/diagnostic_language_rule.dart';

class AIService {
  static final AIService _instance = AIService.internal();
  factory AIService() => _instance;

  @protected
  AIService.internal() {
    _initRules();
  }

  final List<ValidationRule> _rules = [];
  final SessionManager _sessionManager = SessionManager();
  final CitationService _citationService =
      CitationService(LocalStorageService());

  void _initRules() {
    // In a real app, load from JSON. For now, add manually.
    _rules.add(TreatmentRecommendationRule());
    _rules.add(TriageAdviceRule());
    _rules.add(DiagnosticLanguageRule());
    _rules.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Generates a response from the AI model (simulated) and applies validation middleware.
  ///
  /// The [prompt] is the user's input.
  /// Returns a Stream of [ValidationResult].
  Stream<ValidationResult> generateResponse(String prompt) async* {
    // Simulate LLM stream generation
    // In a real integration, this would come from the ModelManager
    final simulatedStream = _getSimulatedResponseStream(prompt);

    String accumulatedResponse = "";

    await for (final chunk in simulatedStream) {
      accumulatedResponse += chunk;

      // Validation Middleware
      ValidationResult? validationResult;

      for (final rule in _rules) {
        if (!rule.enabled) continue;

        final stopwatch = Stopwatch()..start();
        final result = await rule.validate(accumulatedResponse);
        stopwatch.stop();

        if (stopwatch.elapsedMilliseconds > 30) {
          SecureLogger.log(
              "Performance Warning: Rule ${rule.id} took ${stopwatch.elapsedMilliseconds}ms");
        }

        if (result.isModified || !result.isValid) {
          validationResult = result;
          // Stop at the highest priority rule that triggers
          break;
        }
      }

      if (validationResult != null) {
        // Log failure/modification
        _sessionManager.trackValidationFailure();
        SecureLogger.log(
            "Validation triggered: ${validationResult.warning ?? 'Content modified'}");

        // If the content is modified or blocked, we interrupt the stream
        // and yield the modified result (which typically replaces the whole content).
        yield validationResult;
        return; // Interrupt stream
      }

      // If valid, yield the chunk
      yield ValidationResult.valid(chunk);
    }

    final citations =
        _citationService.generateCitationsFromText(accumulatedResponse);
    if (citations.isNotEmpty) {
      for (final citation in citations) {
        await _citationService.addCitation(citation);
      }
      final formatted =
          _citationService.formatCitations(citations, style: 'reference');
      if (formatted.isNotEmpty) {
        yield ValidationResult.valid('\n\nReferences:\n$formatted');
      }
    }
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
