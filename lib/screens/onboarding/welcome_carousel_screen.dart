import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/onboarding/page_indicator.dart';
import '../../widgets/design/glass_button.dart';

/// Welcome carousel model for onboarding pages
class WelcomePageData {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final List<String> highlights;

  WelcomePageData({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    this.highlights = const [],
  });

  factory WelcomePageData.fromJson(Map<String, dynamic> json) {
    return WelcomePageData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] as String,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Welcome carousel screen for introducing app features
class WelcomeCarouselScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const WelcomeCarouselScreen({
    super.key,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<WelcomeCarouselScreen> createState() => _WelcomeCarouselScreenState();
}

class _WelcomeCarouselScreenState extends State<WelcomeCarouselScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  List<WelcomePageData> _pages = [];
  int _currentPage = 0;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadContent();
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
      final jsonString = await rootBundle
          .loadString('assets/data/onboarding/welcome_content.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final pagesJson = jsonData['pages'] as List<dynamic>;

      setState(() {
        _pages = pagesJson
            .map((e) => WelcomePageData.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });

      _fadeController.forward();
    } catch (e) {
      // Fallback to hardcoded content if JSON fails
      setState(() {
        _pages = _getDefaultPages();
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  List<WelcomePageData> _getDefaultPages() {
    return [
      WelcomePageData(
        id: 'privacy',
        title: 'Your Health, Secured',
        description:
            'All your sensitive health data is encrypted with military-grade AES-256 encryption.',
        iconName: 'shield',
        highlights: ['AES-256 encryption', 'Local storage only'],
      ),
      WelcomePageData(
        id: 'vault',
        title: 'Smart Document Vault',
        description:
            'Scan prescriptions, lab results, and medical records with automatic text extraction.',
        iconName: 'folder_special',
        highlights: ['Automatic OCR', 'Smart categorization'],
      ),
      WelcomePageData(
        id: 'ai',
        title: 'AI That Respects Privacy',
        description:
            'Our AI assistant runs entirely on your device. Your data never leaves your phone.',
        iconName: 'psychology',
        highlights: ['100% offline', 'On-device processing'],
      ),
      WelcomePageData(
        id: 'recording',
        title: 'Record Doctor Visits',
        description:
            'Capture medical appointments with automatic transcription and follow-up extraction.',
        iconName: 'mic',
        highlights: ['Encrypted recording', 'Auto transcription'],
      ),
    ];
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    // Mark welcome as completed
    final settings = LocalStorageService().getAppSettings();
    if (!settings.completedOnboardingSteps.contains('welcome')) {
      settings.completedOnboardingSteps = [
        ...settings.completedOnboardingSteps,
        'welcome'
      ];
      LocalStorageService().saveAppSettings(settings);
    }

    widget.onComplete();
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'shield':
        return Icons.shield_rounded;
      case 'folder_special':
        return Icons.folder_special_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'mic':
        return Icons.mic_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
            child: Column(
              children: [
                // Header with Skip button
                _buildHeader(),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Bottom navigation
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page counter
          Text(
            '${_currentPage + 1} / ${_pages.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),

          // Skip button (hidden on last page)
          AnimatedOpacity(
            opacity: isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: isLastPage ? null : _skipOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(WelcomePageData page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Icon with glow effect
          _buildIconContainer(page.iconName),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 17,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Highlights
          if (page.highlights.isNotEmpty) _buildHighlights(page.highlights),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildIconContainer(String iconName) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppTheme.accentTeal.withValues(alpha: 0.3),
            AppTheme.accentTeal.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.3, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withValues(alpha: 0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentTeal.withValues(alpha: 0.8),
              AppTheme.accentTeal,
              AppTheme.primaryColor.withValues(alpha: 0.7),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          _getIcon(iconName),
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHighlights(List<String> highlights) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: highlights.map((highlight) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppTheme.accentTeal,
              ),
              const SizedBox(width: 6),
              Text(
                highlight,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomNav() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      child: Column(
        children: [
          // Page indicator
          AnimatedPageIndicator(
            pageCount: _pages.length,
            currentPage: _currentPage,
          ),

          const SizedBox(height: 32),

          // Continue/Get Started button
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: isLastPage ? 'Get Started' : 'Continue',
              icon: isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
              onPressed: _nextPage,
              isProminent: true,
              tintColor: AppTheme.accentTeal,
            ),
          ),
        ],
      ),
    );
  }
}
