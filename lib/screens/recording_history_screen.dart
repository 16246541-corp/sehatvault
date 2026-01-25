import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';
import '../widgets/design/liquid_glass_background.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';
import '../main_common.dart' show storageService;

class RecordingHistoryScreen extends StatelessWidget {
  const RecordingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = storageService.getAllRecordingAuditEntries();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final theme = Theme.of(context);
    final exportService = ExportService();

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Recording History'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: () => exportService.exportRecordingComplianceReport(
                context,
              ),
            ),
          ],
        ),
        body: entries.isEmpty
            ? Center(
                child: Text(
                  'No recording history found',
                  style: theme.textTheme.bodyLarge,
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (entry.consentConfirmed)
                                Tooltip(
                                  message: 'Consent Confirmed',
                                  child: const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(theme, 'Doctor', entry.doctorName),
                          _buildDetailRow(theme, 'Duration',
                              _formatDuration(entry.duration)),
                          _buildDetailRow(theme, 'Size',
                              _formatFileSize(entry.fileSizeBytes)),
                          _buildDetailRow(theme, 'Device ID', entry.deviceId,
                              isSmall: true),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value,
      {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: isSmall ? 12 : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmall ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds";
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
