import 'package:flutter/material.dart';

/// Liquid Glass background widget used across all screens
class LiquidGlassBackground extends StatelessWidget {
  final Widget child;
  final bool showTexture;

  const LiquidGlassBackground({
    super.key,
    required this.child,
    this.showTexture = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFFF5F3FF), // Very light violet
                  const Color(0xFFF0F9FF), // Very light sky
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showTexture)
            Positioned.fill(
              child: CustomPaint(
                painter: _TexturePainter(isDark: isDark),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  final bool isDark;

  _TexturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle dots
    for (int i = 0; i < 100; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 41) % size.height;
      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
