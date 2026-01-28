import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import '../models/document_extraction.dart';
import 'data_extraction_service.dart';

class OCRService {
  static const MethodChannel _appleVisionOcrChannel =
      MethodChannel('com.sehatlocker/apple_vision_ocr');

  @visibleForTesting
  static Future<String> Function(
    String imagePath, {
    String? language,
    Map? args,
  })? tesseractExtractTextOverride;

  /// Extracts text from an image file using Tesseract OCR.
  /// Handles rotation and low-light preprocessing.
  static Future<String> extractTextFromImage(File image) async {
    if (!await image.exists()) {
      throw Exception("Image file not found at ${image.path}");
    }

    // 1. Preprocessing for better OCR accuracy
    final File processedImageFile = await _preprocessImage(image);

    try {
      return await _runTesseract(processedImageFile.path);
    } catch (e) {
      throw Exception("OCR Extraction failed: $e");
    } finally {
      // Clean up the temporary preprocessed file
      if (processedImageFile.path != image.path) {
        try {
          await processedImageFile.delete();
        } catch (_) {
          // Ignore deletion errors for temporary files
        }
      }
    }
  }

  /// Original method kept for backward compatibility if needed.
  static Future<String> extractText(String imagePath) async {
    return extractTextFromImage(File(imagePath));
  }

  static Future<String> extractTextFromFile(File file) async {
    if (!await file.exists()) {
      throw Exception("File not found at ${file.path}");
    }

    final ext = p.extension(file.path).toLowerCase();
    if (ext == '.txt') {
      final text = await file.readAsString();
      return _cleanText(text);
    }

    if (ext == '.pdf') {
      final bytes = await file.readAsBytes();
      return _extractTextFromPdfBytes(bytes);
    }

    return extractTextFromImage(file);
  }

  /// Full pipeline: Extracts text and then runs data extraction to get structured fields.
  static Future<DocumentExtraction> processDocument(File image) async {
    final String extractedText = await extractTextFromFile(image);
    final Map<String, dynamic> structuredData =
        DataExtractionService.extractStructuredData(extractedText);

    // Simple confidence score heuristic:
    // Base 0.5, +0.2 if text found, +0.2 if structured data found
    double confidenceScore = 0.5;
    if (extractedText.isNotEmpty) confidenceScore += 0.2;
    if (structuredData.values.any((v) => v is List && v.isNotEmpty)) {
      confidenceScore += 0.2;
    }
    if (confidenceScore > 1.0) confidenceScore = 1.0;

    return DocumentExtraction(
      originalImagePath: image.path,
      extractedText: extractedText,
      structuredData: structuredData,
      confidenceScore: confidenceScore,
    );
  }

  static Future<String> _extractTextFromPdfBytes(List<int> bytes) async {
    final buffer = StringBuffer();
    final pdfBytes = Uint8List.fromList(bytes);
    int pageIndex = 0;

    await for (final page in Printing.raster(pdfBytes, dpi: 300)) {
      final pngBytes = await page.toPng();
      final text = await extractTextFromImageBytes(pngBytes);
      if (text.trim().isNotEmpty) {
        buffer.writeln(text);
        buffer.writeln();
      }
      pageIndex++;
      if (pageIndex >= 5) break;
    }

    return buffer.toString().trim();
  }

