import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../widgets/ai/model_info_panel.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';
import '../models/model_option.dart';
import '../main_common.dart' show storageService;
import '../services/storage_usage_service.dart';
import '../services/conversation_cleanup_service.dart';
import 'model_selection_screen.dart';
import 'recording_history_screen.dart';
import 'biometric_settings_screen.dart';
import 'security_dashboard_screen.dart';
import 'desktop_settings_screen.dart';
import '../services/session_manager.dart';
import '../services/generation_parameters_service.dart';
import '../widgets/ai/generation_controls.dart';
import '../services/model_quantization_service.dart';
import '../services/model_update_service.dart';
import 'pin_setup_screen.dart';
import 'privacy_manifest_screen.dart';
import 'issue_reporting_review_screen.dart';
import 'compliance_checklist_screen.dart';
import 'ai_diagnostics_screen.dart';
import 'model_license_screen.dart';
import '../services/keyboard_shortcut_service.dart';

enum SettingCategory {
  privacy,
  storage,
  recording,
  notifications,
  aiModel,
  accessibility,
  desktop,
  about,
}

/// Settings Screen - App preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final StorageUsageService _storageUsageService;
  StorageUsage? _storageUsage;
  bool _isLoadingUsage = false;
  int _pointerCount = 0;
  double? _gestureStartY;
  bool _gestureTriggered = false;
  SettingCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _storageUsageService = StorageUsageService(storageService);
    _loadStorageUsage();
  }

  Future<void> _loadStorageUsage() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsage = true;
    });

    try {
      final usage = await _storageUsageService.calculateStorageUsage();
      if (mounted) {
        setState(() {
          _storageUsage = usage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsage = false;
        });
      }
    }
  }

  String _getSelectedModelName() {
    final settings = storageService.getAppSettings();
    final modelId = settings.selectedModelId;
    return ModelOption.availableModels
        .firstWhere((m) => m.id == modelId,
            orElse: () => ModelOption.availableModels.first)
        .name;
  }

  Future<void> _showAutoStopDurationDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    int? selectedDuration = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title: Text('Auto-stop Duration', style: theme.textTheme.titleLarge),
          backgroundColor: theme.cardColor,
          children: [15, 30, 45, 60].map((duration) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, duration);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      settings.autoStopRecordingMinutes == duration
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('$duration minutes', style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedDuration != null &&
        selectedDuration != settings.autoStopRecordingMinutes) {
      settings.autoStopRecordingMinutes = selectedDuration;
      await storageService.saveAppSettings(settings);
    }
  }

  Future<void> _showAutoDeleteDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    final options = [30, 90, 180, 365, 730];
    int? selectedDays = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title:
              Text('Auto-delete Recordings', style: theme.textTheme.titleLarge),
          backgroundColor: theme.cardColor,
          children: options.map((days) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, days);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      settings.autoDeleteRecordingsDays == days
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('$days days', style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedDays != null &&
        selectedDays != settings.autoDeleteRecordingsDays) {
      settings.autoDeleteRecordingsDays = selectedDays;
      await storageService.saveAppSettings(settings);
      setState(() {});
    }
  }

  Future<void> _showRetentionPolicyDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    final options = [5, 15, 30, 60, 0]; // 0 means Never
    int? selectedMinutes = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title:
              Text('Model Retention Policy', style: theme.textTheme.titleLarge),
          backgroundColor: theme.cardColor,
          children: options.map((mins) {
            String label =
                mins == 0 ? 'Keep loaded (Never unload)' : '$mins minutes';
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, mins);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      settings.modelRetentionMinutes == mins
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(label, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selectedMinutes != null &&
        selectedMinutes != settings.modelRetentionMinutes) {
      settings.modelRetentionMinutes = selectedMinutes;
      await storageService.saveAppSettings(settings);
      setState(() {});
    }
  }

  Future<void> _showMemoryDepthDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    final options = [10, 20, 50, 100];
    int? selected = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title: Text('Conversation Memory Depth',
              style: theme.textTheme.titleLarge),
          backgroundColor: theme.cardColor,
          children: options.map((count) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, count),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      settings.aiMaxMessages == count
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('$count messages', style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && selected != settings.aiMaxMessages) {
      settings.aiMaxMessages = selected;
      await storageService.saveAppSettings(settings);
      setState(() {});
    }
  }

  Future<void> _showMemoryWindowDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    final options = [1024, 2048, 4096, 8192];
    int? selected = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title:
              Text('Context Token Window', style: theme.textTheme.titleLarge),
          backgroundColor: theme.cardColor,
          children: options.map((tokens) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, tokens),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      settings.aiMaxTokens == tokens
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text('$tokens tokens', style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && selected != settings.aiMaxTokens) {
      settings.aiMaxTokens = selected;
      await storageService.saveAppSettings(settings);
      setState(() {});
    }
  }

  Future<void> _showQuantizationDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    final options = QuantizationFormat.values;
    final service = ModelQuantizationService();

    QuantizationFormat? selected = await showDialog<QuantizationFormat>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return SimpleDialog(
          title: Text('Model Quantization', style: theme.textTheme.titleLarge),
          backgroundColor: theme.cardColor,
          children: options.map((format) {
            final tradeoffs = service.getTradeoffs(format);
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, format),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          settings.preferredQuantization == format.name
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(format.label,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0, top: 4.0),
                      child: Text(
                        tradeoffs.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && selected.name != settings.preferredQuantization) {
      settings.preferredQuantization = selected.name;
      await storageService.saveAppSettings(settings);
      setState(() {});
    }
  }

  Future<void> _showIssueReportingDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isEmpty) return;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      IssueReportingReviewScreen(description: controller.text),
                ),
              );
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleModelUpdateCheck(BuildContext context) async {
    final updateService = ModelUpdateService();
    final updates = await updateService.checkForUpdates();

    if (!mounted) return;

    if (updates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All models are up to date and verified.'),
          backgroundColor: AppTheme.healthGreen,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Updates Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: updates.map((model) {
              return ListTile(
                title: Text(model.name),
                subtitle: Text('New version: v${model.metadata.version}'),
                trailing: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await updateService.performUpdate(model);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Successfully updated ${model.name}'
                              : 'Failed to update ${model.name}. Check logs.'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                      setState(() {});
                    }
                  },
                  child: const Text('Update'),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: (event) {
        if (!kDebugMode) return;
        _pointerCount += 1;
        if (_pointerCount == 4) {
          _gestureStartY = event.position.dy;
          _gestureTriggered = false;
        }
      },
      onPointerUp: (event) {
        if (!kDebugMode) return;
        _pointerCount -= 1;
        if (_pointerCount < 0) {
          _pointerCount = 0;
        }
        if (_pointerCount < 4) {
          _gestureStartY = null;
          _gestureTriggered = false;
        }
      },
      onPointerCancel: (event) {
        if (!kDebugMode) return;
        _pointerCount = 0;
        _gestureStartY = null;
        _gestureTriggered = false;
      },
      onPointerMove: (event) {
        if (!kDebugMode) return;
        if (_pointerCount == 4 &&
            !_gestureTriggered &&
            _gestureStartY != null) {
          final dy = event.position.dy - _gestureStartY!;
          if (dy.abs() > 100) {
            _gestureTriggered = true;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ComplianceChecklistScreen(),
              ),
            );
          }
        }
      },
      child: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: DesignConstants.titleTopPadding),
                Row(
                  children: [
                    if (_selectedCategory != null) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => setState(() => _selectedCategory = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      _selectedCategory == null
                          ? 'Settings'
                          : _getCategoryTitle(_selectedCategory!),
                      style: theme.textTheme.displayMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCategory == null
                      ? 'Privacy-first health locker'
                      : _getCategorySubtitle(_selectedCategory!),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: DesignConstants.sectionSpacing),

                if (_selectedCategory == null) ...[
                  _buildMenu(context),
                ],

                // Privacy Section (Category Only)
                if (_selectedCategory == SettingCategory.privacy) ...[
                  _buildSectionHeader(context, 'Privacy & Security'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.dashboard_outlined,
                          title: 'Security Dashboard',
                          subtitle: 'Overview of your security status',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SecurityDashboardScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.lock_outline,
                          title: 'App Lock',
                          subtitle: 'Require authentication to open',
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.pin_outlined,
                          title: 'PIN & Recovery',
                          subtitle: 'Change PIN or security question',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PinUnlockScreen(
                                  title: 'Verify PIN',
                                  subtitle: 'Unlock to update PIN settings',
                                  onAuthenticated: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => PinSetupScreen(
                                          mode: PinSetupMode.change,
                                          onComplete: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  onCancel: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.fingerprint,
                          title: 'Biometric Security',
                          subtitle: 'Manage access controls',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BiometricSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.timer_outlined,
                          title: 'Session Timeout',
                          subtitle:
                              '${storageService.getAppSettings().sessionTimeoutMinutes} minutes',
                          onTap: () => _showTimeoutDialog(context),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.enhanced_encryption_outlined,
                          title: 'Data Encryption',
                          subtitle: 'AES-256 encryption enabled',
                          trailing: const Icon(
                            Icons.check_circle,
                            color: AppTheme.healthGreen,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.history,
                          title: 'Recording History',
                          subtitle: 'View audit logs of all recordings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RecordingHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.bug_report_outlined,
                          title: 'Report an Issue',
                          subtitle: 'Anonymized issue reporting',
                          onTap: () => _showIssueReportingDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],

                // Storage Section (Category Only)
                if (_selectedCategory == SettingCategory.storage) ...[
                  _buildSectionHeader(context, 'Storage'),
                  _buildStorageUsageIndicator(context),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.delete_sweep_outlined,
                          title: 'Clear expired recordings',
                          subtitle:
                              'Remove audio older than ${storageService.getAppSettings().autoDeleteRecordingsDays} days',
                          onTap: _handleClearExpiredRecordings,
                          showChevron: false,
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.compress,
                          title: 'Compress old recordings',
                          subtitle: 'Reduce audio quality after 90 days',
                          onTap: _handleCompressOldRecordings,
                          showChevron: false,
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.auto_delete_outlined,
                          title: 'Auto-delete Original',
                          subtitle: 'Delete images after extraction',
                          trailing: Switch(
                            value: storageService.autoDeleteOriginal,
                            onChanged: (value) async {
                              await storageService.setAutoDeleteOriginal(value);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
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
                ],

                // Recording Section (Category Only)
                if (_selectedCategory == SettingCategory.recording) ...[
                  _buildSectionHeader(context, 'Recording'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.timer_outlined,
                          title: 'Auto-stop Timer',
                          subtitle:
                              'Stop after ${storageService.getAppSettings().autoStopRecordingMinutes} minutes',
                          onTap: () async {
                            await _showAutoStopDurationDialog(context);
                            setState(() {});
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.auto_delete_outlined,
                          title: 'Auto-delete Recordings',
                          subtitle:
                              'Delete after ${storageService.getAppSettings().autoDeleteRecordingsDays} days',
                          onTap: () => _showAutoDeleteDialog(context),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.battery_alert_outlined,
                          title: 'Battery Warnings',
                          subtitle: 'Alert when battery is low',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .enableBatteryWarnings,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.enableBatteryWarnings = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: DesignConstants.sectionSpacing),

                // Notifications Section (Category Only)
                if (_selectedCategory == SettingCategory.notifications) ...[
                  _buildSectionHeader(context, 'Desktop Notifications'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.notifications_active_outlined,
                          title: 'Enable Notifications',
                          subtitle: 'Receive desktop alerts',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .notificationsEnabled,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.notificationsEnabled = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Mask Sensitive Notifications',
                          subtitle: 'Hide content in notification body',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .enhancedPrivacySettings
                                .maskNotifications,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.enhancedPrivacySettings
                                  .maskNotifications = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.accessibility_new_outlined,
                          title: 'Screen Reader Announcements',
                          subtitle: 'Announce notifications for accessibility',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .accessibilityEnabled,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.accessibilityEnabled = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // AI Model Section (Category Only)
                if (_selectedCategory == SettingCategory.aiModel) ...[
                  _buildSectionHeader(context, 'AI Model'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.psychology_outlined,
                          title: 'Local LLM',
                          subtitle: _getSelectedModelName(),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ModelSelectionScreen(),
                              ),
                            );
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.memory_outlined,
                          title: 'Memory Management',
                          subtitle:
                              storageService.getAppSettings().unloadOnLowMemory
                                  ? 'Auto-unload enabled'
                                  : 'Always keep in memory',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .unloadOnLowMemory,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.unloadOnLowMemory = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.timer_outlined,
                          title: 'Retention Policy',
                          subtitle: storageService
                                      .getAppSettings()
                                      .modelRetentionMinutes ==
                                  0
                              ? 'Never unload'
                              : 'Unload after ${storageService.getAppSettings().modelRetentionMinutes}m idle',
                          onTap: () => _showRetentionPolicyDialog(context),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.history_outlined,
                          title: 'Conversation Memory Depth',
                          subtitle:
                              '${storageService.getAppSettings().aiMaxMessages ?? 20} messages retained',
                          onTap: () => _showMemoryDepthDialog(context),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.compress_outlined,
                          title: 'Context Token Window',
                          subtitle:
                              '${storageService.getAppSettings().aiMaxTokens ?? 2048} tokens per prompt',
                          onTap: () => _showMemoryWindowDialog(context),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.download_outlined,
                          title: 'Download Model',
                          subtitle: 'Get AI model for offline use',
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.update_outlined,
                          title: 'Check for Model Updates',
                          subtitle:
                              'Verify integrity and version compatibility',
                          onTap: () => _handleModelUpdateCheck(context),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.healing_outlined,
                          title: 'Wellness Language',
                          subtitle: 'Use person-first language',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .enableWellnessLanguageChecks,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.enableWellnessLanguageChecks = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        if (storageService
                            .getAppSettings()
                            .enableWellnessLanguageChecks) ...[
                          _buildDivider(context),
                          _buildSettingsItem(
                            context,
                            icon: Icons.developer_mode,
                            title: 'Debug Visualization',
                            subtitle: 'Show replacement metrics',
                            trailing: Switch(
                              value: storageService
                                  .getAppSettings()
                                  .showWellnessDebugInfo,
                              onChanged: (value) async {
                                final settings =
                                    storageService.getAppSettings();
                                settings.showWellnessDebugInfo = value;
                                await storageService.saveAppSettings(settings);
                                setState(() {});
                              },
                              activeTrackColor:
                                  AppTheme.accentTeal.withValues(alpha: 0.5),
                              activeThumbColor: AppTheme.accentTeal,
                            ),
                          ),
                        ],
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.tune_outlined,
                          title: 'Advanced Generation Controls',
                          subtitle: 'Fine-tune AI output parameters',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .advancedAiSettingsEnabled,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.advancedAiSettingsEnabled = value;
                              await storageService.saveAppSettings(settings);
                              GenerationParametersService()
                                  .toggleAdvancedSettings(value);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.analytics_outlined,
                          title: 'AI Usage Analytics',
                          subtitle: 'Local performance & usage metrics',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .enableAiAnalytics,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.enableAiAnalytics = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        if (storageService
                            .getAppSettings()
                            .enableAiAnalytics) ...[
                          _buildDivider(context),
                          _buildSettingsItem(
                            context,
                            icon: Icons.dashboard_customize_outlined,
                            title: 'AI Diagnostics Dashboard',
                            subtitle: 'View performance charts & logs',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AIDiagnosticsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ModelInfoPanel(compact: true),
                  if (storageService
                      .getAppSettings()
                      .advancedAiSettingsEnabled) ...[
                    const SizedBox(height: 16),
                    const GenerationControls(),
                  ],
                ],

                // Accessibility Section (Category Only)
                if (_selectedCategory == SettingCategory.accessibility) ...[
                  _buildSectionHeader(context, 'Accessibility & Shortcuts'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.keyboard_outlined,
                          title: 'Keyboard Shortcuts',
                          subtitle: 'Enable desktop shortcuts (Cmd/Ctrl + /)',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .enableKeyboardShortcuts,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.enableKeyboardShortcuts = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.info_outline,
                          title: 'Shortcut Cheat Sheet',
                          subtitle: 'View all available shortcuts',
                          onTap: () {
                            KeyboardShortcutService()
                                .executeAction('toggle_cheat_sheet');
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                // Desktop Experience Section (Category Only)
                if (_selectedCategory == SettingCategory.desktop &&
                    !kIsWeb &&
                    (Platform.isMacOS ||
                        Platform.isWindows ||
                        Platform.isLinux)) ...[
                  _buildSectionHeader(context, 'Desktop Experience'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          icon: Icons.desktop_windows_outlined,
                          title: 'Desktop Optimization',
                          subtitle: 'Performance & window settings',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DesktopSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingsItem(
                          context,
                          icon: Icons.keyboard_outlined,
                          title: 'Keyboard Shortcuts',
                          subtitle: 'Enable desktop hotkeys',
                          trailing: Switch(
                            value: storageService
                                .getAppSettings()
                                .enableKeyboardShortcuts,
                            onChanged: (value) async {
                              final settings = storageService.getAppSettings();
                              settings.enableKeyboardShortcuts = value;
                              await storageService.saveAppSettings(settings);
                              setState(() {});
                            },
                            activeTrackColor:
                                AppTheme.accentTeal.withValues(alpha: 0.5),
                            activeThumbColor: AppTheme.accentTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // About Section (Category Only)
                if (_selectedCategory == SettingCategory.about) ...[
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
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacyManifestScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildSettingsItem(
                          context,
                          icon: Icons.gavel_outlined,
                          title: 'Model Licenses',
                          subtitle: 'Open-source and usage terms',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ModelLicenseScreen(),
                              ),
                            );
                          },
                        ),
                        if (kDebugMode) ...[
                          _buildDivider(context),
                          _buildSettingsItem(
                            context,
                            icon: Icons.fact_check_outlined,
                            title: 'Compliance Checklist',
                            subtitle: 'Review regulatory compliance',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ComplianceChecklistScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      (
        category: SettingCategory.privacy,
        title: 'Privacy & Security',
        icon: Icons.security,
        subtitle: 'App lock, biometric, encryption'
      ),
      (
        category: SettingCategory.storage,
        title: 'Storage',
        icon: Icons.storage,
        subtitle: 'Usage, cleanup, backup'
      ),
      (
        category: SettingCategory.recording,
        title: 'Recording',
        icon: Icons.mic,
        subtitle: 'Auto-stop, retention, alerts'
      ),
      (
        category: SettingCategory.notifications,
        title: 'Desktop Notifications',
        icon: Icons.notifications,
        subtitle: 'Alerts, masking, accessibility'
      ),
      (
        category: SettingCategory.aiModel,
        title: 'AI Model',
        icon: Icons.psychology,
        subtitle: 'Local LLM, memory, generation'
      ),
      (
        category: SettingCategory.accessibility,
        title: 'Accessibility & Shortcuts',
        icon: Icons.accessibility_new,
        subtitle: 'Hotkeys, screen reader'
      ),
      if (!kIsWeb &&
          (Platform.isMacOS || Platform.isWindows || Platform.isLinux))
        (
          category: SettingCategory.desktop,
          title: 'Desktop Experience',
          icon: Icons.desktop_windows,
          subtitle: 'Optimization, window settings'
        ),
      (
        category: SettingCategory.about,
        title: 'About',
        icon: Icons.info_outline,
        subtitle: 'Version, licenses, privacy manifest'
      ),
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            _buildSettingsItem(
              context,
              icon: categories[i].icon,
              title: categories[i].title,
              subtitle: categories[i].subtitle,
              onTap: () => setState(() => _selectedCategory = categories[i].category),
            ),
            if (i < categories.length - 1) _buildDivider(context),
          ],
        ],
      ),
    );
  }

  String _getCategoryTitle(SettingCategory category) {
    switch (category) {
      case SettingCategory.privacy:
        return 'Privacy & Security';
      case SettingCategory.storage:
        return 'Storage';
      case SettingCategory.recording:
        return 'Recording';
      case SettingCategory.notifications:
        return 'Desktop Notifications';
      case SettingCategory.aiModel:
        return 'AI Model';
      case SettingCategory.accessibility:
        return 'Accessibility & Shortcuts';
      case SettingCategory.desktop:
        return 'Desktop Experience';
      case SettingCategory.about:
        return 'About';
    }
  }

  String _getCategorySubtitle(SettingCategory category) {
    switch (category) {
      case SettingCategory.privacy:
        return 'Manage your security preferences';
      case SettingCategory.storage:
        return 'Monitor and optimize storage usage';
      case SettingCategory.recording:
        return 'Configure audio recording behavior';
      case SettingCategory.notifications:
        return 'Customize desktop alerts and privacy';
      case SettingCategory.aiModel:
        return 'Fine-tune your local AI experience';
      case SettingCategory.accessibility:
        return 'Shortcuts and assistive features';
      case SettingCategory.desktop:
        return 'Optimize for your operating system';
      case SettingCategory.about:
        return 'Version and legal information';
    }
  }

  Widget _buildStorageUsageIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final usage = _storageUsage;

    if (_isLoadingUsage || usage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final double usedPercentage = usage.usagePercentage; // Device usage
    final bool showWarning = usedPercentage > 0.8;

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Usage',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_storageUsageService.formatBytes(usage.totalBytes)} used by SehatLocker',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (showWarning) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: theme.colorScheme.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Storage > 80% full',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: CircularProgressIndicator(
                      value: usage
                          .usagePercentage, // Total device usage if available, else 0 or small
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        showWarning
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${(usage.usagePercentage * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStorageRow(
            context,
            'Conversations',
            _storageUsageService.formatBytes(usage.conversationsBytes),
            '${usage.conversationCount} recordings',
            Icons.mic_none_outlined,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStorageRow(
            context,
            'Documents',
            _storageUsageService.formatBytes(usage.documentsBytes),
            '${usage.documentCount} items',
            Icons.description_outlined,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildStorageRow(
            context,
            'Models',
            _storageUsageService.formatBytes(usage.modelsBytes),
            'AI Models',
            Icons.psychology_outlined,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageRow(
    BuildContext context,
    String label,
    String size,
    String detail,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              Text(detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        Text(size,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _handleClearExpiredRecordings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Expired Recordings?'),
        content: Text(
            'This will delete audio recordings older than ${storageService.getAppSettings().autoDeleteRecordingsDays} days, except those marked as "Keep". Transcripts will be preserved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ConversationCleanupService(storageService).runDailyCleanup();
      await _loadStorageUsage();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expired recordings cleared')),
        );
      }
    }
  }

  Future<void> _handleCompressOldRecordings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compress Recordings'),
        content: const Text(
            'This feature will compress audio files older than 90 days to save space while keeping them listenable.\n\nComing soon!'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
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
    VoidCallback? onTap,
    bool showChevron = true,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
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

  Future<void> _showTimeoutDialog(BuildContext context) async {
    final settings = storageService.getAppSettings();
    int selectedMinutes = settings.sessionTimeoutMinutes;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Timeout'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lock app after $selectedMinutes minutes of inactivity'),
                Slider(
                  value: selectedMinutes.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$selectedMinutes min',
                  onChanged: (value) {
                    setState(() {
                      selectedMinutes = value.toInt();
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              settings.sessionTimeoutMinutes = selectedMinutes;
              await storageService.saveAppSettings(settings);
              SessionManager().resetActivity();
              Navigator.pop(context);
              if (mounted) {
                this.setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
