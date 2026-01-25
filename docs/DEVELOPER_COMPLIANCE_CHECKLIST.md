# Developer Compliance Checklist

This document tracks compliance and validation requirements for new features.

## AI Model Transparency

- [x] **Model Info Panel Implementation**
  - [x] Displays active model name and version
  - [x] Shows knowledge cutoff date
  - [x] Displays license information
  - [x] Includes performance metrics (load time, speed)
  - [x] **Validation**: Verify `ModelInfoPanel` correctly loads metadata from `ModelManager`.

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
