import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/app_settings.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/storage_usage_service.dart';
import '../../../services/session_manager.dart';
import '../../../services/onboarding_service.dart';
import '../../../screens/onboarding/onboarding_navigator.dart';
import '../../../app.dart';

class DesktopSettingsCategory {
  final String id;
  final String label;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const DesktopSettingsCategory({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

final List<DesktopSettingsCategory> desktopSettingsCategories = [
  const DesktopSettingsCategory(
    id: 'privacy',
    label: 'Privacy & Security',
    subtitle: 'Biometric, locker',
    description:
        'Manage how Sehat Locker protects your sensitive health data, configure biometric access, and control encryption levels.',
    icon: Icons.security,
    color: Colors.purpleAccent,
  ),
  const DesktopSettingsCategory(
    id: 'storage',
    label: 'Storage',
    subtitle: 'Usage, cleanup',
    description:
        'Review storage usage, manage cache, and keep your locker tidy over time.',
    icon: Icons.storage,
    color: Colors.blueAccent,
  ),
  const DesktopSettingsCategory(
    id: 'recording',
    label: 'Recording',
    subtitle: 'Auto-stop, retention',
    description:
        'Control recording behavior, retention policies, and capture preferences.',
    icon: Icons.mic,
    color: Colors.pinkAccent,
  ),
  const DesktopSettingsCategory(
    id: 'notifications',
    label: 'Notifications',
    subtitle: 'Alerts, masking',
    description:
        'Configure alerts, privacy masking, and how updates appear while you work.',
    icon: Icons.notifications,
    color: Colors.orangeAccent,
  ),
  const DesktopSettingsCategory(
    id: 'ai',
    label: 'AI Model',
    subtitle: 'Local LLM, memory',
    description:
        'Choose your on-device model, adjust behavior, and review assistant settings.',
    icon: Icons.psychology,
    color: Colors.tealAccent,
  ),
  const DesktopSettingsCategory(
    id: 'accessibility',
    label: 'Accessibility',
    subtitle: 'Hotkeys, reader',
    description:
        'Improve readability and navigation with accessibility preferences and shortcuts.',
    icon: Icons.accessibility_new,
    color: Colors.greenAccent,
  ),
  const DesktopSettingsCategory(
    id: 'desktop',
    label: 'Desktop Experience',
    subtitle: 'Window settings',
    description: 'Configure desktop-only behaviors and window preferences.',
    icon: Icons.desktop_windows,
    color: Colors.cyanAccent,
  ),
  const DesktopSettingsCategory(
    id: 'about',
    label: 'About',
    subtitle: 'Version, licenses',
    description: 'Version details, licenses, and app information.',
    icon: Icons.info_outline,
    color: Colors.indigoAccent,
  ),
];

class DesktopSettingsScreen extends StatefulWidget {
  final String selectedCategoryId;

  const DesktopSettingsScreen({
    super.key,
    required this.selectedCategoryId,
  });

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  late final StorageUsageService _storageUsageService;
  StorageUsage? _storageUsage;
  bool _isLoadingUsage = false;

  @override
  void initState() {
    super.initState();
    _storageUsageService = StorageUsageService(LocalStorageService());
    _loadStorageUsage();
  }

  Future<void> _loadStorageUsage() async {
    if (!mounted) return;
    setState(() => _isLoadingUsage = true);
    try {
      final usage = await _storageUsageService.calculateStorageUsage();
      if (mounted) setState(() => _storageUsage = usage);
    } finally {
      if (mounted) setState(() => _isLoadingUsage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Custom Theme Colors for this screen based on screenshot
    final selectedCategory = desktopSettingsCategories.firstWhere(
      (c) => c.id == widget.selectedCategoryId,
      orElse: () => desktopSettingsCategories.first,
    );

    return Scaffold(
      body: ValueListenableBuilder(
          valueListenable: Hive.box('settings').listenable(),
          builder: (context, box, _) {
            return Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Color(0xFF1E293B), // Slate 800
                    Color(0xFF0F172A), // Deep Navy
                  ],
                ),
              ),
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(48, 28, 48, 40),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 980),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings  ›  ${selectedCategory.label}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                selectedCategory.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedCategory.description,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _buildContent(selectedCategory.id),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Search Bar
          Container(
            width: 240,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search,
                    size: 16, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Text(
                  'Search settings...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.settings,
              size: 18,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String categoryId) {
    final settings = LocalStorageService().getAppSettings();

    switch (categoryId) {
      case 'privacy':
        return _buildPrivacyContent(settings);
      case 'storage':
        return _buildStorageContent(settings);
      case 'recording':
        return _buildRecordingContent(settings);
      case 'notifications':
        return _buildNotificationsContent(settings);
      case 'ai':
        return _buildAIContent(settings);
      case 'accessibility':
        return _buildAccessibilityContent(settings);
      case 'desktop':
        return _buildDesktopContent(settings);
      case 'about':
        return _buildAboutContent(settings);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPrivacyContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'ACCESS CONTROL'),
        _SettingsCard(
          icon: Icons.fingerprint,
          iconColor: Colors.purpleAccent,
          title: 'Biometric Unlock',
          description:
              'Use TouchID or FaceID to access your locker without a password.',
          trailing: Switch(
            value: settings
                .enhancedPrivacySettings.requireBiometricsForSensitiveData,
            onChanged: (v) async {
              settings.enhancedPrivacySettings
                  .requireBiometricsForSensitiveData = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.timer,
          iconColor: Colors.indigoAccent,
          title: 'Auto-Lock Timer',
          description:
              'Automatically lock the application after a period of inactivity.',
          trailing: _ValueButton(
            text: 'After ${settings.sessionTimeoutMinutes} minutes',
            onTap: () => _showTimeoutDialog(context, settings),
          ),
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'DATA PROTECTION'),
        _SettingsCard(
          icon: Icons.lock,
          iconColor: Colors.greenAccent,
          title: 'Enhanced Encryption (AES-256)',
          description:
              'All local files are encrypted at rest. Disabling this requires a restart.',
          trailing: Switch(
            value: true,
            onChanged: (v) {}, // Always on for now
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
          ),
          isHighlighted: true,
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.visibility_off,
          iconColor: Colors.amberAccent,
          title: 'Screen Privacy Mode',
          description:
              'Blur sensitive data when application loses focus or is in background.',
          trailing: Switch(
            value: settings.enhancedPrivacySettings
                .maskNotifications, // Mapping to maskNotifications for now
            onChanged: (v) async {
              settings.enhancedPrivacySettings.maskNotifications = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'DANGER ZONE', color: Colors.redAccent),
        _SettingsCard(
          title: 'Reset Local Database',
          description:
              'Permanently delete all locally stored records and keys. This cannot be undone.',
          titleColor: Colors.redAccent,
          trailing: _ActionButton(
            text: 'Reset Data',
            color: Colors.redAccent.withValues(alpha: 0.2),
            textColor: Colors.redAccent,
            onTap: () => _handleClearAllData(context),
          ),
          borderColor: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildStorageContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoadingUsage && _storageUsage == null) ...[
          const _SectionHeader(title: 'USAGE'),
          _SettingsCard(
            title: 'Calculating Storage Usage',
            description: 'Scanning local files and records…',
            icon: Icons.data_usage,
            iconColor: Colors.blueAccent,
            trailing: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
        if (_storageUsage != null) ...[
          const _SectionHeader(title: 'USAGE'),
          _SettingsCard(
            title: 'Storage Usage',
            description:
                '${_storageUsageService.formatBytes(_storageUsage!.totalBytes)} used by SehatLocker',
            icon: Icons.data_usage,
            iconColor: Colors.blueAccent,
            trailing: Text(
              '${(_storageUsage!.usagePercentage * 100).toInt()}%',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
        ],
        const _SectionHeader(title: 'CLEANUP'),
        _SettingsCard(
          icon: Icons.delete_sweep,
          iconColor: Colors.orangeAccent,
          title: 'Clear Expired Recordings',
          description:
              'Remove audio older than ${settings.autoDeleteRecordingsDays} days',
          trailing: _ActionButton(
            text: 'Clear Now',
            color: Colors.orangeAccent.withValues(alpha: 0.2),
            textColor: Colors.orangeAccent,
            onTap: () {}, // TODO: Implement cleanup call
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.auto_delete,
          iconColor: Colors.redAccent,
          title: 'Auto-delete Original',
          description: 'Delete images after extraction',
          trailing: Switch(
            value: LocalStorageService().autoDeleteOriginal,
            onChanged: (v) async {
              await LocalStorageService().setAutoDeleteOriginal(v);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'RECORDING BEHAVIOR'),
        _SettingsCard(
          icon: Icons.timer,
          iconColor: Colors.pinkAccent,
          title: 'Auto-stop Timer',
          description: 'Stop recording automatically after a set duration.',
          trailing: _ValueButton(
            text: '${settings.autoStopRecordingMinutes} minutes',
            onTap: () {}, // TODO: Implement dialog
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.calendar_today,
          iconColor: Colors.blueAccent,
          title: 'Auto-delete Recordings',
          description:
              'Automatically delete recordings after a set number of days.',
          trailing: _ValueButton(
            text: '${settings.autoDeleteRecordingsDays} days',
            onTap: () {}, // TODO: Implement dialog
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'DESKTOP NOTIFICATIONS'),
        _SettingsCard(
          icon: Icons.notifications_active,
          iconColor: Colors.orangeAccent,
          title: 'Enable Notifications',
          description: 'Receive desktop alerts for important events.',
          trailing: Switch(
            value: settings.notificationsEnabled,
            onChanged: (v) async {
              settings.notificationsEnabled = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.privacy_tip,
          iconColor: Colors.purpleAccent,
          title: 'Mask Sensitive Content',
          description: 'Hide sensitive details in notification body.',
          trailing: Switch(
            value: settings.enhancedPrivacySettings.maskNotifications,
            onChanged: (v) async {
              settings.enhancedPrivacySettings.maskNotifications = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAIContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'MODEL CONFIGURATION'),
        _SettingsCard(
          icon: Icons.psychology,
          iconColor: Colors.tealAccent,
          title: 'Local LLM',
          description: 'Selected model for on-device inference.',
          trailing: _ValueButton(
            text: settings.selectedModelId,
            onTap: () {}, // TODO: Navigate to selection
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.memory,
          iconColor: Colors.cyanAccent,
          title: 'Unload on Low Memory',
          description: 'Free up RAM when system memory is low.',
          trailing: Switch(
            value: settings.unloadOnLowMemory,
            onChanged: (v) async {
              settings.unloadOnLowMemory = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'INPUT'),
        _SettingsCard(
          icon: Icons.keyboard,
          iconColor: Colors.greenAccent,
          title: 'Keyboard Shortcuts',
          description: 'Enable keyboard shortcuts for quick navigation.',
          trailing: Switch(
            value: settings.enableKeyboardShortcuts,
            onChanged: (v) async {
              settings.enableKeyboardShortcuts = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'WINDOW'),
        _SettingsCard(
          icon: Icons.window,
          iconColor: Colors.blueGrey,
          title: 'Restore Window Position',
          description: 'Remember window size and position on restart.',
          trailing: Switch(
            value: settings.restoreWindowPosition,
            onChanged: (v) async {
              settings.restoreWindowPosition = v;
              await LocalStorageService().saveAppSettings(settings);
              setState(() {});
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutContent(AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'APPLICATION'),
        const _SettingsCard(
          icon: Icons.info,
          iconColor: Colors.indigoAccent,
          title: 'Version',
          description: '1.0.0 (Build 100)',
          trailing: SizedBox(),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          icon: Icons.description,
          iconColor: Colors.blueAccent,
          title: 'Privacy Policy',
          description: 'Read our privacy policy.',
          trailing: Icon(Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  Future<void> _showTimeoutDialog(
      BuildContext context, AppSettings settings) async {
    int selectedMinutes = settings.sessionTimeoutMinutes;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Session Timeout',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lock app after $selectedMinutes minutes of inactivity',
                  style: const TextStyle(color: Colors.white70)),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$selectedMinutes min',
                onChanged: (value) {
                  setDialogState(() {
                    selectedMinutes = value.toInt();
                  });
                },
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white10,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                settings.sessionTimeoutMinutes = selectedMinutes;
                await LocalStorageService().saveAppSettings(settings);
                SessionManager().resetActivity();
                if (context.mounted) {
                  Navigator.pop(context);
                }
                if (mounted) setState(() {});
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Clear All Data?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'This will permanently delete ALL your records, documents, and settings. This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OnboardingService().logout(clearData: true);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => OnboardingNavigator(
            onComplete: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SehatLockerApp()),
                (route) => false,
              );
            },
          ),
        ),
        (route) => false,
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader({required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String description;
  final Widget? trailing;
  final bool isHighlighted;
  final Color? titleColor;
  final Color? borderColor;

  const _SettingsCard({
    this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    this.trailing,
    this.isHighlighted = false,
    this.titleColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ??
              (isHighlighted
                  ? Colors.blueAccent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05)),
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.blue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? Colors.blue, size: 24),
            ),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 20),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ValueButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ValueButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.text,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(text),
    );
  }
}
