import 'dart:ui';

import 'package:flutter/material.dart';

class DesktopOverlayBarItem {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;

  const DesktopOverlayBarItem({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
  });
}

class DesktopFloatingOverlayBar extends StatelessWidget {
  final List<DesktopOverlayBarItem> items;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double height;

  const DesktopFloatingOverlayBar({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.borderRadius = 28,
    this.height = 68,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = BorderRadius.circular(borderRadius);
    const blurSigma = 22.0;
    final tintTop = (isDark ? Colors.black : Colors.white)
        .withValues(alpha: isDark ? 0.55 : 0.55);
    final tintBottom = (isDark ? Colors.black : Colors.white)
        .withValues(alpha: isDark ? 0.38 : 0.75);
    final stroke = Colors.white.withValues(alpha: isDark ? 0.10 : 0.24);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.55 : 0.20);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: border,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 28,
                spreadRadius: -10,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: border,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tintTop, tintBottom],
                  ),
                  border: Border.all(color: stroke, width: 0.8),
                  borderRadius: border,
                ),
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items) ...[
                        _DesktopOverlayBarButton(item: item),
                        if (item != items.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopOverlayBarButton extends StatelessWidget {
  final DesktopOverlayBarItem item;

  const _DesktopOverlayBarButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = item.onPressed != null;
    final foreground = item.isSelected
        ? Colors.white
        : theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.88 : 0.72);

    final selectedDecoration = BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.95),
          theme.colorScheme.secondary.withValues(alpha: 0.85),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return Tooltip(
      message: item.tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onPressed,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 52,
            height: 52,
            decoration: item.isSelected ? selectedDecoration : null,
            alignment: Alignment.center,
            child: Icon(
              item.icon,
              size: 24,
              color:
                  isEnabled ? foreground : foreground.withValues(alpha: 0.38),
            ),
          ),
        ),
      ),
    );
  }
}
