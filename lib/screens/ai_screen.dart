import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';

import '../utils/design_constants.dart';

import '../widgets/cards/model_status_card.dart';

/// AI Screen - Local LLM interface placeholder
class AIScreen extends StatelessWidget {
  const AIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignConstants.titleTopPadding),
              Text(
                'AI Assistant',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Powered by local LLM • Your data stays on device',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // AI Status Card
              const ModelStatusCard(),
              
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildQuickAction(
                      context,
                      icon: Icons.summarize_outlined,
                      title: 'Summarize Document',
                      description: 'Get a quick summary of any health document',
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.translate,
                      title: 'Explain Medical Terms',
                      description: 'Understand complex medical terminology',
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.compare_arrows,
                      title: 'Compare Results',
                      description: 'Track changes in your lab results over time',
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.search,
                      title: 'Search Records',
                      description: 'Find information across all your documents',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () {
          // TODO: Handle action
        },
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
