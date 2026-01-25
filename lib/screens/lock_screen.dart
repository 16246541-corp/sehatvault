import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../screens/pin_setup_screen.dart'; // For PinUnlockScreen
import '../utils/theme.dart';
import '../widgets/design/glass_button.dart';
import '../widgets/design/liquid_glass_background.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Try to authenticate immediately when lock screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      // Check if biometrics are available
      final canCheckBiometrics = await _biometricService.isBiometricsAvailable;

      if (canCheckBiometrics) {
        final authenticated = await _biometricService.authenticate(
          reason: 'Unlock SehatLocker',
        );

        if (authenticated && mounted) {
          Navigator.of(context).pop();
          return;
        }
      } else {
        // Fallback to PIN if biometrics not available
        _showPinUnlock();
        return; // Return to avoid setting isAuthenticating to false immediately
      }
    } catch (e) {
      debugPrint('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _showPinUnlock() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PinUnlockScreen(
          title: 'Unlock Session',
          subtitle: 'Enter your PIN to resume',
          onAuthenticated: () {
            // Pop PinUnlockScreen
            Navigator.of(context).pop();
            // Pop LockScreen
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Blurred Background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: AppTheme.darkBackground.withOpacity(0.5),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Logo Placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentTeal.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: AppTheme.accentTeal,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Session Locked',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 48),

                  GlassButton(
                    label: 'Unlock',
                    icon: Icons.fingerprint,
                    onPressed: _authenticate,
                    isProminent: true,
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _showPinUnlock,
                    child: Text(
                      'Use PIN',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
