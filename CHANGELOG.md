# Changelog - Sehat Locker

## [2026-01-23 19:10] - Microphone Permission Handling

### Added
- **PermissionService**: Created `lib/services/permission_service.dart` to handle runtime permissions.
  - **Microphone Permission**: Implemented `requestMicPermission()` with platform-specific rationale.
    - **iOS**: Added `NSMicrophoneUsageDescription` to `Info.plist`.
    - **Android**: Added `android.permission.RECORD_AUDIO` to `AndroidManifest.xml` and implemented rationale dialog support.
    - **Settings Redirect**: Handles `permanentlyDenied` state by guiding users to app settings.

## [2026-01-23 19:00] - Unit Tests for MedicalFieldExtractor

### Added
- **Unit Tests**: Created `test/medical_field_extractor_test.dart` to verify `MedicalFieldExtractor` functionality.
  - **Lab Values**: Verified extraction of lab values with various units and formats.
  - **Medications**: Verified extraction of medications including name, dosage, and frequency.
  - **Dates**: Verified extraction of dates in multiple formats.
  - **Aggregate Extraction**: Verified `extractAll` method.

### Fixed
- **MedicalFieldExtractor**:
  - **Lab Name Length**: Updated regex to support 2-letter lab names (e.g., "Hb").
  - **Medication Frequency**: Improved frequency extraction to handle combined phrases (e.g., "twice daily") and prioritize frequencies appearing after the medication.
  - **False Positives**: Added common lab terms (e.g., "hemoglobin", "glucose") to the exclusion list for medication extraction to prevent misclassification.

## [2026-01-23 18:55] - Accessibility: Voice Guidance

### Added
- **Voice Guidance**: Added real-time voice feedback during document scanning.
  - **Text-to-Speech**: Integrated `flutter_tts` to provide audible instructions.
  - **Real-time Analysis**: Analyzes camera stream frames for lighting and stability.
  - **Voice Cues**:
    - "More light needed" when the image is too dark.
    - "Good lighting detected" when lighting conditions improve.
    - "Hold steady" if the image is blurry/moving.
    - "Center your document" as a general guidance cue.
  - **Throttled Feedback**: Ensures voice cues are not repetitive or overwhelming.

## [2026-01-23 18:50] - Auto-Delete Original Image Setting

### Added
- **Auto-Delete Setting**: Added "Auto-delete Original" toggle in Settings > Storage.
  - **Privacy Control**: Allows users to automatically delete the original image file after successful extraction to save space and enhance privacy.
  - **VaultService Integration**: Updated `VaultService` to check this setting and remove the image file immediately after processing.
  - **UI Handling**: `DocumentDetailScreen` gracefully handles missing images by showing a placeholder icon.

## [2026-01-23 18:40] - PDF Export Functionality

### Added
- **PdfExportService**: Created `lib/services/pdf_export_service.dart` to generate PDF reports from document extractions.
  - **PDF Generation**: Uses `pdf` package to create a PDF document with:
    - **Header**: Document title, category, and date.
    - **Image**: Original document image scaled to fit.
    - **Structured Data**: Table displaying extracted key-value pairs.
    - **Original Text**: Raw OCR text for reference.
  - **Dependencies**: Added `pdf` package and downgraded `image` package to `^4.5.0` for compatibility.

## [2026-01-23 18:30] - Search UI & Integration

### Added
- **Documents Screen Search**: Added a search bar to `DocumentsScreen` to filter documents.
  - **Fuzzy Search Integration**: Connected `SearchService` to the UI to allow searching by extracted text content.
  - **Metadata Search**: Also supports searching by document title and category.
  - **Real-time Filtering**: Updates the document grid as the user types.

### Fixed
- **Vault Indexing**: Fixed issue where `VaultService` was not calling `SearchService.indexDocument` when saving new documents. Now documents are automatically indexed upon save.

## [2026-01-23 18:20] - Search Across Extracted Text

### Added
- **SearchService**: Implemented `lib/services/search_service.dart` to index extracted text from documents.
  - **Hive Indexing**: Uses a dedicated Hive box `search_index` to store an inverted index (Token -> List<DocID>).
  - **Fuzzy Search**: Implements search with Levenshtein distance for typo tolerance and partial matches.
  - **Automatic Indexing**: Integrated with `VaultService` to automatically index new documents and remove deleted ones.
  - **Startup Check**: Added `ensureIndexed()` in `main.dart` to index existing documents on app launch if the index is empty.
