import 'package:flutter/foundation.dart';

/// A secure logger wrapper that redacts sensitive information before printing to the console.
///
/// In Debug mode: Redacts sensitive data (SSN, Phone, Email, etc.) and prints to console.
/// In Release mode: Skips logging entirely to prevent sensitive data leakage.
class SecureLogger {
  // Store custom redaction patterns
  static final List<RegExp> _customPatterns = [];
  static final List<String> _customReplacements = [];

  /// Logs a message securely.
  ///
  /// - In Debug builds: Redacts sensitive data and prints using [debugPrint].
  /// - In Release builds: Does nothing.
  ///
  /// **Audit Exclusion**: This logger attempts to prevent logging of biometric results
  /// or encryption keys, but callers should ensure these are never passed.
  static void log(String message) {
    if (kReleaseMode) {
      // Release: Skip logging sensitive operations entirely
      return;
    }

    // Audit Exclusion check (basic safeguards)
    if (_containsHighlySensitiveData(message)) {
      debugPrint(
          '[SECURE LOGGER] Message blocked due to highly sensitive content (Keys/Biometrics).');
      return;
    }

    final redacted = _redactSensitiveData(message);
    debugPrint(redacted);
  }

  /// Adds a custom redaction pattern.
  /// [replacement] is optional, defaults to '[REDACTED]'.
  static void addCustomPattern(RegExp pattern,
      {String replacement = '[REDACTED]'}) {
    _customPatterns.add(pattern);
    _customReplacements.add(replacement);
  }

  /// Redacts sensitive data from the input string based on predefined and custom patterns.
  static String redact(String input) {
    return _redactSensitiveData(input);
  }

  /// Redacts sensitive data from the input string based on predefined and custom patterns.
  static String _redactSensitiveData(String input) {
    var output = input;

    // 1. Social Security Numbers (XXX-XX-XXXX)
    output =
        output.replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[SSN REDACTED]');

    // 2. Phone numbers (10 digits)
    // Note: This is a simple pattern as requested.
    output = output.replaceAll(RegExp(r'\b\d{10}\b'), '[PHONE REDACTED]');

    // 3. Email addresses
    output = output.replaceAll(
        RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}'),
        '[EMAIL REDACTED]');

    // 4. Medical Record Numbers (MRN)
    // Assuming common formats like MRN-12345 or just labelling explicitly tagged MRNs.
    // We'll use a generic pattern for "MRN" followed by digits/chars.
    output = output.replaceAll(
        RegExp(r'\bMRN[-: ]?[\w]+\b', caseSensitive: false), '[MRN REDACTED]');

    // 5. Doctor names
    // Redacts patterns like "Dr. Name" or "Doctor Name"
    output = output.replaceAll(
        RegExp(r'\b(Dr\.|Doctor)\s+[A-Z][a-z]+\b'), '[DOCTOR REDACTED]');

    // 6. Custom Patterns
    for (int i = 0; i < _customPatterns.length; i++) {
      output = output.replaceAll(_customPatterns[i], _customReplacements[i]);
    }

    return output;
  }

  /// Checks for highly sensitive data that should never be logged even in redacted form
  /// if we can detect it (like raw keys).
  static bool _containsHighlySensitiveData(String message) {
    // Check for keywords indicating raw key dumps or biometric auth tokens
    final lower = message.toLowerCase();
    if (lower.contains('private key') ||
        lower.contains('biometric_token') ||
        lower.contains('auth_result_raw')) {
      return true;
    }
    // Check for likely AES keys (32 bytes hex or base64 often look specific, but hard to catch generic strings)
    // We rely on caller mostly, but this catches explicit labels.
    return false;
  }
}
