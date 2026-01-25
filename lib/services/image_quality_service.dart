import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ImageQualityResult {
  final bool isBlurry;
  final bool isDark;
  final double blurScore; // Variance of Laplacian
  final double brightnessScore; // Average luminance
  final List<String> warnings;

  ImageQualityResult({
    required this.isBlurry,
    required this.isDark,
    required this.blurScore,
    required this.brightnessScore,
    required this.warnings,
  });

  bool get hasIssues => warnings.isNotEmpty;

  @override
  String toString() {
    return 'ImageQualityResult(isBlurry: $isBlurry, isDark: $isDark, blurScore: ${blurScore.toStringAsFixed(2)}, brightnessScore: ${brightnessScore.toStringAsFixed(2)}, warnings: $warnings)';
  }
}

class ImageQualityService {
  // Thresholds - these may need tuning based on real-world testing
  static const double _blurThreshold =
      500.0; // Variance of Laplacian. < 500 is often blurry.
  static const double _darknessThreshold =
      100.0; // Average luminance (0-255). < 100 is dark.

  static Future<ImageQualityResult> analyzeImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception("Could not decode image");
    }

    // Resize for speed (analysis doesn't need full res)
    // 512px width is enough for blur/brightness detection
    final resized = img.copyResize(image, width: 512);
    final grayscale = img.grayscale(resized);

    final brightness = _calculateBrightness(grayscale);
    final blurVariance = _calculateBlurVariance(grayscale);

    final isDark = brightness < _darknessThreshold;
    final isBlurry = blurVariance < _blurThreshold;

    final warnings = <String>[];
    if (isDark) warnings.add("Image is too dark. Please add more light.");
    if (isBlurry) warnings.add("Image appears blurry. Please hold steady.");

    return ImageQualityResult(
      isBlurry: isBlurry,
      isDark: isDark,
      blurScore: blurVariance,
      brightnessScore: brightness,
      warnings: warnings,
    );
  }

  static ImageQualityResult analyzeFrame(CameraImage image) {
    double brightness = 0;
    double blurVariance = 0;

    if (image.format.group == ImageFormatGroup.yuv420) {
      // Android: YUV420. Plane 0 is Y (Luminance)
      final yPlane = image.planes[0];
      brightness = _calculateYUVBrightness(yPlane);
      blurVariance =
          _calculateYUVBlurVariance(yPlane, image.width, image.height);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      // iOS: BGRA8888.
      brightness =
          _calculateBGRABrightness(image.planes[0], image.width, image.height);
      // Calculating blur on BGRA is expensive, we might skip it or do a very fast sampling
      // For now, let's skip blur calculation on iOS for realtime or implement a simplified one if needed
      // Or we can just use brightness for "Good lighting" check
      blurVariance = 500.0; // Assume good for now to avoid false positives
    }

    final isDark = brightness < _darknessThreshold;
    final isBlurry = blurVariance < _blurThreshold;

    final warnings = <String>[];
    if (isDark) warnings.add("Image is too dark. Please add more light.");
    if (isBlurry) warnings.add("Image appears blurry. Please hold steady.");

    return ImageQualityResult(
      isBlurry: isBlurry,
      isDark: isDark,
      blurScore: blurVariance,
      brightnessScore: brightness,
      warnings: warnings,
    );
  }

  static double _calculateYUVBrightness(Plane yPlane) {
    final bytes = yPlane.bytes;
    int total = 0;
    // Sample every 10th pixel for speed
    int step = 10;
    int count = 0;
    for (int i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  static double _calculateBGRABrightness(Plane plane, int width, int height) {
    final bytes = plane.bytes;
    int total = 0;
    int count = 0;
    // BGRA = 4 bytes per pixel.
    // Sample every 10th pixel (40 bytes)
    int step = 40;

    for (int i = 0; i < bytes.length; i += step) {
      // B = i, G = i+1, R = i+2
      if (i + 2 < bytes.length) {
        int r = bytes[i + 2];
        int g = bytes[i + 1];
        int b = bytes[i];
        // Luminance
        total += (0.299 * r + 0.587 * g + 0.114 * b).round();
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  static double _calculateYUVBlurVariance(Plane yPlane, int width, int height) {
    // Simplified Laplacian variance for Y plane
    // To be fast, we only sample a central crop

    final bytes = yPlane.bytes;
    final rowStride = yPlane.bytesPerRow;

    double mean = 0;
    double m2 = 0;
    int count = 0;

    // Define a central region (e.g., middle 50%)
    int startX = width ~/ 4;
    int endX = width * 3 ~/ 4;
    int startY = height ~/ 4;
    int endY = height * 3 ~/ 4;

    // Sample step
    int step = 2;

    for (int y = startY; y < endY; y += step) {
      for (int x = startX; x < endX; x += step) {
        // Get pixel and neighbors
        // Careful with bounds
        int index = y * rowStride + x;
        if (index < 0 || index >= bytes.length) continue;

        // Neighbors
        int up = (y - 1) * rowStride + x;
        int down = (y + 1) * rowStride + x;
        int left = y * rowStride + (x - 1);
        int right = y * rowStride + (x + 1);

        if (up < 0 || down >= bytes.length || left < 0 || right >= bytes.length)
          continue;

        int p = bytes[index];
        int pUp = bytes[up];
        int pDown = bytes[down];
        int pLeft = bytes[left];
        int pRight = bytes[right];

        int laplacian = pUp + pDown + pLeft + pRight - (4 * p);

        // Welford
        count++;
        double delta = laplacian - mean;
        mean += delta / count;
        double delta2 = laplacian - mean;
        m2 += delta * delta2;
      }
    }

    return count < 2 ? 0 : m2 / (count - 1);
  }

  static double _calculateBrightness(img.Image image) {
    // Calculate average luminance
    double totalLuminance = 0;
    int count = 0;
    for (final pixel in image) {
      totalLuminance += pixel.luminance;
      count++;
    }
    return count == 0 ? 0 : totalLuminance / count;
  }

  static double _calculateBlurVariance(img.Image image) {
    // Laplacian kernel
    // [0, 1, 0]
    // [1, -4, 1]
    // [0, 1, 0]

    double mean = 0;
    double m2 = 0;
    int count = 0;

    // Iterate over inner pixels
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final p = image.getPixel(x, y).luminance;
        final pUp = image.getPixel(x, y - 1).luminance;
        final pDown = image.getPixel(x, y + 1).luminance;
        final pLeft = image.getPixel(x - 1, y).luminance;
        final pRight = image.getPixel(x + 1, y).luminance;

        final laplacian = pUp + pDown + pLeft + pRight - (4 * p);

        // Welford's algorithm for variance
        count++;
        double delta = laplacian - mean;
        mean += delta / count;
        double delta2 = laplacian - mean;
        m2 += delta * delta2;
      }
    }

    return count < 2 ? 0 : m2 / (count - 1);
  }
}
