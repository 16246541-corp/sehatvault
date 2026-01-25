import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/ai_service.dart';
import 'package:sehatlocker/services/validation/validation_rule.dart';

void main() {
  late AIService aiService;

  setUp(() {
    aiService = AIService();
  });

  group('AIService Validation Tests', () {
    test('Treatment Recommendation Rule triggers replacement', () async {
      // Prompt that triggers "You should take 500mg..."
      final stream = aiService.generateResponse("medicine take");

      final results = await stream.toList();
      final finalResult = results.last;

      expect(finalResult.isModified, isTrue);
      expect(finalResult.warning, contains("Treatment recommendation blocked"));
      expect(finalResult.content,
          contains("I cannot provide specific treatment recommendations"));
    });

    test('Triage Advice Rule triggers warning', () async {
      // Prompt that triggers "Go to the ER"
      final stream = aiService.generateResponse("emergency");

      final results = await stream.toList();
      final finalResult = results.last;

      expect(finalResult.isModified, isTrue);
      expect(finalResult.warning, contains("medical emergency"));
      // The content might be the original "Go to the ER" but with a warning wrapper in the result
      expect(finalResult.content, contains("Go to the ER"));
    });

    test('Diagnostic Language Rule triggers rewrite', () async {
      // Prompt that triggers "You have a fracture"
      final stream = aiService.generateResponse("pain hurt");

      final results = await stream.toList();
      final finalResult = results.last;

      expect(finalResult.isModified, isTrue);
      expect(finalResult.warning, contains("diagnostic language"));
      // Should be rewritten. SafetyFilterService rewrites "You have..." -> "Some people..."
      expect(
          finalResult.content, contains("Some people with similar concerns"));
    });

    test('Safe content passes through unmodified', () async {
      final stream = aiService.generateResponse("hello");

      final results = await stream.toList();
      // Should yield chunks
      expect(results.length, greaterThan(1));

      // Accumulate content
      final fullContent = results.map((r) => r.content).join('');
      expect(fullContent, contains("analyzing your data"));

      // None should be modified
      expect(results.any((r) => r.isModified), isFalse);
    });
  });
}
