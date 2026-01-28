import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sehatlocker/services/vault_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/models/document_extraction.dart';

// Generate mock
@GenerateMocks([LocalStorageService])
import 'vault_service_categorization_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VaultService vaultService;
  late MockLocalStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockLocalStorageService();
    vaultService = VaultService(mockStorageService);

    // Default stubs
    when(mockStorageService.autoDeleteOriginal).thenReturn(false);
    when(mockStorageService.findDocumentExtractionByHash(any)).thenReturn(null);
  });

  test('saveProcessedDocument creates HealthRecord with correct fields',
      () async {
    final extraction = DocumentExtraction(
      originalImagePath: '/path/to/image.jpg',
      extractedText: 'text',
      structuredData: {},
      confidenceScore: 0.9,
    );

    // Stub saveHealthRecord to return a future
    when(mockStorageService.saveRecord(any, any)).thenAnswer((_) async {});
    // Stub saveDocumentExtraction to return a future
    when(mockStorageService.saveDocumentExtraction(any))
        .thenAnswer((_) async {});

    await vaultService.saveProcessedDocument(
      extraction: extraction,
      title: 'Title',
      category: 'Lab Results',
    );

    // Verify extraction saved
    verify(mockStorageService.saveDocumentExtraction(any)).called(1);

    // Verify record saved
    final captured =
        verify(mockStorageService.saveRecord(any, captureAny)).captured;
    final savedRecordMap = captured.first as Map<String, dynamic>;

    expect(savedRecordMap['title'], 'Title');
    expect(savedRecordMap['category'], 'Lab Results');
    expect(savedRecordMap['recordType'], HealthRecord.typeDocumentExtraction);
    expect(savedRecordMap['extractionId'], isNotNull);
  });
}
