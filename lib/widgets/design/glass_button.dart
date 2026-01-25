import 'package:flutter/material.dart';
import '../../utils/design_constants.dart';
import '../../utils/theme.dart';
import 'glass_effect_container.dart';

/// Glass-styled button following Apple's Liquid Glass design language
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isProminent;
  final Color? tintColor;
  final bool isInteractive;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isProminent = false,
    this.tintColor,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveTintColor = tintColor ?? AppTheme.accentTeal;
    final callback = isInteractive ? onPressed : null;

    Widget buildProminent() {
      return ElevatedButton(
        onPressed: callback,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveTintColor,
          foregroundColor: Colors.white,
          padding: DesignConstants.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DesignConstants.buttonCornerRadius),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildGlassContent() {
      final contentColor = isDark ? Colors.white : theme.colorScheme.onSurface;

      return Container(
        padding: DesignConstants.buttonPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color:
                    isDark ? Colors.white : contentColor.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color:
                    isDark ? Colors.white : contentColor.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    if (isProminent) {
      return buildProminent();
    }

    final glassContent = buildGlassContent();

    return GlassEffectCapsule(
      interactive: isInteractive && onPressed != null,
      opacity: DesignConstants.glassOpacityLight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: callback,
          borderRadius: BorderRadius.circular(100),
          child: glassContent,
        ),
      ),
    );
  }
}
