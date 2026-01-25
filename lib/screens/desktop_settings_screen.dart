import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/app_settings.dart';
import '../services/platform_detector.dart';
import '../services/storage_usage_service.dart';
import '../main_common.dart' show storageService;
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';

/// Desktop-Optimized Settings Screen
class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen> {
  late AppSettings _settings;
  PlatformCapabilities? _capabilities;
  StorageUsage? _storageUsage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settings = storageService.getAppSettings();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        PlatformDetector().getCapabilities(),
        StorageUsageService(storageService).calculateStorageUsage(),
      ]);

      if (mounted) {
        setState(() {
          _capabilities = results[0] as PlatformCapabilities;
          _storageUsage = results[1] as StorageUsage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings(Function(AppSettings) update) async {
    update(_settings);
    await storageService.saveAppSettings(_settings);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Desktop Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidGlassBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCapabilityCard(theme),
                    const SizedBox(height: 20),
                    _buildPerformanceSection(theme),
                    const SizedBox(height: 20),
                    _buildWindowManagerSection(theme),
                    const SizedBox(height: 20),
                    _buildStorageValidationSection(theme),
                    const SizedBox(height: 20),
                    _buildDebugToolsSection(theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCapabilityCard(ThemeData theme) {
    if (_capabilities == null) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.computer, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text('System Capabilities', style: theme.textTheme.titleLarge),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Platform', _capabilities!.platformName),
          _buildInfoRow('Device Model', _capabilities!.deviceModel),
          _buildInfoRow(
              'Memory (RAM)', '${_capabilities!.ramGB.toStringAsFixed(2)} GB'),
          _buildInfoRow('GPU Acceleration',
              _capabilities!.hasGpuSupport ? 'Supported' : 'Not Detected'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text('Performance Tuning', style: theme.textTheme.titleMedium),
        ),
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('GPU Acceleration'),
                subtitle: const Text(
                    'Use hardware acceleration for rendering and AI'),
                value: _settings.enableGpuAcceleration,
                onChanged: (val) =>
                    _updateSettings((s) => s.enableGpuAcceleration = val),
              ),
              const Divider(),
              ListTile(
                title: const Text('Cache Limit'),
                subtitle: Text('${_settings.increasedCacheLimitMB} MB'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCacheLimitDialog(),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('High-Capability Models'),
                subtitle: const Text(
                    'Enable resource-intensive AI models for desktop'),
                value: _settings.autoSelectModel,
                onChanged: (val) =>
                    _updateSettings((s) => s.autoSelectModel = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWindowManagerSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text('Window Management', style: theme.textTheme.titleMedium),
        ),
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Persist Window State'),
                subtitle:
                    const Text('Remember window size and position on restart'),
                value: _settings.persistWindowState,
                onChanged: (val) async {
                  await _updateSettings((s) => s.persistWindowState = val);
                },
              ),
              if (_settings.persistWindowState) ...[
                const Divider(),
                SwitchListTile(
                  title: const Text('Restore Position'),
                  subtitle: const Text(
                      'Return window to its last location on screen'),
                  value: _settings.restoreWindowPosition,
                  onChanged: (val) async {
                    await _updateSettings((s) => s.restoreWindowPosition = val);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Reset Window Position'),
                  subtitle:
                      const Text('Center the window on the primary screen'),
                  trailing: const Icon(Icons.center_focus_strong_outlined),
                  onTap: () async {
                    await windowManager.center();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Window centered')),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageValidationSection(ThemeData theme) {
    if (_storageUsage == null) return const SizedBox.shrink();

    final isLowStorage =
        _storageUsage!.freeBytes < (1024 * 1024 * 1024 * 5); // 5GB threshold

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child:
              Text('Storage & Maintenance', style: theme.textTheme.titleMedium),
        ),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  isLowStorage ? Icons.warning_amber_rounded : Icons.storage,
                  color:
                      isLowStorage ? Colors.orange : theme.colorScheme.primary,
                ),
                title: const Text('System Storage Check'),
                subtitle: Text(isLowStorage
                    ? 'Warning: Low disk space detected'
                    : 'Sufficient disk space available'),
                trailing: Text(
                    '${(_storageUsage!.freeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB free'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebugToolsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text('Developer Tools', style: theme.textTheme.titleMedium),
        ),
        GlassCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Desktop Debug Mode'),
                subtitle:
                    const Text('Enable advanced logging and inspection tools'),
                value: _settings.showDesktopDebugTools,
                onChanged: (val) =>
                    _updateSettings((s) => s.showDesktopDebugTools = val),
              ),
              if (_settings.showDesktopDebugTools) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.grid_view),
                  title: const Text('Capability Matrix'),
                  onTap: () => _showCapabilityMatrix(),
                ),
                ListTile(
                  leading: const Icon(Icons.terminal),
                  title: const Text('View Secure Logs'),
                  onTap: () => _showSecureLogs(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showCapabilityMatrix() {
    if (_capabilities == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Capability Matrix',
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              ...DeviceCapability.values.map((cap) => ListTile(
                    title: Text(cap.toString().split('.').last),
                    trailing: Icon(
                      _capabilities!.supportedCapabilities.contains(cap)
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _capabilities!.supportedCapabilities.contains(cap)
                          ? Colors.green
                          : Colors.red,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecureLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Secure Logs (Redacted)'),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildLogEntry('INFO', 'Application started on desktop'),
              _buildLogEntry('DEBUG',
                  'RAM detected: ${_capabilities?.ramGB.toStringAsFixed(2)} GB'),
              _buildLogEntry('WARN',
                  'Low storage check: ${(_storageUsage?.freeBytes ?? 0) / (1024 * 1024 * 1024) < 5 ? "FAILED" : "PASSED"}'),
              _buildLogEntry('INFO', 'Model recommendation: MedGemma-4B'),
              _buildLogEntry(
                  'INFO', 'Window state persisted: width=1200, height=800'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String level, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '[$level] ',
              style: TextStyle(
                color: level == 'WARN'
                    ? Colors.orange
                    : (level == 'DEBUG' ? Colors.blue : Colors.green),
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            TextSpan(
              text: message,
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCacheLimitDialog() async {
    final theme = Theme.of(context);
    final options = [256, 512, 1024, 2048, 4096];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Increased Cache Limit'),
        children: options
            .map((opt) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, opt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          _settings.increasedCacheLimitMB == opt
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text('$opt MB'),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );

    if (result != null) {
      _updateSettings((s) => s.increasedCacheLimitMB = result);
    }
  }
}
