import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:sehatlocker/models/app_settings.dart';
import 'package:sehatlocker/models/citation.dart';
import 'package:sehatlocker/models/doctor_conversation.dart';
import 'package:sehatlocker/models/document_extraction.dart';
import 'package:sehatlocker/models/enhanced_privacy_settings.dart';
import 'package:sehatlocker/models/generation_parameters.dart';
import 'package:sehatlocker/models/health_pattern_insight.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/models/local_audit_entry.dart';
import 'package:sehatlocker/models/model_metadata.dart';
import 'package:sehatlocker/models/user_profile.dart';
import 'package:sehatlocker/services/ai_service.dart';
import 'package:sehatlocker/services/battery_monitor_service.dart';
import 'package:sehatlocker/services/batch_processing_service.dart';
import 'package:sehatlocker/services/local_audit_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';
import 'package:sehatlocker/services/medical_field_extractor.dart';
import 'package:sehatlocker/services/reference_range_service.dart';
import 'package:sehatlocker/services/safety_filter_service.dart';
import 'package:sehatlocker/services/session_manager.dart';
import 'package:sehatlocker/services/health_intelligence_engine.dart';
import 'package:battery_plus/battery_plus.dart';

class _FakeBatteryMonitorService extends BatteryMonitorService {
  @override
  Future<int> get batteryLevel async => 100;

  @override
  Future<BatteryState> get batteryState async => BatteryState.full;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sehatlocker_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(EnhancedPrivacySettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(3))
      Hive.registerAdapter(ModelMetadataAdapter());
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(GenerationParametersAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(CitationAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(DocumentExtractionAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(DoctorConversationAdapter());
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ConversationSegmentAdapter());
    }
    if (!Hive.isAdapterRegistered(17))
      Hive.registerAdapter(LocalAuditEntryAdapter());
    if (!Hive.isAdapterRegistered(40))
      Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(42)) {
      Hive.registerAdapter(HealthPatternInsightAdapter());
    }

