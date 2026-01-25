import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/design_constants.dart';
import '../../utils/theme.dart';

/// Glass Bottom Navigation Bar with 4 tabs
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  final Map<int, int>? badgeCounts;
  final Map<int, bool>? attentionIndicators;

  const GlassBottomNav({
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

    return Container(
      padding: DesignConstants.bottomNavPadding,
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(DesignConstants.bottomNavCornerRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: DesignConstants.bottomNavHeight,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius:
                  BorderRadius.circular(DesignConstants.bottomNavCornerRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  label: 'Documents',
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.task_alt_outlined,
                  activeIcon: Icons.task_alt,
                  label: 'Tasks',
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  icon: Icons.psychology_outlined,
                  activeIcon: Icons.psychology,
                  label: 'AI',
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.article_outlined,
                  activeIcon: Icons.article,
                  label: 'News',
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = currentIndex == index;

    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
    final showAttention = attentionIndicators?[index] == true;

    Widget iconWidget = Icon(
      isActive ? activeIcon : icon,
      color: isActive ? activeColor : inactiveColor,
      size: 24,
    );

    if (badgeCounts != null &&
        badgeCounts![index] != null &&
        badgeCounts![index]! > 0) {
      iconWidget = Badge(
        label: Text('${badgeCounts![index]}'),
        backgroundColor: Colors.red,
        child: iconWidget,
      );
    } else if (showAttention) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.accentTeal,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: DesignConstants.fastAnimationDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
