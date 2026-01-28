import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/metric_snapshot.dart';
import '../../../services/health_metrics_aggregator.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/reference_range_service.dart';
import '../../../services/session_manager.dart';
import '../../../utils/design_constants.dart';
import '../../../widgets/auth_gate.dart';
import '../../../widgets/compliance/fda_disclaimer_widget.dart';
import '../../../widgets/design/glass_progress_bar.dart';
import '../../../widgets/design/liquid_glass_background.dart';
import '../../../widgets/design/responsive_center.dart';
import '../../../widgets/empty_states/empty_conversations_state.dart';
import '../../shared/widgets/profile/metric_card.dart';

/// Mobile profile health dashboard screen
/// Displays ONLY verified health metrics from HealthMetricsAggregator
class ProfileHealthDashboardMobile extends StatefulWidget {
  const ProfileHealthDashboardMobile({super.key});

  @override
  State<ProfileHealthDashboardMobile> createState() =>
      _ProfileHealthDashboardMobileState();
}

class _ProfileHealthDashboardMobileState
    extends State<ProfileHealthDashboardMobile> {
  final LocalStorageService _storage = LocalStorageService();
  final HealthMetricsAggregator _metricsAggregator =
      HealthMetricsAggregator(LocalStorageService());

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<MetricSnapshot> _metrics = [];

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if Phase 1 is complete (has verified documents)
      final hasVerifiedDocuments = _metricsAggregator.checkPhase1Completion();
      if (!hasVerifiedDocuments) {
        setState(() {
          _metrics = [];
          _isLoading = false;
        });
        return;
      }

      // Get all verified metrics
      final metrics = await _metricsAggregator.getAllLatestVerifiedMetrics();

      if (!mounted) return;
      setState(() {
        _metrics = metrics;
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

  Future<void> _refreshMetrics() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Trigger recompute and reload
      await _metricsAggregator.getAllLatestVerifiedMetrics();
      await _loadMetrics();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _navigateToDocumentDetails(String recordId) {
    // TODO: Navigate to document details screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => DocumentDetailsScreen(recordId: recordId),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _storage.getAppSettings();

    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, _, __) {
        return AuthGate(
          enabled: settings
              .enhancedPrivacySettings.requireBiometricsForSensitiveData,
          reason: 'Authenticate to access your health metrics',
          child: LiquidGlassBackground(
            child: ResponsiveCenter(
              maxContentWidth: 800,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Health Metrics'),
                  centerTitle: true,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                ),
                body: RefreshIndicator(
                  onRefresh: _refreshMetrics,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.pageHorizontalPadding,
                      vertical: 16,
                    ),
                    children: [
                      // FDA Disclaimer at top
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: FdaDisclaimerWidget(),
                      ),

                      // Loading state
                      if (_isLoading) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ]
                      // Error state
                      else if (_error != null) ...[
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading metrics',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadMetrics,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // No verified documents state
                      else if (_metrics.isEmpty) ...[
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No Health Metrics Yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Verify your first health document to see your metrics here.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Navigate to document upload
                                  // Navigator.pushNamed(context, '/documents');
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Add Document'),
                              ),
                            ],
                          ),
                        ),
                      ]
                      // Metrics list
                      else ...[
                        // Refresh indicator
                        if (_isRefreshing) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],

                        // Metrics grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _metrics.length,
                          itemBuilder: (context, index) {
                            final metric = _metrics[index];
                            return MetricCard(
                              snapshot: metric,
                              onTap: () => _navigateToDocumentDetails(
                                  metric.sourceRecordId),
                              showReferenceRange: true,
                              isSensitive:
                                  true, // All health metrics are sensitive
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Last updated info
                        Center(
                          child: Text(
                            'Last updated: ${DateFormat('MMM d, y h:mm a').format(DateTime.now())}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