    await Hive.openBox('settings');
    await Hive.openBox('health_records');
    await Hive.openBox<DoctorConversation>('doctor_conversations');
    await Hive.openBox<Citation>('citations');
    await Hive.openBox<LocalAuditEntry>('local_audit_entries');
    await Hive.openBox<UserProfile>('user_profile');
    await Hive.openBox<HealthPatternInsight>('health_pattern_insights');
  });

  setUp(() async {
    await Hive.box('settings').clear();
    await Hive.box('health_records').clear();
    await Hive.box<DoctorConversation>('doctor_conversations').clear();
    await Hive.box<Citation>('citations').clear();
    await Hive.box<LocalAuditEntry>('local_audit_entries').clear();
    await Hive.box<UserProfile>('user_profile').clear();
    await Hive.box<HealthPatternInsight>('health_pattern_insights').clear();

    final settingsBox = Hive.box('settings');
    final appSettings = AppSettings.defaultSettings();
    appSettings.enhancedPrivacySettings =
        EnhancedPrivacySettings.defaultSettings()
          ..showHealthInsights = true
          ..requireBiometricsForSensitiveData = false
          ..userPrivacyThreshold = 0;
    appSettings.generationParameters =
        appSettings.generationParameters.copyWith(enablePatternContext: true);
    await settingsBox.put('app_settings_object', appSettings);

    final profileBox = Hive.box<UserProfile>('user_profile');
    await profileBox.put(
      'user_profile_object',
      UserProfile(
        displayName: 'Test',
        sex: 'male',
        dateOfBirth: DateTime(1986, 1, 1),
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('detects temporal correlation across 3+ conversations (sleep keywords)',
      () async {
    final convBox = Hive.box<DoctorConversation>('doctor_conversations');
    await convBox.put(
      'c1',
      DoctorConversation(
        id: 'c1',
        title: 'Visit Jan 10',
        duration: 0,
        encryptedAudioPath: '',
        transcript: 'I have trouble with sleep lately.',
        createdAt: DateTime.parse('2026-01-10T10:00:00Z'),
        followUpItems: const [],
        doctorName: '',
      ),
    );
    await convBox.put(
      'c2',
      DoctorConversation(
        id: 'c2',
        title: 'Visit Jan 17',
        duration: 0,
        encryptedAudioPath: '',
        transcript: 'Still tired and sleep is inconsistent.',
        createdAt: DateTime.parse('2026-01-17T10:00:00Z'),
        followUpItems: const [],
        doctorName: '',
      ),
    );
    await convBox.put(
      'c3',
      DoctorConversation(
        id: 'c3',
        title: 'Visit Jan 25',
        duration: 0,
        encryptedAudioPath: '',
        transcript: 'We discussed sleep hygiene.',
        createdAt: DateTime.parse('2026-01-25T10:00:00Z'),
        followUpItems: const [],
        doctorName: '',
      ),
    );

    final storage = LocalStorageService();
    final engine = HealthIntelligenceEngine(
      storage: storage,
      fieldExtractor: MedicalFieldExtractor(),
      referenceRanges: ReferenceRangeService(),
      safetyFilter: SafetyFilterService(),
      auditLogger: LocalAuditService(storage, SessionManager()),
    );

    final insights = await engine.detectAndPersistInsights(force: true);
    expect(
        insights.any((i) => i.patternType == 'conversation_keyword_temporal'),
        isTrue);
    final sleepInsight = insights
        .firstWhere((i) => i.patternType == 'conversation_keyword_temporal');
    expect(sleepInsight.timeframeIso8601, 'P15D');
    expect(sleepInsight.citations.length, greaterThanOrEqualTo(3));
  });

  test('detects lab value progression trends using reference ranges', () async {
    final recordsBox = Hive.box('health_records');

    Future<void> addDoc({
      required String recordId,
      required String extractionId,
      required String date,
      required String glucose,
    }) async {
      await recordsBox.put(recordId, {
        'id': recordId,
        'title': 'Lab Report $date',
        'category': 'Lab Results',
        'createdAt': date,
        'updatedAt': date,
        'filePath': '/tmp/$recordId.png',
        'notes': null,
        'recordType': HealthRecord.typeDocumentExtraction,
        'extractionId': extractionId,
        'metadata': {'sensitivityLevel': 0},
      });

      await recordsBox.put(
        extractionId,
        DocumentExtraction(
          id: extractionId,
          originalImagePath: '/tmp/$recordId.png',
          extractedText: 'Glucose $glucose mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'Glucose', 'value': glucose, 'unit': 'mg/dL'}
            ],
            'dates': [date],
          },
          createdAt: DateTime.parse(date),
        ),
      );
    }

    await addDoc(
      recordId: 'r1',
      extractionId: 'e1',
      date: '2026-01-01T00:00:00Z',
      glucose: '90',
    );
    await addDoc(
      recordId: 'r2',
      extractionId: 'e2',
      date: '2026-02-01T00:00:00Z',
      glucose: '100',
    );
    await addDoc(
      recordId: 'r3',
      extractionId: 'e3',
      date: '2026-03-01T00:00:00Z',
      glucose: '110',
    );

    final storage = LocalStorageService();
    final engine = HealthIntelligenceEngine(
      storage: storage,
      fieldExtractor: MedicalFieldExtractor(),
      referenceRanges: ReferenceRangeService(),
      safetyFilter: SafetyFilterService(),
      auditLogger: LocalAuditService(storage, SessionManager()),
    );

    final insights = await engine.detectAndPersistInsights(force: true);
    final glucoseTrend =
        insights.where((i) => i.patternType == 'lab_value_progression');
    expect(glucoseTrend, isNotEmpty);
    expect(
        glucoseTrend.first.summary.toLowerCase(), contains('trending upward'));
    expect(glucoseTrend.first.timeframeIso8601, 'P2M');
  });

  test(
      'safety filter rejects diagnostic phrases and allows non-diagnostic phrasing',
      () {
    final safety = SafetyFilterService();
    expect(safety.hasDiagnosticLanguage('prediabetic range'), isTrue);
    expect(safety.hasDiagnosticLanguage('glucose values trending upward'),
        isFalse);
  });

  test('batch processing throttled job supports pause/resume + cancellation',
      () async {
    final batch = BatchProcessingService.internal(
      batteryMonitor: _FakeBatteryMonitorService(),
    );

    var chunks = 0;
    final startedSecondChunk = Completer<void>();
    batch.pauseProcessing();

    final run = batch.runThrottledJob(
      jobId: 'test_job',
      totalUnits: 30,
      chunkSize: 10,
      processChunk: (start, end) async {
        chunks++;
        if (chunks == 2 && !startedSecondChunk.isCompleted) {
          startedSecondChunk.complete();
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      ignoreThrottle: true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(chunks, 0);
    batch.resumeProcessing();

    await startedSecondChunk.future.timeout(const Duration(seconds: 2));
    batch.cancelJob('test_job');

    expect(run, throwsA(isA<String>()));
  });

  test('output pipeline context enrichment when enablePatternContext=true',
      () async {
    final storage = LocalStorageService();
    final insight = HealthPatternInsight(
      id: 'i1',
      createdAt: DateTime.now(),
      title: 'Test Insight',
      summary: 'Test Summary',
      patternType: 'test',
      timeframeIso8601: 'P7D',
    );
    await storage.saveHealthPatternInsight(insight);

    final aiService = AIService();
    final metadata = await aiService.buildPatternContextMetadataForPipeline();
    expect(metadata['patternContextEnabled'], isTrue);
    expect((metadata['patternContext'] as String), contains('Test Insight'));
  });
}
