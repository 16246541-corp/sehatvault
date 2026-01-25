import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/onboarding_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/onboarding/confetti_animation.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingCompleteScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final OnboardingService _onboardingService = OnboardingService();
  final LocalStorageService _storageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _analyticsService.logEvent('onboarding_completed');
  }

  Future<void> _finish() async {
    await _onboardingService.markStepCompleted(OnboardingStep.completed);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _storageService.getUserProfile();
    final name = profile.displayName ?? 'Friend';
    final settings = _storageService.getAppSettings();

    final checklist = [
      {'label': 'Privacy policy accepted', 'value': settings.hasAcceptedPrivacyPolicy},
      {'label': 'Permissions granted', 'value': settings.hasCompletedPermissionsSetup},
      {'label': 'Security enabled', 'value': settings.hasCompletedSecuritySetup},
      {'label': 'Profile configured', 'value': settings.hasCompletedProfileSetup},
      {'label': 'First scan complete', 'value': settings.hasCompletedFirstScan},
    ];

    return Scaffold(
      body: ConfettiAnimation(
        child: Container(
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 64),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.healthGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, size: 80, color: AppTheme.healthGreen),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'You\'re All Set,\n$name!',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your medical vault is ready. Your health data is now secured and stays locally on your device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 48),
                        
                        // Summary Checklist
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Setup Summary',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 16),
                              ...checklist.map((item) => _buildCheckItem(item['label'] as String, item['value'] as bool)),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildCheckItem(String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: isChecked ? AppTheme.healthGreen : Colors.white24,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isChecked ? Colors.white : Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Get Started',
              icon: Icons.rocket_launch_rounded,
              onPressed: _finish,
              isProminent: true,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
