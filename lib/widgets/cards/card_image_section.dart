import 'package:flutter/material.dart';

/// Image section for research paper cards
class CardImageSection extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final Widget? badge;

  const CardImageSection({
    super.key,
    this.imageUrl,
    required this.height,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B) 
            : const Color(0xFFE2E8F0),
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          // Category badge
          if (badge != null)
            Positioned(
              top: 16,
              left: 16,
              child: badge!,
            ),
          // Placeholder icon when no image
          if (imageUrl == null)
            Center(
              child: Icon(
                Icons.article_outlined,
                size: 64,
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }
}
