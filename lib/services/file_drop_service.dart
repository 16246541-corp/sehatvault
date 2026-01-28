import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add this import
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'vault_service.dart';
import 'image_quality_service.dart';
import '../models/app_settings.dart';
import 'local_storage_service.dart';
import 'ocr_service.dart';
import '../models/document_extraction.dart';
import '../models/health_record.dart';
import '../services/document_classification_service.dart';
import '../screens/document_categorization_screen.dart';

enum FileProcessingStatus {
  pending,
  validating,
  processing,
  completed,
  failed,
}

class FileDropItem {
  final String id;
  final File file;
  final String fileName;
  final int fileSize;
  FileProcessingStatus status;
  double progress;
  String? error;

  FileDropItem({
    required this.id,
    required this.file,
    required this.fileName,
    required this.fileSize,
    this.status = FileProcessingStatus.pending,
    this.progress = 0.0,
    this.error,
  });
}

class FileDropService {
  static final FileDropService _instance = FileDropService._internal();
  factory FileDropService() => _instance;
  FileDropService._internal();

  final _processingQueue = <FileDropItem>[];
  final _statusController = StreamController<List<FileDropItem>>.broadcast();

  Stream<List<FileDropItem>> get statusStream => _statusController.stream;
  List<FileDropItem> get currentQueue => List.unmodifiable(_processingQueue);

