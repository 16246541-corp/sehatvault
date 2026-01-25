import 'package:objectbox/objectbox.dart';

@Entity()
class SearchEntry {
  @Id()
  int id = 0;

  @Index()
  String sourceId;

  @Index()
  String type; // 'conversation', 'document', 'followup'

  String content; // Full searchable text
  String title;
  String subtitle;

  @Property(type: PropertyType.date)
  DateTime timestamp;

  // Store keywords for boosting (e.g. medical terms)
  String keywords;

  SearchEntry({
    required this.sourceId,
    required this.type,
    required this.content,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.keywords = '',
  });
}
