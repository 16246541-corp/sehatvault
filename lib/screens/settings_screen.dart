import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';

/// Settings Screen - App preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignConstants.titleTopPadding),
              Text(
                'Settings',
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Privacy-first health locker',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // Privacy Section
              _buildSectionHeader(context, 'Privacy & Security'),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'App Lock',
                      subtitle: 'Require authentication to open',
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: AppTheme.accentTeal,
                      ),
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.fingerprint,
                      title: 'Biometric Authentication',
                      subtitle: 'Use Face ID or Touch ID',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {},
                        activeColor: AppTheme.accentTeal,
                      ),
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.enhanced_encryption_outlined,
                      title: 'Data Encryption',
                      subtitle: 'AES-256 encryption enabled',
                      trailing: Icon(
                        Icons.check_circle,
                        color: AppTheme.healthGreen,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // Storage Section
              _buildSectionHeader(context, 'Storage'),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.storage_outlined,
                      title: 'Local Storage Used',
                      subtitle: '0 MB of documents',
                      showChevron: false,
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.backup_outlined,
                      title: 'Export Data',
                      subtitle: 'Create encrypted backup',
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.delete_outline,
                      title: 'Clear All Data',
                      subtitle: 'Permanently delete all records',
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // AI Section
              _buildSectionHeader(context, 'AI Model'),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.psychology_outlined,
                      title: 'Local LLM',
                      subtitle: 'Configure local AI model',
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.download_outlined,
                      title: 'Download Model',
                      subtitle: 'Get AI model for offline use',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: DesignConstants.sectionSpacing),
              
              // About Section
              _buildSectionHeader(context, 'About'),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: '1.0.0',
                      showChevron: false,
                    ),
                    _buildDivider(context),
                    _buildSettingsItem(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Your data never leaves your device',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool showChevron = true,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return InkWell(
      onTap: () {
        // TODO: Handle tap
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (showChevron)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }
}
