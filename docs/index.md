# Sehat Locker Project Documentation

Welcome to the comprehensive documentation for **Sehat Locker**, a privacy-first, local-only medical record management and AI-powered health assistant application.

## **Overview**

Sehat Locker is designed to give users full control over their medical data. Unlike traditional health apps that store data in the cloud, Sehat Locker keeps all sensitive information—including medical records, doctor visit recordings, and AI-generated insights—exclusively on the user's device.

### **Core Principles**
- **Privacy First**: No data leaves the device unless explicitly exported by the user.
- **Local AI**: AI processing (OCR, extraction, assistant) happens on-device using local models, with safety validation and citations where applicable.
- **Secure Storage**: Data is stored in encrypted local databases (Hive with AES-256).
- **Transparency**: Every action that affects data privacy is audited and visible to the user.

---

## **App Structure**

### **UI Targets (Mobile vs Desktop)**
Sehat Locker maintains **two UI targets**:
- **Mobile**: iPhone, Android
- **Desktop**: iPad, macOS, Windows

Target selection is handled by **[UiTargetResolver](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ui_target_resolver.dart)**, and each target has its own UI implementation:
- Mobile UI: `lib/ui/mobile/` (containing mobile-optimized screens like `MobileDocumentsScreen`, `SettingsScreen`)
- Desktop UI: `lib/ui/desktop/` (containing desktop-optimized screens like `DesktopDocumentsScreen`, `DesktopSettingsScreen`)
- Desktop UI widgets: `lib/ui/desktop/widgets/` (e.g. `DesktopDocumentGridCard` for document preview/snippet cards)
- Shared, layout-agnostic widgets: `lib/shared/widgets/`

### **Entrypoints & Boot Sequence**
- Environment entrypoints: [main_dev.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/main_dev.dart), [main_staging.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/main_staging.dart), [main_prod.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/main_prod.dart)
- Shared initialization + boot flow: [main_common.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/main_common.dart)
- Runtime configuration: [app_config.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/config/app_config.dart)

The boot flow typically initializes storage/services, performs platform capability checks, resolves the UI target, then routes into onboarding vs the main shell.

---

## **Services**

The application logic is modularized into specialized services, each handling a specific domain of functionality.

### **Bootstrap, Targeting & Platform**
- **[UiTargetResolver](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ui_target_resolver.dart)**: Maps platforms into Mobile vs Desktop targets (iPad is Desktop).
- **[PlatformDetector](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/platform_detector.dart)**: Centralized platform/capability detection (used for feature gating).
- **[PlatformService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/platform_service.dart)**: Abstraction layer for platform-specific capabilities.
- **[OnboardingService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/onboarding_service.dart)**: Stores onboarding progress and determines initial routing.
- **[PermissionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/permission_service.dart)**: Centralized permission checks/requests (desktop flows may auto-complete where OS-native permissions apply).

### **Data & Storage Services**
- **[LocalStorageService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/local_storage_service.dart)**: Manages encrypted Hive boxes for health records, settings, and audits.
- **[EncryptionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/encryption_service.dart)**: Provides cryptographic primitives for data protection.
- **[SearchService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/search_service.dart)**: Orchestrates the ObjectBox search index for fast, local full-text search.
- **[VaultService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/vault_service.dart)**: High-level API for saving and retrieving complex health entities (conversations, extractions) from the secure vault. Includes getDocumentsByDateRange() for chronologically-aware document retrieval using extracted and user-corrected document dates.

