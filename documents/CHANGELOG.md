# VoiceNotes AI - Changelog

All notable changes to this project will be documented in this file.

---

## [1.0.3] - 2026-02-26 - Whisper Fix, Timestamps, Conditional UI

### Added
- **Speaker name setting** — "Your Name" field in Settings (default: "Speaker 1"), persisted via Hive
- **Transcription timestamp header** — Each note shows speaker name + date/time above transcription text (e.g., "Haridas — Feb 26, 2026 at 12:05 PM")
- **Whisper error feedback** — SnackBar warning when Whisper transcription returns empty, allows manual editing
- **Whisper debug logging** — File existence/size validation, detailed error stack traces for troubleshooting

### Changed
- **Audio player hidden for live transcription notes** — Notes without audio files no longer show the player section (previously showed disabled player with "Transcription-only note" message)
- **Reminders section conditionally visible** — Hidden when reminders/notifications disabled in Settings, reappears when re-enabled

### Fixed
- Whisper transcription silently returning empty text with no user feedback

---

## [1.0.2] - 2026-02-26 - UI Polish & Compact Headers

### Changed
- Replaced manual header Rows with proper AppBar widgets on Home, Folders, and Folder Detail pages
- Home page: AppBar with "My Notes" title, "VoiceNotes AI" subtitle, settings icon action
- Folders page: AppBar with "Library" title, "Your folders" subtitle, back button, search action
- Folder Detail page: AppBar with folder name title, note count subtitle, back button, search + popup menu actions
- Reduced top spacing across pages — AppBar handles SafeArea automatically for more compact headers
- Home page body padding reduced from `(20, 20, 20, 120)` to `(20, 8, 20, 120)`
- Stat chips (Total Audio, Notes) in Folder Detail moved below AppBar in body

### Fixed
- Folders page missing back button — now navigates back or to home
- Excessive empty space between page headers and Android status bar

---

## [1.0.1] - 2026-02-26 - Settings Overhaul, Splash Screen & Quick Guide

### Added
- **Splash screen** (`lib/pages/splash_page.dart`) — Animated logo + tagline, 5-second timer, navigates to onboarding (first launch) or home (returning user)
- **Multi-page Quick Guide** — 4-page swipeable onboarding: Welcome, Record & Transcribe, Organize Your Way, Privacy First
  - Skip button on first-run, dot indicators, "Get Started" / "Got It" buttons
  - Accessible from Settings as "Quick Guide" (shows "Got It" instead of "Get Started")
- **Language Detection picker** in Settings — 13 languages + Automatic (auto-detect) option
- **Audio Quality picker** in Settings — Standard ("Smaller file size, good quality") and High Quality ("Lossless audio, larger files")
- **Storage utilization display** — Shows actual disk usage (Hive data + recordings) via `HiveService.getStorageUsage()`
- **Danger Zone section** in Settings — Red-titled group for "Delete All Data" with room for future destructive options
- **HDMPixels branding** — Splash screen shows "by HDMPixels"

### Changed
- Renamed branding from "HariAppBuilders" to "HDMPixels" on splash screen
- Onboarding rewritten from single-page to 4-page `PageView` with `ConsumerStatefulWidget`
- Splash page converted to `ConsumerStatefulWidget` to check onboarding completion status
- Settings page: removed Help Center (not implemented) and Terms of Service (deferred)
- Settings page: "SUPPORT" group now only contains Quick Guide
- Navigation updated: `/` route = SplashPage, `/onboarding` = OnboardingPage

### Fixed
- `flutter install` installing stale release APK — resolved with `flutter clean` before build
- Language and Audio Quality settings now interactive (previously display-only)

---

## [0.1.1] - 2026-02-25 - Concept Alignment & Documentation

### Changed
- Aligned project specification with Product Concept Document
- Updated tech stack: Hive (encrypted) for local storage, Riverpod/Bloc for state management
- Removed authentication requirement from MVP — app works without login
- Updated privacy architecture to local-first with stateless AI processing
- Removed cloud sync from MVP scope (moved to Phase 2)

### Added
- Product Concept Document (`documents/voicenotes-ai-concept.md`)
- Implementation Plan (`documents/IMPLEMENTATION_PLAN.md`) — 8-step roadmap
- CLAUDE.md agent reference file at project root
- "Not In Use" header comment on `lib/pages/login_page.dart`

### Documented
- Privacy architecture (Hive encryption, stateless AI, user control)
- Data models (Note, ActionItem, TodoItem, ReminderItem, Folder, UserSettings)
- Phase 2 and Phase 3 feature roadmap
- Monetization model (freemium, no ads)
- Risk register and mitigations

---

## [0.1.0] - 2026-02-24 - Initial Scaffolding

### Added

#### Project Setup
- Initialized Flutter project (`voicenotes_ai`) with Dart SDK ^3.6.0
- Configured Material Design 3 with custom theme system
- Set up Android, iOS, Web, macOS, Linux, and Windows platform targets
- Added `.gitignore` and `analysis_options.yaml`

#### Theme System (`lib/theme.dart`)
- Custom color palette with light and dark mode variants
- AppSpacing constants (xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48)
- AppRadius constants (sm: 8, md: 16, lg: 24, full: 9999)
- Typography using Google Fonts (Plus Jakarta Sans for headings, Inter for body)
- System-based automatic theme switching

#### Navigation (`lib/nav.dart`)
- Declarative routing with go_router (16.2.0)
- 9 routes configured: onboarding, login, home, recording, note_detail, folders, folder_detail, settings, search
- Route parameter support (recordingPath for note_detail)

#### Screens (UI Only — No Business Logic)
- **Onboarding Page** (339 lines) — Welcome flow with decorative background
- **Login Page** (427 lines) — Email/password form + Google Sign-In button — **NOT IN USE for MVP**
- **Home Page** (535 lines) — Notes feed layout, search bar, category filters, floating record button
- **Recording Page** (486 lines) — Recording UI with timer, pause/resume, save/discard
- **Note Detail Page** (602 lines) — Transcription display and structured sections layout
- **Folders Page** (412 lines) — Folder list view
- **Folder Detail Page** (473 lines) — Notes within a folder
- **Settings Page** (445 lines) — Preferences layout
- **Search Page** (464 lines) — Search interface with filters

#### Services
- **AudioRecorderService** (`lib/services/audio_recorder_service.dart`) — Singleton service for voice recording
  - Start, pause, resume, stop, cancel recording
  - AAC-LC format (128kbps, 44.1kHz, M4A)
  - Real-time amplitude monitoring via ValueNotifier
  - Permission checking
  - File storage at `Documents/recordings/voicenote_[timestamp].m4a`

#### Assets
- App icon (`assets/icons/dreamflow_icon.jpg`) — needs rebranding
- Google logo for sign-in (`assets/icons/google_logo.svg`) — not needed for MVP

#### Platform Configuration
- Android: RECORD_AUDIO permission in AndroidManifest.xml
- Android: Firebase configured (google-services.json)
- iOS: Standard Flutter setup with Podfile
- Web: PWA manifest and icons

### Known Issues
- Android app label reads "dreamflow" instead of "VoiceNotes AI"
- `main.dart` app title is empty string
- Provider state management dependency needs replacement with Riverpod/Bloc
- All screens are UI shells only — no functional business logic connected

---

## [Unreleased] - Planned

### Phase 2
- Whisper API transcription (cloud-based, higher accuracy)
- AI Categorization & Structuring (auto-extract actions/todos/reminders)
- n8n Integration & Advanced Features
- Unit, widget, and integration tests
