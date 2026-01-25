import 'package:flutter/material.dart';
import 'glass_card.dart';

/// Glass banner widget for displaying important messages or alerts.
/// Extends the glassmorphism design language to banner usage.
class GlassBanner extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool isDismissible;
  final VoidCallback? onDismiss;

  const GlassBanner({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.isDismissible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 12,
      onTap: onTap,
      backgroundColor: backgroundColor,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: child),
          if (isDismissible)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
