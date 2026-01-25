import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'batch_task.g.dart';

@HiveType(typeId: 33)
enum BatchTaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
}

@HiveType(typeId: 34)
enum BatchTaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  normal,
  @HiveField(2)
  high,
}

@HiveType(typeId: 35)
class BatchTask extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String filePath;
  
  @HiveField(3)
  BatchTaskStatus status;
  
  @HiveField(4)
  BatchTaskPriority priority;
  
  @HiveField(5)
  double progress;
  
  @HiveField(6)
  String? error;
  
  @HiveField(7)
  DateTime createdAt;
  
  @HiveField(8)
  DateTime? startedAt;
  
  @HiveField(9)
  DateTime? completedAt;
  
  @HiveField(10)
  Map<String, dynamic>? metadata;

  BatchTask({
    required this.id,
    required this.title,
    required this.filePath,
    this.status = BatchTaskStatus.pending,
    this.priority = BatchTaskPriority.normal,
    this.progress = 0.0,
    this.error,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.metadata,
  });

  factory BatchTask.create({
    required String title,
    required String filePath,
    BatchTaskPriority priority = BatchTaskPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    return BatchTask(
      id: const Uuid().v4(),
      title: title,
      filePath: filePath,
      priority: priority,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }

  BatchTask copyWith({
    BatchTaskStatus? status,
    double? progress,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return BatchTask(
      id: id,
      title: title,
      filePath: filePath,
      status: status ?? this.status,
      priority: priority,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata,
    );
  }
}
