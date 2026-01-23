# Changelog - Sehat Locker

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
