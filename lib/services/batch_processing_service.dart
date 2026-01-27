import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../models/batch_task.dart';
import '../models/health_record.dart';
import 'local_storage_service.dart';
import 'vault_service.dart';
import 'storage_usage_service.dart';
import 'desktop_notification_service.dart';
import 'platform_detector.dart';
import 'memory_monitor_service.dart';
import 'battery_monitor_service.dart';

/// Service for managing and processing batches of documents.
/// Features queue management, priority system, background processing, and resource throttling.
class BatchProcessingService {
  static final BatchProcessingService _instance =
      BatchProcessingService._internal();
  factory BatchProcessingService() => _instance;

  @visibleForTesting
  BatchProcessingService.internal({
    LocalStorageService? storageService,
    VaultService? vaultService,
    StorageUsageService? storageUsageService,
    DesktopNotificationService? notificationService,
    MemoryMonitorService? memoryMonitor,
    BatteryMonitorService? batteryMonitor,
  })  : _storageService = storageService ?? LocalStorageService(),
        _notificationService =
            notificationService ?? DesktopNotificationService(),
        _memoryMonitor = memoryMonitor ?? MemoryMonitorService(),
        _batteryMonitor = batteryMonitor ?? BatteryMonitorService() {
    if (vaultService != null) _vaultService = vaultService;
    if (storageUsageService != null) _storageUsageService = storageUsageService;
  }

  BatchProcessingService._internal()
      : _storageService = LocalStorageService(),
        _notificationService = DesktopNotificationService(),
        _memoryMonitor = MemoryMonitorService(),
        _batteryMonitor = BatteryMonitorService();

  final LocalStorageService _storageService;
  late VaultService _vaultService;
  late StorageUsageService _storageUsageService;
  final DesktopNotificationService _notificationService;
  final MemoryMonitorService _memoryMonitor;
  final BatteryMonitorService _batteryMonitor;
  bool _isProcessing = false;
  bool _isPaused = false;
  final List<BatchTask> _queue = [];
  final Map<String, bool> _cancellationTokens = {};
  final Map<String, bool> _jobCancellationTokens = {};
  final Set<String> _activeTaskIds = {};
  StreamSubscription? _boxSubscription;

  // Resource throttling constants
  static const int _maxConcurrentTasks = 2; // Increased for better throughput
  static const double _memoryThreshold = 0.8; // Pause if RAM usage > 80%

  // Status controller for UI updates
  final StreamController<List<BatchTask>> _statusController =
      StreamController<List<BatchTask>>.broadcast();
  Stream<List<BatchTask>> get tasksStream => _statusController.stream;

  bool get isProcessing => _isProcessing;
  bool get isPaused => _isPaused;

  void initialize() {
    _vaultService = VaultService(_storageService);
    _storageUsageService = StorageUsageService(_storageService);
    _loadQueue();
    _checkAndStartProcessing();

    // Listen for changes in the Hive box
    _storageService.batchTasksListenable.addListener(() {
      _loadQueue();
      _checkAndStartProcessing();
    });
  }

  void _loadQueue() {
    final tasks = _storageService.getAllBatchTasks();
    _queue.clear();
    _queue.addAll(tasks);

    // Sort by priority (High -> Low) then by date
    _queue.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.index.compareTo(a.priority.index);
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    _statusController.add(List.unmodifiable(_queue));
  }

  void _checkAndStartProcessing() {
    // Auto-start processing if there are pending tasks and not paused
    if (!_isProcessing &&
        !_isPaused &&
        _queue.any((t) => t.status == BatchTaskStatus.pending)) {
      _startProcessing();
    }
  }

  /// Pause the processing queue
  void pauseProcessing() {
    _isPaused = true;
    _isProcessing = false;
    _statusController.add(List.unmodifiable(_queue));
  }

  /// Resume the processing queue
  void resumeProcessing() {
    _isPaused = false;
    _checkAndStartProcessing();
    _statusController.add(List.unmodifiable(_queue));
  }

  /// Add a new task to the batch processing queue
  Future<void> addTask(String title, String filePath,
      {BatchTaskPriority priority = BatchTaskPriority.normal}) async {
    final task = BatchTask.create(
      title: title,
      filePath: filePath,
      priority: priority,
    );
    await _storageService.saveBatchTask(task);
  }

