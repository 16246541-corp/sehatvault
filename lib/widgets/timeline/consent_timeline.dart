import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/consent_entry.dart';
import '../design/glass_card.dart';
import '../../utils/theme.dart';

class ConsentTimeline extends StatelessWidget {
  final List<ConsentEntry> entries;
  final Function(ConsentEntry) onRevoke;

  const ConsentTimeline({
    super.key,
    required this.entries,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No consent history found.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Line
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: entry.granted
                            ? (entry.revocationDate == null
                                ? AppTheme.healthGreen
                                : AppTheme.healthRed)
                            : AppTheme.healthRed,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.white24,
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
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
                                DateFormat.yMMMd()
                                    .add_jm()
                                    .format(entry.timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: entry.granted &&
                                          entry.revocationDate == null
                                      ? AppTheme.healthGreen.withOpacity(0.2)
                                      : AppTheme.healthRed.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: entry.granted &&
                                            entry.revocationDate == null
                                        ? AppTheme.healthGreen.withOpacity(0.5)
                                        : AppTheme.healthRed.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  entry.revocationDate != null
                                      ? 'REVOKED'
                                      : (entry.granted ? 'GRANTED' : 'DENIED'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: entry.granted &&
                                                entry.revocationDate == null
                                            ? AppTheme.healthGreen
                                            : AppTheme.healthRed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getScopeTitle(entry.scope),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Template: ${entry.templateId} v${entry.version}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white54,
                                    ),
                          ),
                          if (entry.revocationDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Revoked on ${DateFormat.yMMMd().add_jm().format(entry.revocationDate!)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.healthRed,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                            if (entry.revocationReason != null)
                              Text(
                                'Reason: ${entry.revocationReason}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                          ],
                          if (entry.granted &&
                              entry.revocationDate == null) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => onRevoke(entry),
                                icon: const Icon(Icons.block,
                                    size: 16, color: AppTheme.healthRed),
                                label: const Text(
                                  'Revoke Consent',
                                  style: TextStyle(color: AppTheme.healthRed),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getScopeTitle(String scope) {
    switch (scope) {
      case 'recording':
        return 'Recording Consent';
      case 'camera':
        return 'Camera Usage';
      case 'model_usage':
        return 'AI Model Usage';
      default:
        return scope.toUpperCase();
    }
  }
}
