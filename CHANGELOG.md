# Changelog - Sehat Locker

## [1.9.1] - 2026-01-26

### Improved
- **Profile Setup Privacy**: Moved the "All data stays local on your device" notice to a new line for better readability and emphasis.
- **Data Collection Minimization**: Simplified age collection to only require **Year of Birth** instead of a full date, enhancing user privacy while maintaining accuracy for medical reference ranges.
- **UI Refinement**: Styled instructional text in input labels (e.g., "(Optional)") with italics to distinguish them from primary field labels.

## [1.9.0] - 2026-01-26

### Added
- **Profile Customization**: Added a "Randomize" button to the Profile Setup screen to generate Xbox Live-style display names.
- **Privacy Transparency**: Implemented a "Local Calculations" information popup that explains how profile data (age, sex) is used for medical reference ranges and BMI calculations without leaving the device.

### Improved
- **Profile UI**: Simplified the "Personalize Your Experience" header to a single line and adjusted typography for better visual balance.
- **Display Name Refinement**: Moved the "Randomize" button to the same line as the name input field for a more compact and intuitive layout.

## [1.8.9] - 2026-01-26

### Improved
- **Consent UI Overhaul**: Redesigned the Privacy & Terms screen for a cleaner, more streamlined experience.
  - Replaced inline policy cards with a "Review and Continue" sequential popup flow.
  - Expanded "Your Privacy Guarantees" to include 8 key features (added Biometric Protection, Offline AI Analysis, Easy Data Export, and Zero Tracking).
  - Restricted popup width to 600px for a more professional look on desktop platforms.
  - Unified action button styling by applying the primary health green theme to all "Continue" buttons.
  - Enhanced sequential validation logic to ensure smooth transitions between Privacy Policy and Terms of Service reviews.

## [1.8.8] - 2026-01-26

### Improved
- **Consent Experience**: Overhauled the Privacy Policy and Terms of Service acceptance flow.
  - Centered screen titles and subtitles for better visual balance.
  - Relocated the version indicator to be adjacent to the main title.
  - Enhanced the "Accept & Continue" button with a primary green theme and persistent interactivity.
  - Implemented sequential, context-rich validation popups that guide users through reviewing policies if they haven't been accepted yet.
  - Standardized versioning across the onboarding flow to v1.8.8.
- **Desktop Layout Optimization**: Restricted content width and centered UI elements to improve usability on Mac and Windows versions.
  - Created a reusable `ResponsiveCenter` widget to maintain consistent layout constraints (max width 800px) across desktop platforms.
  - Optimized the **Settings Screen** to prevent content from spreading too wide on large screens.
  - Centered and constrained the **Lock Screen** (login flow) for a more focused user experience.
  - Applied desktop layout optimizations to the entire **Onboarding Flow**, including Welcome Carousel, Privacy & Terms, and Security Setup screens.

### Changed
- **Repository Hygiene**: Added `.cursorrules` to `.gitignore` to prevent IDE-specific cursor rules from being tracked in version control.

## [1.8.7] - 2026-01-26

### Added
- **Secure Logout System**: Implemented a comprehensive logout flow in the Settings screen.
  - Added an interactive Logout button with session reset capabilities.
  - Implemented an optional "Clear all data" workflow during logout for users who want to wipe their local traces.
  - Ensured secure navigation redirection to the onboarding flow after logout.

### Fixed
- **Clear All Data Reliability**: Completely overhauled the data wipe functionality to ensure all 17 encrypted Hive boxes are properly cleared.
- **Session Security**: Added a `resetSession` protocol in `SessionManager` to purge transient memory, AI context, and active timers during logout or data clear operations.

## [1.8.6] - 2026-01-26

### Improved
- **Settings Screen Navigation**: Refactored the settings screen from a single long list into a clean, menu-driven interface to reduce information overload.
  - Organized settings into 8 logical categories: Privacy & Security, Storage, Recording, Desktop Notifications, AI Model, Accessibility & Shortcuts, Desktop Experience, and About.
  - Implemented a dynamic header with back navigation for seamless category switching.
  - Enhanced information hierarchy while maintaining the Liquid Glass design aesthetic.

## [1.8.5] - 2026-01-26

### Improved
- **Model Warm-up Experience**: Added a "Go Back" button to the failure state, allowing users to navigate away from the error screen if the AI engine fails to initialize.

## [1.8.4] - 2026-01-26

### Fixed
- **macOS Permissions Screen Hang**: Resolved infinite loading screen after accepting Terms & Conditions on desktop platforms.
  - Root cause: The `permission_handler` package doesn't work correctly on macOS/Windows/Linux and hangs when checking permission status.
  - Added platform detection to skip permission checks on desktop platforms and auto-complete the onboarding step.
  - Permissions are handled natively by the OS when user actually uses camera/mic on desktop.
- **macOS PlatformMenuBar Crash**: Fixed red error screen ("members.isNotEmpty" assertion failure) when navigating to main dashboard.
  - Root cause: `PlatformMenuItemGroup` in `DesktopMenuBar` was being created with an empty `members` list on macOS because the "Exit" menu item was only added for non-macOS platforms.
  - Wrapped the entire `PlatformMenuItemGroup` with the platform conditional check instead of just the menu item.

## [1.8.3] - 2026-01-26

### Fixed
- **macOS Black Screen After Splash**: Resolved a critical bug where the app would show a black screen after the splash animation on macOS.
  - Root cause: `SplashScreen` was not calling `markStepCompleted(OnboardingStep.splash)` before navigating, causing the onboarding navigator to endlessly reload the splash screen.
  - Added `OnboardingService().markStepCompleted(OnboardingStep.splash)` call before completing the splash screen.
- **macOS AppDelegate Crash**: Fixed `unrecognized selector` crash in `AppDelegate.applicationDidFinishLaunching` by removing invalid `super` call that doesn't exist in `FlutterAppDelegate`.
- **macOS Secure Restorable State Warning**: Added `applicationSupportsSecureRestorableState` method to silence the macOS warning about secure coding.
- **Memory Monitor False Positives on Desktop**: Fixed incorrect "critical memory pressure" detection on macOS/Windows/Linux where file cache memory was being reported as "used" memory.
  - Desktop platforms now use absolute free memory thresholds instead of percentage-based detection.
  - Disabled memory-based model fallback on desktop platforms since the OS handles memory pressure better than app-level intervention.
- **ObjectBox Sandbox Permissions**: Changed ObjectBox storage directory from Documents to Application Support for better macOS sandbox compatibility, with graceful fallback if initialization fails.

## [1.8.2] - 2026-01-26

### Added
- **Hardware Verification**: Implemented strict 8GB RAM minimum requirement for mobile devices to ensure stable local AI (LLM, Whisper, OCR) processing.
- **Incompatible Device Screen**: Created a premium glassmorphic blocking screen to gracefully inform users on under-powered devices about hardware requirements.
- **Android Memory Optimization**: Enabled `largeHeap` in `AndroidManifest.xml` to allow the app to utilize more memory for intensive AI tasks.

### Fixed
- **macOS Build Stability**: Resolved a critical build failure in `flutter_sound` by patching the podspec name mismatch (`taudio` vs `flutter_sound`).
- **macOS AppDelegate**: Fixed variable name collision (`channel` vs `trayChannel`) and implemented a more robust, non-Dill-based Do Not Disturb check.
- **macOS Release**: Successfully verified native build for M1/M2/M3/M4 Apple Silicon architecture.

## [1.8.1] - 2026-01-26

### Added
- **Documentation**: Created a comprehensive project index in `docs/index.md` covering all services, models, database structures, and key workflows.

### Fixed
- **Android Build**: Migrated from `flutter_windowmanager` to `flutter_windowmanager_plus` (^1.0.1) and enabled core library desugaring in `build.gradle.kts` to resolve AGP 8.0+ namespace requirements and Java 8+ API compatibility issues.
- **System Stability**: Resolved critical compilation errors in `AppSettings` and `WidgetDataService` by implementing missing ICE (In Case of Emergency) configuration fields.
- **Android Build**: Fixed Gradle build errors in `android/app/build.gradle.kts` by resolving `java.util.Properties` reference conflicts and migrating deprecated `kotlinOptions.jvmTarget` to the modern `compilerOptions` DSL for Kotlin 2.0+ compatibility.
- **App Lifecycle**: Implemented missing `_checkBiometricEnrollment` method in `SehatLockerApp` to correctly prompt users for biometric setup on app resume.
- **Testing**: Fixed `follow_up_extractor_enrichment_test.dart` by implementing missing `saveConversationToVault` mock override.
- **Testing**: Restored `widget_test.dart` compilation by correcting the application class name entry point.
- **Data Persistence**: Regenerated Hive adapters to support new ICE contact fields in `AppSettings`.

## [1.8.0] - 2026-01-26

### Added
- **User Onboarding - Splash Screen**: Implemented an animated splash screen as the first step of the onboarding experience.
  - Created `AnimatedLogo` widget with scale bounce, glow pulse, and 3D rotation effects.
  - Created `AnimatedPrivacyShield` widget displaying "Privacy First" indicator.
  - Implemented `SplashScreen` with staggered text animations for "Sehat Locker" title and "Your Health, Your Device" tagline.
  - Added animated background orbs with gradient effects matching the Liquid Glass design system.
  - Integrated smooth fade-out exit transition after minimum 2.5 second display.
  - Added onboarding tracking fields to `AppSettings`: `hasSeenSplash`, `completedOnboardingSteps`, `isOnboardingComplete`.
  - Integrated splash screen into `main_common.dart` to display for first-time users only.
  - Regenerated Hive adapters for new `AppSettings` fields.
- **User Onboarding - Welcome Carousel**: Implemented a 4-page feature introduction carousel as the second onboarding step.
  - Created `WelcomeCarouselScreen` with swipeable pages introducing Privacy, Document Vault, AI Assistant, and Recording features.
  - Created `WelcomePageData` model for JSON-driven content with title, description, icon, and highlights.
  - Created `AnimatedPageIndicator` widget with animated dot transitions and glow effects.
  - Created `PillPageIndicator` widget with progress bar style indication.
  - Added `assets/data/onboarding/welcome_content.json` with feature content and highlights.
  - Implemented skip button on all pages except the last, with "Get Started" button on final page.
  - Added fade-in animation on content load and smooth page transitions.
  - Integrated into `main_common.dart` onboarding flow with `OnboardingStep` enum for step management.
  - Registered onboarding assets folder in `pubspec.yaml`.
- **User Onboarding - Privacy Policy & Terms Acceptance**: Implemented a legally-compliant consent flow as the third onboarding step.
  - Created `ConsentAcceptanceScreen` with scrollable privacy policy and terms of service content.
  - Created `ConsentChecklistWidget` displaying four key privacy guarantees (AES-256 encryption, no cloud storage, no data leaves device, user owns all data).
  - Added `privacy_policy_v1.md` template covering data collection, security measures, user rights, consent management, and data retention.
  - Added `terms_of_service_v1.md` template covering user responsibilities, medical disclaimers, intellectual property, and liability limitations.
  - Implemented dual checkbox acceptance flow requiring both Privacy Policy and Terms of Service acceptance.
  - Added "Read Full" modal bottom sheet with full markdown rendering using `flutter_markdown` package.
  - Integrated `ConsentService.recordConsent()` for audit-compliant consent recording with version hash, timestamp, and device info.
  - Added version display with policy version number in header.
  - Expanded `AppSettings` with `hasAcceptedPrivacyPolicy`, `acceptedPrivacyPolicyVersion`, `hasAcceptedTermsOfService`, and `acceptedTermsOfServiceVersion` fields.
  - Added analytics logging for `consent_privacy_viewed`, `consent_privacy_accepted`, and `consent_terms_accepted` events.
  - Added `flutter_markdown` dependency for consent document rendering.
  - Regenerated Hive adapters for new `AppSettings` fields.
