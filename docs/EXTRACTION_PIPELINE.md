# Medical Data Extraction Pipeline

## Overview

The extraction pipeline is a two-stage system that processes medical document images and extracts structured data:

1. **OCR Stage** (`OCRService`): Converts images to text using Tesseract OCR with advanced preprocessing
2. **Extraction Stage** (`DataExtractionService`): Parses text using regex patterns to extract medical fields

## Architecture

```
Image File
    ↓
OCRService.processDocument()
    ↓
├─→ Image Preprocessing
│   ├─ Auto-rotation correction
│   ├─ Low-light enhancement
│   └─ Grayscale conversion
    ↓
├─→ Tesseract OCR
│   └─ Text extraction
    ↓
├─→ Text Cleaning
│   ├─ Noise removal
│   └─ Whitespace normalization
    ↓
├─→ DataExtractionService
│   ├─ Date extraction
│   ├─ Lab value extraction
│   ├─ Medication extraction
│   └─ Vitals extraction
    ↓
DocumentExtraction Object
    ↓
LocalStorageService (Hive)
```

## Usage

### Quick Start

```dart
import 'dart:io';
import 'package:sehatlocker/services/ocr_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';

// Process a medical document
final imageFile = File('/path/to/document.jpg');
final result = await OCRService.processDocument(imageFile);

// Access extracted data
print('Text: ${result.extractedText}');
print('Confidence: ${result.confidenceScore}');
print('Dates: ${result.structuredData['dates']}');
print('Lab Values: ${result.structuredData['lab_values']}');
print('Medications: ${result.structuredData['medications']}');
print('Vitals: ${result.structuredData['vitals']}');

// Save to database
final storage = LocalStorageService();
await storage.saveDocumentExtraction(result);
```

### Advanced Usage

#### Text-Only Extraction

```dart
// If you already have text and just need structured data
final text = "Hemoglobin: 14.5 g/dL\nGlucose: 95 mg/dL";
final data = DataExtractionService.extractStructuredData(text);
```

#### Custom Workflow

```dart
// Step-by-step control
final text = await OCRService.extractTextFromImage(imageFile);
final structuredData = DataExtractionService.extractStructuredData(text);

// Create custom DocumentExtraction
final extraction = DocumentExtraction(
  originalImagePath: imageFile.path,
  extractedText: text,
  structuredData: structuredData,
  confidenceScore: 0.85,
);
```

## Extracted Fields

### Dates
Supports multiple formats:
- `DD/MM/YYYY`, `MM/DD/YYYY`, `DD-MM-YYYY`
- `YYYY-MM-DD`
- `12 Jan 2023`, `January 12, 2023`

**Output**: `List<String>`

### Lab Values
Extracts medical test results with validation:
- Pattern: `Field Name: Value Unit`
- Example: `Hemoglobin: 14.5 g/dL`
- Validates against common medical terms and units

**Output**: `List<Map<String, String>>`
```dart
[
  {'field': 'Hemoglobin', 'value': '14.5', 'unit': 'g/dL'},
  {'field': 'Glucose', 'value': '95', 'unit': 'mg/dL'}
]
```

### Medications
Extracts drug names and dosages:
- Pattern: `DrugName Dosage`
- Example: `Metformin 500mg`
- Filters common words to reduce false positives

**Output**: `List<Map<String, String>>`
```dart
[
  {'name': 'Metformin', 'dosage': '500mg'},
  {'name': 'Lisinopril', 'dosage': '10mg'}
]
```

### Vitals
Extracts vital signs:
- **Blood Pressure**: `BP: 120/80`
- **Heart Rate**: `HR: 72 bpm`
- **Temperature**: `Temp: 98.6 F`

**Output**: `List<Map<String, String>>`
```dart
[
  {'name': 'Blood Pressure', 'value': '120/80'},
  {'name': 'Heart Rate', 'value': '72', 'unit': 'bpm'},
  {'name': 'Temperature', 'value': '98.6', 'unit': 'F'}
]
```

## Confidence Scoring

The pipeline calculates a confidence score (0.0 to 1.0) based on:
- **Base**: 0.5
- **+0.2**: If text was successfully extracted
- **+0.2**: If structured data was found
- **Max**: 1.0

## Database Integration

### Saving Extractions

```dart
final storage = LocalStorageService();
await storage.initialize();

// Save extraction
await storage.saveDocumentExtraction(extraction);

// Retrieve by ID
final retrieved = storage.getDocumentExtraction(extraction.id);

// Get all extractions
final all = storage.getAllDocumentExtractions();

// Delete extraction
await storage.deleteDocumentExtraction(extraction.id);
```

### Linking to HealthRecords

```dart
// Create a HealthRecord linked to a DocumentExtraction
final record = HealthRecord(
  id: const Uuid().v4(),
  title: 'Lab Results - Jan 2026',
  category: 'Lab Results',
  createdAt: DateTime.now(),
  recordType: HealthRecord.typeDocumentExtraction,
  extractionId: extraction.id,
);
```

## Customization

### Adding New Patterns

To add new extraction patterns, edit `DataExtractionService`:

```dart
// Add to extractStructuredData method
final Map<String, dynamic> structuredData = {
  'dates': _extractDates(normalizedText),
  'lab_values': _extractLabValues(normalizedText),
  'medications': _extractMedications(normalizedText),
  'vitals': _extractVitals(normalizedText),
  'custom_field': _extractCustomField(normalizedText), // Add here
};

// Implement extraction method
static List<String> _extractCustomField(String text) {
  final pattern = RegExp(r'your-pattern-here');
  return pattern.allMatches(text).map((m) => m.group(0)!).toList();
}
```

### Adjusting OCR Settings

Modify `OCRService.extractTextFromImage()`:

```dart
final String text = await FlutterTesseractOcr.extractText(
  processedImageFile.path,
  language: 'eng', // Change language
  args: {
    "psm": "3", // Page segmentation mode
    "preserve_interword_spaces": "1",
  },
);
```

## Performance Considerations

- **Image Size**: Images are preprocessed and optimized before OCR
- **Processing Time**: Typical processing takes 2-5 seconds per document
- **Memory**: Temporary files are cleaned up automatically
- **Offline**: Entire pipeline works offline (no cloud dependencies)

## Error Handling

```dart
try {
  final result = await OCRService.processDocument(imageFile);
} catch (e) {
  if (e.toString().contains('Image file not found')) {
    // Handle missing file
  } else if (e.toString().contains('OCR Extraction failed')) {
    // Handle OCR failure
  }
}
```

## Testing

See `examples/extraction_pipeline_example.dart` for comprehensive usage examples.

## Future Enhancements

Potential improvements:
- Machine learning-based field extraction
- Multi-language support
- Custom medical terminology dictionaries
- Confidence score refinement using ML
- Batch processing support
