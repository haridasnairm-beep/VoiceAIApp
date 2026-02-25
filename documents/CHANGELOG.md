# VoiceNotes AI - Changelog

All notable changes to this project will be documented in this file.

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

## [Unreleased] - Planned for MVP

### Step 1: Project Alignment & Branding
- Fix app label, title, and icon branding
- Update onboarding → Home flow (remove login gate)

### Step 2: State Management
- Replace Provider with Riverpod (or Bloc)

### Step 3: Data Models & Hive
- Create Hive models with encryption
- Repository layer for CRUD

### Step 4: Wire UI to Data
- Connect all screens to Hive through providers

### Step 5: Speech-to-Text
- Whisper API or Google STT integration
- Offline queue for pending transcriptions

### Step 6: AI Categorization
- OpenAI/Anthropic API for structuring notes
- Contextual grouping and follow-up questions

### Step 7: Waveform, Playback & Notifications
- Real-time waveform visualizer
- Audio playback on note detail
- Reminder notifications

### Step 8: Testing & Release
- Unit, widget, and integration tests
- Store submission preparation
