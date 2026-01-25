import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/utils/secure_logger.dart';

void main() {
  group('SecureLogger', () {
    // Variable to capture log output
    String? lastLog;

    setUp(() {
      lastLog = null;
      // Intercept debugPrint
      debugPrint = (String? message, {int? wrapWidth}) {
        lastLog = message;
      };
    });

    tearDown(() {
      // Restore debugPrint (though in tests it might reset per test)
      debugPrint = (String? message, {int? wrapWidth}) {
        // Default implementation prints to console
        if (message != null) print(message);
      };
    });

    test('redacts SSN', () {
      SecureLogger.log('User SSN is 123-45-6789 today.');
      expect(lastLog, contains('[SSN REDACTED]'));
      expect(lastLog, isNot(contains('123-45-6789')));
    });

    test('redacts Phone numbers', () {
      SecureLogger.log('Call me at 1234567890.');
      expect(lastLog, contains('[PHONE REDACTED]'));
      expect(lastLog, isNot(contains('1234567890')));
    });

    test('redacts Email addresses', () {
      SecureLogger.log('Email user@example.com for info.');
      expect(lastLog, contains('[EMAIL REDACTED]'));
      expect(lastLog, isNot(contains('user@example.com')));
    });

    test('redacts MRN', () {
      SecureLogger.log('Patient MRN-98765 admitted.');
      expect(lastLog, contains('[MRN REDACTED]'));
      expect(lastLog, isNot(contains('MRN-98765')));
    });

    test('redacts Doctor names', () {
      SecureLogger.log('Appointment with Dr. Smith tomorrow.');
      expect(lastLog, contains('[DOCTOR REDACTED]'));
      expect(lastLog, isNot(contains('Dr. Smith')));
    });

    test('supports custom patterns', () {
      SecureLogger.addCustomPattern(RegExp(r'secret\w+'));
      SecureLogger.log('This is a secretCode.');
      expect(lastLog, contains('[REDACTED]'));
      expect(lastLog, isNot(contains('secretCode')));
    });

    test('blocks highly sensitive keywords', () {
      SecureLogger.log('Here is the private key for encryption.');
      expect(lastLog, contains('Message blocked'));
      expect(lastLog, isNot(contains('private key')));
    });
  });
}
