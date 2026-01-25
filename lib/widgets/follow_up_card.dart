import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/follow_up_item.dart';
import '../services/local_storage_service.dart';
import '../services/safety_filter_service.dart';
import '../screens/conversation_transcript_screen.dart';

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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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
                            // Priority Badge (only if high)
                            if (isHighPriority)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.priority_high,
                                        size: 12, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      'High Priority',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Timeframe/Frequency Badge
                            if (item.timeframeRaw != null ||
                                item.frequency != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.frequency ?? item.timeframeRaw!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Date or Frequency Display
                        if (item.dueDate != null || item.frequency != null)
                          Row(
                            children: [
                              Icon(
                                item.frequency != null
                                    ? Icons.repeat
                                    : Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.frequency != null
                                    ? item.frequency!
                                    : DateFormat('MMM d, y')
                                        .format(item.dueDate!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),

                        // Source Conversation Link
                        Builder(
                          builder: (context) {
                            final conversation = LocalStorageService()
                                .getDoctorConversation(
                                    item.sourceConversationId);
                            if (conversation == null) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ConversationTranscriptScreen(
                                        conversation: conversation,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.description_outlined,
                                        size: 14, color: theme.primaryColor),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Extracted from ${conversation.title}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.primaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onAddToCalendar != null)
                    TextButton.icon(
                      onPressed: onAddToCalendar,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Add to Calendar'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  if (onMarkComplete != null)
                    TextButton.icon(
                      onPressed: onMarkComplete,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Complete'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Edit',
                    ),
                ],
              ),
            ],
          ),
        ),
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