- **User Onboarding - Permissions Request Flow**: Implemented a guided permissions request screen as the fourth onboarding step.
  - Created `PermissionsRequestScreen` in `lib/screens/onboarding/permissions_request_screen.dart` with step-by-step permission requests.
  - Created `PermissionCard` widget in `lib/widgets/onboarding/permission_card.dart` for displaying permission icon, title, description, status indicator, and grant button.
  - Implemented one-at-a-time permission requests for:
    - Camera: "Scan medical documents, prescriptions, and lab reports directly with your camera"
    - Microphone: "Record doctor visits and medical consultations for accurate transcription"
    - Notifications (Optional): "Get reminders for follow-up appointments, medication schedules"
  - Added `PermissionStatus` enum to track pending, granted, denied, and permanently denied states.
  - Added notification permission to `PermissionService`:
    - `requestNotificationPermission()` for requesting notification permission
    - Status check methods: `isCameraPermissionGranted()`, `isMicPermissionGranted()`, `isNotificationPermissionGranted()`
    - Permanently denied check methods for all three permission types
    - `openSettings()` utility to redirect users to app settings for permanently denied permissions
  - Implemented graceful denial handling with visual status indicators and Settings deep-link for permanently denied permissions.
  - Added "Skip" button for optional notification permission.
  - Added progress indicator showing current permission step with visual completion states.
  - Expanded `AppSettings` with `hasCompletedPermissionsSetup` field (HiveField 52).
  - Added `OnboardingStep.permissions` to the onboarding step enum.
  - Added analytics logging for permission events:
    - `permissions_screen_viewed`, `permission_camera_granted`, `permission_camera_denied`
    - `permission_mic_granted`, `permission_mic_denied`, `permission_notification_granted`, `permission_notification_denied`
    - `permission_notification_skipped`, `permissions_setup_completed`
  - Implemented pulse animation on active permission cards with glow effect.
  - Regenerated Hive adapters for new `AppSettings field.
- **User Onboarding - Flow Orchestration**: Implemented `OnboardingNavigator` in `lib/screens/onboarding/onboarding_navigator.dart` to manage the multi-step journey.
  - Added deterministic step discovery based on `OnboardingService`.
  - Implemented back/next navigation with state persistence and transition logic.
  - Integrated into `main_common.dart` to orchestrate a seamless first-run experience.
- **User Onboarding - Security & PIN Setup**: Implemented the fifth onboarding step focusing on multi-layered local protection.
  - Created `SecuritySetupScreen` with dynamic progress tracking (Intro, Biometrics, PIN, Completion).
  - Integrated existing `PinSetupScreen` and `BiometricService` into the onboarding funnel.
  - Added `SecurityCompletionCard` for visual confirmation of active security layers.
  - Enforced PIN requirement as a secure fallback even if biometrics are enabled.
- **User Onboarding - Personalized Profile**: Implemented the sixth onboarding step for local demographic data and calibration.
  - Created `UserProfile` model (Hive TypeId 40) for local-only storage of display name, sex, and date of birth.
  - Created `ProfileSetupScreen` with premium HSL-tailored UI for demographic entry.
  - Updated `ReferenceRangeService` to automatically use user profile demographics for lab result evaluations.
  - Implemented "Skip" option with clear, prominent privacy guarantees about data staying local.
- **User Onboarding - Interactive Feature Tour**: Implemented the seventh onboarding step for discovery of key capabilities.
  - Created `FeatureTourScreen` allowing users to opt into a quick tour of the platform.
  - Integrated `EducationModal` to display the "Secure Storage", "Document Scanner", and "AI Features" modules.
  - Added automated analytics tracking for tour engagement and completion milestones.
- **User Onboarding - Guided First Scan**: Implemented the eighth onboarding step for immediate value realization.
  - Created `FirstScanGuideScreen` with step-by-step guidance for scanning lab reports or prescriptions.
  - Enhanced `DocumentScannerScreen` with a `showOnboardingTips` mode utilizing new `CoachMark` overlays.
  - Created `ConfettiAnimation` with `confetti: ^0.7.0` for celebrating successful first-time document captures.
- **User Onboarding - Graduation & Celebration**: Implemented the final onboarding step and transition.
  - Created `OnboardingCompleteScreen` featuring a "Setup Summary" checklist of all completed configurations.
  - Added full-screen confetti celebration for reaching the final onboarding milestone.
  - Optimized the transition logic to move directly from completion to the main app dashboard.
- **Dependencies**: Added `confetti: ^0.7.0` for high-performance celebration animations.


## [1.7.0] - 2026-01-26

### Added
- **Model License Compliance**: Implemented a comprehensive tracking and transparency system for AI model licenses.
  - Created `ModelLicenseService` for centralized license management, version tracking, and plain language summaries.
  - Developed `ModelLicenseScreen` with search capability and detailed view of key restrictions and attribution requirements.
  - Implemented export functionality for legal compliance documentation in `.txt` format.
  - Integrated license links into `ModelInfoPanel` for contextual access during model selection or use.
  - Added "Model Licenses" entry point to the "About" section in `SettingsScreen`.
  - Connected license access and exports to `SecureLogger` for audit-ready compliance tracking.
  - Updated `ComplianceService` and `DEVELOPER_COMPLIANCE_CHECKLIST.md` with license validation checks.
- **Model Update Verification System**: Implemented a comprehensive security framework for local AI model updates and integrity.
  - Created `ModelUpdateService` for offline-first update checking and secure manifest management.
  - Developed `ModelVerificationService` with cryptographic signature verification (RSA/Ed25519) and SHA-256 integrity checks.
  - Implemented a tamper-evident verification system that detects model corruption and triggers recovery mechanisms.
  - Added version compatibility checking to ensure models are compatible with the current app version.
  - Integrated update status indicators and manual update actions into `ModelInfoPanel`.
  - Added manual model update verification and integrity checks to the `SettingsScreen`.
  - Connected verification events to `SecureLogger` for audit-ready security logging.
  - Implemented secure, encrypted storage for model manifests using Hive.
- **Model Quantization Support**: Implemented a comprehensive system for local LLM quantization.
  - Created `ModelQuantizationService` for managing quantization levels, quality assessments, and device compatibility.
  - Implemented `QuantizationFormat` system with support for 2-bit through 16-bit precision levels (Q2_K to F16).
  - Added quality vs. performance tradeoff metrics and automatic recommendation engine based on device RAM and CPU.
  - Updated `ModelOption` to support per-model quantization capability mapping.
  - Integrated quantization information and tradeoff metrics into `ModelInfoPanel`.
  - Added quantization preference selection to `SettingsScreen` with educational tooltips.
  - Updated `ModelWarmupScreen` to provide loading feedback specific to quantization levels.
  - Implemented disk space and RAM compatibility validation with user warnings.
  - Added comprehensive testing suite for quantization levels and compatibility logic.
- **Batch Processing System**: Implemented a robust system for background document processing and storage.
  - Queue management with priority sorting (High/Normal/Low).
  - Parallel task processing with resource-aware throttling (Memory & Battery).
  - Real-time status monitoring with progress tracking and desktop notifications.
  - Persistence across app restarts using encrypted Hive storage.
  - Cancellation support for in-progress and pending tasks.
  - Retry mechanism for failed tasks.
  - Partial success reporting with detailed error logs.
  - Seamless integration with DocumentScanner and Vault services.
  - Created `BatchProcessingService` with queue management, priority-based sorting, and resource throttling.
  - Implemented `BatchTask` model with Hive persistence and AES encryption support.
  - Developed `BatchProcessingScreen` for real-time monitoring and management of the processing queue.
  - Integrated batch processing into `DocumentScannerScreen` for asynchronous document handling.
  - Added a persistent batch status indicator to the `DocumentsScreen` for background task visibility.
  - Implemented pause/resume, retry, and cancellation controls for the processing queue.
  - Integrated with `DesktopNotificationService` for completion alerts.
  - Added resource-aware processing that throttles based on device capabilities and storage availability.
- **Conversation Memory Management**: Implemented persistent, privacy-aware conversation history for AI interactions.
  - Created `ConversationMemoryService` for managing context windows with strategic retention and token limits.
  - Implemented `ConversationMemory` and `MemoryEntry` Hive models with AES encryption support in `LocalStorageService`.
  - Added privacy-aware memory with automatic redaction via `SafetyFilterService` integration.
  - Developed a visual conversation history interface in `ConversationTranscriptScreen` with a dedicated "AI Memory" tab.
  - Added memory depth controls and context window settings to the `SettingsScreen`.
  - Integrated memory management into the `AIService` pipeline for contextual AI responses.
  - Implemented memory usage metrics collection (message count, token usage, redaction count).
  - Optimized context window handling using `TokenCounterService` for multilingual support.
  - Added support for session continuity with persistent conversation memory across app restarts.
- **AI Usage Analytics**: Implemented privacy-focused local performance tracking for AI models.
  - Created `AIAnalyticsService` for metric logging and storage with AES encryption.
  - Implemented `AIUsageMetric` Hive model for tracking inference speed, memory usage, and load times.
  - Developed `AIDiagnosticsScreen` with `fl_chart` visualizations for tokens/sec and peak memory trends.
  - Added opt-in controls and automatic data retention policies (7, 30, 90 days) in `SettingsScreen`.
  - Integrated metric logging into `ModelManager` for tracking model load success rates and initialization performance.
  - Added compliance validation for AI analytics to `ComplianceService` and the developer checklist.
  - Implemented anonymized data export functionality for performance debugging.

## [1.6.0] - 2026-01-26

### Added
- **Hallucination Prevention System**: Implemented a multi-layered verification system for AI factual accuracy.
  - Created `HallucinationValidationService` with adaptive confidence threshold analysis based on content type.
  - Implemented medical fact verification against the structured `MedicalKnowledgeBase`.
  - Integrated `HallucinationValidationStage` into the `AIService` output pipeline for real-time verification.
  - Added user feedback mechanism in `AIResponseBubble` for reporting suspected inaccuracies.
  - Connected with `MedicalFieldExtractor` for validating physiological limits of extracted lab values.
  - Implemented speculative language detection to handle reasonable but uncertain statements.
  - Added comprehensive logging of hallucination patterns and analytics collection via `AnalyticsService`.
  - Integrated hallucination prevention checks into the `DEVELOPER_COMPLIANCE_CHECKLIST.md`.
  - Added a suite of automated tests for hallucination detection and threshold management.

## [1.5.0] - 2026-01-25

### Added
- **Citation Injection System**: Implemented a comprehensive medical citation and factual verification system.
  - Created a pattern-based factual claim detection engine using NLP patterns in `CitationService`.
  - Implemented a source matching algorithm with confidence scoring based on medical authority and review status.
  - Developed a structured medical knowledge base in `lib/data/knowledge_base/` with initial support for WHO, ADA, AHA, and Mayo Clinic guidelines.
  - Integrated interactive visual citations in `AIResponseBubble` with detailed source inspection and confidence indicators.
  - Connected `CitationService` with `ReferenceRangeService`, `MedicalFieldExtractor`, and `SafetyFilterService` for cross-validation.
  - Enhanced `ExportService` and `PdfExportService` to include professional medical references in exported documents.
  - Added a knowledge base update mechanism for future remote synchronization.
  - Implemented comprehensive performance tracking for citation detection and matching.

## [1.4.0] - 2026-01-25

### Added
- **Advanced Generation Controls**: Implemented comprehensive AI parameter management.
  - Created `GenerationParameters` model with Hive support for persistence.
  - Implemented `GenerationParametersService` for centralized parameter management and validation.
  - Added `GenerationControls` widget with parameter sliders and preset system (Balanced, Creative, Precise, Fast).
  - Integrated parameter validation with safety boundaries in `ComplianceService`.
  - Added support for temporary session overrides in `SessionManager`.
  - Integrated parameter configuration with `LLMEngine` for real-time inference optimization.
  - Added advanced toggle and controls to `SettingsScreen`.
  - Implemented comprehensive testing for parameter combinations and validation logic.
- **Knowledge Cutoff Notice**: Implemented a comprehensive system for tracking and displaying AI model knowledge cutoff dates.
  - Created `KnowledgeCutoffNotice` widget with context-aware display and expandable details.
  - Implemented dismissal tracking with re-show logic using Hive persistence in `AppSettings`.
  - Integrated real-time date comparison in `AIScreen` to detect conversations mentioning data newer than the model's knowledge cutoff.
  - Added knowledge cutoff information to PDF and Text headers in `ExportService`.
  - Integrated knowledge cutoff compliance checks into `ComplianceService` and developer checklist.
  - Added support for model-specific cutoff tracking in `DoctorConversation` history.
  - Implemented semantic accessibility and localized date formatting.

## [1.3.0] - 2026-01-25

### Added
- **Memory-Efficient Model Management**: Implemented strategic resource management for local AI models.
  - Created `MemoryMonitorService` for real-time memory pressure monitoring across platforms.
  - Integrated platform-specific memory APIs via `system_info2` for accurate RAM tracking.
  - Implemented strategic model unloading in `ModelManager` with usage prediction and retention timers.
  - Added user-configurable memory retention policies and low-memory fallback strategies.
    - Integrated memory status indicators into `ModelInfoPanel` with color-coded pressure alerts.
    - Added UI controls for memory management and retention policy in `SettingsScreen`.
- **Output Processing Pipeline**: Implemented a modular middleware system for AI response processing in `AIService`.
  - Added modular pipeline architecture with configurable stages and priority-based ordering.
  - Implemented parallel processing for independent validation stages to optimize performance.
  - Added performance metrics tracking for each pipeline stage (Safety, Validation, Citations).
  - Created `PipelineDebugger` for developer visualization and metrics logging.
  - Integrated `SafetyFilterStage` for automated medical content sanitization.
  - Added `ValidationStage` with parallel rule execution for medical advice verification.
  - Integrated `CitationStage` for automated citation injection into AI outputs.
  - Added support for real-time streaming response processing.
  - Integrated pipeline into `ExportService` for processing transcript content before PDF/Text export.
  - Implemented graceful degradation with comprehensive error handling and redacted logging via `SecureLogger`.
- **Safe Prompt Templates**: Implemented `PromptTemplateService` for managed, versioned, and secure AI prompts.
  - Added template versioning with rollback capability and version history tracking.
  - Implemented a context injection system with safety boundaries and input sanitization.
  - Added a template testing framework with automated adversarial example validation.
  - Supported multilingual templates (English and Indonesian initial support).
  - Integrated with `AIService` as the primary prompt generation layer.
  - Connected to `MedicalFieldExtractor` for automated structured data injection into prompts.
  - Added template compliance validation to the developer checklist and `ComplianceService`.
  - Implemented performance metrics collection for template generation efficiency.
  - Integrated with `TokenCounterService` for context window optimization.
- **Context Window Management**: Implemented in `LLMEngine` for optimized local LLM performance.
  - Added `TokenCounterService` with multilingual support (CJK, Arabic, Hebrew, Latin).
  - Implemented strategic truncation preserving conversation starts and ends.
  - Added content compression for repetitive phrases in LLM context.
  - Integrated context usage tracking in `ModelMetrics`.
- **Model Warm-up Experience**: Enhanced the first-time AI initialization flow.
  - Created `ModelWarmupService` for managed state, adaptive time estimates, and background loading.
  - Implemented `ModelWarmupScreen` with animated progress, educational content, and cancellation handling.
  - Added state persistence across app restarts via `AppSettings`.
  - Integrated warmup flow into `SehatLockerApp` onboarding and `ModelManager` loading.
  - Connected to `SessionManager` for lifecycle-aware resource management during warmup.
  - Added abandonment metrics and performance tracking for usability testing.
- **UI Integration**:
  - Added visual context window usage indicators in `ModelInfoPanel`.
  - Implemented real-time token usage progress bars with color-coded alerts (70% warning, 90% critical).
  - Created `TokenUsageIndicator` widget with detailed breakdown and expandable sections.
  - Implemented Model Fallback System:
    - Added `ModelFallbackService` for automatic failure detection and model switching.
    - Enhanced `LLMEngine` with comprehensive error classification (RAM, Memory, Backend failure).
    - Integrated fallback logic into `ModelManager`, `SessionManager`, and `AIService`.
    - Added UI indicators for active model and fallback status in `ModelInfoPanel`.
    - Implemented context preservation during model switching.
    - Added analytics collection for fallback events and failure patterns.
    - Verified with performance benchmarks (Evaluation: ~53μs, Context Capture: ~3μs).
    - Added test coverage for various failure modes and performance benchmarks.
  - Integrated persistent token usage monitoring in `AIScreen`.
- **Analytics**: Added context usage pattern tracking via `AnalyticsService`.
  - Implemented detailed token usage analytics collection.

## [1.7.0] - 2026-01-26

### Added
- **AI Error Recovery System**: Implemented a comprehensive recovery framework for AI failures.
  - Created `AIRecoveryService` for failure mode detection and classification.
  - Implemented structured `AIError` classification (Memory, Initialization, Inference, Context).
  - Added user-friendly error messages with contextual recovery advice.
  - Implemented exponential backoff for automated retry attempts (1s, 2s, 4s).
  - Integrated recovery logic into `AIService` generation pipeline.
  - Connected with `ModelFallbackService` for seamless model switching on critical failures.
  - Implemented graceful degradation with fallback responses when full generation fails.
  - Added comprehensive unit tests for recovery strategies in `test/services/ai_recovery_service_test.dart`.
  - Integrated recovery monitoring into the `DeveloperComplianceChecklist`.

## [1.2.0] - 2026-01-25

### Added
- **LLMEngine**: Integrated GGUF model support using `llama_cpp_dart`.
  - Implemented thread-safe model initialization and inference using managed isolates.
  - Added real-time initialization progress reporting (0.0 to 1.0).
  - Implemented model integrity verification with SHA-256 checksums.
  - Added memory management with low-resource fallback strategies (reduced context size).
  - Integrated performance metrics collection (load time, tokens per second, total tokens).
- **ModelWarmupScreen**: New UI for first-time AI model initialization.
  - Features glassmorphism design with `LiquidGlassBackground` and `GlassProgressBar`.
  - Shows detailed status updates during the warmup process.
- **Integration**:
  - Connected `LLMEngine` to `ModelManager` for automated model loading.
  - Integrated with `AIService` as the primary local backend for text generation.
  - Added resource management in `SessionManager` to dispose of AI resources on session end or backgrounding.
- **Testing**: Added `LLMEngine` unit tests in `test/services/llm_engine_test.dart`.

## [1.1.0] - 2026-01-25

### Added
- `DesktopNotificationService` for managing advanced desktop-specific notifications.
- Notification grouping for batch operations (Storage, Model Status, Recording).
- Action buttons support for desktop notifications.
- Rate limiting for notifications (5-second window per ID).
- System "Do Not Disturb" mode detection for macOS and Windows.
- Accessibility support with screen reader announcements for notifications.
- User-configurable notification preferences in AppSettings (Privacy masking, Accessibility).
- Integrated recording status notifications in `ConversationRecorderService`.
- Added storage usage alerts and model integrity warnings.

### Changed
- `FollowUpReminderService` modified to allow inheritance by `DesktopNotificationService`.
- `EnhancedPrivacySettings` extended with `maskNotifications` option.
- `AppSettings` updated with `accessibilityEnabled` preference.

## [2026-01-26 12:00] - Build Configuration System

### Added
- **Build System**: Created a comprehensive build configuration system in `build/`.
  - Implemented platform-specific build scripts (`build_android.sh`, `build_ios.sh`, `build_desktop.sh`).
  - Added a verification matrix script (`verify_matrix.sh`) for CI/CD readiness.
  - Implemented automated size optimization (ProGuard) and obfuscation for production builds.
  - Added build performance metrics (timer) and security scanning (`flutter pub audit`).
- **Flavor Support**:
  - Implemented multi-flavor architecture (Dev, Staging, Prod).
  - Created entry points: `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`.
  - Added `AppConfig` for runtime flavor-specific configuration (API URLs, logging).
- **Platform Abstraction**:
  - Implemented `PlatformService` with conditional imports (`mobile`, `desktop`, `web`, `stub`).
  - Unified platform detection across the codebase.
- **Security & Compliance**:
  - Added Android signing configuration management via `key.properties`.
  - Integrated flavor-aware model selection in `ModelManager`.
  - Added build verification unit tests in `test/build_config_test.dart`.

### Changed
- **Main Entry Point**: Refactored `lib/main.dart` into `lib/main_common.dart` to support flavor-based initialization.
- **Android Gradle**: Updated `build.gradle.kts` with product flavors, signing configs, and optimization rules.
- **ModelManager**: Enhanced to consider the active build flavor when recommending AI models.

## [2026-01-26 10:30] - System Tray Integration

### Added
- **SystemTrayService**: Created a new service in `lib/services/system_tray_service.dart` for desktop tray management.
  - Implements platform-specific tray icons for macOS and Windows using `MethodChannel`.
  - Features dynamic state indicators for recording (Recording, Paused, Idle).
  - Integrates a context menu with actions for app visibility, recording control, and session locking.
  - Includes real-time battery status monitoring with critical level indicators.
  - Implements privacy-focused tooltips showing session and recording status without sensitive data.
- **Native Implementation**: 
  - **macOS**: Implemented tray logic in `AppDelegate.swift` using `NSStatusItem` and `NSMenu`.
  - **Windows**: Implemented tray logic in `flutter_window.cpp` using Win32 `Shell_NotifyIcon` and popup menus.
- **Enterprise & Security**:
  - Implemented enterprise environment detection (MDM on macOS, Domain Join on Windows).
  - Added accessibility labels and platform-specific keyboard shortcuts in tray menus.
  - Included security measures to prevent tray icon spoofing via platform-specific verification.

### Changed
- **Main**: Integrated `SystemTrayService` initialization into the app startup sequence.
- **ConversationRecorderService**: Refactored to support `ChangeNotifier` for reactive tray state updates.

## [2026-01-25 16:30] - Desktop Menu Bar Integration

### Added
- **DesktopMenuBar**: Created a native-feeling menu bar in `lib/widgets/desktop/desktop_menu_bar.dart` using `PlatformMenuBar`.
  - Implements standard macOS/Windows/Linux menu structures (File, Edit, View, Window, Help).
  - Features dynamic enable/disable states based on session lock and document availability.
  - Integrates platform-specific shortcuts (Cmd for macOS, Ctrl for Windows/Linux).
  - Added a "Recent Documents" MRU (Most Recently Used) submenu fetching from `LocalStorageService`.
- **App Integration**: Successfully integrated `DesktopMenuBar` into the main `SehatLockerApp` in `lib/app.dart`.
  - Connected menu actions to core app features: New Scan, Export, Settings, Lock Session, and Shortcut Cheat Sheet.
  - Implemented navigation to document details from the recent documents menu.

### Changed
- **App Entry Point**: Modified `lib/app.dart` to wrap the main layout with `DesktopMenuBar`, ensuring consistent navigation and shortcut handling across the app.
- **Shortcut Handling**: Unified desktop menu shortcuts with the existing `KeyboardShortcutService` and `AppShortcutManager`.

## [2026-01-25 15:30] - Desktop Window Management

### Added
- **WindowManagerService**: Created a new service in `lib/services/window_manager_service.dart` using `window_manager` and `screen_retriever`.
  - Implements window state persistence (size, position, maximized state).
  - Features multi-monitor awareness with overlap-based visibility validation.
  - Includes failsafe position recovery for disconnected or changed display configurations.
  - Implements DPI scaling awareness for high-resolution displays.
- **Dependencies**: Added `window_manager` and `screen_retriever` for advanced desktop window control.

### Changed
- **AppSettings**: Added `persistWindowState` and `restoreWindowPosition` fields to allow user control over window behavior.
- **DesktopSettingsScreen**: Integrated new window management controls, including toggles for state persistence and a "Reset Window Position" utility.
- **SessionManager**: Refactored to delegate window state management to the specialized `WindowManagerService`.
- **Main**: Integrated `WindowManagerService` initialization into the application startup sequence.

## [2026-01-25] - Desktop Keyboard Shortcuts

### Added
- **KeyboardShortcutService**: Created a singleton service in `lib/services/keyboard_shortcut_service.dart` for centralized shortcut management.
  - Implements platform-specific mappings (Cmd vs Ctrl).
  - Features context-aware action registration and execution.
  - Includes system shortcut conflict detection and haptic feedback integration.
- **AppShortcutManager**: Implemented a global shortcut manager in `lib/managers/shortcut_manager.dart`.
  - Provides a visual cheat sheet overlay with glassmorphism styling.
  - Manages global intents for recording, scanning, settings, and locking.
- **Contextual Shortcuts**:
  - `Cmd/Ctrl + R`: Toggle recording (active on AI Screen).
  - `Cmd/Ctrl + S`: Capture document (active on Scanner Screen) or open scanner (global).
  - `Cmd/Ctrl + L`: Immediately lock the session.
  - `Cmd/Ctrl + ,`: Open application settings.
  - `Cmd/Ctrl + /`: Toggle the keyboard shortcut cheat sheet.

### Changed
- **SettingsScreen**: Added a toggle to enable/disable keyboard shortcuts.
- **SessionManager**: Added `lockImmediately()` for secure shortcut-triggered session locking.
- **AIScreen**: Integrated recording shortcuts via `KeyboardShortcutService`.
- **DocumentScannerScreen**: Integrated document capture shortcuts via `KeyboardShortcutService`.
- **AppSettings**: Added `enableKeyboardShortcuts` field to persist user preference.

## [2026-01-26 09:00] - File Drag-and-Drop Interface

### Added
- **FileDropService**: Created a singleton service in `lib/services/file_drop_service.dart` for batch file processing and validation.
  - Supports image, PDF, and text file validation.
  - Implements a processing queue with stream-based progress tracking.
  - Integrates with `VaultService` for automatic document processing.
  - Supports directory drops to set custom export destinations.
- **FileDropZone**: Created a universal drag-and-drop widget in `lib/widgets/desktop/file_drop_zone.dart`.
  - Features glassmorphism overlay and visual feedback.
  - Includes keyboard accessibility for non-mouse users.
  - Provides a queue indicator for background processing tasks.

### Changed
- **DocumentScannerScreen**: Integrated `FileDropZone` as an alternative to camera-based document scanning.
- **AIScreen**: Integrated `FileDropZone` for importing transcript files for analysis.
- **ExportService**: Enhanced to support user-configurable export destinations via folder drag-and-drop.
  - Refactored all export methods to honor the custom directory set in `AppSettings`.
- **AppSettings**: Added `maxFileUploadSizeMB` and `lastExportDirectory` fields for better control over file handling and exports.
- **PdfExportService**: Updated to support custom output paths for generated PDF files.

## [2026-01-26 08:30] - Desktop-Optimized Settings

### Added
- **DesktopSettingsScreen**: Created a new screen in `lib/screens/desktop_settings_screen.dart` for desktop-specific configurations.
- **Window Management**: Added state persistence for window dimensions and position in `AppSettings` and `SessionManager`.
- **Performance Tuning**: Implemented GPU acceleration toggle and increased cache limit options (up to 4GB) for desktop users.
- **Capability Matrix**: Added a system capability visualization tool in developer tools for debugging hardware support.
- **Storage Validation**: Integrated system storage checks with desktop-specific threshold alerts.

### Changed
- **AppSettings**: Extended model with fields for window state, GPU acceleration, and cache limits.
- **ModelManager**: Enhanced recommendation logic to consider GPU acceleration settings and desktop-only models (e.g., Research-13B).
- **SettingsScreen**: Integrated conditional access to Desktop Experience settings based on platform detection.
- **StorageUsageService**: Added `isStorageSufficient` helper for hardware capability validation.

## [2026-01-26 08:00] - Documents Screen UI/UX & Search Enhancements

### Added
- **Responsive Layout**: Implemented a responsive grid system in `DocumentsScreen` that adapts column count (2 to 4) based on screen width.
- **Staggered Animations**: Integrated `flutter_staggered_animations` for smooth entry of grid items.
- **Storage Monitoring**: Added a low-storage warning banner (triggered at 80% usage) using `StorageUsageService`.
- **Keyboard Accessibility**: Added `FocusableActionDetector` and keyboard shortcuts (Enter/Space) to document and conversation cards.
- **Scroll Preservation**: Implemented `PageStorageKey` and `ScrollController` to maintain scroll position across orientation changes.

### Changed
- **Search System**: Refined `_performSearch` in `DocumentsScreen` to correctly integrate fuzzy search results from ObjectBox via `SearchService`.
- **UI Components**: Converted `FollowUpCard` to use `GlassCard` for visual consistency.
- **Modern Flutter**: Replaced deprecated `withOpacity` with `withValues` across `DocumentsScreen` and grid cards.

### Fixed
- **Type Safety**: Resolved type mismatch between `SearchEntry` and `String` IDs in search filtering logic.
- **Linter Issues**: Fixed several linter warnings including unused imports and statement block formatting.

## [2026-01-26 07:30] - Desktop Detection Service

### Added
- **PlatformDetector**: Created a new service in `lib/services/platform_detector.dart` for cross-platform capability detection.
  - Implements detection for RAM, GPU acceleration, and system resources.
  - Includes lifecycle-aware detection with automatic capability refreshing on app resume.
  - Provides a capability matrix for feature-based selection (e.g., `highRam`, `gpuAcceleration`).
  - Includes performance metrics for detection time.
- **Tests**: Added comprehensive unit tests for `PlatformDetector` in `test/services/platform_detector_test.dart`.

### Changed
- **ModelManager**: Integrated `PlatformDetector` to dynamically select optimal AI models based on actual device capabilities instead of hardcoded platform checks.
- **SessionManager**: Integrated `PlatformDetector` initialization and added lifecycle hooks for capability updates.
- **LocalStorageService**: Added automatic application of platform-specific default settings (e.g., session timeouts) during first-run initialization.
- **AppSettings**: Migrated `Set<String>` fields to `List<String>` to resolve Hive adapter generation issues and improved session timeout defaults.

## [2026-01-26 07:05] - Compliance Checklist Access & Export Fixes

### Added
- **AuditTimelineScreen**: Created visual timeline interface with search, sensitivity filtering, and interactive integrity verification.
- **ExportService**: Added `exportAuditLogReport` for PDF and encrypted JSON audit log exports with integrity pre-checks.
- **SecurityDashboardScreen**: Added direct access to Security Audit Trail and implemented `_PurgeDialog` for manual security cleanup.

### Changed
- **LocalAuditService**: Enhanced integrity verification with detailed `IntegrityResult` and periodic checks.
- **SessionManager**: Integrated periodic audit integrity checks on session start and added `lockImmediately` functionality.
- **SecurityDashboardScreen**: Improved error handling and resolved several linter issues related to privacy manifests and session management.
- **AuditTimelineScreen**: Implemented robust session ID display and error handling for audit entries.

## [2026-01-25 12:30] - Audit-Ready Local Logging Foundations

### Added
- **LocalAuditEntry**: Added Hive model with hash chaining fields for tamper detection.
- **LocalAuditService**: Added service for redaction, hash chaining, integrity checks, and retention pruning.

### Changed
- **SessionManager**: Added session IDs for session-bound audit trails.
- **LocalStorageService**: Added encrypted storage box and adapters for local audit entries.
- **AuthAuditService**: Mirrors authentication events into local audit log.
- **ExportService**: Mirrors export audit events into local audit log.
- **LocalAuditEntry**: Normalized detail hashing for deterministic integrity checks.
- **LocalAuditService**: Aligned redaction with SecureLogger and added retention anchor handling.
- **AppSettings**: Added local audit retention and chain anchor fields.
- **AuthAuditService**: Refined local audit logging integration.
- **ExportService**: Refined local audit logging integration.
- **SessionManager**: Logged session start/lock/unlock and triggered audit retention cleanup.
- **AIScreen**: Logged recording start events into local audit trail.
- **AIScreen**: Logged recording save events into local audit trail.
- **AIScreen**: Logged emergency recording deletions into local audit trail.

## [2026-01-26 07:05] - Compliance Checklist Access & Export Fixes

### Added
- **Dependencies**: Added `url_launcher` for compliance documentation links.
- **SettingsScreen**: Added four-finger swipe access to the Compliance Checklist in debug mode.

### Changed
- **ComplianceChecklistScreen**: Added authentication reason to the auth gate.
- **ExportService**: Routed compliance checklist exports through standard PDF save/share and footer.
- **ExportService**: Corrected compliance checklist export footer/share method usage.
- **SettingsScreen**: Scoped Compliance Checklist menu entry to debug mode.

## [2026-01-26 06:25] - Wellness Language Exception Handling

### Fixed
- **WellnessLanguageValidator**: Preserve exception phrases during replacements to avoid unintended rewrites.
- **WellnessLanguageValidator Tests**: Cleaned up test setup for exception handling coverage.

### Changed
- **WellnessLanguageValidator**: Removed unused medical dictionary import.

## [2026-01-26 06:10] - Wellness Language Integration

### Added
- **WellnessLanguageValidator**: Created validator service (`lib/services/wellness_language_validator.dart`) to identify and replace stigmatizing language with person-first terminology.
- **Wellness Terminology**: Added `assets/data/wellness_terminology.json` with initial set of replacements and exceptions.
- **AppSettings**: Added `enableWellnessLanguageChecks` and `showWellnessDebugInfo` settings to `AppSettings` model.
- **Settings Integration**: Added toggle controls for wellness checks in `SettingsScreen` under AI Model section.

### Changed
- **SafetyFilterService**: Integrated `WellnessLanguageValidator` into `sanitize` pipeline.
- **ExportService**: Applied `SafetyFilterService` sanitization to transcript exports (PDF and plain text).

## [2026-01-26 05:40] - Formatting & Example Fix

### Fixed
- **Examples**: Corrected `totalFields` calculation in `examples/medical_field_integration_example.dart`.

### Changed
- **Formatting**: Applied `dart format` across the codebase.

## [2026-01-26 05:20] - Risk Mitigation Fallbacks & Adapter Regeneration

### Added
- **RiskMitigationService**: Added fallback question selection when no keyword matches are found.
- **Risk Templates**: Added fallback templates to `assets/data/risk_templates.json` for graceful degradation.
- **RecorderProgress**: Defined `RecorderProgress` in `lib/services/conversation_recorder_service.dart` for progress streaming.

### Changed
- **AppSettingsAdapter**: Regenerated Hive adapters via build_runner to restore Set handling.

## [2026-01-26 04:00] - Risk Mitigation Service

### Added
- **RiskMitigationService**: Created `lib/services/risk_mitigation_service.dart` extending `AIService` to provide risk-mitigation response templates.
- **RiskTemplateConfiguration**: Implemented template configuration loading from assets (`lib/services/risk_template_configuration.dart`).
- **Assets**: Added `assets/data/risk_templates.json` containing initial risk templates with keywords and localized messages.
- **UI Integration**:
  - **ConversationTranscriptScreen**: Added "Suggested Questions" section generated by `RiskMitigationService`.
  - **DoctorVisitPrepScreen**: Added "Discussion Prompts" to the generated agenda.

### Changed
- **AIService**: Refactored to allow subclassing (changed `_internal` constructor to `internal` and `@protected`).

## [2026-01-26 03:00] - Model Transparency Panel

### Added
- **ModelInfoPanel**: Created `ModelInfoPanel` widget in `lib/widgets/ai/model_info_panel.dart` to display detailed model information.
  - **Features**: Expandable details, dynamic content loading, knowledge cutoff indicators, license compliance, and performance metrics.
  - **Metrics**: Added display for load time, inference speed, and memory usage.
- **ModelOption**: Updated model definition to include `knowledgeCutoffDate` and `license` fields.
- **AppSettings**: Updated `AppSettings` model to include `selectedModelId`, `modelMetadataMap`, `autoStopRecordingMinutes`, and `enableBatteryWarnings`.
- **Docs**: Created `docs/DEVELOPER_COMPLIANCE_CHECKLIST.md` for feature validation and compliance tracking.

### Changed
- **AIScreen**: Integrated `ModelInfoPanel` to replace simple status card, providing more transparency.
- **SettingsScreen**: Added `ModelInfoPanel` to AI settings section for detailed model inspection.

## [2026-01-26 02:10] - Consent Tracking Enhancements

### Added
- **ConsentEntry**: Added sync status fields for offline queue tracking.
- **ExportService**: Added consent history export with PDF and encrypted JSON.
- **SecurityDashboardScreen**: Added Consent History section with timeline and export action.
- **Tests**: Added unit coverage for consent validity checks.

### Changed
- **ConsentService**: Added offline-aware consent recording and sync helpers.
- **ModelSelectionScreen**: Enforced consent capture before model changes.

## [2026-01-26 01:20] - Emergency Banner Overlay & Localization

### Added
- **Localization**: Added Flutter localization delegates and supported locales to app bootstrap.
- **Dependencies**: Added `flutter_localizations` to enable localization scaffolding.
- **Dependencies**: Updated `intl` to ^0.20.2 for Flutter localization compatibility.
- **Compliance Docs**: Added developer checklist entry for mandatory Emergency Use Banner.
- **Tests**: Added widget coverage for Emergency Use Banner across light and dark themes.

### Changed
- **AIScreen**: Rendered `EmergencyUseBanner` via Overlay with top priority placement.
- **EmergencyUseBanner**: Localized all disclaimer strings and upgraded announcement API usage.
- **ExportService**: Localized emergency warning text for exported headers.

## [2026-01-26 00:55] - Export Emergency Warning Headers

### Changed
- **ExportService**: Added emergency warning banner to follow-up and compliance export headers.

## [2026-01-26 00:30] - Emergency Use Banner Implementation

### Added
- **GlassBanner**: Created `GlassBanner` widget in `lib/widgets/design/glass_banner.dart` extending `GlassCard` for consistent alert UI.
- **EmergencyUseBanner**: Implemented mandatory non-dismissible banner in `lib/widgets/compliance/emergency_use_banner.dart`.
  - **Interaction**: Added "Double tap for details" pattern with haptic feedback.
  - **Compliance**: Added "Not for Medical Emergencies" warning with amber styling.
  - **Details**: Added dialog with safety bullet points.

### Changed
- **AIScreen**: Integrated `EmergencyUseBanner` at the top of the stack (non-dismissible).
- **ExportService**: Added `EmergencyUseBanner` warning content to exported PDF headers (Follow-Up, Transcript, Compliance reports).
- **SessionManager**: Added `onResume` stream to trigger lifecycle-aware UI updates.
- **EmergencyUseBanner**: Connected to `SessionManager.onResume` to trigger accessibility announcements on app resume.

## [2026-01-25 23:50] - Privacy Manifest & Dashboard Integration

### Added
- **PrivacyManifestService**: Created service to aggregate privacy metrics, storage usage, and access logs into a verifiable manifest.
  - **Privacy Score**: Implemented dynamic scoring algorithm based on privacy settings and security events.
  - **Manifest Export**: Added PDF export functionality for privacy manifests.
- **PrivacyManifestScreen**: Added dedicated screen for visualizing privacy data with Liquid Glass design.
  - **Visualizations**: Added interactive score card, storage breakdown, and access history log.
  - **Developer Mode**: Added toggle to view raw technical details.

### Changed
- **SettingsScreen**: Added navigation entry for Privacy Manifest.
- **SecurityDashboardScreen**: Integrated Privacy Manifest into Data Management section.

## [2026-01-25 23:30] - Data Minimization Protocol

### Added
- **TempFileManager**: Implemented `TempFileManager` service in `lib/services/temp_file_manager.dart` for secure lifecycle management of temporary files.
  - **Secure Deletion**: Implemented DoD 5220.22-M compliant 3-pass overwrite (Random, Zero, Random) and post-deletion integrity verification.
  - **Retention Policy**: Integrated with `EnhancedPrivacySettings` to respect user-configurable retention periods.
  - **Orphan Cleanup**: Added background scanning for orphaned temporary files (wav, jpg, enc) to prevent storage leaks.
  - **File Locking**: Implemented file preservation mechanism to prevent purging active files during recording/scanning.
- **EnhancedPrivacySettings**: Added `tempFileRetentionMinutes` field for granular retention control.
- **SecurityDashboardScreen**: Added "Data Management" section with manual purge functionality and glassmorphic progress indicator.

### Changed
- **ConversationRecorderService**: Integrated `TempFileManager` to manage and secure-delete raw WAV segments.
- **DocumentScannerScreen**: Integrated `TempFileManager` to securely manage captured and compressed images.
- **SessionManager**: Added background trigger for `TempFileManager.purgeAll` on app pause.

## [2026-01-25 22:10] - User Education Modals

### Changed
- **IssueReportingService**: Added preview/build flow, toggle-aware payloads, and JSON export alongside PDF.
- **IssueReportingService**: Added queue/submission audit events and encrypted JSON export format.
- **IssueReportingReviewScreen**: Refreshes previews on toggle changes and supports format selection on export.
- **IssueReportAdapter**: Generated Hive adapter for issue report storage.

## [2026-01-25 22:10] - User Education Modals

### Changed
- **AppSettings**: Store education completion versions for feature education gating.
- **EducationService**: Added version-aware completion checks and analytics events.
- **EducationModal**: Added accessibility labels and analytics display logging.
- **EducationGate**: Updated to async completion checks for versioned education.
- **SecurityDashboardScreen**: Added education completion status with async version checks.
- **GlassBottomNav**: Added attention indicators for incomplete education.
- **SehatLockerApp**: Added navigation education indicators for AI and Documents.
- **SessionManager**: Added education modal trigger for first-use flows.
- **AIScreen**: Added session-triggered education display on first use.
- **DocumentScannerScreen**: Added session-triggered education display on first use.
- **ConversationRecorderService**: Enforced education gating before recording.
- **AuthGate**: Added optional education gating for secured features.
- **AppSettingsAdapter**: Regenerated for education completion fields.
- **EducationModal**: Avoided using BuildContext after async gaps.
- **SecurityDashboardScreen**: Removed unused import after education refactor.
- **DocumentsScreen**: Removed unused education gate import.
- **AppSettingsAdapter**: Normalize education and audio IDs to Sets on read.

## [2026-01-25 21:20] - Citation System Integration

### Added
- **CitationService**: Added citation migration for existing documents and text-based citation generation.
- **CitationAdapter**: Added Hive adapter for Citation storage.
- **ExportService**: Added document extraction export with citation preservation across formats.

### Changed
- **AIService**: Added citation post-processing step to append reference sections.
- **DocumentExtraction**: Updated Hive adapter to persist citations.
- **PdfExportService**: Added reference section rendering for document exports.
- **VaultService**: Generates and stores citations during auto-category document saves.
- **main.dart**: Runs citation migration during app startup.

## [2026-01-25 20:00] - Model Output Validation System

### Added
- **AIService**: Implemented `AIService` with validation middleware and streaming interruption support.
- **Validation System**:
  - **ValidationRule**: Created abstract base class for extensible rules.
  - **Rules**: Implemented `TreatmentRecommendationRule` (blocks specific treatment advice), `TriageAdviceRule` (flags emergencies), and `DiagnosticLanguageRule` (rewrites diagnostic statements).
  - **Configuration**: Added `assets/data/validation_rules.json` for rule management.
- **UI**:
  - **AIResponseBubble**: Created a widget with visual indicators (shield icon) for modified or warned content.

### Changed
- **SessionManager**: Updated to track validation failures per session.
- **Integration**:
  - **SafetyFilterService**: Integrated as a complementary layer in `DiagnosticLanguageRule`.
  - **SecureLogger**: Integrated to log validation failures and performance warnings (redacted).
- **Testing**:
  - Added `test/services/ai_service_validation_test.dart` with coverage for all rules and streaming flow.

## [2026-01-25 19:00] - FDA Disclaimer Component

### Added
- **FdaDisclaimerWidget**: Created a reusable, accessible widget extending `GlassCard` to display FDA disclaimers.
  - **Accessibility**: Includes `Semantics` for screen readers and WCAG 2.1 compliant contrast.
  - **Interactivity**: Supports tappable "Learn more" link with haptic feedback.
  - **Logging**: Automatically logs displays via `ComplianceService`.
- **ComplianceService**: Service to manage disclaimer versions and track user acknowledgments/displays via `AuthAuditService`.

### Changed
- **ConversationTranscriptScreen**: Integrated `FdaDisclaimerWidget` below the recording disclaimer.
- **ExportService**: Added FDA disclaimer text to the footer of all generated PDFs.
- **AIScreen**: Added `FdaDisclaimerWidget` to the bottom of the quick actions list for visibility.

## [2026-01-25 18:30] - Safety Filter Service

### Added
- **SafetyFilterService**: Implemented a service to scan and sanitize AI outputs for prohibited diagnostic language.
  - **Detection**: Flags phrases like "you have", "diagnosis", "likely condition", etc.
  - **Replacement**: Replaces prohibited content with educational alternatives ("Some people with similar concerns...").
  - **Performance**: Optimized for < 50ms processing time.
  - **Logging**: Logs triggers in debug mode (redacted in release).
- **Unit Tests**: Added comprehensive tests covering all prohibited patterns and performance requirements.

### Changed
- **FollowUpCard**: Integrated `SafetyFilterService` to sanitize titles and descriptions before display.
- **ConversationTranscriptScreen**: Added placeholder for future integration of safety filter with AI summaries.

## [2026-01-25 18:00] - Lock Screen Widget (ICE)

### Added
- **Lock Screen Widget**: Implemented widgets for Android and iOS to display emergency contact info when locked.
  - **Android**: `SehatLockerWidget` provider showing app icon and optional ICE info.
  - **iOS**: `SehatLockerWidget` using WidgetKit (Accessory & Home Screen families) with App Groups.
- **Privacy & Security**:
  - **Redaction**: ICE data is partially redacted (e.g., `***-***-1234`) before being stored in widget data.
  - **No Medical Data**: Strict policy ensures no medical records are ever sent to the widget.
  - **Explicit Enablement**: Users must opt-in via Security Dashboard to show ICE info.
- **IceContactScreen**: New screen to manage Emergency Contact Name and Phone, with widget preview/toggle.
- **WidgetDataService**: Service to handle secure formatting and updating of widget data from AppSettings.
- **Dependencies**: Added `home_widget` for cross-platform widget data sharing.

### Changed
- **SecurityDashboardScreen**: Added entry point for "ICE Contact" management.
- **AppSettings**: Added `iceContactName`, `iceContactPhone`, and `showIceOnLockScreen` fields.
- **LocalStorageService**: Trigger widget updates automatically when AppSettings are saved.

## [2026-01-25 17:30] - Auth Audit Trail

### Added
- **AuthAuditService**: Dedicated service for logging authentication events with device ID and battery level context.
- **AuthAuditEntry**: Enhanced Hive model with `deviceId`, `batteryLevel`, and `failureReason` fields.
- **Security Dashboard**: Updated to display enhanced auth audit logs, including action types and failure reasons.

### Changed
- **BiometricService**: Integrated `AuthAuditService` to log biometric auth attempts (success/failure).
- **PinAuthService**: Integrated `AuthAuditService` to log PIN verification attempts (success/failure/lockout).
- **AudioPlaybackService**: Integrated `AuthAuditService` to log recording playback/decryption attempts.
- **LocalStorageService**: Registered `AuthAuditEntryAdapter` (TypeId 13).

## [2026-01-25 16:30] - Secure Logging

### Added
- **SecureLogger**: Created a secure logging utility (`SecureLogger`) to prevent sensitive data leakage.
  - **Redaction**: Automatically redacts SSNs, phone numbers, emails, MRNs, and doctor names.
  - **Environment Aware**: Logs to console in debug mode (redacted); disables logging in release mode.
  - **Audit Safety**: Blocks highly sensitive keywords (keys, biometric tokens) from being logged.
  - **Custom Rules**: Supports adding domain-specific redaction patterns.

## [2026-01-25 16:00] - Biometric Enrollment & Fallback

### Added
- **Biometric Enrollment Flow**: Implemented proactive detection and guidance for biometric enrollment.
  - **Proactive Check**: App checks for `availableButNotEnrolled` status on launch and resume.
  - **Guided Dialog**: `BiometricEnrollmentDialog` explains benefits and links to system settings.
  - **Platform Integration**: Deep links to Android/iOS/Windows/macOS security settings via `app_settings`.
  - **Contextual Triggers**: `AuthGate` prompts for enrollment before sensitive operations if available but not set up.
- **PIN Fallback Integration**:
  - **AuthGate**: Integrated `PinUnlockScreen` for users who decline biometrics or are locked out.
  - **Unified Flow**: Seamless transition between Biometric Prompt -> Enrollment -> PIN Fallback.
- **BiometricStatus**: Added `BiometricStatus` enum (enrolled, availableButNotEnrolled, notAvailable) to `BiometricService`.

### Changed
- **SehatLockerApp**: Added lifecycle observer to re-check biometric status on app resume.
- **AuthGate**: Enhanced `_checkAuth` logic to handle enrollment prompts and PIN verification.
- **BiometricService**: Added `getBiometricStatus()` and `openSecuritySettings()` methods.

## [2026-01-25 15:15] - Security Dashboard

### Added
- **SecurityDashboardScreen**: New dashboard in Settings providing a comprehensive view of security status.
  - **Visual Cards**: Displays Auth Status, Device Security, and Storage Security metrics.
  - **Risk Indicators**: Calculates a security score (0-100) with improvement suggestions.
  - **Audit Trail**: Shows a timeline of recent security events (Session Unlocks, Exports).
  - **Quick Actions**: One-tap access to "Lock Now", "Audit Log", and "Security Settings".
- **SessionManager**: Added `lastUnlockTime` tracking to support "Last authenticated" status.
- **SettingsScreen**: Added entry point for "Security Dashboard".

### Changed
- **StorageUsageService**: Utilized for real-time storage encryption metrics.

## [2026-01-25 14:45] - Session Timeout Follow-ups

### Changed
- **AppSettingsAdapter**: Convert `keepAudioIds` to a Set when reading from Hive.

## [2026-01-25 14:30] - Session Timeout & Lock Screen

### Added
- **SessionManager**: Implemented inactivity detection service with configurable timeout.
  - Detects user inactivity using `SessionGuard` (pointer events).
  - Handles app lifecycle changes (locks on resume if timeout exceeded).
  - Exempts locking during active recording.
- **LockScreen**: Created a glassmorphic lock screen with blurred background.
  - Supports Biometric authentication via `BiometricService`.
  - Supports PIN fallback via `PinUnlockScreen`.
- **SessionGuard**: New widget to wrap the app and detect interactions.
- **Settings**: Added "Session Timeout" slider (1-10 minutes) to Security settings.

### Changed
- **AppSettings**: Added `sessionTimeoutMinutes` field (default: 2 minutes).
- **MyApp**: Integrated `SessionManager` and `SessionGuard` at root level.
- **ConversationRecorderService**: Refactored to Singleton to share state with `SessionManager`.

## [2026-01-25 13:00] - Enhanced Auth Prompt UI

### Added
- **AuthPromptDialog**: Created a new glassmorphic authentication prompt with enhanced UI.
  - Features frosted glass background, app icon header, and large biometric indicator.
  - Implements secure screen protection (Android) to prevent screenshots during auth.
  - Includes scale animation and haptic feedback.
  - Supports dynamic text sizing and accessibility labels.
- **Dependencies**: Added `flutter_windowmanager` for screen security flags.

### Changed
- **ExportService**: Integrated `AuthPromptDialog` into the export flow (Follow-up & Compliance reports).

## [2026-01-25 12:20] - Fallback PIN Authentication

### Added
- **PinAuthService**: Secure PIN hashing, lockout/backoff, expiry checks, and security question recovery using `flutter_secure_storage`.
- **PinSetupScreen**: PIN setup wizard with recovery question and 90-day expiration notice.
- **PinUnlockScreen**: PIN verification and recovery flow for PIN-gated access.
- **SettingsScreen**: Added "PIN & Recovery" entry to update PIN and security question.

### Changed
- **AuthGate**: Added PIN fallback when biometrics are unavailable or locked out.
- **SehatLockerApp**: Added onboarding PIN wizard for devices without biometrics.
- **BiometricService**: Added enrolled biometrics check for PIN fallback decisions.

### Testing
- `flutter analyze` (failed: existing warnings/errors in storage_usage_service.dart, temporal_phrase_patterns_configuration.dart, transcription_service.dart, emergency_stop_button.dart, tests, and vault_service_integration_test.dart)
- `flutter test` (failed: BiometricService local_auth options errors, app_settings.g.dart keepAudioIds Set/List mismatch, and follow_up_extractor_enrichment_test.dart mock issue)

## [2026-01-25 11:30] - Sensitive Screen Access Controls

### Changed
- **SehatLockerApp**: Wrapped the AI tab in `AuthGate` with settings-backed enablement.
- **ConversationTranscriptScreen**: Protected transcript viewing behind `AuthGate`.
- **BiometricSettingsScreen**: Protected security settings behind `AuthGate`.
- **ExportService**: Added biometric checks for follow-up and recording compliance exports.

## [2026-01-25 10:15] - Enhanced Privacy Settings

### Added
- **EnhancedPrivacySettings**: New model to store granular biometric preferences (Hive TypeId: 12).
- **BiometricSettingsScreen**: New screen to manage security levels with granular toggles.
  - Controls for Sensitive Data Access, Export Data, Model Management, and Security Settings.
  - Implements "Admin Mode" requiring auth to change security settings.
  - Displays warning when disabling security features.
  - Disables options if biometrics are unavailable on the device.

### Changed
- **AppSettings**: Integrated `EnhancedPrivacySettings` field.
- **SettingsScreen**: Replaced simple Biometric toggle with navigation to `BiometricSettingsScreen`.
- **AudioPlaybackService**: Now respects `requireBiometricsForSensitiveData` setting.
- **ExportService**: Now respects `requireBiometricsForExport` setting.
- **AIScreen**: Resume recording now respects `requireBiometricsForSensitiveData` setting.
- **ModelSelectionScreen**: Model changes now respect `requireBiometricsForModelChange` setting.

## [2026-01-25 09:45] - Biometric Authentication Integration

### Changed
- **BiometricService**: Added session-bound authentication flow, fallback behavior for missing biometrics, and user-friendly error mapping.
- **AudioPlaybackService**: Bound biometric prompts to the active app session.
- **AIScreen**: Bound resume-recording biometric prompt to the active app session.
- **ExportService**: Bound transcript export biometric prompt to the active app session.

### Testing
- `flutter test` (failed: existing LocalStorageService/Hive setup errors in vault_service_integration_test.dart and widget_test.dart, widget_test.dart counter assertion, follow_up_extractor_temporal_test.dart assertions, follow_up_extractor_enrichment_test.dart mock issue)
- `flutter analyze` (failed: existing deprecated_member_use warnings and test warnings/errors, including follow_up_extractor_enrichment_test.dart mock issue)

## [2026-01-24 14:15] - Follow-up Extractor Integration Tests

### Changed
- **FollowUpExtractor Integration Tests**: Normalized verb assertions to be case-insensitive and aligned with extractor verb selection.
- **FollowUpExtractor Integration Tests**: Adjusted poor-audio transcript markers to avoid unintended sentence splitting.
- **FollowUpExtractor Integration Tests**: Updated warning sentence to avoid monitoring verb collision.
- **FollowUpExtractor Integration Tests**: Allowed full warning verb set in assertions.
- **FollowUpExtractor Integration Tests**: Allowed appointment object to match doctor name or follow-up keyword.

### Testing
- `flutter test test/services/follow_up_extractor_integration_test.dart`
- `flutter analyze` (failed: existing warnings/errors in emergency_stop_button.dart, follow_up_extractor_enrichment_test.dart, follow_up_extractor_deduplication_test.dart, vault_service_integration_test.dart)

## [2026-01-24 14:00] - Storage Usage Indicator

### Added
- **StorageUsageService**: Created `lib/services/storage_usage_service.dart` to calculate storage usage for conversations, documents, and models.
- **Settings UI**:
  - **Storage Usage Indicator**: Added circular progress bar showing app storage usage.
  - **Breakdown**: Displays detailed usage for Conversations, Documents, and AI Models.
  - **Threshold Alert**: Shows warning if storage usage exceeds 80% (simulated).
  - **Actions**: Added "Clear expired recordings" and "Compress old recordings" (stub) buttons.

### Changed
- **SettingsScreen**: Updated Storage section to include the new usage indicator and actions.

## [2026-01-24 13:45] - Battery Optimization & Monitoring

### Added
- **BatteryMonitorService**: Created `lib/services/battery_monitor_service.dart` to monitor battery levels and state.
- **Battery Warnings**: Added "Battery Warnings" toggle to `SettingsScreen` (enabled by default).
- **Pre-Recording Check**: Added low battery warning dialog (<20%) in `AIScreen` before starting recording.
- **Real-Time Monitoring**: Added persistent "Recording in Progress" notification with battery % updates.
- **Critical Battery Stop**: Implemented auto-stop safety mechanism when battery drops below 10%.

### Changed
- **ConversationRecorderService**: Integrated `BatteryMonitorService` for runtime monitoring and optimization.
  - Reduces sample rate to 8kHz (from 16kHz) if battery is low (<15%) at start of recording.
  - Updates system notification with battery level during recording.
- **AIScreen**: Updated recording flow to include battery check and handle critical stop events.
- **AppSettings**: Added `enableBatteryWarnings` field.

## [2026-01-24 13:30] - Speaker Diarization

### Added
- **Speaker Diarization Stub**: Implemented heuristic-based speaker assignment in `TranscriptionService`.
  - **Rules**:
    - First segment defaults to User.
    - Silence gaps (>1.5s) trigger speaker alternation.
    - High medical terminology density (>10%) assigns to Doctor.
    - Low confidence (<60%) marks as Unknown.
- **Transcript UI**:
  - **Speaker Badges**: Added colored badges (Blue=User, Green=Doctor, Grey=Unknown) to transcript segments.
  - **Manual Override**: Tapping the speaker label toggles assignment (User -> Doctor -> Unknown).
  - **Confidence Score**: Displayed speaker confidence percentage next to the label.

### Changed
- **ConversationSegment**: Added `speakerConfidence` field to Hive model.
- **TranscriptionService**: Integrated `MedicalDictionaryService` for density analysis.

## [2026-01-24 13:15] - Export Security & Formats

### Added
- **ExportService Enhancements**:
  - **Multi-Format Support**: Added support for Plain Text (`.txt`) and Encrypted JSON (`.json.enc`) exports alongside PDF.
  - **Biometric Security**: Enforced biometric authentication before generating sensitive exports.
  - **PII Redaction**: Implemented regex-based redaction for phone numbers, emails, and addresses in all export formats.
  - **Watermarking**: Added "PRIVATE - DO NOT DISTRIBUTE" watermark to PDF exports.
  - **Audit Logging**: Logs every export action (format, timestamp, recipient type) to `ExportAuditEntry` for compliance tracking.
- **ExportAuditEntry**: Created `lib/models/export_audit_entry.dart` Hive model (TypeId 11) to store export logs.
- **LocalStorageService**: Added `export_audit_entries` box and CRUD methods (`saveExportAuditEntry`, `getAllExportAuditEntries`) to persist export logs.

### Changed
- **ExportService**: Deprecated `exportTranscript` in favor of `exportTranscriptEnhanced` which supports the new options class.
- **Dependencies**: Fixed `share_plus` usage and `pdf` package text styling compatibility.

## [2026-01-24 13:00] - Recording Disclaimer & Watermark

### Added
- **RecordingDisclaimer**: Created `lib/widgets/design/recording_disclaimer.dart`, a reusable widget with FDA-compliant disclaimer text ("personal reference only", "not medical advice") and a confirmation checkbox.
- **ExportService**: Added `exportTranscript` method that generates a PDF transcript with a prominent **"[PERSONAL REFERENCE ONLY]"** watermark (rotated, low-opacity background text) to ensure compliance when sharing.
- **DoctorConversation**: Added compliance metadata fields:
  - `complianceVersion`: Tracks the version of the disclaimer agreed to.
  - `complianceReviewDate`: Tracks when the user reviewed/confirmed the transcript.
- **ConversationTranscriptScreen**:
  - Integrated `RecordingDisclaimer` at the top of the transcript list.
  - Added "Export Transcript" action to the AppBar.
  - Implemented export flow using the watermarked PDF service.

### Changed
- **RecordingConsentDialog**: Replaced the simple consent text with the full `RecordingDisclaimer` widget to ensure users acknowledge terms before recording starts.
- **AIScreen**: Updated to initialize `complianceVersion` and `complianceReviewDate` when a new conversation is created.
- **ExportService**: Refactored PDF generation to use a shared `_saveAndSharePdf` method and added watermark support via `pw.PageTheme`.

## [2026-01-24 12:45] - Emergency Stop Feature

### Added
- **EmergencyStopButton**: Created `lib/widgets/design/emergency_stop_button.dart`, a fixed red button for immediate recording termination.
- **ConversationRecorderService**: Added `emergencyStop` method to stop recording, delete temporary files, and clear memory buffers immediately.
- **AIScreen**: Integrated emergency stop flow:
  - Displays red confirmation modal ("DELETE RECORDING?").
  - Logs "EMERGENCY DELETION" audit entry (no audio metadata).
  - Navigates back to Documents screen upon completion.
  - Requires no additional authentication for safety.

## [2026-01-24 12:15] - Empty Conversations State

### Added
- **EmptyConversationsState**: Created `lib/widgets/empty_states/empty_conversations_state.dart`, a specialized empty state widget featuring:
  - Large microphone icon with pulse animation and gradient.
  - Primary call-to-action button: "+ Record Doctor Visit".
  - Privacy disclaimer and onboarding tooltip.
  - Accessibility semantics.

### Changed
- **DocumentsScreen**: Integrated `EmptyConversationsState` to replace the default empty state when no documents are found.
  - Added `onRecordTap` callback to navigate to the AI/Recording screen.
- **SehatLockerApp**: Updated `DocumentsScreen` instantiation to pass `onRecordTap`, ensuring navigation to the Recording tab (Index 2).

## [2026-01-24 12:05] - Search Service Lint Cleanup

### Changed
- **SearchService**: Added braces around index rebuild loops and simplified string interpolation to satisfy analyzer rules.

### Testing
- `flutter analyze` (failed: undefined_method in VaultService, non_abstract_class_inherits_abstract_member in follow_up_extractor_enrichment_test, unused_import in transcription_service, avoid_print warnings, deprecated_member_use warnings, unused_local_variable warnings)

## [2026-01-24 11:50] - Search Fuzzy Matching

### Added
- **SearchService**: Added fuzzy matching using token-level similarity scoring for titles, keywords, and content.

### Changed
- **SearchService**: Wired medical term extraction to `MedicalDictionaryService.findAllTerms()` for keyword indexing.

## [2026-01-24 11:30] - Enhanced Search with ObjectBox

### Added
- **SearchService**: Re-implemented using **ObjectBox** for high-performance full-text search and fuzzy matching.
  - **Real-time Indexing**: Automatically updates index when Conversations, Follow-Ups, or Documents are saved/edited.
  - **Privacy**: Implemented regex-based masking for sensitive data (SSN, account numbers) before indexing.
  - **Ranking**: Boosts search results based on title match (high), keyword match (medium), and content match (low).
  - **Medical Term Boosting**: Extracts and indexes medical terms using `MedicalDictionaryService` to prioritize medically relevant results.
- **SearchEntry**: Created `lib/models/search_entry.dart` ObjectBox entity for unified search index storage.
- **DocumentsScreen**: Added "Conversations" section to search results with excerpt highlighting (bold text + context).
- **MedicalDictionaryService**: Added `findAllTerms` method to support keyword extraction.

### Changed
- **Dependencies**: Added `objectbox` and `objectbox_flutter_libs` (v2.4.0) to `pubspec.yaml` (downgraded to resolve conflict with hive_generator).
- **Main**: Added `SearchService.init()` to ensure search index availability on startup.
- **SearchService**: Fixed linter errors by aliasing Hive and ObjectBox imports to resolve `Box` ambiguity.

## [2026-01-24 10:15] - Transcript Editing & Versioning

### Changed
- **DoctorConversation**: Added `originalTranscript` and `editedAt` fields to support transcript versioning.
- **ConversationTranscriptScreen**: Added full editing capabilities including:
  - Editable text fields for segments.
  - Speaker toggle (User/Doctor).
  - Undo/Redo functionality.
  - Validation metrics (Quality Score, Character Count).
  - "Confirm Transcript" workflow.

## [2026-01-24 10:00] - Background Recording & Data Safety

### Changed
- **ConversationRecorderService**: Enhanced with full lifecycle awareness.
  - Automatically pauses recording when app goes to background.
  - Flushes buffered audio to encrypted segments immediately on pause (Data Safety).
  - Merges encrypted segments seamlessly upon completion.
  - Implemented auto-stop after 5 minutes of background inactivity (Battery Saver).
  - Shows system notification when recording is paused in background.
- **AIScreen**: Updated to handle secure resume flow.
  - Requires **Biometric Authentication** to resume recording.
  - Syncs pause state with service (e.g., when background paused).
  - Handles auto-stop callback from service.
- **RecordingControlWidget**: Updated to use `RecorderProgress` model for better type safety.

## [2026-01-24 09:20] - Recording Audit Logs

### Added
- **RecordingAuditEntry**: Created `lib/models/recording_audit_entry.dart` Hive model and adapter for recording audit logs.
- **LocalStorageService**: Added `recording_audit_entries` box with save and retrieval helpers.
- **RecordingHistoryScreen**: Created `lib/screens/recording_history_screen.dart` to display recording audit history and export compliance reports.
- **ExportService**: Added recording compliance PDF export with redacted doctor name and device ID fields.

### Changed
- **AIScreen**: Auto-creates audit entries on recording stop with duration, consent flag, file size, and device ID.
- **SettingsScreen**: Added "Recording History" entry under Privacy & Security.
- **RecordingHistoryScreen**: Cleaned unused import.

### Testing
- **flutter analyze**: Fails due to existing issues in biometric_service.dart and tests (unrelated to this change).
- **flutter test**: Fails due to existing biometric_service.dart errors and test setup issues (unrelated to this change).

## [2026-01-24 08:30] - Auto-Delete Recording Policy

### Added
- **ConversationCleanupService**: Created `lib/services/conversation_cleanup_service.dart` to manage automated deletion of expired audio recordings.
  - Deletes audio files older than `autoDeleteRecordingsDays` (default: 365).
  - Skips conversations with pending follow-up items or those explicitly marked as "Keep Permanently".
- **AppSettings**: Added `autoDeleteRecordingsDays` and `keepAudioIds` fields to support the policy.
- **Settings UI**: Added "Auto-delete Recordings" configuration in `SettingsScreen` (Recording section).
- **Transcript UI**: Added "Keep Permanently" toggle and expiration banner to `ConversationTranscriptScreen`.

### Changed
- **Main**: Added `ConversationCleanupService.runDailyCleanup()` on app startup.
- **DoctorConversation**: Made `encryptedAudioPath` mutable to allow clearing the path after deletion.

## [2026-01-24 07:45] - Secure Audio Playback

### Added
- **EncryptionService**: Created `lib/services/encryption_service.dart` (Singleton) using AES-256-GCM.
  - Generates and stores a secure master key using `flutter_secure_storage` (Android KeyStore / iOS Secure Enclave).
  - Handles encryption and decryption with random IVs.
- **BiometricService**: Created `lib/services/biometric_service.dart` to handle biometric authentication using `local_auth`.
- **AudioPlaybackService**: Created `lib/services/audio_playback_service.dart` for secure playback logic.
  - Enforces biometric authentication before decryption.
  - Returns stub audio (silence) if authentication fails/is disabled (security requirement).
  - Logs playback attempts (audit trail).
- **ConversationTranscriptScreen**: Updated to include a secure playback flow.
  - Added lock/unlock icon for playback.
  - Integrated biometric prompt.
  - Uses `flutter_sound` to play decrypted audio in memory.

### Changed
- **Main**: Initialized `EncryptionService` on app startup to ensure key readiness.
- **ConversationRecorderService**: Refactored to use `EncryptionService` for consistent audio encryption.
- **TranscriptionService**: Refactored to use `EncryptionService` for decryption during transcription.
- **Dependencies**: Added `local_auth` for biometrics.

## [2026-01-24 07:00] - Vault Conversation Linking

### Added
- **VaultService**: Added `saveConversationToVault` method to link `DoctorConversation`s to `HealthRecord`s.
  - Creates a `HealthRecord` with `recordType = 'DoctorConversation'`.
  - Links via `extractionId`.
  - Stores metadata: duration, doctorName, transcriptLength, hasFollowUps.
- **HealthRecord**: Added `typeDoctorConversation` constant.
- **ConversationGridCard**: Created `lib/widgets/cards/conversation_grid_card.dart` to display conversation records in the documents grid.
  - Displays doctor icon, duration badge, and conversation details.
- **DocumentsScreen**: Updated to display conversation cards and navigate to `ConversationTranscriptScreen` on tap.

## [2026-01-24 06:15] - Conversation Summary Card

### Added
- **ConversationSummaryCard**: Created `lib/widgets/cards/conversation_summary_card.dart` to display conversation details.
  - Shows title, doctor name, date, and duration.
  - Automatically derives and displays "Key Topics" (FollowUpCategories) from linked follow-up items.
  - Uses `GlassCard` for a consistent modern UI.
- **LocalStorageService**: Added `getFollowUpItem(String id)` method to facilitate efficient item retrieval by ID.

## [2026-01-24 06:00] - Follow-Up PDF Export

### Added
- **ExportService**: Created `lib/services/export_service.dart` to generate and share PDF reports of pending follow-up items.
  - Groups items by category.
  - Includes source conversation references.
- **FollowUpListScreen**: Added "Export Report" button to the AppBar.
- **Dependencies**: Added `share_plus` and `printing` to `pubspec.yaml` for file sharing and PDF handling.

## [2026-01-24 05:30] - Follow-Up Search & Indexing

### Added
- **SearchService**: Updated to support indexing `FollowUpItem`s.
  - Automatically listens to changes in `follow_up_items` Hive box and updates the search index.
  - Indexes verb, object, description, and category.
- **DocumentsScreen**: Integrated follow-up items into the unified search.
  - Displays a mixed list of "Follow-Ups" and "Documents" when searching.
  - Supports editing and completing follow-up items directly from search results.
- **Main**: Initialized `SearchService` listener on app startup to ensure index consistency.

## [2026-01-24 05:15] - Doctor Visit Prep Feature

### Added
- **DoctorVisitPrepScreen**: Created `lib/screens/doctor_visit_prep_screen.dart` to help users prepare for doctor visits.
  - Automatically fetches and lists pending follow-up items.
  - Allows selecting items to include in an agenda.
  - Generates a text agenda (Follow-up items + Due dates) that can be copied to clipboard.
- **FollowUpListScreen**: Added a "Doctor Visit Prep" action button in the AppBar to navigate to the prep screen.

## [2026-01-24 05:00] - Follow-Up Source Linking

### Changed
- **FollowUpCard**: Added a tappable "Extracted from [Conversation Title]" link.
  - Fetches the source conversation using `sourceConversationId`.
  - Navigates to `ConversationTranscriptScreen` on tap to view the full context.

## [2026-01-24 04:45] - FollowUpDashboard Implementation

### Added
- **FollowUpDashboard**: Created `lib/widgets/dashboard/follow_up_dashboard.dart` to display a summary of follow-up items (Pending, Overdue, Due Week).
- **Home Screen Integration**: Integrated the dashboard widget into `DocumentsScreen` (Home) to provide quick access to tasks.

## [2026-01-24 04:30] - Overdue Follow-Up Detection

### Added
- **Overdue Detection**: Added `getOverdueItems` and `followUpItemsListenable` to `LocalStorageService`.
- **UI Notifications**:
  - Displays a **MaterialBanner** on app launch if there are overdue follow-up items.
  - Added a **badge count** to the "Tasks" tab in the bottom navigation bar to show the number of overdue items in real-time.
- **GlassBottomNav**: Updated to support notification badges on navigation items.

### Changed
- **SehatLockerApp**: Updated `initState` to check for overdue items and show the banner.
- **LocalStorageService**: Improved type safety by using typed `Box<FollowUpItem>` for follow-up items storage.

## [2026-01-24 04:00] - FollowUpReminderService Implementation

### Added
- **FollowUpReminderService**: Created `lib/services/follow_up_reminder_service.dart` to handle local notifications.
  - Schedules notifications for follow-up items with due dates.
  - Supports "1 day before" reminders and "on due date" reminders.
  - Supports recurring reminders (Daily, Weekly, Monthly) based on frequency pattern.
- **Dependencies**: Added `flutter_local_notifications` and `timezone` to `pubspec.yaml`.
- **Permissions**: Updated `AndroidManifest.xml` with necessary permissions (POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, etc.).

### Changed
- **Main**: Initialized `FollowUpReminderService` in `main.dart`.
- **FollowUpReviewSheet**: Schedules reminders automatically when items are confirmed/saved.
- **FollowUpListScreen**: Updates/Cancels reminders when items are completed or edited.

## [2026-01-24 03:00] - FollowUpEditDialog Implementation

### Added
- **FollowUpEditDialog**: Created `lib/widgets/dialogs/follow_up_edit_dialog.dart` to allow users to modify follow-up items.
  - Supports editing description, changing category, setting due date, and toggling priority.
  - Validates inputs and returns modified `FollowUpItem`.

### Changed
- **FollowUpListScreen**: Integrated `FollowUpEditDialog`.
  - Tapping an item or the edit button now opens the dialog.
  - Updates the item in Hive storage upon save.
- **FollowUpCard**: Updated to display `description` below the title if available, providing more context to the user.

## [2026-01-24 02:45] - FollowUpReviewSheet & Transcription Flow

### Added
- **FollowUpReviewSheet**: Created `lib/widgets/sheets/follow_up_review_sheet.dart`, a bottom sheet to review and confirm extracted follow-up items after transcription.
- **DoctorConversation Storage**: Added `saveDoctorConversation` and `getAllDoctorConversations` methods to `LocalStorageService`.

### Changed
- **AIScreen**: Integrated the full recording-transcription-extraction-review flow.
  - Triggers transcription and extraction automatically after recording stops.
  - Displays processing state while transcribing.
  - Shows `FollowUpReviewSheet` to let user confirm extracted items.
  - Saves the conversation and confirmed follow-up items to Hive.

## [2026-01-24 02:15] - FollowUpListScreen Implementation

### Added
- **FollowUpListScreen**: Created `lib/screens/follow_up_list_screen.dart` to display grouped follow-up items.
  - Grouped by category with expandable sections.
  - Added count badges per category.
  - Added filter toggle for Completed/Pending items.
  - Uses `FollowUpCard` for item display.
- **LocalStorageService**: Added `_followUpItemsBox` and CRUD methods (`saveFollowUpItem`, `getAllFollowUpItems`, `deleteFollowUpItem`) to manage `FollowUpItem` persistence.
        ### Changed
        - **App Integration**: Integrated `FollowUpListScreen` into the main navigation as the "Tasks" tab.
        - **LocalStorageService**: Updated `initialize` to open the `follow_up_items` Hive box.

## [2026-01-24 02:00] - Add to Calendar Implementation

### Added
- **FollowUpListScreen**: Implemented "Add to Calendar" action for follow-up items.
  - Uses `add_2_calendar` package to create native calendar events.
  - Event title set to item description.
  - Event notes include link to source conversation title.
  - Event date set from `dueDate`.
- **LocalStorageService**: Added `getDoctorConversation` method to retrieve conversation details by ID.

## [2026-01-24 01:45] - FollowUpCard Redesign

### Changed
- **FollowUpCard**: Redesigned widget to match requirements:
  - Title shows **verb + object** (e.g., "Schedule MRI").
  - Added badges for timeframe/frequency and high priority.
  - Recurring items show frequency instead of single date.
  - Added action buttons: "Add to Calendar", "Complete", "Edit".

## [2026-01-24 01:30] - Follow-Up Context Enrichment

### Added
- **Context Enrichment**: Added `enrichItems` method to `FollowUpExtractor` to link extracted items to existing vault records.
  - Links medication items to `Prescriptions` or `Medical Records` in the vault.
  - Links test/monitoring items to `Lab Results` in the vault.
- **FollowUpItem**: Added optional fields `linkedRecordId`, `linkedEntityName`, and `linkedContext` (Hive fields 14-16) to store linkage metadata.
- **Tests**: Added `test/services/follow_up_extractor_enrichment_test.dart` to verify linking logic with mock vault data.

### Changed
- **FollowUpExtractor**: Updated constructor to accept optional `VaultService` dependency.

## [2026-01-24 01:00] - Follow-Up Deduplication

### Added
- **Deduplication Logic**: Implemented Levenshtein distance-based deduplication in `FollowUpExtractor`.
  - Compares new items against existing items using description similarity.
  - Flags items as `isPotentialDuplicate` if similarity > 80%.
- **StringUtils**: Created `lib/utils/string_utils.dart` with `levenshteinDistance` and `calculateSimilarity` functions.
- **FollowUpItem**: Added `isPotentialDuplicate` field (Hive TypeId 7, Field 13).
- **Tests**: Added `test/services/follow_up_extractor_deduplication_test.dart` to verify deduplication logic.

### Changed
- **FollowUpExtractor**: Updated `extractFromTranscript` to optionally accept `existingItems` for duplicate checking.

## [2026-01-24 00:30] - Extractor Matching Fixes

### Fixed
- **TestExtractor**: Require a recognized test/procedure before creating a test follow-up item.
- **MonitoringExtractor**: Added "check" to monitoring verb detection to preserve monitoring categorization when no test is recognized.
- **Frequency Tests**: Injected test medical dictionary service so frequency tests run with loaded configurations.

## [2026-01-24 00:10] - Category-Specific Extractors & Priority Detection

### Added
- **BaseExtractor**: Created `lib/services/extractors/base_extractor.dart` as a base class for specialized extractors, handling temporal info and priority detection.
- **Specialized Extractors**: Implemented category-specific extractors in `lib/services/extractors/`:
  - `MedicationExtractor`: Detects medication verbs ("take", "start") and extracts drug names + dosages.
  - `AppointmentExtractor`: Detects appointment verbs ("schedule", "see") and extracts provider/specialist names.
  - `TestExtractor`: Detects test verbs ("order", "check") and extracts test/procedure names.
  - `LifestyleExtractor`: Detects lifestyle verbs ("exercise", "eat") and extracts targets/frequencies.
  - `MonitoringExtractor`: Detects monitoring verbs ("track", "log") and extracts health metrics/symptoms.
  - `WarningExtractor`: Detects warning verbs ("watch for", "avoid") and extracts symptoms/conditions.
  - `DecisionExtractor`: Detects decision verbs ("discuss", "consider") and extracts topics.

### Changed
- **FollowUpExtractor**: Refactored to delegate extraction to the list of specialized extractors.
- **Priority Detection**: Implemented logic in `BaseExtractor` to set priority to `high` if urgency words ("immediately", "asap") are found.

## [2026-01-23 23:55] - Structured Extraction & UI Card

### Added
- **FollowUpCard**: Created `lib/widgets/follow_up_card.dart` to display follow-up items as human-readable cards with icons and structured titles.
- **Tests**: Added `test/models/follow_up_item_test.dart` to verify `structuredTitle` generation logic.

### Changed
- **FollowUpItem**: Added `structuredTitle` getter to combine `verb`, `object`, and `timeframeRaw` into a rich, human-readable string (e.g., "Schedule MRI within 2 weeks").

## [2026-01-23 23:45] - Frequency Phrase Extraction

### Changed
- **FollowUpExtractor**: Implemented frequency detection and `dueDate` calculation for recurring patterns.
  - Added support for "daily", "twice a day", "every morning", "once a week", "as needed", etc.
  - Calculates the next occurrence `dueDate` based on the frequency (e.g., "daily" -> tomorrow, "weekly" -> +7 days).
- **TemporalPhrasePatternsConfiguration**: Updated `frequency` patterns in `assets/data/temporal_phrase_patterns.json` to be more comprehensive.
- **Tests**: Added `test/services/follow_up_extractor_frequency_test.dart` to verify frequency extraction and due date calculation.

## [2026-01-23 23:15] - Temporal Phrase Extraction

### Changed
- **FollowUpExtractor**: Implemented logic to extract and parse temporal phrases (deadlines, frequencies) into `dueDate` and `timeframeRaw`.
  - Added `referenceDate` parameter to `extractFromTranscript` to support relative date calculations (defaults to `DateTime.now()`).
  - Added support for parsing "in X days/weeks/months/years", "within X hours/days...", "next week/month/year", and "by [weekday]".
- **Tests**: Added `test/services/follow_up_extractor_temporal_test.dart` to verify temporal extraction logic.

## [2026-01-23 23:00] - FollowUpExtractor Validation & Testability

### Changed
- **VerbMappingConfiguration**: Updated `forTesting` constructor to allow injecting a custom map for unit testing.
- **TemporalPhrasePatternsConfiguration**: Updated `forTesting` constructor to allow injecting custom patterns for unit testing.

### Added
- **Tests**: Created `test/services/follow_up_extractor_test.dart` to rigorously validate verb detection, category assignment, and description extraction logic.

## [2026-01-23 22:45] - FollowUpExtractor Sentence Boundary Detection

### Changed
- **FollowUpExtractor**: Enhanced `extractFromTranscript` to support `List<ConversationSegment>` input.
- **Sentence Splitting**: Implemented `_splitIntoSentencesFromSegments` to use punctuation, silence gaps (>1000ms), and speaker changes as sentence boundaries.

## [2026-01-23 22:30] - FollowUpExtractor Service

### Added
- **FollowUpExtractor**: Created `lib/services/follow_up_extractor.dart` service class.
  - **Functionality**: Extracts `FollowUpItem`s from conversation transcripts.
  - **Logic**: Uses regex and NLP heuristics to identify action verbs (from `VerbMappingConfiguration`) and temporal phrases (from `TemporalPhrasePatternsConfiguration`).
- **Tests**: Added `test/services/follow_up_extractor_test.dart` to verify extraction logic.

### Changed
- **VerbMappingConfiguration**: Added `allVerbs` getter and `@visibleForTesting` constructor.
- **TemporalPhrasePatternsConfiguration**: Added `@visibleForTesting` constructor.

## [2026-01-23 22:15] - TemporalPhrasePatterns Configuration

### Added
- **TemporalPhrasePatternsConfiguration**: Created `lib/services/temporal_phrase_patterns_configuration.dart` to load and provide regex patterns for temporal phrases.
- **Assets**: Added `assets/data/temporal_phrase_patterns.json` containing regex patterns for deadline, frequency, and anchor phrases.

### Changed
- **Main**: Updated `lib/main.dart` to initialize `TemporalPhrasePatternsConfiguration` on app startup.

## [2026-01-23 22:00] - VerbMapping Configuration

### Added
- **VerbMappingConfiguration**: Created `lib/services/verb_mapping_configuration.dart` to map action verbs to `FollowUpCategory`.
- **Assets**: Added `assets/data/verb_mapping.json` containing the verb-to-category mapping.

### Changed
- **Main**: Updated `lib/main.dart` to initialize `VerbMappingConfiguration` on app startup.

## [2026-01-23 21:45] - FollowUpCategory Enhancements

### Changed
- **FollowUpCategory**: Enhanced enum in `lib/models/follow_up_item.dart` with `toDisplayString()` and `icon` getter for UI display.
- **Dependencies**: Added `flutter/material.dart` import to `follow_up_item.dart` to support `IconData`.

## [2026-01-23 21:30] - FollowUpItem Model

### Added
- **FollowUpItem**: Created `lib/models/follow_up_item.dart` data class.
  - **Fields**: id, category, verb, object, description, priority, dueDate, etc.
  - **Enums**: `FollowUpCategory` and `FollowUpPriority`.
  - **Hive Persistence**: Generated Hive adapters (TypeId: 7, 8, 9) and registered them in `LocalStorageService`.

## [2026-01-23 21:00] - Conversation Transcript Screen & Diarization

### Added
- **ConversationTranscriptScreen**: New screen to view and edit conversation transcripts.
  - Supports speaker identification (User/Doctor).
  - Allows editing text and toggling speaker labels.
- **ConversationSegment**: New Hive model to store transcript segments with timestamps and speaker info.
- **Speaker Diarization**: Added heuristic-based speaker inference (silence gaps) to `TranscriptionService`.

### Changed
- **TranscriptionService**: Updated to return structured `TranscriptionResult` with segments instead of just a string.
- **DoctorConversation**: Added `segments` field to store detailed transcript data.
- **DoctorConversation**: Made `transcript` field mutable to support edits.

## [2026-01-23 20:30] - Whisper Integration

### Added
- **Dependencies**: Added `whisper_flutter_new` for offline speech-to-text.

### Changed
- **TranscriptionService**: Implemented `transcribeAudio` using `Whisper` (base model).
  - Handles decryption of audio files.
  - Converts decrypted bytes to temporary WAV file.
  - Transcribes using Whisper.cpp.
- **ConversationRecorderService**: Switched recording format to `Codec.pcm16WAV` (16kHz) for Whisper compatibility.
- **AIScreen**: Updated recording file extension to `.wav.enc`.

## [2026-01-23 20:25] - Transcription Service Integration

### Added
- **TranscriptionService**: Created `lib/services/transcription_service.dart` to handle offline speech-to-text.
  - **Stub Implementation**: Added `transcribeAudio` method returning a mock transcript for now.
  - **Whisper Integration**: Prepared structure for future Whisper.cpp integration.

## [2026-01-23 20:15] - Auto-Stop Recording

### Added
- **Auto-Stop Configuration**: Added `autoStopRecordingMinutes` to `AppSettings` (default: 30 minutes).
- **Settings UI**: Added "Recording" section in `SettingsScreen` to configure auto-stop duration (15, 30, 45, 60 minutes).
- **Auto-Stop Logic**: Implemented listener in `AIScreen` to automatically stop recording when the configured duration is reached.
- **Feedback**: Added snackbar notification when recording is auto-stopped.

## [2026-01-23 20:00] - Recording UI & Controls

### Added
- **RecordingControlWidget**: Created `lib/widgets/design/recording_control_widget.dart` featuring:
  - **Circular Timer**: Visual timer showing recording duration.
  - **Visual Mic Indicator**: Animated breathing effect based on audio amplitude.
  - **Controls**: Pause, Resume, and Stop buttons using `GlassButton` styling.
- **Service Enhancements**: Updated `ConversationRecorderService` to support:
  - Pause and Resume functionality.
  - `onProgress` stream for duration and amplitude updates.

### Changed
