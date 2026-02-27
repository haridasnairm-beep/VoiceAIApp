# VoiceNotes AI - Changelog

All notable changes to this project will be documented in this file.

---

## [Unreleased] - Steps 4.6 & 4.7: Tasks, Reminders, Sharing, Rich Text & Images

### Documentation
- Added **FEATURE_TASKS_AND_REMINDERS.md** — full feature spec for interactive checkboxes, aggregated tasks view, and hybrid reminder model
- Added **FEATURE_PROJECT_DOCUMENTS.md Addendum A** — feature spec for sharing/export (A1), rich text formatting (A2), and image blocks/photo attachments (A3)
- Updated **PROJECT_SPECIFICATION.md** (v2.3 → v2.4):
  - Step 4.6: added sections 4.15 (Aggregated Tasks View), 4.16 (Reminder Enhancement), updated Note Detail with interactive checkboxes/manual task creation, updated Home with Tasks tab, added TaskItem view model, added `add_2_calendar`
  - Step 4.7: updated Note Detail with photo attachments and share button, updated Project Document Detail with image blocks/rich text/share/export, added section 4.14 (Image Viewer), added ImageAttachment model, updated ProjectBlock with `imageAttachmentId`/`contentFormat`, added 7 new packages, updated permissions (Camera, Photo Library), updated key behaviors and Out of Scope
- Updated **IMPLEMENTATION_PLAN.md** (v2.3 → v2.4):
  - Added Step 4.6 with 5 sub-steps (A-E): checkboxes, tasks view, reminder enhancement
  - Added Step 4.7 with 7 sub-steps (A-G): data models, sharing/export, rich text, image blocks, note photos, polish; 8 new files, 11 modified files, 7 new packages
  - Updated phase summary diagram with both new steps
- Updated **PROJECT_STATUS.md** — added Step 4.6 and 4.7 status tables, updated Next Steps

---

## [1.4.0] - 2026-02-27 - Library Merge, Whisper UX, UI Polish

### Added
- **Unified Library page** — folders and projects now shown together on a single page with collapsible sections (arrow toggle + count badge)
- **Whisper highlight navigation** — when whisper model is not downloaded, tapping OK in the popup navigates to Settings and auto-scrolls to the AUDIO section with a flash highlight on the Whisper Model download row
- **"Prepare Your App" onboarding page** — new page 4 in Quick Guide explaining the one-time Whisper model download; shows "Let's Set It Up" button (navigates to Settings with highlight) or green "You're all set!" if already downloaded
- **Voice command punctuation tolerance** — parser now strips trailing punctuation (`.` `,` `!` `?`) from keywords before matching, fixing Whisper's tendency to add periods after "Start" and "Project"
- **Debug logging** — `VoiceCmd:` debug prints in notes_provider for tracing voice command processing in adb logcat

### Changed
- **"Add Block" FAB** — hidden when keyboard is open on project detail page (prevents overlap with Save/Cancel buttons)
- **"Add Block" FAB color** — changed from `surface` to `primary` to stand out against card backgrounds
- **Home page Projects card** — now navigates to Library page (same as Folders card) instead of separate Projects page
- **Library subtitle** — changed from "Your folders" to "Folders & Projects"
- **Onboarding** — now 5 pages (added "Prepare Your App" between "Organize Your Way" and "Privacy First")
- **Whisper popup text** — simplified to mention Settings navigation without manual scroll instructions
- **Folder/Project cards** — slightly more compact (48px icon instead of 56px) for better fit in unified view

### Fixed
- **Voice command project creation not working** — root cause was Whisper adding punctuation to keywords (e.g., `"Start."` instead of `"start"`); parser now strips trailing punctuation before matching

---

## [1.3.0] - 2026-02-27 - Voice Command Auto-Linking

