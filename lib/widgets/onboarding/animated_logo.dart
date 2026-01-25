import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Animated logo widget for splash screen and branding
/// Features a lock icon with animated reveal and glow effects
class AnimatedLogo extends StatefulWidget {
  final double size;
  final Duration animationDuration;
  final bool animate;
  final VoidCallback? onAnimationComplete;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.animate = true,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotateController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation - logo bounces in
    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration.inMilliseconds ~/ 2),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_scaleController);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Glow pulse animation - continuous subtle pulse
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Rotate animation - subtle 3D effect
    _rotateController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -0.1, end: 0.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_rotateController);

    if (widget.animate) {
      _startAnimations();
    } else {
      _scaleController.value = 1.0;
      _rotateController.value = 1.0;
    }
  }

  Future<void> _startAnimations() async {
    // Start scale animation
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _scaleController.forward();
    _rotateController.forward();

    // Start glow after logo appears
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _glowController.repeat(reverse: true);

    // Notify when main animation completes
    await Future.delayed(widget.animationDuration);
    if (!mounted) return;

    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController,
        _glowController,
        _rotateController,
      ]),
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(_rotateAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: _buildLogo(isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.accentTeal.withValues(alpha: 0.3),
                AppTheme.accentTeal.withValues(alpha: 0.1),
                Colors.transparent,
              ],
              stops: const [0.4, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentTeal.withValues(alpha: _glowAnimation.value),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(widget.size * 0.15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accentTeal.withValues(alpha: 0.9),
                  AppTheme.accentTeal,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.9),
                  ],
                ).createShader(bounds),
                child: Icon(
                  Icons.lock_rounded,
                  size: widget.size * 0.35,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Privacy shield icon with animated reveal
class AnimatedPrivacyShield extends StatefulWidget {
  final Duration delay;

  const AnimatedPrivacyShield({
    super.key,
    this.delay = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedPrivacyShield> createState() => _AnimatedPrivacyShieldState();
}

class _AnimatedPrivacyShieldState extends State<AnimatedPrivacyShield>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: AppTheme.accentTeal.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Privacy First',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
