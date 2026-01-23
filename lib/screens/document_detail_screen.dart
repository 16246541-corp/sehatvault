import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../models/health_record.dart';
import '../models/document_extraction.dart';
import '../services/vault_service.dart';
import '../services/local_storage_service.dart';
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
      final result = await _vaultService.getCompleteDocument(widget.healthRecordId);
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
        content: const Text('Are you sure you want to delete this document? This action cannot be undone.'),
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
              background: _record!.filePath != null
                  ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _FullScreenImageViewer(
                              imagePath: _record!.filePath!,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'document_${_record!.id}',
                        child: Image.file(
                          File(_record!.filePath!),
                          fit: BoxFit.cover,
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
              padding: const EdgeInsets.all(DesignConstants.pageHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CategoryBadge(
                        label: _record!.category,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
                          if (_extraction!.structuredData.isNotEmpty) ...[
                            ..._extraction!.structuredData.entries.map((e) {
                              if (e.value is List || e.value is Map) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${e.key}: ',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Expanded(
                                      child: Text(e.value.toString()),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(),
                          ],
                          const Text(
                            'Raw Text',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _extraction!.extractedText,
                            style: theme.textTheme.bodySmall,
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
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
