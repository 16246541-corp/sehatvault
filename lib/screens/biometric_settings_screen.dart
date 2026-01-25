import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/enhanced_privacy_settings.dart';
import '../services/biometric_service.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';
import '../main_common.dart' show storageService;
import '../widgets/auth_gate.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  State<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricsAvailable = false;
  bool _isLoading = true;
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final available = await _biometricService.isBiometricsAvailable;
    _settings = storageService.getAppSettings();

    if (mounted) {
      setState(() {
        _isBiometricsAvailable = available;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(
    String key,
    bool value,
    Function(EnhancedPrivacySettings) updateFn,
  ) async {
    // 1. Admin Mode Check
    if (_settings.enhancedPrivacySettings.requireBiometricsForSettings) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to change security settings',
        sessionId: _biometricService.sessionId,
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication required to change settings')),
          );
        }
        return;
      }
    }

    // 2. Warning when disabling
    if (!value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reduce Security?'),
          content: const Text(
              'Disabling this reduces your data security. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // 3. Update Setting
    setState(() {
      updateFn(_settings.enhancedPrivacySettings);
    });
    await storageService.saveAppSettings(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AuthGate(
      enabled: _settings.enhancedPrivacySettings.requireBiometricsForSettings,
      reason: 'Authenticate to manage security settings',
      child: LiquidGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Biometric Security'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isBiometricsAvailable)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.error),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Biometric authentication is not available on this device.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  'Security Levels',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSwitch(
                        context,
                        title: 'Sensitive Data Access',
                        subtitle: 'Require auth for recordings and transcripts',
                        value: _settings.enhancedPrivacySettings
                            .requireBiometricsForSensitiveData,
                        onChanged: (val) => _updateSetting(
                          'sensitive_data',
                          val,
                          (s) => s.requireBiometricsForSensitiveData = val,
                        ),
                      ),
                      const Divider(height: 1),
                      _buildSwitch(
                        context,
                        title: 'Export Data',
                        subtitle: 'Require auth before exporting files',
                        value: _settings
                            .enhancedPrivacySettings.requireBiometricsForExport,
                        onChanged: (val) => _updateSetting(
                          'export',
                          val,
                          (s) => s.requireBiometricsForExport = val,
                        ),
                      ),
                      const Divider(height: 1),
                      _buildSwitch(
                        context,
                        title: 'Model Management',
                        subtitle: 'Require auth to change AI models',
                        value: _settings.enhancedPrivacySettings
                            .requireBiometricsForModelChange,
                        onChanged: (val) => _updateSetting(
                          'model',
                          val,
                          (s) => s.requireBiometricsForModelChange = val,
                        ),
                      ),
                      const Divider(height: 1),
                      _buildSwitch(
                        context,
                        title: 'Security Settings',
                        subtitle: 'Require auth to change these settings',
                        value: _settings.enhancedPrivacySettings
                            .requireBiometricsForSettings,
                        onChanged: (val) => _updateSetting(
                          'settings',
                          val,
                          (s) => s.requireBiometricsForSettings = val,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDisabled = !_isBiometricsAvailable;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isDisabled ? theme.disabledColor : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDisabled ? theme.disabledColor : null,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value && !isDisabled,
            onChanged: isDisabled ? null : onChanged,
            activeTrackColor: AppTheme.accentTeal.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.accentTeal,
          ),
        ],
      ),
    );
  }
}
