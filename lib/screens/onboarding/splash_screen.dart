import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/onboarding/animated_logo.dart';
import '../../services/onboarding_service.dart';

/// Animated splash screen with branding and privacy-first messaging
/// Displays on app launch with smooth transitions
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration minimumDuration;
  final bool respectReducedMotion;

  const SplashScreen({
    super.key,
    required this.onComplete,
    this.minimumDuration = const Duration(milliseconds: 2500),
    this.respectReducedMotion = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _exitController;

  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<Offset> _taglineSlideAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _isReducedMotion = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _checkReducedMotion();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _checkReducedMotion() {
    // Reduced motion will be checked when the widget builds with MediaQuery
    // For now, we'll set it to false and check during build if needed
    _isReducedMotion = false;
  }

  void _initializeAnimations() {
    // Title fade and slide
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline animations (delayed)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Exit animation
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
  }

  Future<void> _startSplashSequence() async {
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    if (_isReducedMotion) {
      // Skip animations for reduced motion
      await Future.delayed(const Duration(milliseconds: 500));
      _completeSplash();
      return;
    }

    // Start title animation after logo begins
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _fadeController.forward();

    // Start tagline animation
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _slideController.forward();

    // Wait for minimum duration then exit
    await Future.delayed(widget.minimumDuration);
    if (!mounted) return;

    _exitSplash();
  }

  Future<void> _exitSplash() async {
    if (_isExiting) return;
    setState(() => _isExiting = true);

    await _exitController.forward();
    if (!mounted) return;

    _completeSplash();
  }

  Future<void> _completeSplash() async {
    // Mark splash as completed before navigating away
    await OnboardingService().markStepCompleted(OnboardingStep.splash);
    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        return Opacity(
          opacity: _exitFadeAnimation.value,
          child: _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
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
        child: Stack(
          children: [
            // Animated background orbs
            _buildBackgroundOrbs(),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Animated Logo
                    AnimatedLogo(
                      size: 140,
                      animate: !_isReducedMotion,
                      animationDuration: const Duration(milliseconds: 1200),
                    ),

                    const SizedBox(height: 32),

                    // App Name
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _titleSlideAnimation,
                          child: FadeTransition(
                            opacity: _titleFadeAnimation,
                            child: Text(
                              'Sehat Locker',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _taglineSlideAnimation,
                          child: FadeTransition(
                            opacity: _taglineFadeAnimation,
                            child: Text(
                              'Your Health, Your Device',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Privacy indicator at bottom
                    const AnimatedPrivacyShield(
                      delay: Duration(milliseconds: 1200),
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        // Top-left orb
        Positioned(
          top: -100,
          left: -100,
          child: _buildOrb(
            size: 300,
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
          ),
        ),
        // Bottom-right orb
        Positioned(
          bottom: -150,
          right: -100,
          child: _buildOrb(
            size: 400,
            color: AppTheme.accentTeal.withValues(alpha: 0.1),
          ),
        ),
        // Center-right orb
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -50,
          child: _buildOrb(
            size: 200,
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
