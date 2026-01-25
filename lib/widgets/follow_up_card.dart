import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/follow_up_item.dart';
import '../services/local_storage_service.dart';
import '../services/safety_filter_service.dart';
import '../screens/conversation_transcript_screen.dart';
import 'design/glass_card.dart';

class FollowUpCard extends StatelessWidget {
  final FollowUpItem item;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCalendar;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onEdit;

  const FollowUpCard({
    super.key,
    required this.item,
    this.onTap,
    this.onAddToCalendar,
    this.onMarkComplete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighPriority = item.priority == FollowUpPriority.high;
    final safetyFilter = SafetyFilterService();

    // Construct title: Verb + Object
    final rawTitle = [
      item.verb.isNotEmpty
          ? '${item.verb[0].toUpperCase()}${item.verb.substring(1)}'
          : item.verb,
      item.object
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    final title = safetyFilter.sanitize(rawTitle);

    return FocusableActionDetector(
      onShowFocusHighlight: (value) {},
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) => onTap?.call(),
        ),
      },
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.category)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.category.icon,
                    color: _getCategoryColor(item.category),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (item.description.isNotEmpty &&
                          item.description != rawTitle) ...[
                        const SizedBox(height: 4),
                        Text(
                          safetyFilter.sanitize(item.description),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Badges Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (isHighPriority)
                            _buildBadge(
                              context,
                              'High Priority',
                              Icons.priority_high,
                              Colors.red,
                            ),
                          if (item.dueDate != null)
                            _buildBadge(
                              context,
                              DateFormat.yMMMd().format(item.dueDate!),
                              Icons.calendar_today,
                              theme.colorScheme.primary,
                            ),
                          if (item.isCompleted)
                            _buildBadge(
                              context,
                              'Completed',
                              Icons.check_circle,
                              Colors.green,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  children: [
                    if (onMarkComplete != null)
                      IconButton(
                        icon: Icon(
                          item.isCompleted
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: item.isCompleted
                              ? Colors.green
                              : theme.disabledColor,
                        ),
                        onPressed: onMarkComplete,
                        tooltip: 'Mark Complete',
                      ),
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
      BuildContext context, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(FollowUpCategory category) {
    switch (category) {
      case FollowUpCategory.medication:
        return Colors.blue;
      case FollowUpCategory.appointment:
        return Colors.purple;
      case FollowUpCategory.test:
        return Colors.orange;
      case FollowUpCategory.lifestyle:
        return Colors.green;
      case FollowUpCategory.monitoring:
        return Colors.teal;
      case FollowUpCategory.warning:
        return Colors.red;
      case FollowUpCategory.decision:
        return Colors.indigo;
    }
  }
}