  // Allowed extensions for medical documents
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.pdf',
    '.txt'
  ];

  Future<void> processFiles(List<File> files,
      {required VaultService vaultService,
      required AppSettings settings}) async {
    final List<Future<void>> processingTasks = [];

    for (final file in files) {
      // Check if it's a directory (for export destination handling)
      if (FileSystemEntity.isDirectorySync(file.path)) {
        settings.lastExportDirectory = file.path;
        await LocalStorageService().saveAppSettings(settings);
        continue;
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString() + file.path;
      final item = FileDropItem(
        id: id,
        file: file,
        fileName: p.basename(file.path),
        fileSize: await file.length(),
      );
      _processingQueue.add(item);
      _statusController.add(List.from(_processingQueue));

      // Process in background
      processingTasks.add(_processItem(item, vaultService, settings));
    }

    // Wait for all files to be processed
    await Future.wait(processingTasks);
  }

  Future<void> _processItem(FileDropItem item, VaultService vaultService,
      AppSettings settings) async {
    try {
      item.status = FileProcessingStatus.validating;
      item.progress = 0.1;
      _statusController.add(List.from(_processingQueue));

      // 1. Security & Validation
      await _validateFile(item, settings);

      item.status = FileProcessingStatus.processing;
      item.progress = 0.3;
      _statusController.add(List.from(_processingQueue));

      // 2. Image Quality Check (following document scanning patterns)
      if (_isImage(item.fileName)) {
        final qualityResult = await ImageQualityService.analyzeImage(item.file);
        if (qualityResult.hasIssues) {
          debugPrint(
              'Quality issues for ${item.fileName}: ${qualityResult.warnings.join(", ")}');
          // We still process it but could notify user
        }
      }

      // 3. Extract text and get categorization suggestion
      final extraction = await OCRService.processDocument(item.file);
      final suggestion = DocumentClassificationService.suggestCategory(
          extraction.extractedText);

      // 4. Show categorization screen - USER MUST CONFIRM CATEGORY
      // This is a compliance requirement - no auto-categorization allowed
      debugPrint(
          'File dropped - showing categorization screen for ${item.fileName}: ${suggestion.category?.displayName} (${suggestion.confidence * 100}%)');

      // Note: We cannot show UI from background service, so we return early
      // The UI layer should handle categorization and then call saveProcessedDocument
      item.status = FileProcessingStatus.completed;
      item.progress = 1.0;

      // Log that categorization is required
      debugPrint(
          'CATEGORIZATION REQUIRED: User must manually categorize ${item.fileName} before saving');
    } catch (e) {
      item.status = FileProcessingStatus.failed;
      item.error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error processing dropped file: $e');
    } finally {
      _statusController.add(List.from(_processingQueue));
    }
  }

  Future<void> _validateFile(FileDropItem item, AppSettings settings) async {
    // Check file size using configurable threshold
    final maxSizeInBytes = settings.maxFileUploadSizeMB * 1024 * 1024;
    if (item.fileSize > maxSizeInBytes) {
      throw Exception(
          'File too large (${(item.fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Max allowed: ${settings.maxFileUploadSizeMB}MB');
    }

    // Check extension
    final ext = p.extension(item.fileName).toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw Exception(
          'Unsupported file type: $ext. Allowed: ${allowedExtensions.join(", ")}');
    }

    // Basic Security Check
    final maliciousExtensions = ['.exe', '.msi', '.sh', '.bat', '.js', '.vbs'];
    if (maliciousExtensions.contains(ext)) {
      throw Exception(
          'Security violation: Executable files are not allowed for health records');
    }
  }

  Future<String> extractTextForOneTimeAnalysis(
    File file, {
    required AppSettings settings,
  }) async {
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final ext = p.extension(fileName).toLowerCase();

    final maxSizeInBytes = settings.maxFileUploadSizeMB * 1024 * 1024;
    if (fileSize > maxSizeInBytes) {
      throw Exception(
          'File too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Max allowed: ${settings.maxFileUploadSizeMB}MB');
    }

    if (!allowedExtensions.contains(ext)) {
      throw Exception(
          'Unsupported file type: $ext. Allowed: ${allowedExtensions.join(", ")}');
    }

    final maliciousExtensions = ['.exe', '.msi', '.sh', '.bat', '.js', '.vbs'];
    if (maliciousExtensions.contains(ext)) {
      throw Exception(
          'Security violation: Executable files are not allowed for health records');
    }

    if (ext == '.txt') {
      return file.readAsString();
    }

    if (ext == '.pdf') {
      final bytes = await file.readAsBytes();
      return _extractTextFromPdfBytes(bytes);
    }

    if (_isImage(fileName)) {
      return OCRService.extractTextFromImage(file);
    }

    throw Exception('Unsupported file type: $ext');
  }

  /// Process a single file with categorization screen
  Future<void> processFileWithCategorization(
    File file, {
    required BuildContext context,
    required VaultService vaultService,
    required AppSettings settings,
  }) async {
    debugPrint('=== FILE DROP CATEGORIZATION STARTED ===');
    debugPrint('File: ${file.path}');
    try {
      // Validate file
      await _validateFileForCategorization(file, settings);

      // Extract text and get categorization suggestion
      final extraction = await OCRService.processDocument(file);
      final suggestion = DocumentClassificationService.suggestCategory(
          extraction.extractedText);

      debugPrint('=== CATEGORIZATION SUGGESTION ===');
      debugPrint('Suggested category: ${suggestion.category?.displayName}');
      debugPrint('Confidence: ${suggestion.confidence}');
      debugPrint('Reasoning: ${suggestion.reasoning}');

      // Show categorization screen
      if (context.mounted) {
        debugPrint('=== SHOWING CATEGORIZATION SCREEN ===');
        final HealthCategory? selectedCategory =
            await Navigator.push<HealthCategory>(
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

        debugPrint('=== CATEGORIZATION SCREEN RETURNED ===');
        debugPrint('Selected category: $selectedCategory');

        if (selectedCategory != null && context.mounted) {
          debugPrint('=== USER CONFIRMED CATEGORY ===');
          debugPrint('Saving with category: ${selectedCategory.displayName}');
          // User selected a category - save to vault
          await vaultService.saveProcessedDocument(
            extraction: extraction,
            title: _getFileNameWithoutExtension(file.path),
            category: selectedCategory.displayName,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('✅ ${selectedCategory.displayName} added to vault'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          debugPrint('=== USER CANCELLED CATEGORIZATION ===');
          // User cancelled - clean up
          debugPrint('User cancelled categorization for ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('=== CATEGORIZATION ERROR ===');
      debugPrint('Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _validateFileForCategorization(
      File file, AppSettings settings) async {
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final ext = p.extension(fileName).toLowerCase();

    // Check file size
    final maxSizeInBytes = settings.maxFileUploadSizeMB * 1024 * 1024;
    if (fileSize > maxSizeInBytes) {
      throw Exception(
          'File too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB). Max allowed: ${settings.maxFileUploadSizeMB}MB');
    }

    // Check extension
    if (!allowedExtensions.contains(ext)) {
      throw Exception(
          'Unsupported file type: $ext. Allowed: ${allowedExtensions.join(", ")}');
    }

    // Security check
    final maliciousExtensions = ['.exe', '.msi', '.sh', '.bat', '.js', '.vbs'];
    if (maliciousExtensions.contains(ext)) {
      throw Exception(
          'Security violation: Executable files are not allowed for health records');
    }
  }

  String _getFileNameWithoutExtension(String filePath) {
    return p.basenameWithoutExtension(filePath);
  }

  Future<String> _extractTextFromPdfBytes(List<int> bytes) async {
    final buffer = StringBuffer();
    final pdfBytes = Uint8List.fromList(bytes);

    final tempDir = await getTemporaryDirectory();
    int pageIndex = 0;

    await for (final page in Printing.raster(pdfBytes, dpi: 160)) {
      final pngBytes = await page.toPng();
      final tempPath = p.join(
        tempDir.path,
        'ephemeral_pdf_page_${DateTime.now().millisecondsSinceEpoch}_$pageIndex.png',
      );
      final tempFile = File(tempPath);
      try {
        await tempFile.writeAsBytes(pngBytes, flush: true);
        final text = await OCRService.extractTextFromImage(tempFile);
        if (text.trim().isNotEmpty) {
          buffer.writeln(text);
          buffer.writeln();
        }
      } finally {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {}
      }
      pageIndex++;
      if (pageIndex >= 5) break;
    }

    return buffer.toString().trim();
  }

  bool _isImage(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    return ['.jpg', '.jpeg', '.png'].contains(ext);
  }

  void clearQueue() {
    _processingQueue.clear();
    _statusController.add([]);
  }

  void removeItem(String id) {
    _processingQueue.removeWhere((item) => item.id == id);
    _statusController.add(List.from(_processingQueue));
  }
}