- **LocalStorageService**: Added support for `search_index` box.

## [2026-01-23 18:10] - Document Detail View

### Added
- **DocumentDetailScreen**: Implemented full detail view for documents (`lib/screens/document_detail_screen.dart`).
  - **Full Screen Image**: Tapping the document image opens a zoomable full-screen viewer using `photo_view`.
  - **Metadata Display**: Shows document title, category, date, and notes.
  - **Extracted Data**: Displays all structured data extracted from the document (OCR results) in a glass card.
  - **Raw Text**: Shows the raw OCR text for reference.
  - **Delete Action**: Added delete functionality with confirmation dialog.
- **Navigation**: Connected `DocumentsScreen` grid items to the detail view.

## [2026-01-23 18:05] - Documents Grid Implementation

### Added
- **Documents Grid**: Replaced placeholder categories with a functional grid displaying saved documents.
  - **Real Data Integration**: Connected `DocumentsScreen` to `VaultService` to fetch and display actual `HealthRecord` data.
  - **DocumentGridCard**: Created a new widget to display document thumbnails, category badges, and formatted dates.
  - **Loading & Empty States**: Added loading indicators and handled empty states with a "Scan Document" prompt.
- **Service Access**: Updated `LocalStorageService` to include a singleton pattern for easier global access.

## [2026-01-23 18:00] - Empty State for Documents Tab

### Added
- **Documents Screen Empty State**: Implemented an empty state view for the Documents tab when no documents are found.
  - **Zero State UI**: Displays a friendly "No Documents Yet" message with an icon.
  - **Quick Action**: Added a prominent "+ Scan Document" button that directly opens the camera.
  - **State Management**: Updated `DocumentsScreen` to be stateful and support toggling between empty state and category grid.

## [2026-01-23 17:50] - Image Quality Feedback

### Added
- **Image Quality Feedback**: Warns user if the captured image is blurry or too dark.
  - **Blur Detection**: Uses Laplacian variance to detect blur.
  - **Brightness Detection**: Checks average luminance to prevent dark images.
  - **Interactive Feedback**: Dialog allows user to Retake or Keep the image.

## [2026-01-23 17:35] - Batch Document Processing

### Added
- **Batch Scanning Support**: Updated `DocumentScannerScreen` to allow capturing multiple pages before processing.
  - **Thumbnail Gallery**: Horizontal list of captured images with delete capability.
  - **Batch Controls**: "Done" button showing count of captured images (e.g., "Done (3)").
- **Batch Save Dialog**: Updated `SaveToVaultDialog` to handle multiple documents.
  - **Dynamic UI**: Title and text update based on number of documents selected.
  - **Progress Tracking**: Added `progressNotifier` to show real-time progress (e.g., "Processing 1/5...").
- **Sequential Processing**: Implemented sequential OCR and saving loop in `DocumentScannerScreen`.
  - **Auto-Naming**: Automatically appends index to document titles (e.g., "Lab Report 1", "Lab Report 2").
  - **Error Handling**: Robust error catching per batch.

## [2026-01-23 17:15] - Medical Dictionary
 
### Added
- **Offline Medical Dictionary**: Embedded `assets/data/medical_dictionary.json` containing 30+ common lab tests, units, and abbreviations.
- **MedicalDictionaryService**: Created `lib/services/medical_dictionary_service.dart` to load and parse dictionary data from assets.
- **MedicalDictionaryRegistry**: Implemented `lib/services/medical_dictionary_registry.dart` for pure Dart dictionary logic (type definitions, lookups, validation).
- **Pure Dart Support**: Added support for running dictionary method logic outside of Flutter (useful for CLI tools/testing) via `loadFromJsonString`.
- **Usage Example**: Added `examples/medical_dictionary_example.dart` demonstrating lookups, unit validation, and abbreviation expansion.

## [2026-01-23 17:10] - OCR Mobile Optimization

### Added
- **OCR optimization**: Image downscaling (max width 1024px) for faster processing.
- **OCR optimization**: Character whitelist to limit Tesseract search space for medical reports.

## [2026-01-23 17:20] - Document Type Classification

