import 'package:flutter/material.dart';

import '../../models/citation.dart';
import '../../models/health_pattern_insight.dart';
import '../../widgets/design/glass_card.dart';

class HealthInsightCard extends StatelessWidget {
  final HealthPatternInsight insight;

  const HealthInsightCard({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final citations = insight.citations;
    final hasCitations = citations.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.summary,
            style: theme.textTheme.bodyMedium,
          ),
          if (insight.timeframeIso8601 != null) ...[
            const SizedBox(height: 12),
            Text(
              'Timeframe: ${insight.timeframeIso8601}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (hasCitations) ...[
            const SizedBox(height: 12),
            _CitationsPanel(citations: citations),
          ],
        ],
      ),
    );
  }
}

class _CitationsPanel extends StatelessWidget {
  final List<Citation> citations;

  const _CitationsPanel({required this.citations});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Citation>.from(citations)
      ..sort((a, b) {
        final ad = a.sourceDate;
        final bd = b.sourceDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      title: Text(
        'Sources (${sorted.length})',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: sorted.map((c) => _CitationRow(citation: c)).toList(),
    );
  }
}

class _CitationRow extends StatelessWidget {
  final Citation citation;

  const _CitationRow({required this.citation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = (citation.confidenceScore * 100).round();
    final dateText = citation.sourceDate != null
        ? _formatDate(citation.sourceDate!)
        : 'Unknown date';
    final related = citation.relatedField?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.link,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  citation.sourceTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (related != null && related.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    related,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Confidence: $confidence%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
