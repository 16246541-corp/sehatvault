import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:app_settings/app_settings.dart';
import 'local_storage_service.dart';
import 'auth_audit_service.dart';

enum BiometricStatus {
  enrolled,
  availableButNotEnrolled,
  notAvailable,
}

class BiometricAuthException implements Exception {
  final String message;
  final String code;
  BiometricAuthException(this.message, this.code);
  @override
  String toString() => message;
}

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;

  BiometricService._internal() : auth = LocalAuthentication() {
    _sessionId = const Uuid().v4();
  }

  BiometricService.withAuth(this.auth) {
    _sessionId = const Uuid().v4();
  }

  final LocalAuthentication auth;
  late final String _sessionId;
  DateTime? _lastAuthenticatedTime;
  static const Duration _authSessionDuration = Duration(minutes: 2);

  String get sessionId => _sessionId;

  Future<bool> get hasEnrolledBiometrics async {
    try {
      return await auth.canCheckBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> get isBiometricsAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<BiometricStatus> getBiometricStatus() async {
    try {
      final bool isSupported = await auth.isDeviceSupported();
      if (!isSupported) {
        return BiometricStatus.notAvailable;
      }

      final bool canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        return BiometricStatus.enrolled;
      }

      return BiometricStatus.availableButNotEnrolled;
    } on PlatformException catch (_) {
      return BiometricStatus.notAvailable;
    }
  }

  Future<void> openSecuritySettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.security);
  }

  Future<List<BiometricType>> getEnrolledTypes() async {
    try {
      return await auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<bool> authenticate({required String reason, String? sessionId}) async {
    if (sessionId != null && sessionId != _sessionId) {
      throw BiometricAuthException(
        'Session expired. Please try again.',
        'session_mismatch',
      );
    }

    if (!await isBiometricsAvailable) {
      return false;
    }

    // Check for cached session
    if (_lastAuthenticatedTime != null) {
      final difference = DateTime.now().difference(_lastAuthenticatedTime!);
      if (difference < _authSessionDuration) {
        // Log cached access
        await _logAuth(reason, true, 'Cached session');
        return true;
      }
    }

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: reason,
        // options: const AuthenticationOptions(
        //   stickyAuth: true,
        //   biometricOnly: false,
        // ),
      );

      if (authenticated) {
        _lastAuthenticatedTime = DateTime.now();
      }

      await _logAuth(reason, authenticated, 'Biometric/Device auth');
      return authenticated;
    } on PlatformException catch (e) {
      await _logAuth(reason, false, 'Error: ${e.code}');
      throw _mapAuthException(e);
    }
  }

  Future<void> _logAuth(
      String operation, bool success, String logReason) async {
    try {
      final authAuditService = AuthAuditService(LocalStorageService());
      await authAuditService.logEvent(
        action: operation,
        success: success,
        failureReason: success ? null : logReason,
      );
    } catch (e) {
      // Fail silently for audit logs to avoid blocking user flow
      debugPrint('Failed to log auth audit: $e');
    }
  }

  BiometricAuthException _mapAuthException(PlatformException e) {
    String message = 'Authentication failed';
    switch (e.code) {
      case 'lockedOut':
        message = 'Biometrics locked out. Please try again later.';
        break;
      case 'permanentlyLockedOut':
        message = 'Biometrics permanently locked out. Password required.';
        break;
      case 'notAvailable':
        message = 'Biometrics not available on this device.';
        break;
      case 'passcodeNotSet':
        message = 'Device passcode not set.';
        break;
      case 'notEnrolled':
        message = 'No biometrics enrolled on this device.';
        break;
      case 'otherOperatingSystem':
        message = 'Operating system not supported.';
        break;
      default:
        message = e.message ?? 'Authentication error.';
    }
    return BiometricAuthException(message, e.code);
  }
}
