import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/utils/secure_logger.dart';

void main() {
  group('Issue Reporting Redaction Suite', () {
    test('redacts SSN from string', () {
      const input = 'My SSN is 123-45-6789.';
      final output = SecureLogger.redact(input);
      expect(output, contains('[SSN REDACTED]'));
      expect(output, isNot(contains('123-45-6789')));
    });

    test('redacts Phone numbers from string', () {
      const input = 'Call 1234567890 now.';
      final output = SecureLogger.redact(input);
      expect(output, contains('[PHONE REDACTED]'));
      expect(output, isNot(contains('1234567890')));
    });

    test('redacts Email addresses from string', () {
      const input = 'Contact admin@sehatlocker.com for help.';
      final output = SecureLogger.redact(input);
      expect(output, contains('[EMAIL REDACTED]'));
      expect(output, isNot(contains('admin@sehatlocker.com')));
    });

    test('redacts MRN from string', () {
      const input = 'Patient id: MRN-55555.';
      final output = SecureLogger.redact(input);
      expect(output, contains('[MRN REDACTED]'));
      expect(output, isNot(contains('MRN-55555')));
    });

    test('redacts Doctor names from string', () {
      const input = 'Dr. House diagnosed this.';
      final output = SecureLogger.redact(input);
      expect(output, contains('[DOCTOR REDACTED]'));
      expect(output, isNot(contains('Dr. House')));
    });

    test('redacts multiple sensitive items', () {
      const input =
          'Dr. House (MRN-123) sent email to test@test.com about 123-45-6789';
      final output = SecureLogger.redact(input);
      expect(output, contains('[DOCTOR REDACTED]'));
      expect(output, contains('[MRN REDACTED]'));
      expect(output, contains('[EMAIL REDACTED]'));
      expect(output, contains('[SSN REDACTED]'));
      expect(output, isNot(contains('House')));
      expect(
          output,
          isNot(contains(
              '123'))); // MRN number part might be tricky if it matches other things, but here it's part of MRN pattern
      expect(output, isNot(contains('test@test.com')));
    });
  });
}
