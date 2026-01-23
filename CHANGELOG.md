# Changelog - Sehat Locker

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
