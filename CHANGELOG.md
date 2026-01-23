# Changelog - Sehat Locker

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
