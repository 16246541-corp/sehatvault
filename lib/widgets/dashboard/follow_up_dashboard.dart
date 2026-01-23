import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/follow_up_item.dart';
import '../design/glass_card.dart';

class FollowUpDashboard extends StatelessWidget {
  final VoidCallback onTap;

  const FollowUpDashboard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<FollowUpItem>>(
      valueListenable: Hive.box<FollowUpItem>('follow_up_items').listenable(),
      builder: (context, box, _) {
        final items = box.values.toList();
        final now = DateTime.now();
        final endOfWeek = now.add(const Duration(days: 7));

        final pendingCount = items.where((i) => !i.isCompleted).length;
        
        final overdueCount = items.where((i) {
          if (i.isCompleted || i.dueDate == null) return false;
          return i.dueDate!.isBefore(now);
        }).length;

        final dueThisWeekCount = items.where((i) {
           if (i.isCompleted || i.dueDate == null) return false;
           return i.dueDate!.isAfter(now) && i.dueDate!.isBefore(endOfWeek);
        }).length;

        return GestureDetector(
          onTap: onTap,
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tasks Overview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios, 
                        size: 16, 
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(context, pendingCount, 'Pending', Colors.blue),
                      _buildSummaryItem(context, overdueCount, 'Overdue', Colors.red),
                      _buildSummaryItem(context, dueThisWeekCount, 'Due Week', Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(BuildContext context, int count, String label, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