### Added
- **Voice command parsing** — in Whisper mode, say "Folder/Project name Start content" to auto-organize recordings
  - Supports: `Folder name`, `Project name`, or both before `Start`
  - "Start" keyword is required as delimiter between command and content
  - Command prefix is stripped from saved transcription
  - If folder/project doesn't exist, it's auto-created
  - Manual dropdown selections take priority over voice commands
- **`VoiceCommandParser`** (`lib/utils/voice_command_parser.dart`) — keyword parsing logic
- **`VoiceCommandProcessor`** (`lib/services/voice_command_processor.dart`) — folder/project lookup and auto-create
- **Voice Commands toggle** in Settings AUDIO section (enabled by default)
- **`voiceCommandsEnabled`** setting — `@HiveField(11)` on `UserSettings`

### Changed
- **`transcribeInBackground()`** — accepts `hasManualFolder` and `hasManualProject` flags to avoid overriding user's dropdown selections

---

## [1.2.3] - 2026-02-26 - Edge-to-Edge Display & UI Fixes

### Fixed
- **Android navigation bar** — now truly transparent (edge-to-edge) by adding `android:navigationBarColor` and `android:statusBarColor` to both light and dark Android styles.xml
- **Nav bar icon brightness** — dynamically adapts to light/dark theme (light icons in dark mode, dark icons in light mode)
- **Edit Note button overlap** — bottom bar on note detail page now accounts for system navigation bar padding
- **SpeedDialFab overlap** — FAB on Home, Folders, and Project Documents pages no longer overlaps Android navigation buttons
- **FAB position consistency** — all pages now use `SafeArea(top: false)` wrapping the body Stack, ensuring consistent FAB positioning across Home, Folders, and Project Documents pages

---

## [1.2.2] - 2026-02-26 - Default Folder & Create from Recording Page

### Added
- **Default "General" folder** — auto-created on first launch, pre-selected in recording page
- **`defaultFolderId`** setting — new `@HiveField(10)` on `UserSettings`, persisted in Hive
- **Create folder from recording page** — "+ New Folder" option at bottom of folder dropdown, shows name input dialog
- **Create project from recording page** — "+ New Project" option at bottom of project dropdown, shows title input dialog
- **Default Folder picker in Settings** — AUDIO section setting to choose which folder new recordings go to
- **Whisper Model status in Settings** — always-visible download status/button (shown only when Whisper mode active)

### Changed
- **"No project" label** → "None" in recording page dropdown (both hint and item)
- **"No folder" label** → "None" in recording page dropdown
- **Recording page** pre-selects default folder from settings when no folder context is passed

---

## [1.2.1] - 2026-02-26 - Recording Page Enhancements

### Added
- **Folder/Project selection on recording page** — in Whisper mode, dropdown selectors let users assign folder and/or project before saving
  - Selected folder is used when creating the note
  - Selected project auto-links the note as a block in the project document
  - Pre-selects folder if recording was launched from a folder context
- **Full-screen blur scrim** — Speed Dial FAB overlay now uses Flutter `Overlay` + `BackdropFilter` for full-screen frosted glass effect

### Changed
- **Default recording mode** changed from Live STT to Whisper (record-then-transcribe)
- **Recording page** — removed settings gear icon from top bar
- **Whisper mode UI** — replaced 240px transcription box with compact recording indicator + folder/project selection panel
- **Whisper model check** — on first recording attempt, if whisper model not downloaded, shows dialog and auto-navigates to Settings page (AUDIO section) for one-time download
- **Hive migration** — existing users with `transcriptionMode = 'live'` are automatically migrated to `'whisper'` on app startup
- **`UserSettings.transcriptionMode`** default changed from `'live'` to `'whisper'`
- **`SettingsState.transcriptionMode`** default changed to match `'whisper'`

---

## [1.2.0] - 2026-02-26 - Speed Dial FAB, Background Transcription & UI Polish

