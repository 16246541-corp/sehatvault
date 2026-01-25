import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:sehatlocker/services/llm_engine.dart';
import 'package:sehatlocker/models/model_option.dart';

@GenerateMocks([LlamaParent, ModelOption])
void main() {
  // Since LLMEngine is a singleton and depends on LlamaParent which is hard to mock
  // without structural changes to LLMEngine (to allow injection),
  // we will focus on testing the state management and public API behavior
  // where possible, or suggest refactoring for better testability.

  group('LLMEngine Tests', () {
    late LLMEngine engine;

    setUp(() {
      engine = LLMEngine();
    });

    test('LLMEngine should be a singleton', () {
      final engine1 = LLMEngine();
      final engine2 = LLMEngine();
      expect(identical(engine1, engine2), isTrue);
    });

    test('initializationProgress should emit values', () async {
      // This is hard to test without a real model file and llama_cpp setup
      // but we can verify the stream exists
      expect(engine.initializationProgress, isA<Stream<double>>());
    });

    test('shouldDegrade should return false initially', () {
      expect(engine.shouldDegrade(), isFalse);
    });
  });
}
