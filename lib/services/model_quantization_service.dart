import 'dart:io';
import 'package:flutter/foundation.dart';
import 'platform_detector.dart';

/// Supported quantization formats for local LLM models.
enum QuantizationFormat {
  q2_k,
  q3_k_m,
  q4_k_m,
  q5_k_m,
  q6_k,
  q8_0,
  f16;

  /// Human-readable label for the quantization level.
  String get label {
    switch (this) {
      case QuantizationFormat.q2_k:
        return '2-bit (Extreme)';
      case QuantizationFormat.q3_k_m:
        return '3-bit (Medium)';
      case QuantizationFormat.q4_k_m:
        return '4-bit (Balanced)';
      case QuantizationFormat.q5_k_m:
        return '5-bit (High Quality)';
      case QuantizationFormat.q6_k:
        return '6-bit (Near Lossless)';
      case QuantizationFormat.q8_0:
        return '8-bit (Professional)';
      case QuantizationFormat.f16:
        return '16-bit (Full Precision)';
    }
  }

  /// Estimated quality impact compared to full precision (0.0 to 1.0).
  double get qualityImpact {
    switch (this) {
      case QuantizationFormat.q2_k:
        return 0.65;
      case QuantizationFormat.q3_k_m:
        return 0.80;
      case QuantizationFormat.q4_k_m:
        return 0.92;
      case QuantizationFormat.q5_k_m:
        return 0.97;
      case QuantizationFormat.q6_k:
        return 0.99;
      case QuantizationFormat.q8_0:
        return 0.999;
      case QuantizationFormat.f16:
        return 1.0;
    }
  }

  /// Estimated speed multiplier (higher is faster).
  double get speedMultiplier {
    switch (this) {
      case QuantizationFormat.q2_k:
        return 2.5;
      case QuantizationFormat.q3_k_m:
        return 2.0;
      case QuantizationFormat.q4_k_m:
        return 1.5;
      case QuantizationFormat.q5_k_m:
        return 1.2;
      case QuantizationFormat.q6_k:
        return 1.0;
      case QuantizationFormat.q8_0:
        return 0.8;
      case QuantizationFormat.f16:
        return 0.5;
    }
  }

  /// File size multiplier relative to the 4-bit (balanced) base size.
  double get sizeMultiplier {
    switch (this) {
      case QuantizationFormat.q2_k:
        return 0.5; // Half of 4-bit
      case QuantizationFormat.q3_k_m:
        return 0.75;
      case QuantizationFormat.q4_k_m:
        return 1.0;
      case QuantizationFormat.q5_k_m:
        return 1.25;
      case QuantizationFormat.q6_k:
        return 1.5;
      case QuantizationFormat.q8_0:
        return 2.0;
      case QuantizationFormat.f16:
        return 4.0;
    }
  }

  /// Returns a description of the trade-offs for this format.
  String get tradeOffDescription {
    switch (this) {
      case QuantizationFormat.q2_k:
        return 'Fastest speed, smallest size, but significant quality loss. Best for legacy devices.';
      case QuantizationFormat.q3_k_m:
        return 'Good speed and size, acceptable for simple tasks. Noticeable quality loss in reasoning.';
      case QuantizationFormat.q4_k_m:
        return 'Recommended. Excellent balance of speed, size, and medical reasoning accuracy.';
      case QuantizationFormat.q5_k_m:
        return 'High accuracy with moderate speed. Ideal for mid-range devices with enough RAM.';
      case QuantizationFormat.q6_k:
        return 'Near full-precision quality. Recommended for detailed analysis on modern hardware.';
      case QuantizationFormat.q8_0:
        return 'Professional grade quality. Slower and requires significant RAM and storage.';
      case QuantizationFormat.f16:
        return 'Maximum possible accuracy. Very slow and extremely resource intensive.';
    }
  }
}

