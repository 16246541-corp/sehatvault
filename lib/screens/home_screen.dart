import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/responsive_center.dart';
import '../widgets/dashboard/follow_up_dashboard.dart';
import '../utils/design_constants.dart';
import 'follow_up_list_screen.dart';

/// Home Screen - Overview and Tasks
class HomeScreen extends StatelessWidget {
  final VoidCallback? onTasksTap;

  const HomeScreen({
    super.key,
    this.onTasksTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: Material(
        type: MaterialType.transparency,
        child: ResponsiveCenter(
          maxContentWidth: 1000,
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DesignConstants.titleTopPadding),
                  Text(
                    'Home',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your health at a glance',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DesignConstants.sectionSpacing),
                  FollowUpDashboard(
                    onTap: () {
                      if (onTasksTap != null) {
                        onTasksTap!();
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FollowUpListScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: DesignConstants.sectionSpacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