  static Future<String> extractTextFromImageBytes(Uint8List bytes) async {
    // On iOS/macOS, we trust Apple Vision to handle the image processing.
    // We skip the heavy downscaling/grayscaling that Tesseract needs.
    if (Platform.isIOS || Platform.isMacOS) {
      final directory = await getTemporaryDirectory();
      final tempPath = p.join(
        directory.path,
        'ocr_pdf_prep_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final preprocessedFile = File(tempPath);

      // Just write the bytes directly if they are already an image (PNG from PDF raster)
      // Note: Printing.raster returns PNG bytes.
      await preprocessedFile.writeAsBytes(bytes, flush: true);

      try {
        return await _runTesseract(preprocessedFile.path);
      } catch (e) {
        throw Exception("OCR Extraction failed: $e");
      } finally {
        try {
          if (await preprocessedFile.exists()) {
            await preprocessedFile.delete();
          }
        } catch (_) {}
      }
    }

    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Unsupported image data');
    }

    if (image.width > 1024) {
      image = img.copyResize(image, width: 1024);
    }

    image = img.bakeOrientation(image);
    image = img.adjustColor(
      image,
      contrast: 1.5,
      brightness: 1.1,
      gamma: 1.2,
    );
    image = img.grayscale(image);
    image = img.contrast(image, contrast: 1.2);

    final directory = await getTemporaryDirectory();
    final tempPath = p.join(
      directory.path,
      'ocr_pdf_prep_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    final preprocessedFile = File(tempPath);
    await preprocessedFile.writeAsBytes(
      img.encodeJpg(image, quality: 90),
      flush: true,
    );

    try {
      if (!await preprocessedFile.exists()) {
        throw Exception('Failed to prepare OCR image');
      }
      return await _runTesseract(preprocessedFile.path);
    } catch (e) {
      throw Exception("OCR Extraction failed: $e");
    } finally {
      try {
        if (await preprocessedFile.exists()) {
          await preprocessedFile.delete();
        }
      } catch (_) {}
    }
  }

  static Future<String> _runTesseract(String imagePath) async {
    final override = tesseractExtractTextOverride;
    if (override != null) {
      final text = await override(
        imagePath,
        language: 'eng',
        args: {
          "psm": "3",
          "preserve_interword_spaces": "1",
        },
      );
      return _cleanText(text);
    }

    if (Platform.isIOS || Platform.isMacOS) {
      try {
        print("OCR: Attempting Apple Vision on $imagePath");
        final text = await _runAppleVision(imagePath);
        print("OCR: Apple Vision result length: ${text.length}");
        if (text.trim().isNotEmpty) return text;
        print("OCR: Apple Vision returned empty...");
      } catch (e) {
        print("OCR: Apple Vision error: $e");
      }

      // On macOS, we cannot fallback to Tesseract (not supported)
      if (Platform.isMacOS) {
        print(
            "OCR: No fallback available on macOS (Tesseract not supported). Returning empty.");
        return "";
      }

      // On iOS, we can try Tesseract as a fallback
      print("OCR: Falling back to Tesseract on iOS...");
      // Continue to Tesseract fallback below
    } else if (Platform.isAndroid) {
      // Android uses Tesseract directly
      print("OCR: Using Tesseract on Android...");
    } else {
      // Windows/Linux - not supported
      throw Exception(
          "OCR on ${Platform.operatingSystem} is not currently supported due to lack of native package compatibility. Please use the mobile app for OCR.");
    }

    // Tesseract fallback (only reached on iOS/Android)
    final runner = FlutterTesseractOcr.extractText;
    final text = await runner(
      imagePath,
      language: 'eng',
      args: {
        "psm": "3",
        "preserve_interword_spaces": "1",
      },
    );
    return _cleanText(text);
  }

  static Future<String> _runAppleVision(String path) async {
    final text = await _appleVisionOcrChannel.invokeMethod<String>(
      'extractText',
      {'imagePath': path},
    );
    return _cleanText(text ?? '');
  }

  /// Internal preprocessing: handles rotation, low-light enhancement, and grayscale.
  static Future<File> _preprocessImage(File imageFile) async {
    // Skip preprocessing for Apple Vision (iOS/macOS) as it handles
    // high-res color images better than Tesseract's preprocessed inputs.
    if (Platform.isIOS || Platform.isMacOS) {
      return imageFile;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      // 1. Resize for Speed (Downscale)
      // Processing 12MP+ images is slow. Resize to manageable width (e.g., 1024px)
      // while maintaining aspect ratio.
      if (image.width > 1024) {
        image = img.copyResize(image, width: 1024);
      }

      // 2. Handle Orientation (Auto-rotation)
      // This fixes issues with images taken in different orientations.
      image = img.bakeOrientation(image);

      // 3. Low-light preprocessing: Enhance contrast and brightness
      // Medical documents often have faint text or are captured in poor lighting.
      image = img.adjustColor(
        image,
        contrast: 1.5, // 50% boost
        brightness: 1.1, // 10% boost
        gamma: 1.2,
      );

      // 4. Convert to Grayscale
      // Tesseract performs better on grayscale or binarized images.
      image = img.grayscale(image);

      // 5. Final contrast stretch
      image = img.contrast(image, contrast: 1.2);

      // Save to a temporary file for Tesseract to read
      final directory = await getTemporaryDirectory();
      final tempPath = p.join(directory.path,
          "ocr_prep_${DateTime.now().millisecondsSinceEpoch}.jpg");

      final preprocessedFile = File(tempPath);
      await preprocessedFile.writeAsBytes(img.encodeJpg(image, quality: 90));

      return preprocessedFile;
    } catch (e) {
      // Fallback to original image if preprocessing fails
      return imageFile;
    }
  }

  /// Cleans the raw OCR text by removing noise and normalizing whitespace.
  static String _cleanText(String text) {
    if (text.trim().isEmpty) return "";

    final lines = text.split('\n').map((l) => l.trimRight()).toList();
    final letterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);

    final cleanedLines = lines.where((line) {
      final t = line.trim();
      if (t.isEmpty) return false;
      return letterOrNumber.hasMatch(t);
    }).toList();

    return cleanedLines
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Max two consecutive newlines
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalize spaces
        .replaceAll(
            RegExp(r'[\|\\\/~_]'), '') // Remove common OCR "noise" characters
        .trim();
  }

  /// Pre-warm Tesseract or ensure assets are ready.
  static Future<void> initialize() async {
    // Currently handled by the package, but here for future-proofing.
  }
}
