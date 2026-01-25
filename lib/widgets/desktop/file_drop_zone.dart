import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/file_drop_service.dart';
import '../../services/vault_service.dart';
import '../../models/app_settings.dart';
import '../design/glass_card.dart';
import '../design/glass_effect_container.dart';
import '../../utils/theme.dart';

class FileDropZone extends StatefulWidget {
  final Widget child;
  final VaultService vaultService;
  final AppSettings settings;

  const FileDropZone({
    super.key,
    required this.child,
    required this.vaultService,
    required this.settings,
  });

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _isDragging = false;
  final FileDropService _dropService = FileDropService();

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        final files = details.files.map((xf) => File(xf.path)).toList();
        await _dropService.processFiles(
          files,
          vaultService: widget.vaultService,
          settings: widget.settings,
        );
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging) _buildOverlay(),
          _buildQueueIndicator(),
          // Accessibility hint for keyboard users
          _buildAccessibilityHint(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: GlassEffect(
        blurSigma: 15,
        opacity: 0.2,
        tintColor: AppTheme.primaryColor,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.26)
                  : Colors.white.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.upload_file_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Drop Medical Records',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'JPG, PNG, PDF, TXT (Max ${widget.settings.maxFileUploadSizeMB}MB)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueIndicator() {
    return StreamBuilder<List<FileDropItem>>(
      stream: _dropService.statusStream,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        if (queue.isEmpty) return const SizedBox.shrink();

        final processingCount = queue
            .where((i) =>
                i.status != FileProcessingStatus.completed &&
                i.status != FileProcessingStatus.failed)
            .length;

        return Positioned(
          bottom: 24,
          right: 24,
          child: GlassCard(
            width: 280,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      processingCount > 0 ? 'Processing...' : 'Completed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (processingCount > 0)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _dropService.clearQueue(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: queue.length > 5 ? 5 : queue.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item =
                          queue[queue.length - 1 - index]; // Show newest first
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(item.status),
                                size: 14,
                                color: _getStatusColor(item.status),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (item.status == FileProcessingStatus.processing ||
                              item.status == FileProcessingStatus.validating)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 22),
                              child: LinearProgressIndicator(
                                value: item.progress,
                                minHeight: 2,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          if (item.status == FileProcessingStatus.failed)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, left: 22),
                              child: Text(
                                item.error ?? 'Unknown error',
                                style: const TextStyle(
                                    color: AppTheme.healthRed, fontSize: 10),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (queue.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${queue.length - 5} more files',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessibilityHint() {
    return Positioned(
      top: 16,
      right: 16,
      child: Focus(
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            if (!hasFocus) return const SizedBox.shrink();

            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard, size: 16),
                  const SizedBox(width: 8),
                  const Text('Press Enter to upload files',
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: pickFiles,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Choose Files'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getStatusIcon(FileProcessingStatus status) {
    switch (status) {
      case FileProcessingStatus.pending:
        return Icons.hourglass_empty;
      case FileProcessingStatus.validating:
        return Icons.security;
      case FileProcessingStatus.processing:
        return Icons.sync;
      case FileProcessingStatus.completed:
        return Icons.check_circle;
      case FileProcessingStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(FileProcessingStatus status) {
    switch (status) {
      case FileProcessingStatus.pending:
        return Colors.grey;
      case FileProcessingStatus.validating:
        return AppTheme.primaryColor;
      case FileProcessingStatus.processing:
        return AppTheme.accentTeal;
      case FileProcessingStatus.completed:
        return AppTheme.healthGreen;
      case FileProcessingStatus.failed:
        return AppTheme.healthRed;
    }
  }

  Future<void> pickFiles() async {
    const typeGroup = XTypeGroup(
      label: 'Health Records',
      extensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt'],
    );
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isNotEmpty) {
      final fileList = files.map((xf) => File(xf.path)).toList();
      await _dropService.processFiles(
        fileList,
        vaultService: widget.vaultService,
        settings: widget.settings,
      );
    }
  }
}
