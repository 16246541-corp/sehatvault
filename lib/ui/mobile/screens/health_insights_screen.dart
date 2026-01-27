import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/health_pattern_insight.dart';
import '../../../services/battery_monitor_service.dart';
import '../../../services/health_intelligence_engine.dart';
import '../../../services/local_audit_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/medical_field_extractor.dart';
import '../../../services/reference_range_service.dart';
import '../../../services/safety_filter_service.dart';
import '../../../services/session_manager.dart';
import '../../../shared/widgets/health_insight_card.dart';
import '../../../utils/design_constants.dart';
import '../../../widgets/auth_gate.dart';
import '../../../widgets/compliance/emergency_use_banner.dart';
import '../../../widgets/compliance/fda_disclaimer_widget.dart';
import '../../../widgets/design/liquid_glass_background.dart';
import '../../../widgets/design/responsive_center.dart';

class HealthInsightsScreen extends StatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  State<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends State<HealthInsightsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final BatteryMonitorService _batteryMonitor = BatteryMonitorService();

  bool _isLoading = true;
  String? _error;
  String? _batteryGateMessage;
  List<HealthPatternInsight> _insights = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _batteryGateMessage = null;
    });

    try {
      final settings = _storage.getAppSettings();
      if (!settings.enhancedPrivacySettings.showHealthInsights && !force) {
        setState(() {
          _insights = const [];
          _isLoading = false;
        });
        return;
      }

      final level = await _batteryMonitor.batteryLevel;
      final state = await _batteryMonitor.batteryState;
      if (state != BatteryState.charging &&
          state != BatteryState.full &&
          level < BatteryMonitorService.warningThreshold) {
        setState(() {
          _batteryGateMessage =
              'Background analysis is disabled below ${BatteryMonitorService.warningThreshold}% battery.';
          _insights = const [];
          _isLoading = false;
        });
        return;
      }

      final engine = HealthIntelligenceEngine(
        storage: _storage,
        fieldExtractor: MedicalFieldExtractor(),
        referenceRanges: ReferenceRangeService(),
        safetyFilter: SafetyFilterService(),
        auditLogger: LocalAuditService(_storage, SessionManager()),
      );

      final insights = await engine.detectAndPersistInsights(force: force);
      if (!mounted) return;
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, _, __) {
        final settings = _storage.getAppSettings();
        return AuthGate(
          enabled: settings.enhancedPrivacySettings.requireBiometricsForSensitiveData,
          reason: 'Authenticate to access Health Insights',
          child: LiquidGlassBackground(
            child: ResponsiveCenter(
              maxContentWidth: 800,
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.pageHorizontalPadding,
                    ),
                    children: [
                      const SizedBox(height: 96),
                      const SizedBox(height: DesignConstants.titleTopPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Health Insights',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          IconButton(
                            onPressed: _isLoading ? null : () => _load(force: true),
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Analyze again',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Privacy-preserving, on-device patterns (non-diagnostic)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      if (_batteryGateMessage != null)
                        Text(
                          _batteryGateMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (!settings.enhancedPrivacySettings.showHealthInsights)
                        Text(
                          'Health Insights are turned off in Privacy settings.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else if (_insights.isEmpty)
                        Text(
                          'No insights available yet.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ..._insights.map(
                          (insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HealthInsightCard(insight: insight),
                          ),
                        ),
                      const SizedBox(height: 28),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 32),
                        child: FdaDisclaimerWidget(),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.pageHorizontalPadding,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EmergencyUseBanner(),
                            const SizedBox(height: 8),
                            const FdaDisclaimerWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
