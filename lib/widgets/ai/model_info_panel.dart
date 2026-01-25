import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/model_option.dart';
import '../../services/model_manager.dart';
import '../../services/model_fallback_service.dart';
import '../../services/reference_range_service.dart';
import '../../services/llm_engine.dart';
import '../design/glass_card.dart';

class ModelInfoPanel extends StatefulWidget {
  final ModelOption? model;
  final bool compact;
  final bool initiallyExpanded;

  const ModelInfoPanel({
    super.key,
    this.model,
    this.compact = false,
    this.initiallyExpanded = false,
  });

  @override
  State<ModelInfoPanel> createState() => _ModelInfoPanelState();
}

class _ModelInfoPanelState extends State<ModelInfoPanel> {
  late bool _isExpanded;
  ModelOption? _activeModel;
  bool _loading = true;

  // Performance metrics
  final Map<String, dynamic> _metrics = {
    'loadTime': '0.0s',
    'inferenceSpeed': '0 t/s',
    'memoryUsage': 'Unknown',
    'contextUsage': 0.0,
    'contextTokens': 0,
    'maxContext': 2048,
  };

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _loadModelInfo();
    ModelFallbackService().addListener(_onFallbackEvent);
  }

  @override
  void dispose() {
    ModelFallbackService().removeListener(_onFallbackEvent);
    super.dispose();
  }

  void _onFallbackEvent() {
    if (mounted) {
      _loadModelInfo();
    }
  }

  Future<void> _loadModelInfo() async {
    final engine = LLMEngine();
    if (engine.currentModel != null) {
      setState(() {
        _activeModel = engine.currentModel;
        _loading = false;
        _updateMetrics(_activeModel!);
      });
      return;
    }

    if (widget.model != null) {
      setState(() {
        _activeModel = widget.model;
        _loading = false;
        _updateMetrics(_activeModel!);
      });
      return;
    }

    // Load from ModelManager
    final model = await ModelManager.getRecommendedModel();

    if (mounted) {
      setState(() {
        _activeModel = model;
        _loading = false;
        _updateMetrics(model);
      });
    }
  }

  void _updateMetrics(ModelOption model) {
    final engine = LLMEngine();
    final metrics = engine.metrics;

    if (metrics != null) {
      setState(() {
        _metrics['loadTime'] =
            '${(metrics.loadTimeMs / 1000).toStringAsFixed(1)}s';
        _metrics['inferenceSpeed'] =
            '${metrics.tokensPerSecond.toStringAsFixed(1)} t/s';
        _metrics['memoryUsage'] = '${model.ramRequired} GB';
        _metrics['contextUsage'] = metrics.contextUsage;
        _metrics['contextTokens'] = metrics.contextTokens;
        _metrics['maxContext'] = metrics.maxContextTokens;
      });
    } else {
      setState(() {
        if (model.id.contains('tiny')) {
          _metrics['loadTime'] = '0.8s';
          _metrics['inferenceSpeed'] = '55 t/s';
          _metrics['memoryUsage'] = '1.1 GB';
        } else if (model.id.contains('advanced')) {
          _metrics['loadTime'] = '2.4s';
          _metrics['inferenceSpeed'] = '25 t/s';
          _metrics['memoryUsage'] = '5.8 GB';
        } else {
          _metrics['loadTime'] = '1.5s';
          _metrics['inferenceSpeed'] = '35 t/s';
          _metrics['memoryUsage'] = '${model.ramRequired} GB';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GlassCard(child: Center(child: CircularProgressIndicator()));
    }

    if (_activeModel == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    // Check if knowledge is outdated (> 1 year)
    final isOutdated = _activeModel!.knowledgeCutoffDate != null &&
        DateTime.now().difference(_activeModel!.knowledgeCutoffDate!).inDays >
            365;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Semantics(
            button: true,
            label:
                'Model Information Panel. Double tap to ${_isExpanded ? "collapse" : "expand"}.',
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.psychology,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeModel!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.compact)
                            Text(
                              'v${_activeModel!.metadata.version} • ${_activeModel!.license}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (isOutdated)
                      Tooltip(
                        message: 'Knowledge cutoff > 1 year ago',
                        child: Icon(Icons.warning_amber,
                            color: Colors.orange, size: 20),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      context, 'Version', _activeModel!.metadata.version),
                  _buildInfoRow(
                      context,
                      'Release Date',
                      DateFormat.yMMMd()
                          .format(_activeModel!.metadata.releaseDate)),
                  if (_activeModel!.knowledgeCutoffDate != null)
                    _buildInfoRow(
                      context,
                      'Knowledge Cutoff',
                      DateFormat.yMMMd()
                          .format(_activeModel!.knowledgeCutoffDate!),
                      isWarning: isOutdated,
                      helpText: isOutdated
                          ? 'Model knowledge may be outdated for recent medical developments'
                          : null,
                    ),
                  _buildInfoRow(context, 'License', _activeModel!.license),

                  if (ModelFallbackService().history.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildFallbackStatus(context),
                  ],

                  const SizedBox(height: 20),
                  Text('Performance Metrics',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(context, 'Load Time', _metrics['loadTime']),
                      _buildMetric(
                          context, 'Speed', _metrics['inferenceSpeed']),
                      _buildMetric(context, 'Memory', _metrics['memoryUsage']),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text('Context Window',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_metrics['contextTokens']} / ${_metrics['maxContext']} tokens',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '${(_metrics['contextUsage'] * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _metrics['contextUsage'] > 0.8
                                  ? Colors.orange
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _metrics['contextUsage'],
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _metrics['contextUsage'] > 0.9
                                ? Colors.red
                                : _metrics['contextUsage'] > 0.7
                                    ? Colors.orange
                                    : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automatic truncation preserves conversation flow',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Integration check / Reference Range
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            size: 20, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reference Database Active',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${ReferenceRangeService.getAllTestNames().length} medical tests supported',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      {bool isWarning = false, String? helpText}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7))),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isWarning ? Colors.orange : null,
                ),
              ),
            ],
          ),
          if (helpText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                helpText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            )),
      ],
    );
  }

  Widget _buildFallbackStatus(BuildContext context) {
    final theme = Theme.of(context);
    final lastEvent = ModelFallbackService().history.last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fallback Active',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Reason: ${lastEvent.reason ?? "Optimization"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Show dialog to manage models or disable fallback
              _showFallbackSettings(context);
            },
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }

  void _showFallbackSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final service = ModelFallbackService();
          return AlertDialog(
            title: const Text('Model Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Automatic Fallback'),
                  subtitle:
                      const Text('Automatically switch models on failure'),
                  value: service.isAutoFallbackEnabled,
                  onChanged: (val) {
                    service.setAutoFallback(val);
                    setDialogState(() {});
                  },
                ),
                const Divider(),
                const Text('Active Model History',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...service.history.reversed.take(3).map((e) => ListTile(
                      dense: true,
                      title: Text('${e.fromModel.name} → ${e.toModel.name}'),
                      subtitle: Text(DateFormat.jm().format(e.timestamp)),
                      leading: const Icon(Icons.history, size: 16),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
