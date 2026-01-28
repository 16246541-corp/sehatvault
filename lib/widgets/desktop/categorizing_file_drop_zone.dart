import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../services/file_drop_service.dart';
import '../../services/vault_service.dart';
import '../../services/ocr_service.dart';
import '../../services/document_classification_service.dart';
import '../../models/app_settings.dart';
import '../../models/document_extraction.dart';
import '../../models/health_record.dart';
import '../../screens/document_categorization_screen.dart';
import '../design/glass_card.dart';
import '../design/glass_effect_container.dart';
import '../../utils/theme.dart';
import 'package:path/path.dart' as p;

/// A file drop zone that shows categorization screen before saving
class CategorizingFileDropZone extends StatefulWidget {
  final Widget child;
  final VaultService vaultService;
  final AppSettings settings;
  final VoidCallback? onFilesProcessed;

  const CategorizingFileDropZone({
    super.key,
    required this.child,
    required this.vaultService,
    required this.settings,
    this.onFilesProcessed,
  });

  @override
  State<CategorizingFileDropZone> createState() => _CategorizingFileDropZoneState();
}

class _CategorizingFileDropZoneState extends State<CategorizingFileDropZone> {
  bool _isDragging = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) {
        if (!_isProcessing) {
          setState(() => _isDragging = true);
        }
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) async {
        if (_isProcessing) return;
        
        setState(() {
          _isDragging = false;
          _isProcessing = true;
        });

        final files = details.files.map((xf) => File(xf.path)).toList();
        await _processFilesWithCategorization(files);

        setState(() => _isProcessing = false);
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging) _buildOverlay(),
          if (_isProcessing) _buildProcessingOverlay(),
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
                  'PDF, TXT, JPG, PNG (Max ${widget.settings.maxFileUploadSizeMB}MB)',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Processing document...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processFilesWithCategorization(List<File> files) async {
    if (files.isEmpty) return;

    try {
      // Process files one by one with categorization
      for (final file in files) {
        await _processSingleFile(file);
      }

      // Call the callback after all files are processed
      if (widget.onFilesProcessed != null) {
        widget.onFilesProcessed!();
      }
    } catch (e) {
      debugPrint('Error processing files with categorization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processSingleFile(File file) async {
    // Validate file first
    await _validateFile(file);

    // Extract text and get categorization suggestion
    final extraction = await OCRService.processDocument(file);
    final suggestion = DocumentClassificationService.suggestCategory(extraction.extractedText);

    // Show categorization screen
    if (mounted) {
      final HealthCategory? selectedCategory = await Navigator.push<HealthCategory>(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentCategorizationScreen(
            extraction: extraction,
            suggestedCategory: suggestion.category,
            confidence: suggestion.confidence,
            reasoning: suggestion.reasoning,
          ),
        ),
      );

      if (selectedCategory != null) {
        // User selected a category - save to vault
        await widget.vaultService.saveProcessedDocument(
          extraction: extraction,
          title: _getFileNameWithoutExtension(file.path),
          category: selectedCategory.displayName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${selectedCategory.displayName} added to vault'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // User cancelled - clean up
        debugPrint('User cancelled categorization for ${file.path}');
      }
    }
  }

  Future<void> _validateFile(File file) async {
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final ext = p.extension(fileName).toLowerCase();

    // Check file size
    final maxSizeInBytes = widget.settings.maxFileUploadSizeMB * 1024 * 1024;
    if (fileSize > maxSizeInBytes) {
      throw Exception(
          'File too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Max allowed: ${widget.settings.maxFileUploadSizeMB}MB');
    }

    // Check extension
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf', '.txt'];
    if (!allowedExtensions.contains(ext)) {
      throw Exception(
          'Unsupported file type: $ext. Allowed: ${allowedExtensions.join(", ")}');
    }

    // Security check
    const maliciousExtensions = ['.exe', '.msi', '.sh', '.bat', '.js', '.vbs'];
    if (maliciousExtensions.contains(ext)) {
      throw Exception(
          'Security violation: Executable files are not allowed for health records');
    }
  }

  String _getFileNameWithoutExtension(String filePath) {
    return p.basenameWithoutExtension(filePath);
  }
}