### Added
- **Speed Dial FAB** — expandable floating action button on Home, Folders, and Project Documents pages
  - Common actions: Record Note, New Folder, New Project (+ Search on Home page)
  - Animated mini-FABs with label chips, scrim overlay, 45° rotation on main FAB
  - Reusable `SpeedDialFab` widget (`lib/widgets/speed_dial_fab.dart`)
- **Background Whisper transcription** — recording in Whisper mode now saves note immediately and transcribes in background
  - Note card shows time-based progress bar (estimated from audio duration × 1.2)
  - Progress capped at 95% until actual completion
  - `_TranscribingProgress` StatefulWidget with 1-second Timer refresh
- **`NotesNotifier.transcribeInBackground()`** — fire-and-forget transcription method

### Changed
- **Home page** — replaced custom circular mic button with Speed Dial FAB (bottom-right)
- **Folders page** — replaced "New Folder" extended FAB with Speed Dial FAB
- **Project Documents page** — replaced "New Project" extended FAB with Speed Dial FAB
- **Project document blocks** — ultra-compact layout with 3-dot popup menu (move up/down, details, remove)
- **Recording page** — Whisper stop flow changed from blocking overlay to background processing
- **`NotesNotifier.addNote()`** — accepts `isProcessed` parameter
- **`NotesRepository.createNote()`** — accepts `isProcessed` parameter

---

## [1.1.0] - 2026-02-26 - Project Documents Feature (Step 4.5)

### Added
- **Project Documents feature** — rich composite documents assembled from voice notes
- **3 new Hive models** — ProjectDocument (typeId: 6), ProjectBlock (typeId: 7), TranscriptVersion (typeId: 8)
- **BlockType enum** — noteReference, freeText, sectionHeader (typeId: 9)
- **ProjectDocumentsRepository** — full CRUD for project documents and blocks
- **projectDocumentsProvider** — Riverpod Notifier managing project document state
- **Transcript versioning** — full version history on note transcripts with bi-directional editing
- **Note model extended** — added `transcriptVersions` and `projectDocumentIds` fields (HiveFields 17, 18)
- **Data migration** — existing notes auto-receive v1 TranscriptVersion from rawTranscription on startup
- **Project Documents List page** — create/rename/delete projects, card view with note count and last updated
- **Project Document Detail page** — scrollable canvas with 3 block types, reorder mode, add block sheet
- **Note Reference Block** — displays transcript, timestamp, language badge, in-place editing, overflow menu
- **Free-Text Block** — editable text area for typed content
- **Section Header Block** — large/bold editable text with divider
- **Note Picker page** — multi-select notes with search, "linked" indicator for already-added notes
- **Version History page** — view all transcript versions, restore any version
- **4 new routes** — /project_documents, /project_document_detail, /note_picker, /version_history
- **Home page "Projects" card** — quick access to project documents alongside Folders
- **Deleted note handling** — project blocks show "This note has been deleted" placeholder
- **Bi-directional editing** — editing a transcript in a project creates a new version on the original note
- **HiveService updated** — projectDocumentsBox (AES-256 encrypted), migration method, deleteAllData cleanup

### Files Created (13)
- `lib/models/project_document.dart`, `project_block.dart`, `transcript_version.dart`
- `lib/services/project_documents_repository.dart`
- `lib/providers/project_documents_provider.dart`
- `lib/pages/project_documents_page.dart`, `project_document_detail_page.dart`, `note_picker_page.dart`, `version_history_page.dart`
- Generated: `project_document.g.dart`, `project_block.g.dart`, `transcript_version.g.dart`

### Files Modified (8)
- `lib/models/note.dart` — added transcriptVersions and projectDocumentIds fields
- `lib/services/hive_service.dart` — new box, adapters, migration, deleteAllData
- `lib/services/notes_repository.dart` — transcript versioning and project reference methods
- `lib/providers/notes_provider.dart` — transcript versioning methods exposed
- `lib/nav.dart` — 4 new routes added
- `lib/pages/home_page.dart` — Projects category card
- `lib/main.dart` — transcript migration call on startup

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