### Added
- **DocumentClassificationService**: Created `lib/services/document_classification_service.dart` to categorize documents based on keyword matching.
- **Auto-Categorization**: Integrated classifier into `DataExtractionService` to automatically tag extracted documents.
  - Supports: Lab Results, Prescriptions, Vaccinations, Insurance, Medical Records.
  - Keyword-based scoring system for accurate classification.
- **Vault Integration**: Updated `VaultService` to prioritize the new keyword-based classification for auto-saving documents.

## [2026-01-23 17:05] - Document Duplicate Detection

### Added
- **Duplicate Detection**: Implemented SHA-256 content hashing to prevent duplicate document extractions.
  - **Content Hashing**: Added `contentHash` field to `DocumentExtraction` model.
  - **Verification Logic**: `VaultService` checks for existing content hashes before saving new documents.
  - **UI Feedback**: `SaveToVaultDialog` now catches `DuplicateDocumentException` and displays a specific warning message ("This document already exists in your vault").
  - **Exception Handling**: Created `DuplicateDocumentException` for precise error control.

## [2026-01-23 16:35] - Save to Vault Action

### Added
- **VaultService**: Created comprehensive document vault service (`lib/services/vault_service.dart`) that orchestrates the complete document saving pipeline:
  - **Full OCR Pipeline Integration**: Automatically runs OCR processing, creates DocumentExtraction, and links to HealthRecord
  - **Encrypted Storage**: Saves both DocumentExtraction and HealthRecord to encrypted Hive boxes
  - **Manual Category Selection**: `saveDocumentToVault()` method allows users to specify title, category, and notes
  - **Auto-Category Detection**: `saveDocumentWithAutoCategory()` intelligently detects document type from extracted content:
    - Lab values → Lab Results
    - Medications → Prescriptions
    - Vaccination keywords → Vaccinations
    - Default → Medical Records
  - **Progress Callbacks**: Optional `onProgress` callback for real-time status updates during save operation
  - **Complete Document Retrieval**: Methods to fetch HealthRecord with linked DocumentExtraction data
  - **Smart Deletion**: `deleteDocument()` removes HealthRecord, DocumentExtraction, and associated image file
  - **Vault Statistics**: Helper methods to analyze vault contents and extraction quality
- **SaveToVaultDialog**: Created premium glassmorphic dialog (`lib/widgets/dialogs/save_to_vault_dialog.dart`) for document metadata collection:
  - **Form Validation**: Required title field with helpful placeholder text
  - **Category Dropdown**: All 6 health categories (Medical Records, Lab Results, Prescriptions, Vaccinations, Insurance, Other)
  - **Optional Notes**: Multi-line text field for additional context
  - **Loading States**: Shows progress indicator during OCR and save operations
  - **Error Handling**: User-friendly error messages with retry capability
  - **Glassmorphic Design**: Consistent with app's premium aesthetic
- **DocumentScannerScreen Integration**: Enhanced document scanner workflow:
  - **Seamless Save Flow**: After image capture and compression, automatically shows SaveToVaultDialog
  - **Complete Pipeline**: Image capture → Compression → OCR → Extraction → Vault storage
  - **User Feedback**: Success/error snackbars with icons and clear messaging
  - **Cancellation Support**: Users can cancel at any point without losing progress
- **Comprehensive Example**: Created detailed usage example (`examples/vault_service_example.dart`) demonstrating:
  - Manual category saving with metadata
  - Auto-category detection
  - Document retrieval (single and batch)
  - Complete document deletion
  - Vault statistics and analytics
- **Documentation & Testing**:
  - Added `VAULT_SERVICE_API.md` for comprehensive API reference
  - Added `test/vault_service_integration_test.dart` for end-to-end integration testing
  - Added `SAVE_TO_VAULT_SUMMARY.md` for implementation overview

### Technical Details
- **Service Architecture**: VaultService acts as orchestrator between OCRService, LocalStorageService, and data models
- **Data Linking**: HealthRecord stores `extractionId` to link to DocumentExtraction, enabling rich document queries
- **Metadata Enrichment**: Automatically adds confidence scores, text length, and field counts to HealthRecord metadata
- **Error Recovery**: Comprehensive try-catch blocks with detailed logging for debugging
- **Type Safety**: Uses Dart 3 record types for clean multi-value returns: `({HealthRecord record, DocumentExtraction? extraction})`
- **Memory Management**: Proper disposal of controllers and cleanup of temporary files

