import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/health_record.dart';
import '../design/glass_card.dart';
import 'category_badge.dart';

class ConversationGridCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback? onTap;

  const ConversationGridCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = record.metadata?['duration'] as int? ?? 0;
    final doctorName =
        record.metadata?['doctorName'] as String? ?? 'Unknown Doctor';

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
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Section (replaces Image)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    // Duration Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(duration),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryBadge(
                      label: 'Conversation',
                      backgroundColor: theme.colorScheme.tertiaryContainer
                          .withValues(alpha: 0.5),
                      textColor: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
