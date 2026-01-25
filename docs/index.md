# Sehat Locker Project Documentation

Welcome to the comprehensive documentation for **Sehat Locker**, a privacy-first, local-only medical record management and AI-powered health assistant application.

## **Overview**

Sehat Locker is designed to give users full control over their medical data. Unlike traditional health apps that store data in the cloud, Sehat Locker keeps all sensitive information—including medical records, doctor visit recordings, and AI-generated insights—exclusively on the user's device.

### **Core Principles**
- **Privacy First**: No data leaves the device unless explicitly exported by the user.
- **Local AI**: All AI processing (OCR, extraction, diagnostics) happens on-device using local LLMs.
- **Secure Storage**: Data is stored in encrypted local databases (Hive with AES-256).
- **Transparency**: Every action that affects data privacy is audited and visible to the user.

---

## **Services**

The application logic is modularized into specialized services, each handling a specific domain of functionality.

### **Data & Storage Services**
- **[LocalStorageService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/local_storage_service.dart)**: Manages encrypted Hive boxes for health records, settings, and audits.
- **[EncryptionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/encryption_service.dart)**: Provides cryptographic primitives for data protection.
- **[SearchService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/search_service.dart)**: Orchestrates the ObjectBox search index for fast, local full-text search.
- **[VaultService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/vault_service.dart)**: High-level API for saving and retrieving complex health entities (conversations, extractions) from the secure vault.

### **AI & Extraction Services**
- **[AIService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_service.dart)**: Core interface for interacting with local LLMs.
- **[LLMEngine](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/llm_engine.dart)**: Manages the lifecycle and execution of the on-device Large Language Model.
- **[OCRService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ocr_service.dart)**: Extracts text from images of medical documents.
- **[DataExtractionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/data_extraction_service.dart)**: High-level service that coordinates OCR and LLM-based extraction.
- **[MedicalFieldExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/medical_field_extractor.dart)**: Specialized logic for identifying medical entities in unstructured text.

### **Media & Transcription Services**
- **[ConversationRecorderService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/conversation_recorder_service.dart)**: Handles audio recording of doctor visits with privacy guards.
- **[TranscriptionService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/transcription_service.dart)**: Converts recorded audio into text locally.
- **[AudioPlaybackService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/audio_playback_service.dart)**: Manages playback of encrypted medical recordings.

### **Security & Compliance Services**
- **[BiometricService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/biometric_service.dart)**: Integrates with device biometric hardware for secure app access.
- **[PinAuthService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/pin_auth_service.dart)**: Manages the secure PIN fallback mechanism.
- **[ComplianceService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/compliance_service.dart)**: Monitors the app's state against developer and privacy compliance checklists.
- **[LocalAuditService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/local_audit_service.dart)**: Records all privacy-sensitive actions in a tamper-evident local log.

---

## **Models & Data Structures**

### **Hive Type IDs**
The following models are persisted in Hive with the specified `typeId`:

| Model | Type ID | Description |
| :--- | :---: | :--- |
| [HealthRecord](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/health_record.dart) | 0 | Metadata for all medical records. |
| [AppSettings](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/app_settings.dart) | 1 | Global application configuration and state. |
| [ModelMetadata](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/model_metadata.dart) | 3 | Information about downloaded/available LLM models. |
| [DocumentExtraction](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/document_extraction.dart) | 4 | Structured data extracted from medical documents. |
| [DoctorConversation](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/doctor_conversation.dart) | 5 | Transcripts and summaries of recorded doctor visits. |
| [FollowUpItem](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/follow_up_item.dart) | 7 | Extracted tasks and reminders from medical visits. |
| [RecordingAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/recording_audit_entry.dart) | 10 | Audit log for audio recording starts/stops. |
| [AuthAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/auth_audit_entry.dart) | 13 | Audit log for biometric and PIN authentication attempts. |
| [Citation](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/citation.dart) | 14 | References to source documents for AI-generated text. |
| [IssueReport](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/issue_report.dart) | 15 | Local storage for user-reported app issues. |
| [ConsentEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/consent_entry.dart) | 16 | Records of user acceptance of Privacy Policy/TOS. |
| [LocalAuditEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/local_audit_entry.dart) | 17 | General purpose tamper-evident audit logs. |
| [ConversationMemory](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/conversation_memory.dart) | 25 | Contextual memory for the AI assistant. |
| [AIUsageMetric](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/ai_usage_metric.dart) | 32 | Local tracking of AI token usage and performance. |
| [BatchTask](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/batch_task.dart) | 35 | Status and details of background processing tasks. |
| [UserProfile](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/user_profile.dart) | 40 | Local demographic data for health personalization. |

### **ObjectBox Entities**
- **[SearchEntry](file:///Users/fam/Documents/Projects/sehatlocker/lib/models/search_entry.dart)**: The primary entity for the local search engine, containing searchable text and metadata links.

---

## **Key Workflows**

### **Onboarding Flow**
The onboarding process is a multi-step journey managed by the **[OnboardingNavigator](file:///Users/fam/Documents/Projects/sehatlocker/lib/screens/onboarding/onboarding_navigator.dart)**:
1. **Splash Screen**: Initial brand and privacy indicator.
2. **Welcome Carousel**: Feature introduction.
3. **Consent Acceptance**: Legally-compliant acceptance of Privacy Policy and Terms.
4. **Permissions Request**: Guided requests for Camera, Microphone, and Notifications.
5. **Security Setup**: PIN and Biometric enrollment.
6. **Personalized Profile**: Local entry of name, sex, and DOB for better lab result calibration.
7. **Feature Tour**: Interactive walkthrough of key app capabilities.
8. **First Scan Guide**: Step-by-step guidance for the user's first document capture.

### **Extraction Pipeline**
When a document is scanned, it passes through the following stages:
1. **OCR**: Tesseract extracts raw text from the image.
2. **Classification**: AI identifies the type of document (Prescription, Lab Result, etc.).
3. **Field Extraction**: Specific extractors ([MedicationExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/extractors/medication_extractor.dart), [TestExtractor](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/extractors/test_extractor.dart), etc.) parse structured data.
4. **Validation**: AI Middleware ([SafetyFilterStage](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_middleware/stages/safety_filter_stage.dart), [HallucinationValidationStage](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/ai_middleware/stages/hallucination_validation_stage.dart)) ensures the extracted data is safe and accurate.
5. **Vault Storage**: The structured data is encrypted and saved to the local vault.

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
- **[MedicalDictionaryService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/medical_dictionary_service.dart)**: Provides a local database of medical terms and definitions.
- **[BatchProcessingService](file:///Users/fam/Documents/Projects/sehatlocker/lib/services/batch_processing_service.dart)**: Manages long-running tasks like OCR and model warming in the background.
- **[ShortcutManager](file:///Users/fam/Documents/Projects/sehatlocker/lib/managers/shortcut_manager.dart)**: Handles keyboard shortcuts for desktop users.