  /// Add multiple tasks as a batch
  Future<void> addBatch(List<({String title, String filePath})> items,
      {BatchTaskPriority priority = BatchTaskPriority.normal}) async {
    for (final item in items) {
      final task = BatchTask.create(
        title: item.title,
        filePath: item.filePath,
        priority: priority,
      );
      await _storageService.saveBatchTask(task);
    }
  }

  void cancelJob(String jobId) {
    _jobCancellationTokens[jobId] = true;
  }

  void clearJobCancellation(String jobId) {
    _jobCancellationTokens.remove(jobId);
  }

  Future<void> runThrottledJob({
    required String jobId,
    required int totalUnits,
    required Future<void> Function(int start, int end) processChunk,
    int chunkSize = 50,
    bool ignoreThrottle = false,
  }) async {
    if (totalUnits <= 0) return;
    clearJobCancellation(jobId);

    for (var start = 0; start < totalUnits; start += chunkSize) {
      if (_jobCancellationTokens[jobId] == true) {
        throw 'Cancelled by user';
      }

      while (_isPaused) {
        if (_jobCancellationTokens[jobId] == true) {
          throw 'Cancelled by user';
        }
        await Future.delayed(const Duration(milliseconds: 150));
      }

      if (!ignoreThrottle && await _shouldThrottle()) {
        await Future.delayed(const Duration(milliseconds: 250));
        start -= chunkSize;
        continue;
      }

      final end = (start + chunkSize) > totalUnits ? totalUnits : start + chunkSize;
      await processChunk(start, end);
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> _startProcessing() async {
    if (_isProcessing) return;
    _isProcessing = true;
    _statusController.add(List.unmodifiable(_queue));

    try {
      while (_isProcessing && !_isPaused) {
        // Find next pending tasks up to max concurrency
        final pendingTasks = _queue
            .where((t) =>
                t.status == BatchTaskStatus.pending &&
                !_activeTaskIds.contains(t.id))
            .take(_maxConcurrentTasks - _activeTaskIds.length)
            .toList();

        if (pendingTasks.isEmpty && _activeTaskIds.isEmpty) break;

        // Check resource throttling before starting new tasks
        if (pendingTasks.isNotEmpty && await _shouldThrottle()) {
          debugPrint('Batch processing throttled due to high resource usage');
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        if (pendingTasks.isEmpty) {
          // Wait for some active tasks to finish
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        // Start tasks in parallel
        for (final task in pendingTasks) {
          _activeTaskIds.add(task.id);
          _processTask(task).then((_) {
            _activeTaskIds.remove(task.id);
            _checkAndStartProcessing();
          });
        }

        // Wait a bit before next loop to avoid tight loop
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      if (_activeTaskIds.isEmpty) {
        _isProcessing = false;
        _statusController.add(List.unmodifiable(_queue));

        // Notify on completion if queue is empty of pending/processing
        final hasRemaining = _queue.any((t) =>
            t.status == BatchTaskStatus.pending ||
            t.status == BatchTaskStatus.processing);
        if (!hasRemaining) {
          _notifyCompletion();
        }
      }
    }
  }

  Future<void> _processTask(BatchTask task) async {
    debugPrint('Processing batch task: ${task.title}');

    // Update status to processing
    task.status = BatchTaskStatus.processing;
    task.startedAt = DateTime.now();
    task.progress = 0.1;
    await _storageService.saveBatchTask(task);
    _statusController.add(List.unmodifiable(_queue));

    try {
      // Check for early cancellation
      if (_cancellationTokens[task.id] == true) {
        throw 'Cancelled by user';
      }

      final file = File(task.filePath);
      if (!await file.exists()) {
        throw Exception('File not found: ${task.filePath}');
      }

      // Integration with VaultService
      await _vaultService.saveDocumentWithAutoCategory(
        imageFile: file,
        title: task.title,
        onProgress: (status) async {
          // Check for cancellation during progress updates
          if (_cancellationTokens[task.id] == true) {
            throw 'Cancelled by user';
          }

          // Update progress based on status messages
          if (status.contains('Analyzing')) task.progress = 0.3;
          if (status.contains('Generating')) task.progress = 0.6;
          if (status.contains('Saving')) task.progress = 0.8;

          await _storageService.saveBatchTask(task);
          _statusController.add(List.unmodifiable(_queue));
        },
      );

      // Task completed successfully
      task.status = BatchTaskStatus.completed;
      task.progress = 1.0;
      task.completedAt = DateTime.now();
      await _storageService.saveBatchTask(task);

      // Update storage usage after each successful task
      await _storageUsageService.calculateStorageUsage();
    } catch (e) {
      if (e == 'Cancelled by user') {
        debugPrint('Batch task ${task.id} cancelled');
        task.status = BatchTaskStatus.cancelled;
      } else {
        debugPrint('Error processing batch task ${task.id}: $e');
        task.status = BatchTaskStatus.failed;
        task.error = e.toString();
      }
      await _storageService.saveBatchTask(task);
    } finally {
      _cancellationTokens.remove(task.id);
      _statusController.add(List.unmodifiable(_queue));
    }
  }

  Future<bool> _shouldThrottle() async {
    try {
      // 1. Check Memory Pressure
      final memoryStatus =
          _memoryMonitor.lastStatus ?? await _memoryMonitor.refresh();
      if (memoryStatus.level == MemoryPressureLevel.critical) {
        debugPrint(
            'Throttling: Critical memory pressure (${memoryStatus.usagePercentage.toStringAsFixed(1)}%)');
        return true;
      }

      // 2. Check Battery Level
      final batteryLevel = await _batteryMonitor.batteryLevel;
      final batteryState = await _batteryMonitor.batteryState;
      final isCharging = batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;

      if (!isCharging &&
          batteryLevel < BatteryMonitorService.criticalThreshold) {
        debugPrint('Throttling: Critical battery level ($batteryLevel%)');
        return true;
      }

      // 3. Check Platform Capabilities
      final capabilities = await PlatformDetector().getCapabilities();
      if (!capabilities.supports(DeviceCapability.highRam) &&
          memoryStatus.level == MemoryPressureLevel.warning) {
        debugPrint('Throttling: Warning memory pressure on low-RAM device');
        return true;
      }

      // 4. Check Storage Space
      final isStorageOk =
          await _storageUsageService.isStorageSufficient(requiredMB: 500);
      if (!isStorageOk) {
        debugPrint('Throttling: Insufficient storage space');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking throttle conditions: $e');
      return false;
    }
  }

  void _notifyCompletion() {
    final completedCount =
        _queue.where((t) => t.status == BatchTaskStatus.completed).length;
    final failedCount =
        _queue.where((t) => t.status == BatchTaskStatus.failed).length;

    String body = 'Processed $completedCount documents successfully.';
    if (failedCount > 0) {
      body += ' $failedCount tasks failed.';
    }

    _notificationService.showDesktopNotification(
      id: 'batch_processing_complete',
      title: 'Batch Processing Complete',
      body: body,
      groupKey: 'batch_processing',
    );
  }

  Future<void> cancelTask(String taskId) async {
    final task = _queue.firstWhere((t) => t.id == taskId);

    if (task.status == BatchTaskStatus.processing) {
      _cancellationTokens[taskId] = true;
    } else if (task.status == BatchTaskStatus.pending) {
      task.status = BatchTaskStatus.cancelled;
      await _storageService.saveBatchTask(task);
      _loadQueue();
    }
  }

  Future<void> retryTask(String taskId) async {
    final index = _queue.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _queue[index];
      task.status = BatchTaskStatus.pending;
      task.progress = 0.0;
      task.error = null;
      await _storageService.saveBatchTask(task);
    }
  }

  Future<void> clearCompleted() async {
    final toDelete = _queue
        .where((t) =>
            t.status == BatchTaskStatus.completed ||
            t.status == BatchTaskStatus.cancelled ||
            t.status == BatchTaskStatus.failed)
        .map((t) => t.id)
        .toList();

    for (final id in toDelete) {
      await _storageService.deleteBatchTask(id);
    }
  }

  Future<void> clearAll() async {
    _isProcessing = false;
    for (final task in _queue) {
      await _storageService.deleteBatchTask(task.id);
    }
  }

  void dispose() {
    _boxSubscription?.cancel();
    _statusController.close();
  }
}
