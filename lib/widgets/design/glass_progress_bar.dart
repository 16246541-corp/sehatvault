import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass progress bar widget
class GlassProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final Color? activeColor;
  final Color? backgroundColor;

  const GlassProgressBar({
    Key? key,
    required this.value,
    this.height = 8.0,
    this.activeColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          // Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor ??
                    (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),

          // Progress
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                height: height,
                decoration: BoxDecoration(
                  color: activeColor ??
                      Theme.of(context).primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: (activeColor ?? Theme.of(context).primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
