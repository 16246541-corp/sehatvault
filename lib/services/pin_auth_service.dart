import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'local_storage_service.dart';
import 'auth_audit_service.dart';

enum PinVerificationStatus { success, invalid, lockedOut, expired, notSet }

enum PinSecurityQuestion { mothersMaidenName, firstPet }

extension PinSecurityQuestionLabel on PinSecurityQuestion {
  String get label {
    switch (this) {
      case PinSecurityQuestion.mothersMaidenName:
        return "Mother's maiden name";
      case PinSecurityQuestion.firstPet:
        return 'First pet name';
    }
  }
}

class PinVerificationResult {
  final PinVerificationStatus status;
  final String? message;
  final Duration? lockoutRemaining;
  final bool requiresChange;

  const PinVerificationResult({
    required this.status,
    this.message,
    this.lockoutRemaining,
    this.requiresChange = false,
  });

  bool get isSuccess => status == PinVerificationStatus.success;
}

class PinAuthService {
  static final PinAuthService _instance = PinAuthService._internal();
  factory PinAuthService() => _instance;
  PinAuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _pinHashKey = 'pin_hash';
  static const String _pinCreatedKey = 'pin_created';
  static const String _pinFailedAttemptsKey = 'pin_failed_attempts';
  static const String _pinLockoutUntilKey = 'pin_lockout_until';
  static const String _pinLockoutCountKey = 'pin_lockout_count';
  static const String _pinSecurityQuestionKey = 'pin_security_question';
  static const String _pinSecurityAnswerHashKey = 'pin_security_answer_hash';
  static const String _pinSecurityAnswerCreatedKey =
      'pin_security_answer_created';

  static const int _maxAttempts = 5;
  static const Duration _baseLockout = Duration(seconds: 30);
  static const int _expiryDays = 90;

  Future<bool> hasPin() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<bool> setPin(String pin) async {
    try {
      final hash = _hashValue(pin);
      await _secureStorage.write(key: _pinHashKey, value: hash);
      await _secureStorage.write(
        key: _pinCreatedKey,
        value: DateTime.now().toIso8601String(),
      );
      await _resetAttempts();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> getPinCreatedAt() async {
    final value = await _secureStorage.read(key: _pinCreatedKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<bool> isPinExpired() async {
    final created = await getPinCreatedAt();
    if (created == null) {
      return false;
    }
    final age = DateTime.now().difference(created);
    return age.inDays >= _expiryDays;
  }

  Future<PinVerificationResult> verifyPin(String pin) async {
    final authAuditService = AuthAuditService(LocalStorageService());
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null || storedHash.isEmpty) {
      return const PinVerificationResult(
        status: PinVerificationStatus.notSet,
        message: 'No PIN is set',
      );
    }

    final lockoutRemaining = await _getLockoutRemaining();
    if (lockoutRemaining != null && lockoutRemaining > Duration.zero) {
      await authAuditService.logEvent(
        action: 'pin_verify',
        success: false,
        failureReason: 'Locked out',
      );
      return PinVerificationResult(
        status: PinVerificationStatus.lockedOut,
        message: 'Too many attempts. Try again later.',
        lockoutRemaining: lockoutRemaining,
      );
    }

    final inputHash = _hashValue(pin);
    if (inputHash == storedHash) {
      final expired = await isPinExpired();
      await _resetAttempts();

      await authAuditService.logEvent(
        action: 'pin_verify',
        success: true,
      );

      if (expired) {
        return const PinVerificationResult(
          status: PinVerificationStatus.expired,
          message: 'PIN expired. Update required.',
          requiresChange: true,
        );
      }
      return const PinVerificationResult(
        status: PinVerificationStatus.success,
      );
    }

    final attempts = await _incrementFailedAttempts();

    await authAuditService.logEvent(
      action: 'pin_verify',
      success: false,
      failureReason: 'Incorrect PIN',
    );

    if (attempts >= _maxAttempts) {
      final lockout = await _applyLockout();
      return PinVerificationResult(
        status: PinVerificationStatus.lockedOut,
        message: 'Too many attempts. Try again later.',
        lockoutRemaining: lockout,
      );
    }

    return const PinVerificationResult(
      status: PinVerificationStatus.invalid,
      message: 'Incorrect PIN',
    );
  }

  Future<void> clearLockout() async {
    await _secureStorage.delete(key: _pinLockoutUntilKey);
    await _secureStorage.write(key: _pinFailedAttemptsKey, value: '0');
  }

  Future<bool> setSecurityQuestion(
    PinSecurityQuestion question,
    String answer,
  ) async {
    try {
      final hash = _hashValue(_normalizeAnswer(answer));
      await _secureStorage.write(
        key: _pinSecurityQuestionKey,
        value: question.name,
      );
      await _secureStorage.write(
        key: _pinSecurityAnswerHashKey,
        value: hash,
      );
      await _secureStorage.write(
        key: _pinSecurityAnswerCreatedKey,
        value: DateTime.now().toIso8601String(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PinSecurityQuestion?> getSecurityQuestion() async {
    final key = await _secureStorage.read(key: _pinSecurityQuestionKey);
    if (key == null || key.isEmpty) {
      return null;
    }
    for (final question in PinSecurityQuestion.values) {
      if (question.name == key) {
        return question;
      }
    }
    return null;
  }

  Future<bool> verifySecurityAnswer(String answer) async {
    final storedHash =
        await _secureStorage.read(key: _pinSecurityAnswerHashKey);
    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }
    final inputHash = _hashValue(_normalizeAnswer(answer));
    final matches = inputHash == storedHash;
    if (matches) {
      await clearLockout();
    }
    return matches;
  }

  String _hashValue(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  String _normalizeAnswer(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<int> _incrementFailedAttempts() async {
    final value = await _secureStorage.read(key: _pinFailedAttemptsKey);
    final current = int.tryParse(value ?? '0') ?? 0;
    final next = current + 1;
    await _secureStorage.write(
      key: _pinFailedAttemptsKey,
      value: next.toString(),
    );
    return next;
  }

  Future<void> _resetAttempts() async {
    await _secureStorage.write(key: _pinFailedAttemptsKey, value: '0');
    await _secureStorage.delete(key: _pinLockoutUntilKey);
    await _secureStorage.write(key: _pinLockoutCountKey, value: '0');
  }

  Future<Duration?> _getLockoutRemaining() async {
    final value = await _secureStorage.read(key: _pinLockoutUntilKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    final lockoutUntil = DateTime.tryParse(value);
    if (lockoutUntil == null) {
      return null;
    }
    final now = DateTime.now();
    if (now.isAfter(lockoutUntil)) {
      await _secureStorage.delete(key: _pinLockoutUntilKey);
      return null;
    }
    return lockoutUntil.difference(now);
  }

  Future<Duration> _applyLockout() async {
    final value = await _secureStorage.read(key: _pinLockoutCountKey);
    final count = int.tryParse(value ?? '0') ?? 0;
    final nextCount = count + 1;
    final multiplier = 1 << (nextCount - 1);
    final lockoutDuration =
        Duration(seconds: _baseLockout.inSeconds * multiplier);
    final lockoutUntil = DateTime.now().add(lockoutDuration);
    await _secureStorage.write(
      key: _pinLockoutUntilKey,
      value: lockoutUntil.toIso8601String(),
    );
    await _secureStorage.write(
      key: _pinLockoutCountKey,
      value: nextCount.toString(),
    );
    await _secureStorage.write(key: _pinFailedAttemptsKey, value: '0');
    return lockoutDuration;
  }
}
