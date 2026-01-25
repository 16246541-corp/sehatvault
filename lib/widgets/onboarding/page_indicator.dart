import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// Animated page indicator dots for carousel screens
class AnimatedPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double activeDotWidth;
  final double spacing;
  final Duration animationDuration;

  const AnimatedPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8.0,
    this.activeDotWidth = 24.0,
    this.spacing = 8.0,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppTheme.accentTeal;
    final inactive =
        inactiveColor ?? Colors.white.withValues(alpha: 0.3);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? activeDotWidth : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(dotSize / 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: active.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

/// Pill-style page indicator with progress animation
class PillPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final Color? activeColor;
  final Color? trackColor;
  final double height;
  final double width;

  const PillPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.activeColor,
    this.trackColor,
    this.height = 4.0,
    this.width = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppTheme.accentTeal;
    final track = trackColor ?? Colors.white.withValues(alpha: 0.2);
    final progress = (currentPage + 1) / pageCount;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: constraints.maxWidth * progress,
                height: height,
                decoration: BoxDecoration(
                  color: active,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: active.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
