import 'package:flutter/material.dart';
import '../../utils/theme.dart';

/// A checklist widget showing key privacy features of the app
/// Displays security and privacy guarantees to build user trust
class ConsentChecklistWidget extends StatelessWidget {
  final bool compact;

  const ConsentChecklistWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _ChecklistItem(
        icon: Icons.lock_rounded,
        title: 'AES-256 Encryption',
        description: 'Military-grade encryption protects all your data',
      ),
      const _ChecklistItem(
        icon: Icons.cloud_off_rounded,
        title: 'No Cloud Storage',
        description: 'Your data stays on your device only',
      ),
      const _ChecklistItem(
        icon: Icons.phonelink_off_rounded,
        title: 'No Data Leaves Device',
        description: 'AI processing happens locally',
      ),
      const _ChecklistItem(
        icon: Icons.person_rounded,
        title: 'You Own Your Data',
        description: 'Export or delete anytime',
      ),
    ];

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: items.map((item) => _buildCompactItem(context, item)).toList(),
      );
    }

    return Column(
      children: items.map((item) => _buildExpandedItem(context, item)).toList(),
    );
  }

  Widget _buildCompactItem(BuildContext context, _ChecklistItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 16,
            color: AppTheme.accentTeal,
          ),
          const SizedBox(width: 6),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedItem(BuildContext context, _ChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: AppTheme.accentTeal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppTheme.healthGreen,
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  final IconData icon;
  final String title;
  final String description;

  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