### **AI & Extraction Services**
- **[AIService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_service.dart)**: Core interface for interacting with local LLMs.
- **[LLMEngine](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/llm_engine.dart)**: Manages the lifecycle and execution of the on-device Large Language Model.
- **[OCRService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ocr_service.dart)**: Extracts text from images (and rasterized PDFs) of medical documents, and supports plain-text inputs for ingestion/analysis.
- **[DataExtractionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/data_extraction_service.dart)**: High-level service that coordinates OCR and LLM-based extraction.
- **[MedicalFieldExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/medical_field_extractor.dart)**: Specialized logic for identifying medical entities in unstructured text.
- **[DateValidationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/date_validation_service.dart)**: Validates document dates for chronological plausibility and prevents impossible dates from entering the vault.
- **[OutputPipeline](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_middleware/output_pipeline.dart)**: Middleware pipeline for assistant output processing (safety, validation, citations, analytics).
- **[SafetyFilterService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/safety_filter_service.dart)**: Validates outputs against medical safety and policy constraints.
- **[HallucinationValidationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/hallucination_validation_service.dart)**: Adds guardrails to reduce unsupported medical assertions.
- **[CitationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/citation_service.dart)**: Generates citations for AI-produced statements when source context is available.
- **[AIRecoveryService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_recovery_service.dart)**: Error recovery/fallback handling for model initialization and generation failures.
- **[AIAnalyticsService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_analytics_service.dart)**: Local-only usage metrics (performance + token usage) for debugging and transparency.
- **[GenerationParametersService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/generation_parameters_service.dart)**: User-configurable generation controls (temperature, top-p, max tokens).
- **[ModelVerificationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/model_verification_service.dart)**: Local integrity checks for downloaded models.
- **[ModelUpdateService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/model_update_service.dart)**: Local model update orchestration.
- **[ModelLicenseService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/model_license_service.dart)**: Tracks/validates licensing information for bundled/downloaded models.
- **[ModelQuantizationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/model_quantization_service.dart)**: Quantization format selection and related trade-offs.

### **Media & Transcription Services**
- **[ConversationRecorderService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/conversation_recorder_service.dart)**: Handles audio recording of doctor visits with privacy guards.
- **[TranscriptionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/transcription_service.dart)**: Converts recorded audio into text locally.
- **[AudioPlaybackService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/audio_playback_service.dart)**: Manages playback of encrypted medical recordings.

### **Export & Reporting Services**
- **[ExportService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/export_service.dart)**: Orchestrates secure export flows (documents, follow-ups, transcripts) with auditing.
- **[PdfExportService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/pdf_export_service.dart)**: Generates PDF exports for sharing/printing.

### **Security & Compliance Services**
- **[BiometricService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/biometric_service.dart)**: Integrates with device biometric hardware for secure app access.
- **[PinAuthService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/pin_auth_service.dart)**: Manages the secure PIN fallback mechanism.
- **[SessionManager](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/session_manager.dart)**: Manages session timeouts, locking, and security-related lifecycle state.
- **[ComplianceService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/compliance_service.dart)**: Monitors the app's state against developer and privacy compliance checklists.
- **[LocalAuditService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/local_audit_service.dart)**: Records all privacy-sensitive actions in a tamper-evident local log.
- **[AuthAuditService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/auth_audit_service.dart)**: Audit logging for authentication events (PIN/biometric).
- **[ConsentService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/consent_service.dart)**: Stores and manages user consent records for policies and legal acceptance.
- **[PrivacyManifestService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/privacy_manifest_service.dart)**: Canonical registry of privacy promises and enforcement rules.
- **[TempFileManager](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/temp_file_manager.dart)**: Secure temp file lifecycle and cleanup for sensitive exports and processing artifacts.

### **Desktop & System Integration Services**
- **[WindowManagerService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/window_manager_service.dart)**: Desktop window sizing, persistence, and restoration.
- **[SystemTrayService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/system_tray_service.dart)**: System tray controls and status integration on desktop.
- **[DesktopNotificationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/desktop_notification_service.dart)**: Desktop notification dispatch and privacy masking.
- **[KeyboardShortcutService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/keyboard_shortcut_service.dart)**: Keyboard shortcuts for desktop workflows.
- **[FileDropService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/file_drop_service.dart)**: Drag-and-drop ingestion and folder drop workflows on desktop.


---

## **Models & Data Structures**

### **Hive Type IDs**
The following models are persisted in Hive with the specified `typeId`:

| Model | Type ID | Description |
| :--- | :---: | :--- |
| [HealthRecord](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/health_record.dart) | 0 | Metadata for all medical records. |
| [AppSettings](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/app_settings.dart) | 1 | Global application configuration (Theme, Font Scale, Privacy, AI). |
| [ModelMetadata](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/model_metadata.dart) | 3 | Information about downloaded/available LLM models. |
| [DocumentExtraction](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/document_extraction.dart) | 4 | Structured data extracted from medical documents. Includes extracted document dates (Hive Field 22) and user-corrected dates (Hive Field 23) for chronology validation. |
| [DoctorConversation](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/doctor_conversation.dart) | 5 | Transcripts and summaries of recorded doctor visits. |
| [ConversationSegment](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/doctor_conversation.dart) | 6 | Timestamped conversation segments (speaker + text). |
| [FollowUpItem](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/follow_up_item.dart) | 7 | Extracted tasks and reminders from medical visits. |
| [FollowUpCategory](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/follow_up_item.dart) | 8 | Follow-up type classification (appointment, medication, test). |
| [FollowUpPriority](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/follow_up_item.dart) | 9 | Follow-up priority (high/normal). |
| [RecordingAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/recording_audit_entry.dart) | 10 | Audit log for audio recording starts/stops. |
| [ExportAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/export_audit_entry.dart) | 11 | Audit log for export actions (type, format, recipient). |
| [EnhancedPrivacySettings](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/enhanced_privacy_settings.dart) | 12 | Additional privacy controls (biometric gates, retention, masking). |
| [AuthAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/auth_audit_entry.dart) | 13 | Audit log for biometric and PIN authentication attempts. |
| [Citation](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/citation.dart) | 14 | References to source documents for AI-generated text. |
| [IssueReport](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/issue_report.dart) | 15 | Local storage for user-reported app issues. |
| [ConsentEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/consent_entry.dart) | 16 | Records of user acceptance of Privacy Policy/TOS. |
| [LocalAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/local_audit_entry.dart) | 17 | General purpose tamper-evident audit logs. |
| [ConversationMemory](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/conversation_memory.dart) | 25 | Contextual memory for the AI assistant. |
| [MemoryEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/conversation_memory.dart) | 26 | Individual assistant/user turns stored in memory history. |
| [GenerationParameters](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/generation_parameters.dart) | 31 | LLM generation parameter presets and user overrides. |
| [AIUsageMetric](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/ai_usage_metric.dart) | 32 | Local tracking of AI token usage and performance. |
| [BatchTaskStatus](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/batch_task.dart) | 33 | Background task status (pending/processing/completed). |
| [BatchTaskPriority](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/batch_task.dart) | 34 | Background task priority (low/normal/high). |
| [BatchTask](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/batch_task.dart) | 35 | Status and details of background processing tasks. |
| [UserProfile](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/user_profile.dart) | 40 | Local demographic data for health personalization. |
| [QuantizationFormat](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/model_quantization_service.dart) | 41 | Quantization formats for local LLM models. |
| [HealthPatternInsight](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/health_pattern_insight.dart) | 42 | Persisted on-device, non-diagnostic pattern insights with source attribution. |
| [MetricSnapshot](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/metric_snapshot.dart) | 68 | Latest verified health metric values with source attribution for FDA compliance. |

### **UI Components**

