import 'dart:ui';

import 'package:flutter/material.dart';

class MobileFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  final Map<int, int>? badgeCounts;
  final Map<int, bool>? attentionIndicators;

  const MobileFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    this.badgeCounts,
    this.attentionIndicators,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(30);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: 74,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: isDark ? 0.62 : 0.58),
                        (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: isDark ? 0.42 : 0.78),
                      ],
                    ),
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.22),
                      width: 0.9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.20),
                        blurRadius: 26,
                        spreadRadius: -10,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _NavIcon(
                        icon: Icons.home_rounded,
                        tooltip: 'Home',
                        isSelected: currentIndex == 0,
                        showAttention: attentionIndicators?[0] == true,
                        badgeCount: badgeCounts?[0],
                        onTap: () => onItemTapped(0),
                      ),
                      _NavIcon(
                        icon: Icons.psychology_rounded,
                        tooltip: 'AI',
                        isSelected: currentIndex == 2,
                        showAttention: attentionIndicators?[2] == true,
                        onTap: () => onItemTapped(2),
                      ),
                      _NavIcon(
                        icon: Icons.article_rounded,
                        tooltip: 'News',
                        isSelected: currentIndex == 3,
                        showAttention: attentionIndicators?[3] == true,
                        onTap: () => onItemTapped(3),
                      ),
                      _NavIcon(
                        icon: Icons.folder_rounded,
                        tooltip: 'Documents',
                        isSelected: currentIndex == 1,
                        showAttention: attentionIndicators?[1] == true,
                        onTap: () => onItemTapped(1),
                      ),
                      _NavIcon(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        isSelected: currentIndex == 4,
                        showAttention: attentionIndicators?[4] == true,
                        onTap: () => onItemTapped(4),
                      ),
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

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final bool showAttention;
  final int? badgeCount;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.showAttention,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.86 : 0.70);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 56,
                  height: 56,
                  decoration: isSelected
                      ? BoxDecoration(
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
                        )
                      : null,
                ),
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : inactiveColor,
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Badge(
                      label: Text('$badgeCount'),
                      backgroundColor: Colors.red,
                      child: const SizedBox(width: 0, height: 0),
                    ),
                  )
                else if (showAttention)
                  Positioned(
                    right: 16,
                    top: 14,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

