import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class OCRService {
  /// Extracts text from an image file using Tesseract OCR.
  /// Handles rotation and low-light preprocessing.
  static Future<String> extractTextFromImage(File image) async {
    if (!await image.exists()) {
      throw Exception("Image file not found at ${image.path}");
    }

    // 1. Preprocessing for better OCR accuracy
    final File processedImageFile = await _preprocessImage(image);

    try {
      // 2. Run Tesseract OCR
      // We use 'eng' as default. For medical documents, 'eng' is usually sufficient
      // if the document is in English.
      final String text = await FlutterTesseractOcr.extractText(
        processedImageFile.path,
        language: 'eng',
        args: {
          "psm": "3", // Fully automatic page segmentation, but no OSD.
          "preserve_interword_spaces": "1",
        },
      );

      // 3. Clean and return the extracted text
      return _cleanText(text);
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

  /// Internal preprocessing: handles rotation, low-light enhancement, and grayscale.
  static Future<File> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      // 1. Handle Orientation (Auto-rotation)
      // This fixes issues with images taken in different orientations.
      image = img.bakeOrientation(image);

      // 2. Low-light preprocessing: Enhance contrast and brightness
      // Medical documents often have faint text or are captured in poor lighting.
      image = img.adjustColor(
        image, 
        contrast: 1.5, // 50% boost
        brightness: 1.1, // 10% boost
        gamma: 1.2,
      );

      // 3. Convert to Grayscale
      // Tesseract performs better on grayscale or binarized images.
      image = img.grayscale(image);

      // 4. Final contrast stretch
      image = img.contrast(image, contrast: 1.2);

      // Save to a temporary file for Tesseract to read
      final directory = await getTemporaryDirectory();
      final tempPath = p.join(
        directory.path, 
        "ocr_prep_${DateTime.now().millisecondsSinceEpoch}.jpg"
      );
      
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
    if (text.isEmpty) return "";

    // 1. Initial split and trim
    List<String> lines = text.split('\n').map((l) => l.trim()).toList();

    // 2. Filter out noisy lines (mostly non-alphanumeric single chars)
    List<String> cleanedLines = lines.where((line) {
      if (line.isEmpty) return false;
      // Keep lines that have at least one alphanumeric character
      // and aren't just a string of symbols
      return RegExp(r'[a-zA-Z0-9]').hasMatch(line) && line.length > 1;
    }).toList();

    // 3. Rejoin and apply global regex cleaning
    return cleanedLines.join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Max two consecutive newlines
        .replaceAll(RegExp(r'[ \t]+'), ' ')     // Normalize spaces
        .replaceAll(RegExp(r'[\|\\\/~_]'), '')  // Remove common OCR "noise" characters
        .trim();
  }

  /// Pre-warm Tesseract or ensure assets are ready.
  static Future<void> initialize() async {
    // Currently handled by the package, but here for future-proofing.
  }
}
