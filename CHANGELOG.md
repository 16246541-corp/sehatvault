# Changelog - Sehat Locker

## [1.9.6] - 2026-01-27

### Added
- **Desktop Settings UI**: Implemented a new, premium desktop-specific settings screen in `lib/ui/desktop/screens/desktop_settings_screen.dart`.
  - **Visual Overhaul**: Applied a deep navy-to-indigo gradient theme with glassmorphism effects to match the new design language.
  - **Split-View Layout**: Introduced a two-column layout with a persistent sidebar navigation and a spacious content area.
  - **Categorization**: Organized settings into clear categories (Privacy, Storage, Recording, Notifications, AI, Accessibility, Desktop, About).
  - **Interactive Components**: Created custom styled widgets (`_SettingsCard`, `_SidebarItem`, `_ValueButton`) for a polished look.

### Changed
- **Navigation**: Updated `SehatLockerDesktopApp` to route the "Settings" tab to the new `DesktopSettingsScreen` instead of the shared mobile version.
- **Desktop UI**: Removed the lower/bottom menu bar from the Desktop shell (sidebar navigation remains).
- **Integration**: Wired up existing settings logic (Hive persistence, Storage Usage, Security Toggles) to the new desktop UI.
- **macOS**: Enabled App Sandbox in `DebugProfile.entitlements` to match `ENABLE_APP_SANDBOX=YES`.
- **macOS**: Updated `Runner.xcodeproj` metadata to current recommended settings.
- **macOS**: Normalized CocoaPods build settings (deployment target + Swift version + warning policy) via `Podfile` post-install hooks.
- **macOS**: Fixed CocoaPods xcconfig parsing issue with `DART_DEFINES` containing `=` padding.
- **macOS**: Removed duplicate libc++ link flags from generated CocoaPods xcconfigs.
- **macOS**: Patched `flutter_tts` and `whisper_flutter_new` via local overrides for Xcode/Swift toolchain compatibility.
