import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/wellness_language_validator.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WellnessLanguageValidator', () {
    late WellnessLanguageValidator validator;

    setUp(() async {
      validator = WellnessLanguageValidator();

      const mockData = {
        "replacements": [
          {
            "term": "diabetic",
            "replacement": "person with diabetes",
            "context": "condition_identity",
            "severity": "low"
          },
          {
            "term": "addict",
            "replacement": "person with substance use disorder",
            "context": "condition_identity",
            "severity": "high"
          },
          {
            "term": "suffering from",
            "replacement": "living with",
            "context": "victimization",
            "severity": "medium"
          }
        ],
        "exceptions": ["American Diabetic Association"]
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
        final String key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/data/wellness_terminology.json') {
          return ByteData.view(
              Uint8List.fromList(utf8.encode(json.encode(mockData))).buffer);
        }
        return null;
      });

      await validator.load();
    });

    test('replaces stigmatizing terms with person-first language', () {
      final input = 'The patient is a diabetic.';
      final expected = 'The patient is a person with diabetes.';
      expect(validator.validate(input), equals(expected));
    });

    test('preserves capitalization', () {
      final input = 'Diabetic patients need care.';
      final expected = 'Person with diabetes patients need care.';
      expect(validator.validate(input), equals(expected));
    });

    test('ignores exceptions', () {
      final input = 'According to the American Diabetic Association...';
      expect(validator.validate(input), equals(input));
    });

    test('handles multiple replacements', () {
      final input = 'The addict is suffering from depression.';
      final expected =
          'The person with substance use disorder is living with depression.';
      expect(validator.validate(input), equals(expected));
    });

    test('handles empty input', () {
      expect(validator.validate(''), equals(''));
    });

    test('handles text with no matches', () {
      final input = 'The patient has a headache.';
      expect(validator.validate(input), equals(input));
    });
  });
}
