import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/metric_snapshot.dart';
import '../../../services/reference_range_service.dart';
import '../../../widgets/design/glass_card.dart';
import '../../../widgets/compliance/fda_disclaimer_widget.dart';

/// Shared metric card widget that displays health metrics with source attribution
/// Extends GlassCard for consistent glassmorphism design
class MetricCard extends StatelessWidget {
  final MetricSnapshot snapshot;
  final VoidCallback? onTap;
  final bool showReferenceRange;
  final bool isSensitive;

  const MetricCard({
    super.key,
    required this.snapshot,
    this.onTap,
    this.showReferenceRange = true,
    this.isSensitive = false,
  });

  /// Formats the metric name for display (e.g., "ldl_cholesterol" → "LDL Cholesterol")
  String _formatMetricName(String metricName) {
    return metricName
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  /// Gets the reference range for display
  String? _getReferenceRange() {
    if (!showReferenceRange) return null;
    
    final ranges = ReferenceRangeService.lookupReferenceRange(snapshot.metricName);
    if (ranges.isEmpty) return null;
    
    final range = ranges.first;
    final normalRange = range['normalRange'] as Map<String, dynamic>;
    final unit = range['unit'] as String;
    
    return 'Ref: ${normalRange['min']}-${normalRange['max']} $unit';
  }

  /// Gets source type description
  String _getSourceType() {
    // This would typically come from the health record type
    // For now, return a generic lab report label
    return 'From Lab Report';
  }

  /// Formats the document date
  String _formatDocumentDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedName = _formatMetricName(snapshot.metricName);
    final referenceRange = _getReferenceRange();
    final sourceType = _getSourceType();
    final documentDate = _formatDocumentDate(snapshot.measuredAt);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Semantics(
        label: '$formattedName ${snapshot.value.toStringAsFixed(1)} ${snapshot.unit} from $sourceType dated ${snapshot.measuredAt.toIso8601String()}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metric name and value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formattedName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  snapshot.value.toStringAsFixed(1),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: snapshot.isOutsideReference
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Unit and reference range
            Row(
              children: [
                Text(
                  snapshot.unit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (referenceRange != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    referenceRange,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Source attribution
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sourceType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            
            // Document date
            Text(
              documentDate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            
            // Sensitive data indicator
            if (isSensitive) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Protected Health Information',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}