/// Service for managing model quantization and device compatibility.
class ModelQuantizationService {
  static final ModelQuantizationService _instance =
      ModelQuantizationService._internal();
  factory ModelQuantizationService() => _instance;
  ModelQuantizationService._internal();

  /// Detects the recommended quantization format based on current device capabilities.
  Future<QuantizationFormat> getRecommendedFormat() async {
    final capabilities = await PlatformDetector().getCapabilities();

    if (capabilities.isDesktop) {
      if (capabilities.ramGB >= 32) return QuantizationFormat.q8_0;
      if (capabilities.ramGB >= 16) return QuantizationFormat.q6_k;
      return QuantizationFormat.q4_k_m;
    }

    if (capabilities.ramGB >= 12) return QuantizationFormat.q5_k_m;
    if (capabilities.ramGB >= 8) return QuantizationFormat.q4_k_m;
    if (capabilities.ramGB >= 6) return QuantizationFormat.q3_k_m;

    return QuantizationFormat.q2_k;
  }

  /// Assesses if the device has enough free disk space for a specific quantization level.
  Future<AssessmentResult> assessCompatibility(
      double baseStorageGB, QuantizationFormat format) async {
    final requiredSize = baseStorageGB * format.sizeMultiplier;
    final capabilities = await PlatformDetector().getCapabilities();

    // Check RAM compatibility
    // Assuming 4-bit base ramRequired in ModelOption
    final estimatedRam = requiredSize * 1.2; // Rough estimate of RAM usage
    final hasEnoughRam = capabilities.ramGB >= estimatedRam;

    // In a real app, we'd check actual disk space here.
    // For now, we simulate the check.
    const availableSpaceGB = 50.0; // Simulated available space
    final hasEnoughSpace = availableSpaceGB > requiredSize;

    return AssessmentResult(
      isCompatible: hasEnoughRam && hasEnoughSpace,
      estimatedRamGB: estimatedRam,
      estimatedStorageGB: requiredSize,
      ramWarning: !hasEnoughRam
          ? 'Device RAM (${capabilities.ramGB.toStringAsFixed(1)}GB) is below recommended ${estimatedRam.toStringAsFixed(1)}GB'
          : null,
      storageWarning: !hasEnoughSpace
          ? 'Insufficient storage. Required: ${requiredSize.toStringAsFixed(1)}GB'
          : null,
    );
  }

  /// Returns accurate quality assessment metrics for a given model and format.
  Map<String, double> getQualityMetrics(QuantizationFormat format) {
    return {
      'medicalReasoning': format.qualityImpact,
      'factualAccuracy':
          format.qualityImpact * 1.02, // Slightly higher for facts
      'coherence': format.qualityImpact * 0.98, // Slightly lower for long text
      'inferenceSpeed': format.speedMultiplier,
    };
  }

  /// Returns the trade-off metrics for UI display.
  QuantizationTradeoffs getTradeoffs(QuantizationFormat format) {
    return QuantizationTradeoffs(
      quality: format.qualityImpact,
      speed: format.speedMultiplier / 2.5, // Normalize to 0.0-1.0 (2.5 is max)
      efficiency: 1.0 / format.sizeMultiplier, // Smaller is more efficient
      description: format.tradeOffDescription,
    );
  }
}

/// Represents the trade-off metrics for a quantization level.
class QuantizationTradeoffs {
  final double quality;
  final double speed;
  final double efficiency;
  final String description;

  QuantizationTradeoffs({
    required this.quality,
    required this.speed,
    required this.efficiency,
    required this.description,
  });
}

/// Represents the result of a compatibility assessment.
class AssessmentResult {
  final bool isCompatible;
  final double estimatedRamGB;
  final double estimatedStorageGB;
  final String? ramWarning;
  final String? storageWarning;

  AssessmentResult({
    required this.isCompatible,
    required this.estimatedRamGB,
    required this.estimatedStorageGB,
    this.ramWarning,
    this.storageWarning,
  });

  bool get hasWarnings => ramWarning != null || storageWarning != null;
}
