# Sehat Locker

A **privacy-first, 100% offline** health records locker and AI assistant. Built with Flutter for iOS, Android, macOS, and Windows.

> **Your Health Data, Your Device.** No cloud dependencies. No data ever leaves your phone.

---

## ✨ Core Philosophy

Sehat Locker is designed around three principles:

1.  **Privacy First**: All data is encrypted at rest using AES-256-GCM. Encryption keys are stored in the device's secure enclave (Keychain on iOS/macOS, Keystore on Android).
2.  **Offline First**: All AI features, including LLM chat and audio transcription, run entirely on-device. The app works without an internet connection.
3.  **User Ownership**: You own your data. Export it anytime in open formats (PDF, encrypted JSON).

---

## 🚀 Features

### 📄 Document Vault
*   **Scan & OCR**: Capture medical documents with your camera. On-device Tesseract OCR extracts text with image preprocessing for rotation correction and low-light enhancement.
*   **Automatic Data Extraction**: Regex-based extraction pipeline identifies lab values, medications, and dates from scanned text.
*   **AI-Powered Categorization**: Documents are analyzed and AI suggests categories (Lab Results, Prescriptions, Medical Records, etc.) with confidence scores.
*   **User Confirmation Required**: FDA-compliant workflow requires users to review AI suggestions and manually confirm the category before saving - no auto-categorization without consent.
*   **Duplicate Detection**: SHA-256 content hashing prevents saving the same document twice.
*   **AES-256 Encrypted Storage**: All records are stored in encrypted Hive boxes.

### 🤖 On-Device AI Assistant
*   **Powered by llama.cpp**: Run GGUF-format large language models locally on your device.
*   **Model Selection**: Choose from recommended models based on your device's hardware capabilities (RAM, OS).
*   **Context Management**: Strategic token counting and history truncation to keep conversations within model limits.
*   **Safety Filters**: FDA-compliant language filtering replaces diagnostic phrasing (e.g., "You have X") with educational alternatives.
*   **Wellness Language Validation**: Ensures AI responses use appropriate health terminology.

### 🎙️ Doctor Visit Recording
*   **Encrypted Audio Recording**: Record doctor conversations. Audio is encrypted with AES-256 immediately upon capture.
*   **On-Device Transcription**: Uses Whisper.cpp to transcribe recordings entirely on your device.
*   **Speaker Diarization**: Heuristic-based speaker identification distinguishes between User and Doctor based on silence gaps and medical terminology density.
*   **Follow-Up Extraction**: Automatically extracts action items from transcripts:
    *   Medications to take
    *   Tests to schedule
    *   Lifestyle changes
    *   Warning signs to monitor

### 📊 Lab Value Intelligence
*   **Reference Range Lookup**: Embedded database of reference ranges for common lab tests (CBC, BMP, lipids, thyroid, vitamins).
*   **Value Evaluation**: Automatically determine if a lab value is Normal, High, or Low, with support for gender-specific ranges.
*   **Medical Dictionary**: An offline dictionary of lab test names, units, and abbreviations for intelligent matching.

### 🔐 Security & Compliance
*   **Biometric Authentication**: Face ID, Touch ID, and device passcode support via `local_auth`.
*   **PIN Fallback**: Optional 4-6 digit PIN for devices without biometrics.
*   **Audit Logging**: All sensitive actions (exports, authentication attempts, data access) are logged locally for compliance.
*   **Compliance Dashboard**: In-app checklist for HIPAA/FDA-adjacent best practices, with exportable reports.
*   **Consent Management**: Track user consent for recording and data processing.

### 📤 Export & Sharing
*   **PDF Export**: Generate professional PDFs of transcripts, follow-up items, and compliance reports.
*   **Encrypted JSON**: Export data in an encrypted, portable format.
*   **Plain Text**: Simple text export for easy sharing.
*   **External Recipient Mode**: Optionally redact sensitive data when sharing externally.

### 🔍 Full-Text Search
*   **ObjectBox Indexing**: Fast, offline full-text search across all documents, conversations, and follow-up items.
*   **Fuzzy Matching**: Uses Levenshtein distance for typo-tolerant search.
*   **Medical Term Expansion**: Searches automatically include synonyms from the medical dictionary.

### 💻 Desktop Features (macOS/Windows)
*   **System Tray**: Minimize to tray with recording status indicators.
*   **Keyboard Shortcuts**: Quick access to common actions.
*   **Window Manager**: Remember window position and size.
*   **Desktop Notifications**: Native notifications for reminders.

---

## 🛠️ Tech Stack

| Component | Technology |
| :--- | :--- |
| **Framework** | Flutter (iOS, Android, macOS, Windows) |
| **Local Database** | Hive (encrypted), ObjectBox (search index) |
| **LLM Engine** | llama.cpp via `llama_cpp_dart` |
| **OCR** | Tesseract via `flutter_tesseract_ocr` |
| **Speech-to-Text** | Whisper.cpp via `whisper_flutter_new` |
| **Audio Recording** | `flutter_sound` |
| **PDF Generation** | `pdf` package |
| **Secure Storage** | `flutter_secure_storage` (Keychain/Keystore) |
| **Biometrics** | `local_auth` |

---

## 📦 Getting Started

### Prerequisites

*   Flutter SDK (Latest Stable)
*   Xcode (for iOS/macOS) or Android Studio (for Android)

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/your-org/sehatlocker.git
    cd sehatlocker
    ```

2.  **Get dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the app**
    ```bash
    # iOS
    flutter run -d ios

    # Android
    flutter run -d android

    # macOS
    flutter run -d macos
    ```

---

## 📁 Project Structure

```
lib/
├── config/           # App configuration (flavors, build config)
├── models/           # Data models (HealthRecord, DocumentExtraction, etc.)
├── screens/          # UI screens (AI, Documents, Settings, etc.)
├── services/         # Business logic and platform services
│   ├── ai_middleware/    # AI safety and prompt management
│   ├── extractors/       # Follow-up item extraction (medications, tests, etc.)
│   └── validation/       # Input validation services
├── utils/            # Utilities (secure logging, string helpers)
└── widgets/          # Reusable UI components (Liquid Glass design system)
```

---

## 🔒 Security Model

1.  **Data at Rest**: All health records are encrypted using AES-256. The encryption key is generated on first launch and stored in the device's secure enclave.
2.  **Audio Encryption**: Recordings are encrypted in memory before being written to disk. The raw audio never exists unencrypted on the filesystem.
3.  **No Network Calls**: The app does not make network requests except for:
    *   Downloading on-device LLM models (user-initiated).
    *   Fetching research papers (optional, configurable).
4.  **Secure Logging**: Debug logs automatically redact sensitive data patterns (SSNs, emails, etc.).

---

## 📜 License

Proprietary. See `LICENSE` for details.