#### **Shared Widgets**
- **[MetricCard](file:///Users/fam/Documents/Projects/sehatlocker/lib/ui/shared/widgets/profile/metric_card.dart)**: Shared health metric card extending GlassCard with source attribution and reference range display.

#### **Mobile Screens**
- **[ProfileHealthDashboardMobile](file:///Users/fam/Documents/Projects/sehatlocker/lib/ui/mobile/screens/profile_health_dashboard_mobile.dart)**: Mobile health metrics dashboard with grid layout and pull-to-refresh.

#### **Desktop Screens**  
- **[ProfileHealthDashboardDesktop](file:///Users/fam/Documents/Projects/sehatlocker/lib/ui/desktop/screens/profile_health_dashboard_desktop.dart)**: Desktop health metrics dashboard with split-view sidebar navigation and detailed content area.

Other data structures exist that are not persisted in Hive (e.g., [EducationContent](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/education_content.dart), [MedicalTestDefinition](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/medical_test.dart)).

### **Exceptions**
- **[UnverifiedDataException](file:///Users/fam/Documents/Projects/sehatlocker/lib/exceptions/unverified_data_exception.dart)**: FDA compliance exception thrown when attempting to access health metrics before Phase 1 completion.

### **ObjectBox Entities**
- **[SearchEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/search_entry.dart)**: The primary entity for the local search engine, containing searchable text and metadata links.

---

## **Key Workflows**
### **Boot & Target Selection**
The boot flow is orchestrated in [main_common.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/main_common.dart) and typically:
1. Loads runtime config ([app_config.dart](file:///Users/fam/Documents/Projects/sehatlocker/lib/config/app_config.dart)).
2. Initializes encrypted storage and critical services.
3. Resolves UI target ([UiTargetResolver](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ui_target_resolver.dart)).
4. Applies platform capability checks ([PlatformDetector](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/platform_detector.dart)).
5. Routes into onboarding vs the main shell ([OnboardingService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/onboarding_service.dart)).


### **Onboarding Flow**
The onboarding process is a multi-step journey managed by the **[OnboardingNavigator](file:///Users/fam/Documents/Projects/sehatlocker/lib/screens/onboarding/onboarding_navigator.dart)**:
1. **Splash Screen**: Initial brand and privacy indicator.
2. **Welcome Carousel**: Feature introduction.
3. **Consent Acceptance**: Legally-compliant acceptance of Privacy Policy and Terms.
4. **Permissions Request**: Guided requests for Camera, Microphone, and Notifications (desktop platforms may auto-complete where the OS manages access on use).
5. **Security Setup**: PIN and Biometric enrollment.
6. **Personalized Profile**: Local entry of name, sex, and DOB for better lab result calibration.
7. **Feature Tour**: Interactive walkthrough of key app capabilities.
8. **First Scan Guide**: Step-by-step guidance for the user's first document capture.
### **Session Lock & Secure Access**
Sehat Locker enforces session security via:
- **[SessionManager](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/session_manager.dart)**: Timeouts and lock state.
- **[AuthGate](file:///Users/fam/Documents/Projects/sehatlocker/lib/widgets/auth_gate.dart)** and **[SessionGuard](file:///Users/fam/Documents/Projects/sehatlocker/lib/widgets/session_guard.dart)**: UI-level enforcement.


### **Extraction Pipeline**
When a document is scanned, it passes through the following stages:
1. **OCR**: Raw text is extracted locally on-device (Android uses Tesseract; iOS/macOS use Apple Vision; PDFs are rasterized to images before OCR).
2. **Classification**: AI identifies the type of document (Prescription, Lab Result, etc.) using deterministic pattern matching with confidence scoring.
3. **Categorization Screen**: Users review OCR results and AI suggestions, then manually select the appropriate category before saving.
4. **Field Extraction**: Specific extractors ([MedicationExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/extractors/medication_extractor.dart), [TestExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/extractors/test_extractor.dart), etc.) parse structured data.
5. **Date Extraction**: [MedicalFieldExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/medical_field_extractor.dart) extracts dates with context-aware confidence scoring, prioritizing header/footer dates as document creation dates.
6. **Chronology Validation**: [DateValidationService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/date_validation_service.dart) prevents chronologically impossible dates from entering the vault.
7. **Validation**: AI middleware stages (e.g. [SafetyFilterStage](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_middleware/stages/safety_filter_stage.dart), [HallucinationValidationStage](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_middleware/stages/hallucination_validation_stage.dart)) ensure outputs are safe and accurate.
8. **Extraction Verification**: Users must explicitly verify/correct extracted fields (including setting a document date) before saving.
9. **Vault Storage**: The structured data is encrypted and saved to the local vault.

### **Document Categorization Workflow**
All document ingestion methods (camera scanner, file drop, batch processing) now follow a unified categorization flow:
- **OCR Processing**: Documents are processed with on-device OCR to extract text
- **AI Classification**: Deterministic pattern matching suggests document categories with confidence scores
- **User Review**: Categorization screen shows OCR preview, suggestions, and manual category selection with a consistent, accessible UI.
- **Extraction Verification**: Verification screen requires explicit user confirmation/corrections of extracted fields before persistence, including document date validation with chronology checks.
- **Biometric Security**: Sensitive categories require biometric authentication before saving
- **Audit Logging**: Categorization and verification actions are logged for transparency, including document date corrections.

The categorization system supports 14 health document types including Lab Results, Prescriptions, Imaging Reports, Genetic Tests, and more.
### **Exports & Auditing**
- Exports are orchestrated by **[ExportService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/export_service.dart)** and may generate PDFs via **[PdfExportService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/pdf_export_service.dart)**.
- Export activity is tracked with **[ExportAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/export_audit_entry.dart)** and broader actions are tracked by **[LocalAuditService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/local_audit_service.dart)**.

### **Desktop Workflows (Tray, Windowing, Drag & Drop)**
- Tray and window persistence: **[SystemTrayService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/system_tray_service.dart)**, **[WindowManagerService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/window_manager_service.dart)**
- Drag-and-drop ingestion: **[FileDropService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/file_drop_service.dart)** and desktop widgets under `lib/ui/desktop/widgets/` - now includes categorization screen before saving to vault


---

## **Database Architecture**

Sehat Locker uses a hybrid storage approach:

1. **Hive (Key-Value)**:
   - Used for primary data storage (Health Records, Settings, Audits).
   - Encrypted with AES-256 using a key stored in the device's Secure Storage (Keystore/Keychain).
   - Highly performant for object storage and retrieval.

2. **ObjectBox (NoSQL / Search)**:
   - Used specifically for the **Search Index**.
   - Provides lightning-fast full-text search across all local data.
   - Synchronized automatically with Hive boxes via listeners in `SearchService`.

---

## **Programs & Utilities**

- **[ReferenceRangeService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/reference_range_service.dart)**: Evaluates lab results against age and sex-specific medical reference ranges.
- **[HealthMetricsAggregator](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/health_metrics_aggregator.dart)**: Computes latest values exclusively from user-verified documents with FDA compliance safeguards. Integrates with ReferenceRangeService but never computes diagnostic conclusions.
- **[MedicalDictionaryService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/medical_dictionary_service.dart)**: Provides a local database of medical terms and definitions.
- **[BatchProcessingService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/batch_processing_service.dart)**: Manages long-running tasks like OCR and model warming in the background.
- **[BatteryMonitorService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/battery_monitor_service.dart)**: Tracks battery state for long-running operations.
- **[MemoryMonitorService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/memory_monitor_service.dart)**: Monitors memory pressure for safe local AI execution.
- **[WidgetDataService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/widget_data_service.dart)**: Formats/redacts ICE data for native lock-screen widgets (Android/iOS).
- **[KeyboardShortcutService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/keyboard_shortcut_service.dart)**: Handles keyboard shortcuts for desktop users.

---

## **Platform Build Notes**

### **iOS**
- CocoaPods is required; see [ios/Podfile](file:///Users/fam/Documents/Projects/sehatlocker/ios/Podfile) and [ios/Podfile.lock](file:///Users/fam/Documents/Projects/sehatlocker/ios/Podfile.lock).
- If Simulator builds fail for OCR dependencies (SwiftyTesseract/libtesseract), the project excludes `arm64` for `iphonesimulator` and may require running the Simulator under Rosetta on Apple Silicon (see [CHANGELOG.md](file:///Users/fam/Documents/Projects/sehatlocker/CHANGELOG.md)).

### **macOS**
- CocoaPods is used; see [macos/Podfile](file:///Users/fam/Documents/Projects/sehatlocker/macos/Podfile) and [macos/Podfile.lock](file:///Users/fam/Documents/Projects/sehatlocker/macos/Podfile.lock).
- App Sandbox is enabled for the Runner target; see [DebugProfile.entitlements](file:///Users/fam/Documents/Projects/sehatlocker/macos/Runner/DebugProfile.entitlements).
