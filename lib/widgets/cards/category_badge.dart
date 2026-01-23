import 'package:flutter/material.dart';

/// Category badge for research papers
class CategoryBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const CategoryBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? 
            (isDark 
                ? Colors.white.withValues(alpha: 0.2) 
                : Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? 
              (isDark ? Colors.white : Colors.black87),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
