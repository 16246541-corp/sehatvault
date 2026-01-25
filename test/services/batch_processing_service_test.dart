import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive/hive.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sehatlocker/services/batch_processing_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';
import 'package:sehatlocker/services/vault_service.dart';
import 'package:sehatlocker/services/storage_usage_service.dart';
import 'package:sehatlocker/services/desktop_notification_service.dart';
import 'package:sehatlocker/services/memory_monitor_service.dart';
import 'package:sehatlocker/services/battery_monitor_service.dart';
import 'package:sehatlocker/models/batch_task.dart';
import 'package:flutter/foundation.dart';

import 'batch_processing_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<LocalStorageService>(),
  MockSpec<VaultService>(),
  MockSpec<StorageUsageService>(),
  MockSpec<DesktopNotificationService>(),
  MockSpec<MemoryMonitorService>(),
  MockSpec<BatteryMonitorService>(),
  MockSpec<Box<BatchTask>>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BatchProcessingService service;
  late MockLocalStorageService mockStorage;
  late MockVaultService mockVault;
  late MockStorageUsageService mockStorageUsage;
  late MockDesktopNotificationService mockNotifications;
  late MockMemoryMonitorService mockMemory;
  late MockBatteryMonitorService mockBattery;
  late MockBox mockBox;

  setUp(() {
    mockStorage = MockLocalStorageService();
    mockVault = MockVaultService();
    mockStorageUsage = MockStorageUsageService();
    mockNotifications = MockDesktopNotificationService();
    mockMemory = MockMemoryMonitorService();
    mockBattery = MockBatteryMonitorService();
    mockBox = MockBox();

    // Setup default mock behaviors
    when(mockStorage.getAllBatchTasks()).thenReturn([]);
    when(mockStorage.batchTasksListenable).thenReturn(ValueNotifier(mockBox));

    // Mock memory monitor
    when(mockMemory.lastStatus).thenReturn(null);
    when(mockMemory.refresh()).thenAnswer((_) async => MemoryStatus(
          totalRAMGB: 8.0,
          usedRAMGB: 4.0,
          availableRAMGB: 4.0,
          level: MemoryPressureLevel.normal,
          timestamp: DateTime.now(),
        ));

    // Mock battery monitor
    when(mockBattery.batteryLevel).thenAnswer((_) async => 80);
    when(mockBattery.batteryState)
        .thenAnswer((_) async => BatteryState.charging);

    // Mock storage usage
    when(mockStorageUsage.isStorageSufficient(
            requiredMB: anyNamed('requiredMB')))
        .thenAnswer((_) async => true);

    service = BatchProcessingService.internal(
      storageService: mockStorage,
      vaultService: mockVault,
      storageUsageService: mockStorageUsage,
      notificationService: mockNotifications,
      memoryMonitor: mockMemory,
      batteryMonitor: mockBattery,
    );
  });

  group('BatchProcessingService Tests', () {
    test('addTask adds a task to storage', () async {
      await service.addTask('Test Task', 'path/to/file');
      verify(mockStorage.saveBatchTask(any)).called(1);
    });

    test('addBatch adds multiple tasks to storage', () async {
      final items = [
        (title: 'Task 1', filePath: 'path/1'),
        (title: 'Task 2', filePath: 'path/2'),
      ];
      await service.addBatch(items);
      verify(mockStorage.saveBatchTask(any)).called(2);
    });

    test('pauseProcessing stops processing and sets paused state', () {
      service.pauseProcessing();
      expect(service.isPaused, true);
      expect(service.isProcessing, false);
    });

    test('resumeProcessing resets paused state', () {
      service.pauseProcessing();
      service.resumeProcessing();
      expect(service.isPaused, false);
    });

    test('clearCompleted deletes completed/failed/cancelled tasks', () async {
      final tasks = [
        BatchTask.create(title: 'T1', filePath: 'p1')
          ..status = BatchTaskStatus.completed,
        BatchTask.create(title: 'T2', filePath: 'p2')
          ..status = BatchTaskStatus.failed,
        BatchTask.create(title: 'T3', filePath: 'p3')
          ..status = BatchTaskStatus.pending,
      ];
      when(mockStorage.getAllBatchTasks()).thenReturn(tasks);

      // Trigger load queue
      service.initialize();

      await service.clearCompleted();

      verify(mockStorage.deleteBatchTask(tasks[0].id)).called(1);
      verify(mockStorage.deleteBatchTask(tasks[1].id)).called(1);
      verifyNever(mockStorage.deleteBatchTask(tasks[2].id));
    });

    test('cancelTask sets cancellation token for processing task', () async {
      final task = BatchTask.create(title: 'T1', filePath: 'p1')
        ..status = BatchTaskStatus.processing;
      when(mockStorage.getAllBatchTasks()).thenReturn([task]);

      service.initialize();
      await service.cancelTask(task.id);

      // We can't directly check private _cancellationTokens, but we can verify it doesn't
      // immediately change status to cancelled if it's processing (it waits for the loop)
      verifyNever(mockStorage.saveBatchTask(any));
    });

    test('cancelTask immediately cancels pending task', () async {
      final task = BatchTask.create(title: 'T1', filePath: 'p1')
        ..status = BatchTaskStatus.pending;
      when(mockStorage.getAllBatchTasks()).thenReturn([task]);

      service.initialize();
      await service.cancelTask(task.id);

      verify(mockStorage.saveBatchTask(argThat(predicate(
          (BatchTask t) => t.status == BatchTaskStatus.cancelled)))).called(1);
    });

    test('retryTask resets task to pending', () async {
      final task = BatchTask.create(title: 'T1', filePath: 'p1')
        ..status = BatchTaskStatus.failed
        ..error = 'Some error';
      when(mockStorage.getAllBatchTasks()).thenReturn([task]);

      service.initialize();
      await service.retryTask(task.id);

      verify(mockStorage.saveBatchTask(argThat(predicate((BatchTask t) =>
          t.status == BatchTaskStatus.pending &&
          t.error == null &&
          t.progress == 0.0)))).called(1);
    });
  });
}
