# VaultService API Documentation

## Overview

The `VaultService` is a comprehensive document vault service that orchestrates the complete pipeline for saving medical documents to encrypted storage. It integrates OCR processing, data extraction, and encrypted Hive storage into a seamless workflow.

## Architecture

```
User Action (Scan Document)
    ↓
DocumentScannerScreen (Capture & Compress Image)
    ↓
VaultService.saveDocumentToVault()
    ↓
├─→ OCRService.processDocument() → DocumentExtraction
├─→ LocalStorageService.saveDocumentExtraction()
├─→ Create HealthRecord (linked to DocumentExtraction)
└─→ LocalStorageService.saveRecord()
    ↓
Encrypted Hive Storage
```

## Core Methods

### `saveDocumentToVault()`

Saves a document to the vault with manual category selection.

**Signature:**
```dart
Future<HealthRecord> saveDocumentToVault({
  required File imageFile,
  required String title,
  required String category,
  String? notes,
  Map<String, dynamic>? additionalMetadata,
  void Function(String status)? onProgress,
})
```

**Parameters:**
- `imageFile`: The image file to process (compressed image from scanner)
- `title`: User-provided title for the document
- `category`: One of: 'Medical Records', 'Lab Results', 'Prescriptions', 'Vaccinations', 'Insurance', 'Other'
- `notes`: Optional notes/description
- `additionalMetadata`: Optional additional metadata to store with the record
- `onProgress`: Optional callback for progress updates

**Returns:** The created `HealthRecord` object

**Progress Updates:**
1. "Extracting text from document..."
2. "Saving extraction data..."
3. "Creating health record..."
4. "Saving to encrypted vault..."
5. "Document saved successfully!"

**Example:**
```dart
final vaultService = VaultService(storageService);

final healthRecord = await vaultService.saveDocumentToVault(
  imageFile: File('/path/to/compressed_image.jpg'),
  title: 'Blood Test Results - Jan 2026',
  category: 'Lab Results',
  notes: 'Annual health checkup',
  additionalMetadata: {
    'doctor': 'Dr. Smith',
    'hospital': 'City Medical Center',
  },
  onProgress: (status) {
    print('Progress: $status');
  },
);

print('Saved with ID: ${healthRecord.id}');
print('Extraction ID: ${healthRecord.extractionId}');
```

---

### `saveDocumentWithAutoCategory()`

Saves a document with intelligent category detection based on extracted content.

**Signature:**
```dart
Future<HealthRecord> saveDocumentWithAutoCategory({
  required File imageFile,
  required String title,
  String? notes,
  Map<String, dynamic>? additionalMetadata,
  void Function(String status)? onProgress,
})
```

**Auto-Detection Logic:**
- **Lab Results**: If lab values are detected (e.g., "Hemoglobin: 14.5 g/dL")
- **Prescriptions**: If medications are detected (e.g., "Metformin 500mg")
- **Vaccinations**: If vaccination keywords found in vitals
- **Medical Records**: Default fallback

**Example:**
```dart
final healthRecord = await vaultService.saveDocumentWithAutoCategory(
  imageFile: File('/path/to/prescription.jpg'),
  title: 'Prescription - Dr. Johnson',
  notes: 'Antibiotics for infection',
  onProgress: (status) {
    print('Progress: $status');
  },
);

print('Auto-detected category: ${healthRecord.category}');
// Output: "Auto-detected category: Prescriptions"
```

---

### `getCompleteDocument()`

Retrieves a health record with its linked extraction data.

**Signature:**
```dart
Future<({HealthRecord record, DocumentExtraction? extraction})> getCompleteDocument(String healthRecordId)
```

**Returns:** A record containing both the `HealthRecord` and its linked `DocumentExtraction` (if available)

**Example:**
```dart
final completeDoc = await vaultService.getCompleteDocument(recordId);

print('Title: ${completeDoc.record.title}');
print('Category: ${completeDoc.record.category}');

if (completeDoc.extraction != null) {
  print('Confidence: ${completeDoc.extraction!.confidenceScore}');
  print('Extracted Text: ${completeDoc.extraction!.extractedText}');
  print('Structured Data: ${completeDoc.extraction!.structuredData}');
}
```

---

### `getAllDocuments()`

Retrieves all documents from the vault with their extraction data.

**Signature:**
```dart
Future<List<({HealthRecord record, DocumentExtraction? extraction})>> getAllDocuments()
```

**Example:**
```dart
final allDocs = await vaultService.getAllDocuments();

print('Total documents: ${allDocs.length}');

for (final doc in allDocs) {
  print('- ${doc.record.title} (${doc.record.category})');
  
  if (doc.extraction != null) {
    final structuredData = doc.extraction!.structuredData;
    
    if (structuredData.containsKey('labValues')) {
      final labValues = structuredData['labValues'] as List;
      print('  Lab values: ${labValues.length}');
    }
    
    if (structuredData.containsKey('medications')) {
      final medications = structuredData['medications'] as List;
      print('  Medications: ${medications.length}');
    }
  }
}
```

---

### `deleteDocument()`

