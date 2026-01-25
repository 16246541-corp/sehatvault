import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/pin_auth_service.dart';
import '../screens/pin_setup_screen.dart';
import 'dialogs/biometric_enrollment_dialog.dart';
import 'education/education_gate.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final String reason;
  final String? educationContentId;

  const AuthGate({
    super.key,
    required this.child,
    this.enabled = true,
    required this.reason,
    this.educationContentId,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final BiometricService _biometricService = BiometricService();
  final PinAuthService _pinAuthService = PinAuthService();
  bool _isAuthenticated = false;
  bool _isChecking = true;
  String? _error;
  bool _usePin = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void didUpdateWidget(AuthGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    if (!widget.enabled) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
      return;
    }

    try {
      final status = await _biometricService.getBiometricStatus();

      if (status == BiometricStatus.availableButNotEnrolled) {
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BiometricEnrollmentDialog(
            onEnroll: () async {
              Navigator.pop(context);
              await _biometricService.openSecuritySettings();
              // Upon return, we re-check
              _checkAuth();
            },
            onUsePin: () {
              Navigator.pop(context);
              _enablePin();
            },
            onDismiss: () {
              Navigator.pop(context);
              _enablePin();
            },
          ),
        );
        return;
      }

      final hasBiometrics = await _biometricService.hasEnrolledBiometrics;
      if (!hasBiometrics) {
        await _enablePin();
        return;
      }

      final authenticated = await _biometricService.authenticate(
        reason: widget.reason,
        sessionId: _biometricService.sessionId,
      );

      if (mounted) {
        setState(() {
          _isAuthenticated = authenticated;
          _isChecking = false;
          _error = authenticated ? null : 'Authentication failed';
        });
      }
    } catch (e) {
      if (e is BiometricAuthException &&
          _shouldFallbackToPin(e.code) &&
          await _pinAuthService.hasPin()) {
        await _enablePin();
        return;
      }
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isChecking = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _enablePin() async {
    if (mounted) {
      setState(() {
        _usePin = true;
        _isChecking = false;
      });
    }
  }

  bool _shouldFallbackToPin(String code) {
    return code == 'lockedOut' ||
        code == 'permanentlyLockedOut' ||
        code == 'notAvailable' ||
        code == 'notEnrolled';
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthenticated) {
      if (_usePin) {
        return PinUnlockScreen(
          title: 'Enter PIN',
          subtitle: widget.reason,
          onAuthenticated: () {
            if (mounted) {
              setState(() {
                _isAuthenticated = true;
                _usePin = false;
              });
            }
          },
          onCancel: () {
            if (mounted) {
              setState(() {
                _usePin = false;
                _isChecking = false;
                _error = 'Authentication cancelled';
              });
            }
          },
        );
      }

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Authentication required',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkAuth,
                child: const Text('Try Again'),
              ),
              if (widget.enabled) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _enablePin,
                  child: const Text('Use PIN'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (widget.educationContentId != null) {
      return EducationGate(
        contentId: widget.educationContentId!,
        child: widget.child,
      );
    }
    return widget.child;
  }
}
