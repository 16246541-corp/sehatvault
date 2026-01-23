# Sehat Locker

A privacy-first health records locker app built with Flutter.
Designed to run locally with no external cloud dependencies.

## Features

- **Privacy First**: All data is stored locally using encrypted Hive boxes.
- **Liquid Glass Design**: Premium UI with glassmorphism effects.
- **Local AI**: Ready for on-device LLM integration.
- **Research News**: Swipeable cards for browsing medical research papers.

## Getting Started

This project is a starting point for a Flutter application.

### Prerequisites

- Flutter SDK (Latest Stable)
- Android Studio / Xcode

### Installation

1.  **Get Dependencies**
    ```bash
    flutter pub get
    ```

2.  **Run Locally**
    - Android: `flutter run -d android`
    - iOS: `flutter run -d ios`

## Project Structure

- `lib/services/local_storage_service.dart`: Handles encrypted local storage.
- `lib/widgets/design/`: Contains port of Liquid Glass design system.
- `lib/screens/`:
    - `Documents`: Health records storage.
    - `AI`: Local LLM interface.
    - `News`: Research paper browsing.
    - `Settings`: Privacy and security settings.

## Security

- Health records are encrypted using AES-256.
- Encryption keys are stored securely in Keychain (iOS) / Keystore (Android).
- Internet permission is only used for fetching research papers (if configured) or downloading local models.

## License

Proprietary
