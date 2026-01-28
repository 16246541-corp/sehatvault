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
import '../../../widgets/design/glass_card.dart';
import '../../../widgets/design/liquid_glass_background.dart';
import '../../shared/widgets/profile/metric_card.dart';

/// Desktop profile health dashboard screen with split-view layout
/// Displays ONLY verified health metrics from HealthMetricsAggregator
class ProfileHealthDashboardDesktop extends StatefulWidget {
  const ProfileHealthDashboardDesktop({super.key});

  @override
  State<ProfileHealthDashboardDesktop> createState() => _ProfileHealthDashboardDesktopState();
}

class _ProfileHealthDashboardDesktopState extends State<ProfileHealthDashboardDesktop> {
  final LocalStorageService _storage = LocalStorageService();
  final HealthMetricsAggregator _metricsAggregator = HealthMetricsAggregator(LocalStorageService());
  
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<MetricSnapshot> _metrics = [];
  MetricSnapshot? _selectedMetric;
  
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
        // Select first metric by default if available
        _selectedMetric = metrics.isNotEmpty ? metrics.first : null;
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

  void _selectMetric(MetricSnapshot metric) {
    setState(() {
      _selectedMetric = metric;
    });
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

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Health Metrics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _isRefreshing ? null : _refreshMetrics,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh metrics',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // FDA Disclaimer
          const FdaDisclaimerWidget(
            padding: EdgeInsets.all(12),
          ),
          const SizedBox(height: 16),
          
          // Metrics list
          if (_isLoading) ...[
            const Center(child: CircularProgressIndicator()),
          ]
          else if (_error != null) ...[
            GlassCard(
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
              borderColor: theme.colorScheme.error.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading metrics',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _loadMetrics,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ]
          else if (_metrics.isEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 48,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Health Metrics Yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verify your first health document to see your metrics here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to document upload
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add Document'),
                  ),
                ],
              ),
            ),
          ]
          else ...[
            // Metrics list
            Expanded(
              child: ListView.builder(
                itemCount: _metrics.length,
                itemBuilder: (context, index) {
                  final metric = _metrics[index];
                  final isSelected = _selectedMetric?.metricName == metric.metricName;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _selectMetric(metric),
                      borderRadius: BorderRadius.circular(12),
                      child: GlassCard(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : null,
                        borderColor: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : null,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    metric.metricName
                                        .split('_')
                                        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
                                        .join(' '),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${metric.value.toStringAsFixed(1)} ${metric.unit}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: metric.isOutsideReference
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('MMM d, y').format(metric.measuredAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    final theme = Theme.of(context);
    
    if (_selectedMetric == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a metric to view details',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large metric card
          MetricCard(
            snapshot: _selectedMetric!,
            onTap: () => _navigateToDocumentDetails(_selectedMetric!.sourceRecordId),
            showReferenceRange: true,
            isSensitive: true,
          ),
          
          const SizedBox(height: 24),
          
          // Additional details
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metric Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Source information
                _buildDetailRow(
                  context,
                  'Source',
                  'Lab Report',
                  Icons.description,
                ),
                const SizedBox(height: 12),
                
                // Document date
                _buildDetailRow(
                  context,
                  'Document Date',
                  DateFormat('MMMM d, y').format(_selectedMetric!.measuredAt),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                
                // Reference range
                if (_getReferenceRange() != null) ...[
                  _buildDetailRow(
                    context,
                    'Reference Range',
                    _getReferenceRange()!,
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Status
                _buildDetailRow(
                  context,
                  'Status',
                  _selectedMetric!.isOutsideReference ? 'Outside Reference Range' : 'Within Reference Range',
                  _selectedMetric!.isOutsideReference ? Icons.warning : Icons.check_circle,
                  color: _selectedMetric!.isOutsideReference
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToDocumentDetails(_selectedMetric!.sourceRecordId),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Source Document'),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Last updated
          Center(
            child: Text(
              'Last updated: ${DateFormat('MMM d, y h:mm a').format(DateTime.now())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getReferenceRange() {
    final ranges = ReferenceRangeService.lookupReferenceRange(_selectedMetric!.metricName);
    if (ranges.isEmpty) return null;
    
    final range = ranges.first;
    final normalRange = range['normalRange'] as Map<String, dynamic>;
    final unit = range['unit'] as String;
    
    return '${normalRange['min']}-${normalRange['max']} $unit';
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _storage.getAppSettings();
    
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, _, __) {
        return AuthGate(
          enabled: settings.enhancedPrivacySettings.requireBiometricsForSensitiveData,
          reason: 'Authenticate to access your health metrics',
          child: LiquidGlassBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('Health Metrics Dashboard'),
                centerTitle: true,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              body: Row(
                children: [
                  // Sidebar (1/3 width)
                  SizedBox(
                    width: 350,
                    child: _buildSidebar(),
                  ),
                  
                  // Content area (2/3 width) with vertical divider
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: _buildContentArea(),
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