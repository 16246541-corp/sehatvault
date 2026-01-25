import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/model_option.dart';
import '../../utils/design_constants.dart';
import '../../utils/theme.dart';
import '../design/glass_card.dart';

class KnowledgeCutoffNotice extends StatefulWidget {
  final ModelOption model;
  final VoidCallback? onDismiss;
  final bool forceShow;

  const KnowledgeCutoffNotice({
    super.key,
    required this.model,
    this.onDismiss,
    this.forceShow = false,
  });

  @override
  State<KnowledgeCutoffNotice> createState() => _KnowledgeCutoffNoticeState();
}

class _KnowledgeCutoffNoticeState extends State<KnowledgeCutoffNotice> {
  bool _isExpanded = false;
  bool _isDismissed = false;

  bool get _isOutdated {
    if (widget.model.knowledgeCutoffDate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(widget.model.knowledgeCutoffDate!);
    return difference.inDays > 365; // Older than 1 year
  }

  @override
  Widget build(BuildContext context) {
    if ((_isDismissed && !widget.forceShow) || !_isOutdated) {
      return const SizedBox.shrink();
    }

    final cutoffDate = widget.model.knowledgeCutoffDate != null
        ? DateFormat.yMMMMd().format(widget.model.knowledgeCutoffDate!)
        : 'Unknown';

    return Semantics(
      container: true,
      label: 'Knowledge Cutoff Notice for ${widget.model.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GlassCard(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.history_toggle_off,
                  color: Colors.orange,
                  size: 28,
                ),
                title: Text(
                  'Knowledge Cutoff: $cutoffDate',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'This model may not be aware of recent medical developments.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      tooltip: _isExpanded ? 'Show less' : 'Show more',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () {
                        setState(() => _isDismissed = true);
                        widget.onDismiss?.call();
                      },
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.info_outline,
                        'Model: ${widget.model.name} (v${widget.model.metadata.version})',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.update,
                        'Last Updated: ${DateFormat.yMMMMd().format(widget.model.metadata.releaseDate)}',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.warning_amber_rounded,
                        'Medical information changes rapidly. Always verify critical findings with a healthcare professional.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Why this matters:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'AI models are trained on data up to a specific point in time. New clinical guidelines, drug approvals, or health alerts released after this date are not included in the model\'s knowledge base.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