### Changed
- **DocumentScannerScreen Workflow**: Modified `_usePicture()` method to integrate vault saving instead of just returning image path
- **User Experience**: Enhanced feedback with icon-based snackbars and multi-step progress indication

## [2026-01-23 16:25] - Reference Range Lookup Service


### Added
- **ReferenceRangeService**: Created comprehensive lab test reference range lookup service (`lib/services/reference_range_service.dart`) with:
  - **Embedded Reference Data**: 50+ common lab tests with normal ranges across 6 categories:
    - Blood Count Tests (Hemoglobin, WBC, RBC, Platelets, Hematocrit, MCV, MCH, MCHC)
    - Metabolic Panel (Glucose, HbA1c, Creatinine, BUN, Electrolytes, Calcium)
    - Lipid Panel (Total Cholesterol, LDL, HDL, Triglycerides, VLDL)
    - Liver Function Tests (Bilirubin, AST/SGOT, ALT/SGPT, ALP, Albumin, Total Protein, GGT)
    - Thyroid Function (TSH, T3, T4, Free T3, Free T4)
    - Vitamins & Minerals (Vitamin D, B12, Folate, Iron, Ferritin)
  - **Gender-Specific Ranges**: Automatic handling of male/female reference ranges for tests like Hemoglobin, RBC, Hematocrit, Iron, and Ferritin
  - **Smart Matching Algorithm**: Intelligent test name matching with priority system:
    - Exact matches (highest priority)
    - Word boundary matches
    - Partial matches sorted by specificity
  - **Lab Value Evaluation**: Methods to evaluate single or multiple lab values against reference ranges:
    - `lookupReferenceRange()`: Find reference ranges for a test name
    - `evaluateLabValue()`: Evaluate a single value and determine if normal/low/high
    - `evaluateMultipleLabValues()`: Batch evaluation with summary statistics
  - **Category-Based Queries**: Helper methods to retrieve tests by category or list all available tests
- **Comprehensive Example**: Created detailed usage example (`examples/reference_range_example.dart`) demonstrating:
  - Simple reference range lookups
  - Single and multiple value evaluations
  - Gender-specific range handling
  - Category-based queries
  - Real-world scenario with OCR data processing and health recommendations

