import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'citation.g.dart';

@HiveType(typeId: 14)
class Citation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourceTitle;

  @HiveField(2)
  final String? sourceUrl;

  @HiveField(3)
  final DateTime? sourceDate;

  @HiveField(4)
  final String? textSnippet;

  @HiveField(5)
  final double confidenceScore;

  @HiveField(6)
  final String type; // e.g., 'guideline', 'reference', 'study'

  @HiveField(7)
  final String? relatedField; // Field in the document this citation applies to

  @HiveField(8)
  final String? authors;

  @HiveField(9)
  final String? publication;

  Citation({
    String? id,
    required this.sourceTitle,
    this.sourceUrl,
    this.sourceDate,
    this.textSnippet,
    this.confidenceScore = 1.0,
    this.type = 'guideline',
    this.relatedField,
    this.authors,
    this.publication,
  }) : id = id ?? const Uuid().v4();

  // Helpers for FDA format
  String get inlineCitation => '($sourceTitle, ${sourceDate?.year ?? "n.d."})';

  String get footnoteCitation =>
      '$sourceTitle. $publication. ${sourceDate?.year ?? "n.d."}.';

  String get fullReference =>
      '$authors. "$sourceTitle." $publication, ${sourceDate?.year ?? "n.d."}. ${sourceUrl ?? ""}';
}
