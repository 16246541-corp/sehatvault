import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../document_scanner_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/onboarding/confetti_animation.dart';

class FirstScanGuideScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const FirstScanGuideScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<FirstScanGuideScreen> createState() => _FirstScanGuideScreenState();
}

class _FirstScanGuideScreenState extends State<FirstScanGuideScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final OnboardingService _onboardingService = OnboardingService();
  bool _hasScanned = false;

  Future<void> _startScanning() async {
    await _analyticsService.logEvent('onboarding_first_scan_started');
    if (!mounted) return;
    
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const DocumentScannerScreen(showOnboardingTips: true),
      ),
    );

    if (result != null && mounted) {
      setState(() => _hasScanned = true);
      await _analyticsService.logEvent('onboarding_first_scan_completed');
    }
  }

  Future<void> _skip() async {
    await _analyticsService.logEvent('onboarding_first_scan_skipped');
    await _complete();
  }

  Future<void> _complete() async {
    await _onboardingService.markStepCompleted(OnboardingStep.firstScan);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasScanned) {
      return _buildCelebration();
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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.document_scanner_rounded, size: 64, color: AppTheme.accentTeal),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Scan Your First\nDocument',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Let\'s try scanning a lab report or prescription. Our AI will automatically extract tests, dates, and values for you.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildTip(Icons.lightbulb_outline, 'Ensure good lighting'),
                        _buildTip(Icons.straighten_rounded, 'Keep the document flat'),
                        _buildTip(Icons.vibration_rounded, 'Hold steady for better OCR'),
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
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Text(
            'Step 8 of 10',
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

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Launch Camera',
              icon: Icons.camera_alt_rounded,
              onPressed: _startScanning,
              isProminent: true,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _skip,
            child: const Text('I\'ll scan later', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebration() {
    return Scaffold(
      body: ConfettiAnimation(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
          ),

          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 80, color: AppTheme.healthGreen),
                const SizedBox(height: 24),
                Text(
                  'Great Job!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Your first document is now securely stored and analyzed in your private vault.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 64),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _complete,
                      isProminent: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