### Technical Details
- **Data Structure**: Each reference range includes test names (with aliases), unit, normal range (min/max), gender specification, age group, category, and description
- **Matching Logic**: Prevents false matches (e.g., "hemoglobin" won't match "mean corpuscular hemoglobin")
- **Return Format**: All evaluation methods return structured maps with status, matched range, message, and metadata
- **Summary Statistics**: Batch evaluations include counts of normal/low/high/unknown values and abnormal flags

## [2026-01-23 16:20] - Medical Field Extractor Service


### Added
- **MedicalFieldExtractor Service**: Created a dedicated service (`lib/services/medical_field_extractor.dart`) with granular extraction methods that return structured maps:
  - **extractLabValues()**: Extracts lab test results with categorization (blood, metabolic, lipid, liver, thyroid, vitamin)
    - Returns: `values` (list of lab results), `count`, `categories` (grouped by test type)
    - Each value includes: `field`, `value`, `unit`, `rawText`
  - **extractMedications()**: Extracts medication names, dosages, and frequencies
    - Returns: `medications` (list), `count`, `dosageUnits` (unique units found)
    - Each medication includes: `name`, `dosage`, `frequency`, `rawText`
  - **extractDates()**: Extracts dates in multiple formats with format detection
    - Returns: `dates` (list), `count`, `formats` (detected format types)
    - Each date includes: `value`, `format`, `rawText`
    - Supports: numeric slash, ISO date, day-month-year, month-day-year, full month formats
  - **extractAll()**: Comprehensive extraction combining all methods with summary statistics
- **Enhanced Pattern Matching**: Improved regex patterns with support for:
  - Extended medical units (µg/dL, ng/mL, pg/mL, cells/µL, x10^3/µL, etc.)
  - Medication frequency patterns (bid, tid, qid, od, bd, prn, etc.)
  - Multiple date format variations
- **Smart Categorization**: Automatic grouping of lab values by medical category for easier analysis
- **Example Implementation**: Created comprehensive usage example (`examples/medical_field_extractor_example.dart`) demonstrating all extraction methods

### Changed
- **Modular Architecture**: Separated field extraction logic into a dedicated service with public methods for better reusability
- **Structured Return Values**: All methods return detailed maps with metadata (counts, categories, formats) for enhanced data analysis

## [2026-01-23 16:17] - Medical Data Extraction Pipeline

### Added
- **DataExtractionService**: Created comprehensive regex-based extraction service (`lib/services/data_extraction_service.dart`) to parse medical fields from OCR text.
- **Structured Field Extraction**: Implemented pattern matching for:
  - **Dates**: Multiple formats (DD/MM/YYYY, YYYY-MM-DD, "12 Jan 2023", etc.)
  - **Lab Values**: Field name + numeric value + units (e.g., "Hemoglobin: 14.5 g/dL")
  - **Medications**: Drug names with dosages (e.g., "Metformin 500mg")
  - **Vitals**: Blood pressure, heart rate, temperature with units
- **Smart Filtering**: Implemented medical term validation using common lab terminology and unit patterns to reduce false positives.
- **Complete Pipeline**: Added `processDocument(File image)` method to `OCRService` that:
  1. Runs OCR with preprocessing
  2. Extracts structured data via regex patterns
  3. Calculates confidence scores
  4. Returns a complete `DocumentExtraction` object ready for storage

### Changed
- **OCRService Integration**: Extended `OCRService` to automatically populate `structuredData` field in `DocumentExtraction` objects.
- **Confidence Scoring**: Implemented heuristic-based confidence calculation based on text extraction success and structured data richness.

## [2026-01-23 16:12] - Document Extraction Data Model

### Added
- **DocumentExtraction Model**: Created a new data model (`lib/models/document_extraction.dart`) for storing OCR results, including UUID, image path, extracted text, confidence scores, and structured data maps.
- **Hive Persistence**: Generated Hive adapter for `DocumentExtraction` and registered it in `LocalStorageService` with `typeId: 4`.
- **Unique Identification**: Integrated `uuid` package for consistent document tracking across the local database.

## [2026-01-23 16:14] - HealthRecord Model Extension

### Changed
- **HealthRecord Expansion**: Extended `HealthRecord` class to support `recordType` and `extractionId`.
- **OCR Linking**: Added support for linking health records to specific `DocumentExtraction` results via their unique IDs.
- **Hive Update**: Regenerated Hive adapters to include new fields for persistent storage.

## [2026-01-23 16:11] - OCR Service API Implementation

### Added
- **API Function**: Implemented `extractTextFromImage(File image)` in `OCRService` for robust text extraction.
- **Advanced Preprocessing**: Added multi-stage image processing pipeline including auto-rotation, low-light enhancement (contrast/brightness boost), and grayscale conversion.
- **Cleaned Output**: Developed a text cleaning pipeline to remove OCR noise, normalize whitespace, and filter out non-alphanumeric artifacts.

## [2026-01-23 16:08] - Bug Fixes & Deprecation Resolution

### Fixed
- **Document Scanner Errors**: Fixed `EdgeInsets.bottom()` syntax error → corrected to `EdgeInsets.only(bottom: 20)`.
- **Image Preview**: Removed invalid `backgroundColor` parameter from `Image.file` widget, wrapped in `Container` with background color instead.
- **Async Context Safety**: Added `mounted` check before using `BuildContext` in async gap within `_takePicture()` method.

### Changed
- **Flutter 3.31+ Deprecations**: Replaced deprecated `activeColor` with `activeThumbColor` and `activeTrackColor` for all `Switch` widgets in Settings and Model Selection screens.
- **Flutter 3.32+ Deprecations**: Replaced deprecated `Radio<T>` widget (groupValue/onChanged) with custom icon-based selection using `Icons.radio_button_checked/unchecked`.
- **Performance Improvement**: Added `const` constructor to static `Icon` widget in Settings screen.
- **Library Documentation**: Fixed dangling library doc comment in `design_widgets.dart` by adding proper `library` directive.

### Added
- **Dependency**: Added `path` package to `pubspec.yaml` as a direct dependency (was previously used but not declared).

### Removed
- **Unused Imports**: Removed `liquid_glass_background.dart` import from `app.dart` and `glass_button.dart` import from `ai_screen.dart`.

## [2026-01-23 16:40] - Advanced OCR Preprocessing & Cleaning

### Added
- **Image Preprocessing**: Implemented `_preprocessImage` in `OCRService` using the `image` package to handle:
    - **Automatic Rotation**: Uses `bakeOrientation` to fix misoriented camera captures.
    - **Low-Light Enhancement**: Adjusts contrast and brightness for better visibility in dim conditions.
    - **Grayscale Conversion**: Converts images to grayscale to improve Tesseract's recognition accuracy.
- **Enhanced OCR Method**: Added `extractTextFromImage(File image)` for a more robust OCR workflow.
- **Text Cleaning Pipeline**: Implemented `_cleanText` to remove OCR noise, normalize whitespace, and filter out single-character artifacts.

### Changed
- **OCR Logic Refactoring**: Updated the original `extractText` method to leverage the new preprocessing and cleaning pipeline.
- **Dependency Update**: Added the `image` package for advanced on-device image manipulation.

## [2026-01-23 16:35] - Tesseract OCR Integration

### Added
- **OCR Service**: Integrated Tesseract OCR via `flutter_tesseract_ocr` for local image-to-text conversion.
- **Offline Language Packs**: Added English (`eng.traineddata`) language pack for offline processing.
- **OCR Service Layer**: Created `lib/services/ocr_service.dart` to handle text extraction from scanned medical documents.
- **TDS Configuration**: Set up `assets/tessdata/` structure for secure, offline handling of OCR models.

### Changed
- **Dependency Update**: Added `flutter_tesseract_ocr` to manage on-device optical character recognition without cloud dependencies.


## [2026-01-23 16:30] - Document Scanner & Image Optimization

### Added
- **Image Optimization Service**: Created `lib/services/image_service.dart` providing robust 2MP compression to balance image quality and processing performance.
- **Advanced Document Scanner**: Implemented a manual camera scanner with high-res capture support and automatic optimization.
- **A4 Guidance Overlay**: Added a high-precision A4-aspect ratio scanner frame with animated corner markers and guidance text.
- **Flash/Torch Control**: Integrated real-time flash/torch toggling for low-light document scanning.

### Changed
- **Premium Scanner UI**:
    - Refined the camera preview to utilize `BoxFit.cover` with `OverflowBox` for a seamless edge-to-edge experience.
    - Updated image preview to use `BoxFit.contain` with a dark cinematic background.
    - Implemented a branded "Optimizing for processing..." state with liquid glass feedback.
    - Enhanced ergonomics with bottom-weighted controls and clear feedback loops.
## [2026-01-23 16:20] - Camera Permissions & Device Integration

### Added
- **PermissionService**: Created `lib/services/permission_service.dart` with `requestCameraPermission()` to manage camera access requests.
- **Platform Configuration**: Configured Android and iOS manifests to support camera permissions.
- **iOS Permission Macro**: Enabled `PERMISSION_CAMERA` in `Podfile` for proper `permission_handler` integration on Apple devices.
- **Android Permissions**: Added `android.permission.CAMERA` to `AndroidManifest.xml`.
- **iOS Usage Description**: Added `NSCameraUsageDescription` to `Info.plist` for App Store compliance.

## [2026-01-23 16:15] - Offline-First Model Loading & Performance

### Added
- **Multi-Isolate Loading**: Implemented `compute()` for background model loading in `ModelManager`, offloading heavy SHA-256 verification and graph initialization to a background isolate.
- **Offline Cache Indicators**: Added "Cached" status chips to the `ModelSelectionScreen` UI to visually confirm models stored in app documents.
- **Background Isolate Parameters**: Created `_ModelLoadParams` for safe data transfer between the main thread and background tasks.

### Changed
- **Version-Aware Syncing**: Enhanced `downloadModelIfNotExists` to detect version changes and automatically re-download models if the metadata version differs from the local copy.
- **Optimized UI States**: Refined the transition between "Downloading", "Loading" (background), and "Cached" states for a smoother, premium user experience.
- **Storage Check Throttling**: Reduced simulated latency in storage verification for faster UI response.

## [2026-01-23 16:00] - Model Integrity Verification

### Added
- **SHA-256 Integrity Check**: Implemented mandatory SHA-256 hash verification in `ModelManager` before loading or completing a model download.
- **Crypto Integration**: Added `package:crypto` to the project for secure cryptographic operations.
- **Model Integrity Error Handling**: Enhanced `ModelSelectionScreen` to detect and display specific "Integrity Check Failed" errors to the user.

### Changed
- **Verified Download Simulation**: Updated model download stub to generate files with predictable content and verify them against real hashes stored in `ModelOption`.
- **ModelLoadException Expansion**: Added `isIntegrityIssue` flag to distinguish between filesystem errors and corruption/tampering.

## [2026-01-23 15:55] - Model Versioning & Metadata

### Added
- **ModelMetadata Class**: New data structure (`lib/models/model_metadata.dart`) to track AI model version, checksum, and release date.
- **Persistence Layer**: Integrated model metadata into `AppSettings` via Hive, ensuring versioning info is preserved across app updates.
- **Auto-Initialization**: Implemented logic in `LocalStorageService` to automatically populate model metadata in the settings box on the first app launch.
- **Checksum Support**: Added storage for model checksums to enable future model integrity verification.

## [2026-01-23 15:50] - Model Error Handling & Validation

### Added
- **Storage Validation**: Implemented `hasEnoughStorage` check in `ModelManager` to prevent failed downloads on limited devices.
- **Model Error Dialog**: Created `lib/widgets/dialogs/model_error_dialog.dart` featuring glassmorphism and intelligent "Lighter Model" recommendations.
- **Async Selection State**: Added loading indicators and radio button disabling in `ModelSelectionScreen` to prevent race conditions during model initialization.
- **Real-time Status Monitoring**: Integrated `isModelDownloaded` checks in both selection and status cards to reflect actual filesystem state.

### Changed
- **Robust Model Loading**: Refactored `downloadModelIfNotExists` to throw descriptive `ModelLoadException`s for better UI feedback.
- **Smart Downgrade Logic**: Implemented automated finding of the best alternative model when the primary selection fails due to storage constraints.

## [2026-01-23 15:47] - AI Dashboard Enhancements

### Added
- **ModelStatusCard Widget**: Created a new glass-styled widget (`lib/widgets/cards/model_status_card.dart`) that displays the currently active AI model, RAM usage estimates, and storage requirements.
- **Dynamic AI Dashboard**: Integrated the `ModelStatusCard` into the main AI screen (`lib/screens/ai_screen.dart`), replacing the static placeholder.

### Changed
- **Navigation Feedback**: Implemented automatic state refresh in `ModelStatusCard` after returning from the `ModelSelectionScreen` to ensure the UI reflects the user's choices immediately.

## [2026-01-23 15:38] - Model Download Simulation

### Added
- **Model Check & Download**: Implemented `downloadModelIfNotExists` in `ModelManager` to verify local storage for LLM files.
- **Path Provider Integration**: Added storage path detection using `path_provider` to manage model directories in application documents.
- **Download Stub**: Implemented a simulated 3-second download latency with dummy `config.json` creation for developer verification.

## [2026-01-23 15:35] - AppSettings & Hive Persistence

### Added
- **AppSettings Model**: Implemented `lib/models/app_settings.dart` with Hive annotations for persistent configuration.
- **Hive Adapter Integration**: Registered `AppSettingsAdapter` and `HealthRecordAdapter` in `LocalStorageService`.

### Changed
- **LocalStorageService Persistence**: Refactored settings management to use a structured `AppSettings` object instead of primitive keys.
- **Model Selection UI**: Updated `ModelSelectionScreen` to use the centralized `AppSettings` model for selection and auto-toggle states.
- **Settings Screen Integration**: Displayed current AI model name in settings and added auto-rebuild on navigation return.

## [2026-01-23 09:55] - Model Selection UI

### Added
- **AI Model Selection Screen**: Created `lib/screens/model_selection_screen.dart` to allow users to choose between local LLM models (TinyLlama, MedGemma, etc.).
- **Auto-select Logic**: Integrated hardware detection in the selection screen to recommend models based on device RAM.

### Changed
- **GlassCard Enhancement**: Added `borderColor` property to `lib/widgets/design/glass_card.dart` to support active selection highlighting.
- **Settings Navigation**: Updated `lib/screens/settings_screen.dart` to link 'Local LLM' to the new `ModelSelectionScreen`.
- **Project Protocol**: Established a mandatory changelog update and review process for all future coding tasks.

### Fixed
- **UI Consistency**: Fixed duplicated code blocks in `settings_screen.dart` and missing return statements in `model_selection_screen.dart`.
