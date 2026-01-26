import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/education_service.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/design/responsive_center.dart';
import '../../widgets/education/education_modal.dart';

class FeatureTourScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const FeatureTourScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();
}

class _FeatureTourScreenState extends State<FeatureTourScreen> {
  final EducationService _educationService = EducationService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final OnboardingService _onboardingService = OnboardingService();

  final List<String> _featureIds = [
    'secure_storage',
    'document_scanner',
    'ai_features',
  ];

  bool _isShowingTour = false;

  Future<void> _startTour() async {
    setState(() => _isShowingTour = true);
    await _analyticsService.logEvent('onboarding_tour_started');

    for (int i = 0; i < _featureIds.length; i++) {
      if (!mounted) return;
      await EducationModal.show(context, contentId: _featureIds[i]);
    }

    if (mounted) {
      await _analyticsService.logEvent('onboarding_tour_completed');
      _complete();
    }
  }

  Future<void> _skipTour() async {
    await _analyticsService.logEvent('onboarding_tour_skipped');
    _complete();
  }

  Future<void> _complete() async {
    await _onboardingService.markStepCompleted(OnboardingStep.featureTour);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.accentTeal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.explore_outlined,
                                size: 64, color: AppTheme.accentTeal),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Quick Tour?',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Would you like a quick tour of the key features that make Sehat Locker special? It only takes a minute.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          _buildFeaturePreview(
                              Icons.storage_rounded, 'Secure Document Vault'),
                          _buildFeaturePreview(Icons.document_scanner_rounded,
                              'AI Document Scanning'),
                          _buildFeaturePreview(Icons.auto_awesome_rounded,
                              'Health Insights & Trends'),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (widget.onBack != null && !_isShowingTour)
            IconButton(
              onPressed: widget.onBack,
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            'Step 7 of 10',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: AppTheme.accentTeal.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
              label: 'Yes, Show Me',
              icon: Icons.play_arrow_rounded,
              onPressed: _isShowingTour ? null : _startTour,
              isProminent: true,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _isShowingTour ? null : _skipTour,
            child: const Text('Skip Tour',
                style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }
}
