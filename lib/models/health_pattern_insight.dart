import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'citation.dart';

@HiveType(typeId: 42)
class HealthPatternInsight extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String summary;

  @HiveField(4)
  final String patternType;

  @HiveField(5)
  final String? timeframeIso8601;

  @HiveField(6)
  final List<Citation> citations;

  @HiveField(7)
  final List<String> sourceIds;

  HealthPatternInsight({
    String? id,
    DateTime? createdAt,
    required this.title,
    required this.summary,
    required this.patternType,
    this.timeframeIso8601,
    this.citations = const [],
    this.sourceIds = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get contentHash {
    final bytes = utf8.encode('$title|$summary|$patternType|$timeframeIso8601');
    return sha256.convert(bytes).toString();
  }
}

class HealthPatternInsightAdapter extends TypeAdapter<HealthPatternInsight> {
  @override
  final int typeId = 42;

  @override
  HealthPatternInsight read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthPatternInsight(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      title: fields[2] as String,
      summary: fields[3] as String,
      patternType: fields[4] as String,
      timeframeIso8601: fields[5] as String?,
      citations: (fields[6] as List?)?.cast<Citation>() ?? const [],
      sourceIds: (fields[7] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, HealthPatternInsight obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.summary)
      ..writeByte(4)
      ..write(obj.patternType)
      ..writeByte(5)
      ..write(obj.timeframeIso8601)
      ..writeByte(6)
      ..write(obj.citations)
      ..writeByte(7)
      ..write(obj.sourceIds);
  }
}