Deletes a document and all associated data.

**Signature:**
```dart
Future<void> deleteDocument(String healthRecordId)
```

**What gets deleted:**
1. The `HealthRecord` from Hive
2. The linked `DocumentExtraction` from Hive
3. The original image file from storage

**Example:**
```dart
await vaultService.deleteDocument(recordId);
print('Document and all associated data deleted');
```

---

## Data Models

### HealthRecord

```dart
class HealthRecord {
  final String id;                    // UUID
  final String title;                 // User-provided title
  final String category;              // Document category
  final DateTime createdAt;           // Creation timestamp
  final DateTime? updatedAt;          // Last update timestamp
  final String? filePath;             // Path to image file
  final String? notes;                // User notes
  final Map<String, dynamic>? metadata; // Additional metadata
  final String? recordType;           // 'DocumentExtraction'
  final String? extractionId;         // Link to DocumentExtraction
}
```

**Metadata Fields (auto-populated):**
- `confidenceScore`: OCR confidence (0.0 - 1.0)
- `textLength`: Number of characters extracted
- `structuredFieldCount`: Number of structured data fields
- `autoDetectedCategory`: Boolean (if auto-detection was used)

### DocumentExtraction

```dart
class DocumentExtraction {
  final String id;                           // UUID
  final String originalImagePath;            // Path to original image
  final String extractedText;                // Raw OCR text
  final DateTime createdAt;                  // Creation timestamp
  final double confidenceScore;              // OCR confidence
  final Map<String, dynamic> structuredData; // Extracted structured data
}
```

**Structured Data Fields:**
- `labValues`: List of lab test results
- `medications`: List of medications with dosages
- `dates`: List of dates found in document
- `vitals`: List of vital signs

---

## Usage Patterns

### Pattern 1: Basic Document Saving

```dart
// Initialize services
final storageService = LocalStorageService();
await storageService.initialize();
final vaultService = VaultService(storageService);

// Save document
final record = await vaultService.saveDocumentToVault(
  imageFile: capturedImage,
  title: userProvidedTitle,
  category: selectedCategory,
  notes: userNotes,
);
```

### Pattern 2: Smart Auto-Category

```dart
// Let the system detect the category
final record = await vaultService.saveDocumentWithAutoCategory(
  imageFile: capturedImage,
  title: userProvidedTitle,
  onProgress: (status) {
    // Update UI with progress
    setState(() => _statusMessage = status);
  },
);
```

### Pattern 3: Document Analysis

```dart
// Get all documents
final allDocs = await vaultService.getAllDocuments();

// Filter by category
final labReports = allDocs.where(
  (doc) => doc.record.category == 'Lab Results'
).toList();

// Analyze extraction quality
final avgConfidence = labReports
    .where((d) => d.extraction != null)
    .map((d) => d.extraction!.confidenceScore)
    .reduce((a, b) => a + b) / labReports.length;

print('Average OCR confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
```

### Pattern 4: Document Search

```dart
// Search by title
final searchResults = (await vaultService.getAllDocuments())
    .where((doc) => doc.record.title.toLowerCase().contains(query.toLowerCase()))
    .toList();

// Search by extracted text
final textSearchResults = (await vaultService.getAllDocuments())
    .where((doc) => 
        doc.extraction?.extractedText.toLowerCase().contains(query.toLowerCase()) ?? false
    )
    .toList();
```

---

## Error Handling

The VaultService throws exceptions in the following cases:

1. **Image file not found**: OCRService throws if image doesn't exist
2. **OCR failure**: If Tesseract fails to process the image
3. **Storage failure**: If Hive operations fail
4. **Document not found**: When retrieving/deleting non-existent documents

**Best Practice:**
```dart
try {
  final record = await vaultService.saveDocumentToVault(
    imageFile: imageFile,
    title: title,
    category: category,
  );
  
  // Success handling
  showSuccessMessage('Document saved!');
  
} catch (e, stackTrace) {
  // Error handling
  debugPrint('Error saving document: $e');
  debugPrint('Stack trace: $stackTrace');
  
  showErrorDialog('Failed to save document: $e');
}
```

---

## Performance Considerations

1. **OCR Processing**: Can take 2-10 seconds depending on image quality and device
2. **Image Compression**: Always compress images before OCR (use `ImageService.compressImage()`)
3. **Background Processing**: OCR runs on main thread - show loading indicators
4. **Storage Impact**: Each document uses ~2-5MB (compressed image + extraction data)

---

## Security

- All data is encrypted using AES-256 encryption via Hive
- Encryption keys are stored in secure storage (FlutterSecureStorage)
- No data is transmitted over network
- All processing happens on-device

---

## Future Enhancements

Potential improvements for future versions:

1. **Batch Processing**: Save multiple documents in one operation
2. **Cloud Sync**: Optional encrypted cloud backup
3. **OCR Language Selection**: Support for multiple languages
4. **Advanced Search**: Full-text search with fuzzy matching
5. **Document Versioning**: Track changes to documents over time
6. **Export Functionality**: Export documents as PDF or JSON
