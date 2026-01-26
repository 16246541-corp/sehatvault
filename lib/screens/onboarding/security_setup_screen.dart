import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/biometric_service.dart';
import '../../services/pin_auth_service.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/design/glass_card.dart';
import '../../widgets/design/responsive_center.dart';
import '../../widgets/onboarding/security_completion_card.dart';
import '../pin_setup_screen.dart';

class SecuritySetupScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const SecuritySetupScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final BiometricService _biometricService = BiometricService();
  final PinAuthService _pinAuthService = PinAuthService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final OnboardingService _onboardingService = OnboardingService();

  int _currentStep =
      0; // 0: Intro, 1: Biometric (if available), 2: PIN Setup, 3: Completed
  bool _biometricEnabled = false;
  bool _pinSet = false;
  bool _recoveryQuestionSet = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometricService.isBiometricsAvailable;
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _isLoading = false;
      });
    }
  }

  Future<void> _enableBiometrics() async {
    try {
      final success = await _biometricService.authenticate(
        reason: 'Enable biometric authentication for Sehat Locker',
      );
      if (success && mounted) {
        setState(() => _biometricEnabled = true);
        await _analyticsService.logEvent('security_biometric_enabled');
        _nextStep();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication failed: $e')),
        );
      }
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
      // Skip biometric step if not available
      if (_currentStep == 1 && !_biometricAvailable) {
        _currentStep++;
      }
    });
  }

  Future<void> _finishSecuritySetup() async {
    await _onboardingService.markStepCompleted(OnboardingStep.security);
    await _analyticsService.logEvent('security_setup_completed');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveCenter(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepContent(),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    double progress = (_currentStep + 1) / 4;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0 && _currentStep < 3)
                IconButton(
                  onPressed: () => setState(() => _currentStep--),
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                )
              else if (widget.onBack != null && _currentStep == 0)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildBiometricStep();
      case 2:
        return _buildPinStep();
      case 3:
        return _buildCompletion();
      default:
        return const SizedBox();
    }
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentTeal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.security_rounded,
              size: 48, color: AppTheme.accentTeal),
        ),
        const SizedBox(height: 24),
        Text(
          'Your Health Data\nIs Sensitive',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sehat Locker uses military-grade AES-256 encryption to protect your medical records. Setting up extra security ensures only you can access this data on your device.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildSecurityPoint(Icons.lock_outline, 'End-to-end Local Encryption'),
        _buildSecurityPoint(Icons.fingerprint, 'Biometric & PIN Protection'),
        _buildSecurityPoint(Icons.no_accounts_outlined, 'Private & Anonymous'),
      ],
    );
  }

  Widget _buildSecurityPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentTeal, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Unlock with Biometrics',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Use Face ID or Touch ID for faster, secure access to your vault.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Icon(Icons.fingerprint,
                  size: 80, color: AppTheme.accentTeal.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              if (_biometricEnabled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.healthGreen),
                    const SizedBox(width: 8),
                    const Text('Biometrics Enabled',
                        style: TextStyle(
                            color: AppTheme.healthGreen,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    return SizedBox(
      height: 500, // Constrain size for SingleChildScrollView
      child: PinSetupScreen(
        mode: PinSetupMode.setup,
        showAppBar: false,
        onComplete: () {
          setState(() {
            _pinSet = true;
            _recoveryQuestionSet = true; // PinSetupScreen handles both
          });
          _analyticsService.logEvent('security_pin_set');
          _nextStep();
        },
      ),
    );
  }

  Widget _buildCompletion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Security Verified',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your medical vault is now protected with multi-layered security.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 32),
        SecurityCompletionCard(
          biometricEnabled: _biometricEnabled,
          pinSet: _pinSet,
          recoveryQuestionSet: _recoveryQuestionSet,
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    if (_currentStep == 2)
      return const SizedBox(); // PinSetupScreen has its own buttons

    String label = 'Continue';
    IconData icon = Icons.arrow_forward_rounded;
    VoidCallback? onPressed;

    if (_currentStep == 0) {
      onPressed = _nextStep;
    } else if (_currentStep == 1) {
      label = _biometricEnabled ? 'Next' : 'Enable Biometrics';
      onPressed = _biometricEnabled ? _nextStep : _enableBiometrics;
    } else if (_currentStep == 3) {
      label = 'Complete Setup';
      icon = Icons.check_rounded;
      onPressed = _finishSecuritySetup;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_currentStep == 1 && !_biometricEnabled)
            TextButton(
              onPressed: _nextStep,
              child: const Text('Maybe later (use PIN only)',
                  style: TextStyle(color: Colors.white60)),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: label,
              icon: icon,
              onPressed: onPressed,
              isProminent: true,
            ),
          ),
        ],
      ),
    );
  }
}
