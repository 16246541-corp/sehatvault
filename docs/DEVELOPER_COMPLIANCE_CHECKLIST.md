# Developer Compliance Checklist

This document tracks compliance and validation requirements for new features.

## Document Processing

- [x] **Classification Compliance**
  - [x] Document classification uses deterministic patterns only—no AI inference
  - [x] Suggestions are non-binding and require user confirmation
  - [x] Confidence thresholds (<40%) prevent low-quality suggestions
  - [x] **FDA Compliance**: No auto-categorization without user confirmation
  - [x] **VaultService Safety Checks**: Prevents saving documents with auto-assigned or uncategorized status
  - [x] **FileDropService**: Removed auto-save functionality - user must manually categorize

## AI Model Transparency

- [x] **Model Info Panel Implementation**
  - [x] Displays active model name and version
  - [x] Shows knowledge cutoff date
  - [x] Displays license information
  - [x] Includes performance metrics (load time, speed)
  - [x] **Validation**: Verify `ModelInfoPanel` correctly loads metadata from `ModelManager`.

- [x] **Model License Compliance**
  - [x] Comprehensive license tracking system implemented in `ModelLicenseService`
  - [x] Plain language summaries for key restrictions and attribution requirements
  - [x] Export functionality for compliance documentation
  - [x] Integration with `AboutScreen` and `ModelInfoPanel`
  - [x] Access auditing via `SecureLogger`
  - [x] **Validation**: Verify `ModelLicenseScreen` displays accurate license data and export works.

- [ ] **Knowledge Cutoff Warning**
  - [x] Visual indicator for outdated models (> 1 year)
  - [ ] Context-aware warnings in chat for recent events

## Privacy & Security

- [ ] **FDA Disclaimer**
  - [x] Visible on all medical advice screens
  - [x] Included in PDF exports

- [ ] **Data Encryption**
  - [x] AES-256 enabled for all local storage
  - [x] Biometric auth required for access

## Health Intelligence Engine

- [ ] **Health Intelligence Engine (`health_intelligence_engine`)**
  - [ ] **Validation**:
    1. Verify `SafetyFilterService.sanitize()` is applied to all displayed insights.
    2. Confirm `SafetyFilterService.hasDiagnosticLanguage()` blocks diagnostic phrasing (regex audit).
    3. Confirm every insight includes source citations via `CitationService`.
    4. Validate `EmergencyUseBanner` + `FdaDisclaimerWidget` are visible on every insight surface.
    5. Verify audit trail entries exist with `action = 'health_pattern_generated'` and only redacted hashes in details.
    6. Confirm analysis is on-device only (no network calls) via `SecureLogger` review.

## AI Safety & Factual Accuracy

- [ ] **Hallucination Prevention System**
  - [x] Confidence threshold analysis implemented
  - [x] Fact verification against `MedicalKnowledgeBase`
  - [x] Logging of hallucination patterns via `SecureLogger`
  - [x] Analytics collection for detection events
  - [x] **Validation**: Verify `HallucinationValidationStage` is active in `AIService` pipeline.

## AI Usage Analytics

- [x] **Local AI Usage Analytics**
  - [x] Privacy-focused collection (Zero PHI)
  - [x] Visual dashboard with charts and graphs
  - [x] Anonymized data export functionality
  - [x] Retention policies with automatic purging
  - [x] Opt-in management in `SettingsScreen`
  - [x] Performance optimization (minimal overhead)
  - [x] **Validation**: Verify `AIAnalyticsService` logs metrics to Hive and displays in `AIDiagnosticsScreen`.

## AI Error Recovery

- [ ] **AI Error Recovery System**
  - [x] Failure mode detection and classification in `AIRecoveryService`
  - [x] User-friendly error messages with context
  - [x] Exponential backoff for retry attempts
  - [x] Integration with `ModelFallbackSystem` and `SessionManager`
  - [x] Graceful degradation for partial functionality
  - [x] **Validation**: Verify recovery logic in `AIService` via unit tests and manual failure simulation.

## Model Update Verification

- [x] **Secure Model Update System**
  - [x] Offline-first update checking implemented in `ModelUpdateService`
  - [x] Cryptographic signature verification (RSA/Ed25519) in `ModelVerificationService`
  - [x] SHA-256 integrity verification for all model files
  - [x] Version compatibility checking for model upgrades
  - [x] Secure storage for model manifests using encrypted Hive
  - [x] Tamper-evident verification system with recovery mechanisms
  - [x] Integration with `ModelInfoPanel` for update status and actions
  - [x] Connection to `SettingsScreen` for manual update checks
  - [x] Verification logging via `SecureLogger`
  - [x] **Validation**: Verify `ModelUpdateService` and `ModelVerificationService` correctly handle corrupted or unsigned models.
