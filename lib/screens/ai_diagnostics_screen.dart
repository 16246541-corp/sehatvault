import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/ai_analytics_service.dart';
import '../models/ai_usage_metric.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../utils/theme.dart';

class AIDiagnosticsScreen extends StatefulWidget {
  const AIDiagnosticsScreen({super.key});

  @override
  State<AIDiagnosticsScreen> createState() => _AIDiagnosticsScreenState();
}

class _AIDiagnosticsScreenState extends State<AIDiagnosticsScreen> {
  final AIAnalyticsService _analyticsService = AIAnalyticsService();
  late List<AIUsageMetric> _metrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _analyticsService.init();
    _metrics = _analyticsService.getMetrics();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI Diagnostics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _analyticsService.exportAnonymizedData(),
            tooltip: 'Export Anonymized Data',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearConfirm,
            tooltip: 'Clear Data',
          ),
        ],
      ),
      body: LiquidGlassBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _metrics.isEmpty
                ? _buildEmptyState()
                : _buildDashboard(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined,
                size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'No Analytics Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Usage data will appear here once you start using the AI assistant.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignConstants.pageHorizontalPadding,
        kToolbarHeight + DesignConstants.pageVerticalPadding,
        DesignConstants.pageHorizontalPadding,
        DesignConstants.pageVerticalPadding,
      ),
      children: [
        _buildSummaryCards(),
        const SizedBox(height: DesignConstants.sectionSpacing),
        _buildTpsChart(),
        const SizedBox(height: DesignConstants.sectionSpacing),
        _buildMemoryChart(),
        const SizedBox(height: DesignConstants.sectionSpacing),
        _buildModelUsageList(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final avgTps = _metrics.isEmpty
        ? 0.0
        : _metrics.map((m) => m.tokensPerSecond).reduce((a, b) => a + b) /
            _metrics.length;
    final totalTokens = _metrics.fold<int>(0, (sum, m) => sum + m.totalTokens);
    final avgLoadTime = _metrics.isEmpty
        ? 0.0
        : _metrics.map((m) => m.loadTimeMs).reduce((a, b) => a + b) /
            _metrics.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Speed',
            '${avgTps.toStringAsFixed(1)} t/s',
            Icons.speed,
          ),
        ),
        const SizedBox(width: DesignConstants.gridSpacing),
        Expanded(
          child: _buildStatCard(
            'Total Tokens',
            NumberFormat.compact().format(totalTokens),
            Icons.token,
          ),
        ),
        const SizedBox(width: DesignConstants.gridSpacing),
        Expanded(
          child: _buildStatCard(
            'Avg Load',
            '${(avgLoadTime / 1000).toStringAsFixed(1)}s',
            Icons.timer,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTpsChart() {
    // Show last 10 inference results
    final inferenceMetrics = _metrics
        .where((m) => m.operationType == 'inference')
        .toList()
        .reversed
        .take(10)
        .toList()
        .reversed
        .toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance (Tokens/sec)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: inferenceMetrics.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.tokensPerSecond);
                    }).toList(),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryChart() {
    // Show memory usage over time
    final memoryMetrics = _metrics.reversed.take(10).toList().reversed.toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peak Memory Usage (MB)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: memoryMetrics.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.peakMemoryMb,
                        color: Colors.purple.withOpacity(0.7),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelUsageList() {
    final Map<String, int> modelCounts = {};
    for (var m in _metrics) {
      modelCounts[m.modelId] = (modelCounts[m.modelId] ?? 0) + 1;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Model Usage History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...modelCounts.entries.map((e) => ListTile(
                leading: const Icon(Icons.model_training),
                title: Text(e.key),
                trailing: Text('${e.value} sessions'),
                dense: true,
              )),
        ],
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Analytics?'),
        content: const Text('This will delete all local usage metrics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _analyticsService.clearAllData();
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
