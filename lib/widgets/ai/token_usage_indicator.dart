import 'package:flutter/material.dart';
import '../../services/llm_engine.dart';
import '../../services/analytics_service.dart';
import '../../utils/design_constants.dart';
import '../design/glass_card.dart';

/// A widget that displays the current token usage of the AI model.
///
/// Features:
/// - Real-time token counting with visual progress bar
/// - Color-coded status indicators (Warning at 70%, Critical at 90%)
/// - Detailed breakdown view with expandable sections
/// - Tooltip explanations for accessibility
class TokenUsageIndicator extends StatefulWidget {
  final bool compact;

  const TokenUsageIndicator({
    super.key,
    this.compact = false,
  });

  @override
  State<TokenUsageIndicator> createState() => _TokenUsageIndicatorState();
}

class _TokenUsageIndicatorState extends State<TokenUsageIndicator> {
  final LLMEngine _engine = LLMEngine();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ModelMetrics>(
      stream: _engine.metricsStream,
      initialData: _engine.metrics,
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        if (metrics == null) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final usage = metrics.contextUsage;

        // Determine color based on usage thresholds
        Color statusColor = theme.colorScheme.primary;
        String statusText = 'Normal';

        if (usage >= 0.9) {
          statusColor = Colors.red;
          statusText = 'Critical';
        } else if (usage >= 0.7) {
          statusColor = Colors.orange;
          statusText = 'Warning';
        }

        // Log usage patterns for analytics
        AnalyticsService().logEvent('token_usage_viewed', parameters: {
          'usage_ratio': usage,
          'tokens': metrics.contextTokens,
          'max_tokens': metrics.maxContextTokens,
        });

        return Semantics(
          label:
              'Token usage indicator. Context usage is ${(usage * 100).toStringAsFixed(0)}%. Status: $statusText.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProgressBar(context, usage, statusColor, statusText),
              if (!widget.compact && _isExpanded)
                _buildDetailedBreakdown(context, metrics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(
      BuildContext context, double usage, Color color, String status) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.compact
          ? null
          : () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Context Usage',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          'Tokens are the building blocks of AI language. Your context window determines how much conversation history the AI can remember.',
                      child: Icon(Icons.info_outline,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
                Text(
                  '${(usage * 100).toStringAsFixed(0)}% ($status)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usage,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBreakdown(BuildContext context, ModelMetrics metrics) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                context, 'Current Tokens', metrics.contextTokens.toString()),
            _buildDetailRow(
                context, 'Max Context', metrics.maxContextTokens.toString()),
            _buildDetailRow(context, 'Generation Speed',
                '${metrics.tokensPerSecond.toStringAsFixed(1)} t/s'),
            _buildDetailRow(context, 'Total Session Tokens',
                metrics.totalTokens.toString()),
            const Divider(height: 16),
            Text(
              'What does this mean?',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Higher usage means the AI is processing more data. If it reaches 100%, older parts of the conversation will be automatically summarized or removed to make room for new input.',
              style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
