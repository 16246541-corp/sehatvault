import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../models/document_extraction.dart';
import '../../../models/health_record.dart';
import '../../../widgets/cards/category_badge.dart';
import '../../../widgets/design/glass_card.dart';

class DesktopDocumentGridCard extends StatelessWidget {
  final HealthRecord record;
  final DocumentExtraction? extraction;
  final VoidCallback? onTap;

  const DesktopDocumentGridCard({
    super.key,
    required this.record,
    required this.extraction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewFile = _resolvePreviewFile(record, extraction);
    final hasFile = previewFile != null;
    final isPdf = hasFile && _isPdfFile(previewFile.path);
    final isImage = hasFile && _isImageFile(previewFile.path);
    final hasPreview = isPdf || isImage;

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
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPreview && previewFile != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: isPdf
                          ? DesktopPdfThumbnail(file: previewFile)
                          : Image.file(
                              previewFile,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _previewFallback(theme);
                              },
                            ),
                    )
                  else if (_hasSnippet(extraction))
                    _snippetPreview(theme, extraction!.extractedText)
                  else
                    _previewFallback(theme),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('MMM d').format(record.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryBadge(
                    label: record.category,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    textColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isPdfFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.pdf');
}

bool _isImageFile(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png');
}

File? _resolvePreviewFile(HealthRecord record, DocumentExtraction? extraction) {
  final fromRecord = record.filePath;
  if (fromRecord != null) {
    final f = File(fromRecord);
    if (f.existsSync()) return f;
  }

  final fromExtraction = extraction?.originalImagePath;
  if (fromExtraction != null) {
    final f = File(fromExtraction);
    if (f.existsSync()) return f;
  }

  return null;
}

bool _hasSnippet(DocumentExtraction? extraction) {
  final text = extraction?.extractedText;
  if (text == null) return false;
  return text.trim().isNotEmpty;
}

Widget _previewFallback(ThemeData theme) {
  return Container(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icon(
      Icons.description_outlined,
      size: 40,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
}

Widget _snippetPreview(ThemeData theme, String extractedText) {
  final snippet = _buildSnippet(extractedText);
  return Container(
    color: theme.colorScheme.surfaceContainerHighest,
    padding: const EdgeInsets.all(12),
    alignment: Alignment.topLeft,
    child: Text(
      snippet,
      maxLines: 10,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        height: 1.25,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

String _buildSnippet(String extractedText) {
  final normalized = extractedText
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .take(8)
      .join('\n');

  if (normalized.isEmpty) return '';
  if (normalized.length <= 320) return normalized;
  return normalized.substring(0, 320);
}

class DesktopPdfThumbnail extends StatefulWidget {
  final File file;

  const DesktopPdfThumbnail({super.key, required this.file});

  @override
  State<DesktopPdfThumbnail> createState() => _DesktopPdfThumbnailState();
}

class _DesktopPdfThumbnailState extends State<DesktopPdfThumbnail> {
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _imageBytes;
  Future<void>? _inflight;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.file.path];
    if (cached != null) {
      _imageBytes = cached;
    } else {
      _inflight = _renderPdf();
    }
  }

  @override
  void didUpdateWidget(covariant DesktopPdfThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path == widget.file.path) return;
    final cached = _cache[widget.file.path];
    if (cached != null) {
      setState(() => _imageBytes = cached);
      return;
    }
    setState(() => _imageBytes = null);
    _inflight = _renderPdf();
  }

  Future<void> _renderPdf() async {
    try {
      final bytes = await widget.file.readAsBytes();
      await for (final page in Printing.raster(bytes, pages: [0], dpi: 150)) {
        final image = await page.toPng();
        if (!mounted) return;
        _cache[widget.file.path] = image;
        setState(() {
          _imageBytes = image;
        });
        break;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_imageBytes == null) {
      if (_inflight == null) {
        return _previewFallback(theme);
      }
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
  }
}
