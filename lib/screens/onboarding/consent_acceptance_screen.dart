import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/analytics_service.dart';
import '../../services/consent_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/theme.dart';
import '../../widgets/design/glass_button.dart';
import '../../widgets/design/responsive_center.dart';
import '../../widgets/onboarding/consent_checklist_widget.dart';

/// Consent acceptance screen for Privacy Policy and Terms of Service
/// Users must review and accept both documents before proceeding
class ConsentAcceptanceScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const ConsentAcceptanceScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<ConsentAcceptanceScreen> createState() =>
      _ConsentAcceptanceScreenState();
}

class _ConsentAcceptanceScreenState extends State<ConsentAcceptanceScreen>
    with TickerProviderStateMixin {
  static const String _privacyPolicyVersion = '1.8.9';
  static const String _termsOfServiceVersion = '1.8.9';

  bool _privacyPolicyAccepted = false;
  bool _termsOfServiceAccepted = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  String _privacyPolicyContent = '';
  String _termsOfServiceContent = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final ConsentService _consentService = ConsentService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadContent();
    _logAnalytics('consent_privacy_viewed');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadContent() async {
    try {
      final privacyPolicy = await _consentService.loadTemplate(
        'privacy_policy',
        'v1',
      );
      final termsOfService = await _consentService.loadTemplate(
        'terms_of_service',
        'v1',
      );

      setState(() {
        _privacyPolicyContent = privacyPolicy;
        _termsOfServiceContent = termsOfService;
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      // Fallback content if loading fails
      setState(() {
        _privacyPolicyContent = _getFallbackPrivacyPolicy();
        _termsOfServiceContent = _getFallbackTermsOfService();
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  String _getFallbackPrivacyPolicy() {
    return '''
# Privacy Policy

**Version $_privacyPolicyVersion**

Your health data is encrypted with AES-256 encryption and never leaves your device. 
We do not collect, share, or sell your personal information.

## Key Points:
- All data stored locally on your device
- Military-grade encryption
- No cloud uploads
- You control your data
''';
  }

  String _getFallbackTermsOfService() {
    return '''
# Terms of Service

**Version $_termsOfServiceVersion**

By using Sehat Locker, you agree to use the app for personal health record management.

## Key Points:
- For informational purposes only
- Not a substitute for professional medical advice
- You own your data
- You are responsible for maintaining backups
''';
  }

  Future<void> _logAnalytics(String event) async {
    await _analyticsService.logEvent(event);
  }

  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      } else if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else {
        // Desktop platforms
        final deviceData = await deviceInfo.deviceInfo;
        return deviceData.data['id']?.toString() ?? 'unknown_desktop';
      }
    } catch (e) {
      return 'unknown';
    }
  }

  bool get _canProceed =>
      _privacyPolicyAccepted && _termsOfServiceAccepted && !_isSubmitting;

  Future<void> _handleAcceptAndContinue() async {
    if (!_canProceed) {
      if (!_privacyPolicyAccepted) {
        _showPrivacyPolicyPopup();
      } else if (!_termsOfServiceAccepted) {
        _showTermsOfServicePopup();
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final deviceId = await _getDeviceId();

      // Record privacy policy consent
      await _consentService.recordConsent(
        templateId: 'privacy_policy',
        version: _privacyPolicyVersion,
        userId: 'local_user', // Local-only app, no real user ID
        scope: 'privacy_policy',
        granted: true,
        content: _privacyPolicyContent,
        deviceId: deviceId,
      );
      await _logAnalytics('consent_privacy_accepted');

      // Record terms of service consent
      await _consentService.recordConsent(
        templateId: 'terms_of_service',
        version: _termsOfServiceVersion,
        userId: 'local_user',
        scope: 'terms_of_service',
        granted: true,
        content: _termsOfServiceContent,
        deviceId: deviceId,
      );
      await _logAnalytics('consent_terms_accepted');

      // Update app settings
      final settings = LocalStorageService().getAppSettings();
      settings.hasAcceptedPrivacyPolicy = true;
      settings.acceptedPrivacyPolicyVersion = _privacyPolicyVersion;
      settings.hasAcceptedTermsOfService = true;
      settings.acceptedTermsOfServiceVersion = _termsOfServiceVersion;

      // Mark consent as completed onboarding step
      if (!settings.completedOnboardingSteps.contains('consent')) {
        settings.completedOnboardingSteps = [
          ...settings.completedOnboardingSteps,
          'consent'
        ];
      }

      await LocalStorageService().saveAppSettings(settings);

      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record consent: $e'),
          backgroundColor: AppTheme.healthRed,
        ),
      );
    }
  }

  void _showFullDocument(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FullDocumentSheet(
        title: title,
        content: content,
      ),
    );
  }

  void _showPrivacyPolicyPopup() {
    showDialog(
      context: context,
      builder: (context) => _ConsentPopup(
        popupTitle: 'We need you to review and accept the privacy policy',
        title: 'Privacy Policy',
        version: _privacyPolicyVersion,
        summaryPoints: const [
          'All data encrypted with AES-256',
          'No data collection or sharing',
          'You control your health records',
          'Delete your data anytime',
        ],
        onViewFull: () {
          Navigator.pop(context);
          _showFullDocument('Privacy Policy', _privacyPolicyContent);
        },
        onAccept: () {
          setState(() => _privacyPolicyAccepted = true);
          Navigator.pop(context);
          _handleAcceptAndContinue();
        },
      ),
    );
  }

  void _showTermsOfServicePopup() {
    showDialog(
      context: context,
      builder: (context) => _ConsentPopup(
        popupTitle: 'We need you to review and accept the terms of service',
        title: 'Terms of Service',
        version: _termsOfServiceVersion,
        summaryPoints: const [
          'For personal health management only',
          'Not a substitute for medical advice',
          'You own all your data',
          'Maintain your own backups',
        ],
        onViewFull: () {
          Navigator.pop(context);
          _showFullDocument('Terms of Service', _termsOfServiceContent);
        },
        onAccept: () {
          setState(() => _termsOfServiceAccepted = true);
          Navigator.pop(context);
          _handleAcceptAndContinue();
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: ResponsiveCenter(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Centered Header Title & Subtitle
                          Center(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Privacy & Terms',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildVersionBadge(),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please review and accept our policies to continue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Privacy checklist
                          Center(
                              child: _buildSectionTitle(
                                  'Your Privacy Guarantees')),
                          const SizedBox(height: 16),
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: const ConsentChecklistWidget(),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action button
                  _buildBottomAction(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVersionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 14,
            color: AppTheme.accentTeal,
          ),
          const SizedBox(width: 4),
          Text(
            'v$_privacyPolicyVersion',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildConsentCard({
    required String title,
    required String version,
    required bool isAccepted,
    required ValueChanged<bool> onAcceptChanged,
    required VoidCallback onViewFull,
    required List<String> summaryPoints,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAccepted
              ? AppTheme.accentTeal.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: isAccepted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0x335B21B6),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(
                  title.contains('Privacy')
                      ? Icons.privacy_tip_rounded
                      : Icons.description_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Version $version',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewFull,
                child: const Text(
                  'Read Full',
                  style: TextStyle(
                    color: AppTheme.accentTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Summary points
          ...summaryPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppTheme.healthGreen.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Checkbox
          GestureDetector(
            onTap: () => onAcceptChanged(!isAccepted),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color:
                        isAccepted ? AppTheme.accentTeal : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isAccepted
                          ? AppTheme.accentTeal
                          : Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: isAccepted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I have read and accept the $title',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Continue button
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: _isSubmitting
                  ? 'Recording Consent...'
                  : 'Review and Continue',
              icon: _isSubmitting
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: _handleAcceptAndContinue,
              isProminent: true,
              tintColor: AppTheme.healthGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full document sheet for viewing complete policy/terms
class _FullDocumentSheet extends StatelessWidget {
  final String title;
  final String content;

  const _FullDocumentSheet({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Markdown content
          Expanded(
            child: Markdown(
              data: content,
              padding: const EdgeInsets.all(24),
              styleSheet: MarkdownStyleSheet(
                h1: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                h2: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                h3: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                p: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.6,
                ),
                listBullet: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                blockquoteDecoration: const BoxDecoration(
                  color: Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.accentTeal,
                      width: 4,
                    ),
                  ),
                ),
                strong: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentPopup extends StatefulWidget {
  final String popupTitle;
  final String title;
  final String version;
  final List<String> summaryPoints;
  final VoidCallback onViewFull;
  final VoidCallback onAccept;

  const _ConsentPopup({
    required this.popupTitle,
    required this.title,
    required this.version,
    required this.summaryPoints,
    required this.onViewFull,
    required this.onAccept,
  });

  @override
  State<_ConsentPopup> createState() => _ConsentPopupState();
}

class _ConsentPopupState extends State<_ConsentPopup> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.popupTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),

            // Card Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Version ${widget.version}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: widget.onViewFull,
                        child: const Text(
                          'Read Full',
                          style: TextStyle(
                            color: AppTheme.healthGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.summaryPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color:
                                  AppTheme.healthGreen.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checkbox
            GestureDetector(
              onTap: () => setState(() => _isAccepted = !_isAccepted),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _isAccepted
                          ? AppTheme.accentTeal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isAccepted
                            ? AppTheme.accentTeal
                            : Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: _isAccepted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I have read and accept the ${widget.title}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: GlassButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isAccepted ? widget.onAccept : null,
                isProminent: true,
                tintColor: AppTheme.healthGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
