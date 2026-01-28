import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:printing/printing.dart';
import '../../../models/health_record.dart';
import '../../../models/document_extraction.dart';
import '../../../services/vault_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/reference_range_service.dart';
import '../../../widgets/cards/category_badge.dart';
import '../../../widgets/design/glass_card.dart';
import '../../../utils/design_constants.dart';
import '../../../widgets/design/liquid_glass_background.dart';

class DesktopDocumentDetailScreen extends StatefulWidget {
  final String healthRecordId;

  const DesktopDocumentDetailScreen({
    super.key,
    required this.healthRecordId,
  });

  @override
  State<DesktopDocumentDetailScreen> createState() => _DesktopDocumentDetailScreenState();
}

class _DesktopDocumentDetailScreenState extends State<DesktopDocumentDetailScreen> {
  final VaultService _vaultService = VaultService(LocalStorageService());
  HealthRecord? _record;
  DocumentExtraction? _extraction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocumentDetails();
  }

  Future<void> _loadDocumentDetails() async {
    try {
      final result =
          await _vaultService.getCompleteDocument(widget.healthRecordId);
      if (mounted) {
        setState(() {
          _record = result.record;
          _extraction = result.extraction;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
            'Are you sure you want to delete this document? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _vaultService.deleteDocument(widget.healthRecordId);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting document: $e')),
          );
        }
      }
    }
  }

  File? _getDocumentFile() {
    if (_extraction?.originalImagePath != null) {
      final file = File(_extraction!.originalImagePath);
      if (file.existsSync()) {
        return file;
      }
    }
    if (_record?.filePath != null) {
      final file = File(_record!.filePath!);
      if (file.existsSync()) {
        return file;
      }
    }
    return null;
  }

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic');
  }

  bool _isPdfFile(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const LiquidGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null || _record == null) {
      return LiquidGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(),
          ),
          body: Center(
            child: Text('Error loading document: ${_error ?? "Unknown error"}'),
          ),
        ),
      );
    }

    final docFile = _getDocumentFile();
    final isPdf = docFile != null && _isPdfFile(docFile.path);
    final isImage = docFile != null && _isImageFile(docFile.path);
    final hasPreview = isPdf || isImage;

    return LiquidGlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteDocument,
              tooltip: 'Delete Document',
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.pageHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Document Image Snippet (Upper Half)
                  if (hasPreview)
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: GestureDetector(
                          onTap: isImage
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          _FullScreenImageViewer(
                                        imagePath: docFile!.path,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Hero(
                            tag: 'document_${_record!.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: isPdf
                                    ? _PdfThumbnail(file: docFile!)
                                    : Image.file(
                                        docFile!,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Expanded(
                      flex: 2,
                      child: Center(
                        child: Icon(Icons.description_outlined, size: 80),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Metadata
                  Row(
                    children: [
                      CategoryBadge(
                        label: _record!.category,
                        backgroundColor:
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                        textColor: theme.colorScheme.primary,
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMMM d, y').format(_record!.createdAt),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _record!.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Extracted Data Header
                  Row(
                    children: [
                      Text(
                        'Extracted Data',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_extraction != null)
                        Text(
                          'Confidence: ${(_extraction!.confidenceScore * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Extracted Text (Lower Half - Scrollable)
                  Expanded(
                    flex: 6,
                    child: GlassCard(
                      child: _extraction != null
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Structured Data
                                  _buildLabValues(
                                      _extraction!.structuredData, theme),
                                  _buildSection(
                                      'Medications',
                                      _extraction!
                                              .structuredData['medications'] ??
                                          _extraction!
                                              .structuredData['Medications'],
                                      theme),
                                  _buildSection(
                                      'Vitals',
                                      _extraction!.structuredData['vitals'] ??
                                          _extraction!.structuredData['Vitals'],
                                      theme),

                                  const Divider(),
                                  const SizedBox(height: 16),

                                  // Raw Text
                                  const Text(
                                    'Raw Text',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SelectableText(
                                    _extraction!.extractedText,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Text(
                                'No extracted text available.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabValues(Map<String, dynamic> data, ThemeData theme) {
    final labValues = data['labValues'] ?? data['Lab Values'] ?? data['labs'];
    if (labValues == null || (labValues is! List && labValues is! Map)) {
      return const SizedBox.shrink();
    }

    final List<dynamic> valuesList =
        labValues is Map ? labValues.values.toList() : labValues;

    if (valuesList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lab Values',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...valuesList.map((item) {
          if (item is! Map) return Text(item.toString());

          final name = item['name'] ?? item['test'] ?? 'Unknown Test';
          final value = item['value']?.toString() ?? '';
          final unit = item['unit']?.toString() ?? '';

          final double? numValue =
              double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));

          Map<String, dynamic>? evaluation;
          if (numValue != null) {
            evaluation = ReferenceRangeService.evaluateLabValue(
              testName: name,
              value: numValue,
              unit: unit,
            );
          }

          final status = evaluation?['status'] ?? 'unknown';
          final isNormal = status == 'normal';
          final isHigh = status == 'high';
          final isLow = status == 'low';

          Color statusColor = theme.colorScheme.onSurface;
          IconData? statusIcon;
          String statusText = '';

          if (isNormal) {
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_outline;
            statusText = 'Normal';
          } else if (isHigh) {
            statusColor = Colors.orange;
            statusIcon = Icons.warning_amber_rounded;
            final range = evaluation?['normalRange'];
            statusText =
                'High${range != null ? ' - reference <${range['max']}' : ''}';
          } else if (isLow) {
            statusColor = Colors.orange;
            statusIcon = Icons.warning_amber_rounded;
            final range = evaluation?['normalRange'];
            statusText =
                'Low${range != null ? ' - reference >${range['min']}' : ''}';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                if (statusIcon != null) ...[
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$name: $value $unit',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (statusText.isNotEmpty)
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: statusColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSection(String title, dynamic data, ThemeData theme) {
    if (data == null) return const SizedBox.shrink();

    List<dynamic> items = [];
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data.entries.map((e) => '${e.key}: ${e.value}').toList();
    } else {
      items = [data.toString()];
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          String text = '';
          if (item is Map) {
            final name = item['name'] ?? item['medication'] ?? '';
            final dosage = item['dosage'] ?? item['dose'] ?? '';
            text = '$name $dosage'.trim();
            if (text.isEmpty) text = item.toString();
          } else {
            text = item.toString();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(text),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: FileImage(File(imagePath)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }
}

class _PdfThumbnail extends StatefulWidget {
  final File file;
  const _PdfThumbnail({required this.file});

  @override
  State<_PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<_PdfThumbnail> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _renderPdf();
  }

  Future<void> _renderPdf() async {
    try {
      final bytes = await widget.file.readAsBytes();
      await for (final page in Printing.raster(bytes, pages: [0], dpi: 150)) {
        final image = await page.toPng();
        if (mounted) {
          setState(() {
            _imageBytes = image;
          });
        }
        break;
      }
    } catch (e) {
      debugPrint('Error rendering PDF thumbnail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Image.memory(_imageBytes!, fit: BoxFit.contain);
  }
}
