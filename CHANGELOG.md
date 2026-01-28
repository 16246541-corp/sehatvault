# Changelog - Sehat Locker

## [1.9.18] - 2026-01-28

### Added
- **Profile Health Dashboard**: Implemented comprehensive health metrics dashboard for both Mobile and Desktop platforms displaying ONLY verified health metrics from HealthMetricsAggregator.
  - **Shared Widget**: Created `lib/ui/shared/widgets/profile/metric_card.dart` extending GlassCard:
    - Large value display with headlineSmall typography
    - Source attribution badge using ModelInfoPanel visual pattern
    - Reference range context from ReferenceRangeService (display only)
    - Accessibility labels with full context for screen readers
    - Sensitive data indicators with lock icons
  - **Mobile Dashboard**: Implemented `lib/ui/mobile/screens/profile_health_dashboard_mobile.dart`:
    - Grid layout with 2-column metric cards
    - Pull-to-refresh functionality triggering HealthMetricsAggregator.recompute()
    - Empty state with custom icon and "Add Document" call-to-action
    - FDA disclaimer widget at top with mandatory compliance text
    - Biometric gate via AuthGate for sensitive metrics
    - Loading states with CircularProgressIndicator
  - **Desktop Dashboard**: Implemented `lib/ui/desktop/screens/profile_health_dashboard_desktop.dart` with split-view layout:
    - Sidebar navigation (1/3 width) with metric list
    - Content area (2/3 width) showing selected metric details
    - Document date formatting and source attribution
    - Reference range display with status indicators
    - Refresh functionality and error handling
  - **FDA Compliance**: Integrated FdaDisclaimerWidget with mandatory disclaimer text:
    - "Values verified by you from personal documents. Not a medical record. Consult your provider for health decisions."
    - Displayed prominently at top of both mobile and desktop screens
  - **Privacy & Security**: Enhanced privacy protection with:
    - Biometric authentication gate for sensitive health data
    - Protected Health Information indicators on all metric cards
    - Source document navigation (tappable → DocumentDetailsScreen)
    - No placeholder metrics - only verified data displayed
  - **Architecture Integration**: Full integration with existing services:
    - HealthMetricsAggregator for verified metrics only
    - ReferenceRangeService for display-only reference ranges
    - LocalStorageService for metric persistence
    - AuthGate for biometric protection
    - GlassCard design system consistency

## [1.9.17] - 2026-01-28

### Added
- **Verified Metrics Aggregation Service**: Created FDA-compliant health metrics aggregator that processes only user-verified documents.
  - **HealthMetricsAggregator**: Implemented `lib/services/health_metrics_aggregator.dart` with strict FDA safeguards:
    - `getLatestVerifiedMetric()`: Returns latest verified metric values exclusively from documents where `userVerifiedAt != null`
    - `getAllLatestVerifiedMetrics()`: Aggregates all unique metrics from verified documents with source attribution
    - **Phase 1 Compliance**: Includes `checkPhase1Completion()` method to ensure FDA compliance before metric access
    - **Performance**: Meets <300ms response time requirement for 200 verified documents (tested)
    - **Zero Network Calls**: All computation performed on-device via Hive queries
  - **MetricSnapshot Model**: Created `lib/models/metric_snapshot.dart` (Hive TypeId 68) with:
    - `metricName`, `value`, `unit`, `measuredAt`, `sourceRecordId`, `isOutsideReference` fields
    - Complete audit trail with source document attribution for FDA compliance
  - **UnverifiedDataException**: Added `lib/exceptions/unverified_data_exception.dart` for FDA safeguard violations
  - **LocalStorageService Enhancement**: Extended with metric snapshot persistence and verified document queries:
    - `getDocumentsWithVerifiedExtractions()`: Returns ONLY documents where `userVerifiedAt != null`
    - `saveMetricSnapshot()`, `getMetricSnapshot()`, `getAllMetricSnapshots()` methods
  - **ReferenceRangeService Integration**: Uses existing reference range evaluation but NEVER computes diagnostic conclusions
  - **SecureLogger Compliance**: All methods include `@mustCallSuper` annotation with redaction requirements
  - **Comprehensive Testing**: Added `test/services/health_metrics_aggregator_test.dart` with 15+ test cases covering:
    - FDA compliance verification, performance requirements, edge cases, and error handling

## [1.9.16] - 2026-01-28

### Added
- **Document Chronology Validation System**: Implemented comprehensive date validation to prevent chronologically impossible dates from entering the vault.
  - **DateValidationService**: Created `lib/services/date_validation_service.dart` with chronology validation logic:
    - `isChronologicallyPlausible()`: Validates dates within 7 days before capture and 1 day after
    - `isValidDocumentDate()`: Ensures dates are after 1900 and not more than 1 year in future
    - `isHighConfidenceDate()`: Context-based confidence scoring for header/footer dates
  - **Enhanced MedicalFieldExtractor**: Extended `extractDates()` method to prioritize document header/footer dates:
    - Added confidence scoring (high/medium/low) based on context indicators
    - Implemented document date detection with priority for header/footer locations
    - Returns `documentDate` field with highest confidence header/footer date
  - **DocumentExtraction Model**: Added new Hive fields for document date management:
    - `@HiveField(22) DateTime? extractedDocumentDate`: From OCR text analysis
    - `@HiveField(23) DateTime? userCorrectedDocumentDate`: Explicit user override
  - **Enhanced Verification Screens**: Updated both Mobile and Desktop verification screens:
    - **Document Date Section**: Prominent card with auto-extracted date indicator
    - **"Use Today's Date" Button**: Quick action to set document date to current date
    - **Warning Banner**: Shows validation failures with clear error messages
    - **Date Picker**: Extended range to allow dates up to 1 year in future
    - **Save Blocking**: Prevents saving when date validation fails
  - **VaultService Enhancement**: Added `getDocumentsByDateRange()` method:
    - Filters documents using `userCorrectedDocumentDate ?? extractedDocumentDate`
    - Falls back to `record.createdAt` if no document dates available
    - Returns chronologically sorted results (most recent first)
  - **Audit Logging**: Enhanced with document date correction tracking:
    - Logs `document_date_corrected` events with original vs corrected dates
    - Integrated with existing `document_verified` audit trail

### Changed
- **Extraction Verification Flow**: Updated both mobile and desktop verification screens to prominently display document date validation
- **Date Resolution Logic**: Implemented priority order: user corrected > extracted > structured data > creation date
- **Save Validation**: Enhanced to block saves when chronologically implausible dates are detected

### Fixed
- **Date Validation**: Prevented acceptance of dates more than 1 year in future or before 1900
- **Chronological Consistency**: Added validation to reject dates that are chronologically impossible relative to document capture time

### Added
- **Extraction Verification**: Implemented a mandatory "Verified Extraction Review" screen between OCR and Vault storage.
  - **VerifiedExtractionCard**: Reusable widget for reviewing and editing extracted Lab Values, Medications, and Vitals.
  - **UI (Mobile/Desktop)**: Added platform-specific verification screens (`ExtractionVerificationScreenMobile/Desktop`) with visual confidence indicators.
  - **Data Model**: Extended `DocumentExtraction` with `userVerifiedAt` and `userCorrections` fields (Hive Field 20, 21).
  - **Validation**: Enforced data validation (Reference Ranges) and prevented saving empty or undated extractions.
  - **Audit Trail**: Logged `document_verified` events with extraction ID and category metadata.