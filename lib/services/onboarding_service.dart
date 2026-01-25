import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/local_storage_service.dart';

enum OnboardingStep {
  splash,
  welcome,
  consent,
  permissions,
  security,
  profile,
  featureTour,
  firstScan,
  completed,
}

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  Future<OnboardingStep> getFirstIncompleteStep() async {
    final settings = LocalStorageService().getAppSettings();
    
    if (!settings.hasSeenSplash) return OnboardingStep.splash;
    if (!settings.hasAcceptedPrivacyPolicy || !settings.hasAcceptedTermsOfService) return OnboardingStep.consent;
    if (!settings.hasCompletedPermissionsSetup) return OnboardingStep.permissions;
    if (!settings.hasCompletedSecuritySetup) return OnboardingStep.security;
    if (!settings.hasCompletedProfileSetup) return OnboardingStep.profile;
    if (!settings.hasCompletedFeatureTour) return OnboardingStep.featureTour;
    if (!settings.hasCompletedFirstScan) return OnboardingStep.firstScan;
    
    return OnboardingStep.completed;
  }

  Future<void> markStepCompleted(OnboardingStep step) async {
    final settings = LocalStorageService().getAppSettings();
    final stepName = step.name;
    
    if (!settings.completedOnboardingSteps.contains(stepName)) {
      settings.completedOnboardingSteps = [...settings.completedOnboardingSteps, stepName];
    }

    switch (step) {
      case OnboardingStep.splash:
        settings.hasSeenSplash = true;
        break;
      case OnboardingStep.consent:
        settings.hasAcceptedPrivacyPolicy = true;
        settings.hasAcceptedTermsOfService = true;
        break;
      case OnboardingStep.permissions:
        settings.hasCompletedPermissionsSetup = true;
        break;
      case OnboardingStep.security:
        settings.hasCompletedSecuritySetup = true;
        break;
      case OnboardingStep.profile:
        settings.hasCompletedProfileSetup = true;
        break;
      case OnboardingStep.featureTour:
        settings.hasCompletedFeatureTour = true;
        break;
      case OnboardingStep.firstScan:
        settings.hasCompletedFirstScan = true;
        break;
      case OnboardingStep.completed:
        settings.isOnboardingComplete = true;
        settings.onboardingCompletedAt = DateTime.now();
        break;
      default:
        break;
    }

    await LocalStorageService().saveAppSettings(settings);
  }

  Future<bool> isOnboardingComplete() async {
    final settings = LocalStorageService().getAppSettings();
    return settings.isOnboardingComplete;
  }

  Future<void> resetOnboarding() async {
    final settings = LocalStorageService().getAppSettings();
    settings.hasSeenSplash = false;
    settings.completedOnboardingSteps = [];
    settings.isOnboardingComplete = false;
    settings.hasAcceptedPrivacyPolicy = false;
    settings.hasAcceptedTermsOfService = false;
    settings.hasCompletedPermissionsSetup = false;
    settings.hasCompletedSecuritySetup = false;
    settings.hasCompletedProfileSetup = false;
    settings.hasCompletedFeatureTour = false;
    settings.hasCompletedFirstScan = false;
    settings.onboardingCompletedAt = null;
    await LocalStorageService().saveAppSettings(settings);
  }
}
