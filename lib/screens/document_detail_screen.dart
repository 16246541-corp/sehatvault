import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../models/health_record.dart';
import '../models/document_extraction.dart';
import '../services/vault_service.dart';
import '../services/local_storage_service.dart';
import '../services/reference_range_service.dart';
import '../widgets/cards/category_badge.dart';
import '../widgets/design/glass_card.dart';
import '../utils/design_constants.dart';

/// Screen to view document details and extracted data
class DocumentDetailScreen extends StatefulWidget {
  final String healthRecordId;

  const DocumentDetailScreen({
    super.key,
    required this.healthRecordId,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
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
          Navigator.pop(context, true); // Return true to indicate deletion
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

  File? _getImageFile() {
    // Try to find a valid image file to display

    // 1. Check extraction image path (often the source for OCR)
    if (_extraction?.originalImagePath != null) {
      final file = File(_extraction!.originalImagePath);
      if (file.existsSync() && _isImageFile(file.path)) {
        return file;
      }
    }

    // 2. Check record file path
    if (_record?.filePath != null) {
      final file = File(_record!.filePath!);
      if (file.existsSync() && _isImageFile(file.path)) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _record == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Error loading document: ${_error ?? "Unknown error"}'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _getImageFile() != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _FullScreenImageViewer(
                              imagePath: _getImageFile()!.path,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'document_${_record!.id}',
                        child: Image.file(
                          _getImageFile()!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image_outlined,
                                        size: 48,
                                        color: theme.colorScheme.error),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Could not load image',
                                      style: TextStyle(
                                          color: theme.colorScheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.description_outlined, size: 64),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteDocument,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CategoryBadge(
                        label: _record!.category,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.1),
                        textColor: theme.colorScheme.primary,
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMMM d, y').format(_record!.createdAt),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _record!.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_record!.notes != null && _record!.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Notes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _record!.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (_extraction != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Extracted Data',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Confidence Score
                          Row(
                            children: [
                              const Text('Confidence Score: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                  '${(_extraction!.confidenceScore * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                          const Divider(),

                          // Structured Data Sections
                          _buildLabValues(_extraction!.structuredData, theme),
                          _buildSection(
                              'Medications',
                              _extraction!.structuredData['medications'] ??
                                  _extraction!.structuredData['Medications'],
                              theme),
                          _buildSection(
                              'Vitals',
                              _extraction!.structuredData['vitals'] ??
                                  _extraction!.structuredData['Vitals'],
                              theme),
                          _buildSection(
                              'Dates',
                              _extraction!.structuredData['dates'] ??
                                  _extraction!.structuredData['Dates'],
                              theme),

                          const Divider(),
                          const Text(
                            'Raw Text',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: Text(
                                _extraction!.extractedText,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabValues(Map<String, dynamic> data, ThemeData theme) {
    // Try to find lab values in common keys
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

          // Evaluate using ReferenceRangeService
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
            // Handle structured item like medication
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
