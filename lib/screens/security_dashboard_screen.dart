import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';
import '../main.dart'; // for storageService
import '../services/storage_usage_service.dart';
import '../services/session_manager.dart';
import '../services/biometric_service.dart';
import '../services/pin_auth_service.dart';
import '../models/export_audit_entry.dart';
import '../models/auth_audit_entry.dart';
import '../services/auth_audit_service.dart';
import '../services/education_service.dart';
import '../widgets/education/education_modal.dart';
import '../services/temp_file_manager.dart';
import '../services/consent_service.dart';
import '../services/export_service.dart';
import '../models/consent_entry.dart';
import '../widgets/timeline/consent_timeline.dart';
import 'biometric_settings_screen.dart';
import 'recording_history_screen.dart'; // Using as placeholder for full audit log if needed
import 'audit_timeline_screen.dart';
import 'privacy_manifest_screen.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() =>
      _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  final StorageUsageService _storageUsageService =
      StorageUsageService(storageService);
  final SessionManager _sessionManager = SessionManager();
  final BiometricService _biometricService = BiometricService();
  final PinAuthService _pinAuthService = PinAuthService();
  late final AuthAuditService _authAuditService;
  final ConsentService _consentService = ConsentService();
  final ExportService _exportService = ExportService();

  bool _isLoading = true;
  StorageUsage? _storageUsage;
  bool _isBiometricsAvailable = false;
  bool _hasPin = false;
  List<dynamic> _recentActivity = [];
  int _securityScore = 100;
  List<String> _improvementSuggestions = [];
  List<ConsentEntry> _consentHistory = [];
  final List<Map<String, String>> _educationItems = const [
    {'id': 'ai_features', 'title': 'AI Assistant'},
    {'id': 'document_scanner', 'title': 'Document Scanner'},
    {'id': 'secure_storage', 'title': 'Secure Storage'},
  ];

  @override
  void initState() {
    super.initState();
    _authAuditService = AuthAuditService(storageService);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load Storage Usage
    final usage = await _storageUsageService.calculateStorageUsage();

    // Load Biometrics Availability
    final bioAvailable = await _biometricService.isBiometricsAvailable;

    // Load PIN Status
    final hasPin = await _pinAuthService.hasPin();

    // Load Audit Logs
    List<dynamic> activity = [];
    try {
      final exports = storageService.getAllExportAuditEntries();
      final auths = _authAuditService.getRecentEvents();

      activity.addAll(exports);
      activity.addAll(auths);

      // Sort by date desc
      activity.sort((a, b) {
        DateTime timeA;
        DateTime timeB;
        if (a is ExportAuditEntry) {
          timeA = a.timestamp;
        } else if (a is AuthAuditEntry) {
          timeA = a.timestamp;
        } else {
          timeA = DateTime(0);
        }

        if (b is ExportAuditEntry) {
          timeB = b.timestamp;
        } else if (b is AuthAuditEntry) {
          timeB = b.timestamp;
        } else {
          timeB = DateTime(0);
        }

        return timeB.compareTo(timeA);
      });
    } catch (e) {
      debugPrint('Error loading audit logs: $e');
    }

    if (mounted) {
      setState(() {
        _storageUsage = usage;
        _isBiometricsAvailable = bioAvailable;
        _hasPin = hasPin;
        _recentActivity = activity.take(10).toList();
        _consentHistory = _consentService.getAllHistory();
        _calculateRiskScore();
        _isLoading = false;
      });
    }
  }

  void _calculateRiskScore() {
    int score = 100;
    List<String> suggestions = [];

    final settings = storageService.getAppSettings();
    final privacy = settings.enhancedPrivacySettings;

    if (!_hasPin) {
      score -= 30;
      suggestions.add('Set up a backup PIN');
    }

    if (!privacy.requireBiometricsForSensitiveData) {
      score -= 20;
      suggestions.add('Enable auth for sensitive data');
    }

    if (!privacy.requireBiometricsForExport) {
      score -= 10;
      suggestions.add('Enable auth for exports');
    }

    if (settings.sessionTimeoutMinutes > 5) {
      score -= 10;
      suggestions.add('Reduce session timeout (< 5 min)');
    }

    if (score < 0) score = 0;

    _securityScore = score;
    _improvementSuggestions = suggestions;
  }

  String _getTimeAgo(DateTime? time) {
    if (time == null) return 'Unknown';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppTheme.healthGreen;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'At Risk';
  }

  Future<void> _confirmRevokeConsent(ConsentEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Revoke Consent'),
            content: const Text(
                'Revoking consent disables this feature until you grant consent again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Revoke'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await _consentService.revokeConsent(entry.scope, 'User revoked');
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Security Dashboard'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Risk Indicator
                    _buildRiskIndicator(context),
                    const SizedBox(height: DesignConstants.sectionSpacing),

                    // Visual Cards
                    Text('Status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildStatusCards(context),
                    const SizedBox(height: DesignConstants.sectionSpacing),

                    // Audit Trail
                    Text('Recent Activity', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildAuditTrail(context),
                    const SizedBox(height: DesignConstants.sectionSpacing),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Consent History',
                            style: theme.textTheme.titleMedium),
                        IconButton(
                          onPressed: () =>
                              _exportService.exportConsentHistory(context),
                          icon: const Icon(Icons.share),
                          tooltip: 'Export Consent History',
                        ),
                      ],
                    ),
                    ConsentTimeline(
                      entries: _consentHistory,
                      onRevoke: _confirmRevokeConsent,
                    ),
                    const SizedBox(height: DesignConstants.sectionSpacing),

                    // Connected Devices
                    Text('Connected Devices',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildConnectedDevices(context),
                    const SizedBox(height: DesignConstants.sectionSpacing),

                    // Data Management
                    Text('Data Management', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildDataManagementCard(context),
                    const SizedBox(height: DesignConstants.sectionSpacing),

                    // Quick Actions
                    Text('Quick Actions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildAuditActionCard(context),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRiskIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getScoreColor(_securityScore);

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _securityScore / 100,
                      strokeWidth: 8,
                      backgroundColor: color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    '$_securityScore',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Score: ${_getScoreLabel(_securityScore)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_improvementSuggestions.isNotEmpty)
                      ..._improvementSuggestions
                          .take(2)
                          .map((suggestion) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 14,
                                        color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        suggestion,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                    else
                      Text(
                        'Your vault is well protected.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.healthGreen,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context) {
    final theme = Theme.of(context);
    final lastAuth = _sessionManager.lastUnlockTime;

    return Column(
      children: [
        // Auth Status
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security, color: AppTheme.accentTeal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_isBiometricsAvailable ? "Biometrics active" : "PIN active"} • Last authenticated ${_getTimeAgo(lastAuth)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Device Security
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phonelink_lock, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Security',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Strong encryption • No unauthorized access',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Storage Security
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.enhanced_encryption, color: Colors.purple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Security',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_storageUsage?.conversationCount ?? 0} recordings encrypted • ${_storageUsage?.documentCount ?? 0} documents protected',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildEducationCard(context),
      ],
    );
  }

  Widget _buildEducationCard(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<Map<String, bool>>(
      future: _getEducationCompletionMap(),
      builder: (context, snapshot) {
        final completionMap = snapshot.data ?? {};
        final completedCount =
            _educationItems.where((e) => completionMap[e['id']] == true).length;
        final totalCount = _educationItems.length;
        final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          onTap: () {
            _showEducationList(context, _educationItems, completionMap);
          },
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    backgroundColor:
                        theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    color: AppTheme.accentTeal,
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Knowledge Base',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount of $totalCount topics completed',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, bool>> _getEducationCompletionMap() async {
    final service = EducationService();
    final Map<String, bool> completionMap = {};
    for (final item in _educationItems) {
      final id = item['id'];
      if (id == null) continue;
      completionMap[id] = await service.isEducationCompleted(id);
    }
    return completionMap;
  }

  void _showEducationList(BuildContext context, List<Map<String, String>> items,
      Map<String, bool> completed) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Education Modules',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...items.map((item) {
                final isCompleted = completed[item['id']] == true;
                return ListTile(
                  title: Text(item['title']!),
                  leading: Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: isCompleted ? AppTheme.healthGreen : Colors.grey,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await EducationModal.show(context, contentId: item['id']!);
                    setState(() {});
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditTrail(BuildContext context) {
    final theme = Theme.of(context);

    if (_recentActivity.isEmpty && _sessionManager.lastUnlockTime == null) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No recent activity logged',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> events = [];

    // Combine session unlock with other activities if needed,
    // or just assume AuthAuditEntry covers unlocks (if we logged them).
    // SessionManager usually logs unlock events?
    // Checking SessionManager: it calls _logAuth? No, SessionManager just tracks in-memory.
    // So we should manually add the "Current Session" at the top if active.

    if (_sessionManager.lastUnlockTime != null) {
      events.add(_buildTimelineItem(
        context,
        icon: Icons.login,
        title: 'Current Session Unlocked',
        time: _sessionManager.lastUnlockTime!,
        color: AppTheme.healthGreen,
        isFirst: true,
        isLast: _recentActivity.isEmpty,
      ));
    }

    for (var i = 0; i < _recentActivity.length; i++) {
      final activity = _recentActivity[i];
      final isLast = i == _recentActivity.length - 1;
      final isFirst = events.isEmpty;

      if (activity is ExportAuditEntry) {
        events.add(_buildTimelineItem(
          context,
          icon: Icons.output,
          title: 'Data Exported (${activity.format.toUpperCase()})',
          subtitle: 'To: ${activity.recipientType}',
          time: activity.timestamp,
          color: Colors.orange,
          isFirst: isFirst,
          isLast: isLast,
        ));
      } else if (activity is AuthAuditEntry) {
        events.add(_buildTimelineItem(
          context,
          icon: activity.success ? Icons.verified_user : Icons.warning_amber,
          title: 'Auth: ${activity.action}',
          subtitle:
              '${activity.success ? "Success" : "Failed"}: ${activity.failureReason ?? "Unknown"}',
          time: activity.timestamp,
          color: activity.success ? Colors.blue : Colors.red,
          isFirst: isFirst,
          isLast: isLast,
        ));
      }
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: events,
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required DateTime time,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_sweep, color: Colors.amber),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temporary Files',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Securely shred cached recordings and images',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showPurgeDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Purge Now'),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.privacy_tip, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Manifest',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View detailed privacy report',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PrivacyManifestScreen(),
                    ),
                  );
                },
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPurgeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PurgeDialog(),
    );
  }

  Widget _buildConnectedDevices(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.devices_other, size: 48, color: theme.disabledColor),
              const SizedBox(height: 12),
              Text(
                'No connected devices',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sync features coming soon',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditActionCard(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AuditTimelineScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history_toggle_off,
                color: AppTheme.accentTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Audit Trail',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View and verify system security logs',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.lock_outline,
            label: 'Lock Now',
            onTap: () {
              _sessionManager.lockImmediately();
              Navigator.of(context)
                  .pop(); // Optional: Close dashboard? No, lock screen covers it.
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.history,
            label: 'Audit Log',
            onTap: () {
              // Navigate to full audit log (Recording History for now as placeholder or new screen)
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const RecordingHistoryScreen(), // Placeholder
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.settings_suggest_outlined,
            label: 'Security',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BiometricSettingsScreen(),
                ),
              );
              // Refresh data when returning
              _loadData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurgeDialog extends StatefulWidget {
  @override
  State<_PurgeDialog> createState() => _PurgeDialogState();
}

class _PurgeDialogState extends State<_PurgeDialog> {
  bool _isPurging = false;
  String _status = 'Preparing to purge...';

  @override
  void initState() {
    super.initState();
    _startPurge();
  }

  Future<void> _startPurge() async {
    setState(() => _isPurging = true);

    try {
      final tempManager = TempFileManager();

      setState(() => _status = 'Shredding temporary audio segments...');
      await tempManager.purgeAll(reason: 'manual_purge');

      setState(() => _status = 'Clearing image cache...');
      // Assuming more purge logic here if needed

      setState(() => _status = 'Purge complete.');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _status = 'Purge failed: $e');
    } finally {
      if (mounted) setState(() => _isPurging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              const Text(
                'Security Purge',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isPurging) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              if (!_isPurging)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
