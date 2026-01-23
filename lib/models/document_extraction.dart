import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'document_extraction.g.dart';

/// Model representing the results of a document OCR extraction process
@HiveType(typeId: 4)
class DocumentExtraction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String originalImagePath;

  @HiveField(2)
  final String extractedText;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final double confidenceScore;

  @HiveField(5)
  final Map<String, dynamic> structuredData;

  @HiveField(6)
  final String? contentHash;

  DocumentExtraction({
    String? id,
    required this.originalImagePath,
    required this.extractedText,
    DateTime? createdAt,
    required this.confidenceScore,
    this.structuredData = const {},
    this.contentHash,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  DocumentExtraction copyWith({
    String? id,
    String? originalImagePath,
    String? extractedText,
    DateTime? createdAt,
    double? confidenceScore,

    Map<String, dynamic>? structuredData,
    String? contentHash,
  }) {
    return DocumentExtraction(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      extractedText: extractedText ?? this.extractedText,
      createdAt: createdAt ?? this.createdAt,
      confidenceScore: confidenceScore ?? this.confidenceScore,

      structuredData: structuredData ?? this.structuredData,
      contentHash: contentHash ?? this.contentHash,
    );
  }
}
