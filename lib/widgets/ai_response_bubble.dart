import 'package:flutter/material.dart';
import '../services/validation/validation_rule.dart';

class AIResponseBubble extends StatelessWidget {
  final String content;
  final bool isModified;
  final String? warning;

  const AIResponseBubble({
    super.key,
    required this.content,
    this.isModified = false,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    // Visual indicator when content is modified
    final Color statusColor = isModified ? Colors.orange : Colors.blue;
    final Color backgroundColor =
        isModified ? Colors.orange.withOpacity(0.05) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isModified || warning != null) ...[
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning ?? "Content modified for safety",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
          ],
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
