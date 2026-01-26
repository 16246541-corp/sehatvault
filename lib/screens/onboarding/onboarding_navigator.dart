import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/onboarding_service.dart';
import 'splash_screen.dart';
import 'welcome_carousel_screen.dart';
import 'consent_acceptance_screen.dart';
import 'permissions_request_screen.dart';
import 'security_setup_screen.dart';
import 'profile_setup_screen.dart';
import 'feature_tour_screen.dart';
import 'first_scan_guide_screen.dart';
import 'onboarding_complete_screen.dart';

class OnboardingNavigator extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingNavigator({super.key, required this.onComplete});

  @override
  State<OnboardingNavigator> createState() => _OnboardingNavigatorState();
}

class _OnboardingNavigatorState extends State<OnboardingNavigator> {
  final OnboardingService _onboardingService = OnboardingService();
  OnboardingStep _currentStep = OnboardingStep.splash;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentStep();
  }

  Future<void> _loadCurrentStep() async {
    debugPrint('OnboardingNavigator: Loading current step...');
    final step = await _onboardingService.getFirstIncompleteStep();
    debugPrint('OnboardingNavigator: First incomplete step is: $step');
    if (mounted) {
      setState(() {
        _currentStep = step;
        _isLoading = false;
      });
      debugPrint('OnboardingNavigator: Set current step to $_currentStep');
    }
  }

  void _next() async {
    debugPrint('OnboardingNavigator: _next() called, reloading step...');
    await _loadCurrentStep();
  }

  void _back() {
    // Basic back logic - can be improved with a stack if needed
    if (_currentStep.index > 0) {
      setState(() {
        _currentStep = OnboardingStep.values[_currentStep.index - 1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_currentStep) {
      case OnboardingStep.splash:
        return SplashScreen(onComplete: _next);
      case OnboardingStep.welcome:
        return WelcomeCarouselScreen(onComplete: _next);
      case OnboardingStep.consent:
        return ConsentAcceptanceScreen(onComplete: _next);
      case OnboardingStep.permissions:
        return PermissionsRequestScreen(onComplete: _next, onBack: _back);
      case OnboardingStep.security:
        return SecuritySetupScreen(onComplete: _next, onBack: _back);
      case OnboardingStep.profile:
        return ProfileSetupScreen(onComplete: _next, onBack: _back);
      case OnboardingStep.featureTour:
        return FeatureTourScreen(onComplete: _next, onBack: _back);
      case OnboardingStep.firstScan:
        return FirstScanGuideScreen(onComplete: _next, onBack: _back);
      case OnboardingStep.completed:
        return OnboardingCompleteScreen(onComplete: widget.onComplete);
    }
  }
}

