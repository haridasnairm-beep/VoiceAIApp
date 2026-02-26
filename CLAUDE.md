# CLAUDE.md — VoiceNotes AI Agent Reference

This file provides context for AI agents (Claude Code, Copilot, etc.) working on this project.

**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Branch:** main

---

## Project Summary

**VoiceNotes AI** is a privacy-first, voice-driven note-taking and task management mobile app built with Flutter. Users record voice notes, the app transcribes audio on-device, and organizes content into folders with manual categorization.

**Current Phase:** MVP (Phase 1) — Core 100% complete (all 7 steps done + bonus features). Step 4.5 (Project Documents) approved for development.

---

## Phase Architecture

| Phase | Scope | AI Required |
|---|---|---|
| **Phase 1 (Current)** | On-device recording, transcription (speech_to_text), local storage, manual organization, playback, notifications | **No AI** |
| Phase 2 (Future) | Whisper API transcription, AI categorization, auto-folders, n8n integration | Yes |

---

## Core Principles (MUST follow)

1. **Privacy-first** — All data stored locally in encrypted Hive. No cloud storage in MVP.
2. **No login required** — MVP works without any account creation or sign-in.
3. **Voice as primary interface** — Every core feature is voice-accessible.
4. **No ads, ever** — Revenue through freemium model only.
5. **Phase 1 = No AI** — All features must work without any cloud AI service. See AI exclusion rules below.

---

## CRITICAL: Phase 1 AI Exclusion Rules

**Phase 1 has NO AI features.** During Phase 1 implementation, agents MUST:

1. **HIDE or REMOVE** all AI-related UI elements (see table below)
2. **DO NOT** implement any cloud API calls (OpenAI, Anthropic, Whisper)
3. **DO NOT** build AI categorization, auto-structuring, or smart suggestions
4. **DO NOT** add auto-folder assignment or topic extraction
5. **DO NOT** implement follow-up question generation
6. **USE** `speech_to_text` package (on-device, free) for transcription — NOT Whisper API
7. **Reminders** are manual (user picks date/time) — NOT AI-extracted

### AI UI Elements to Hide/Remove in Phase 1

| Page | Element | Action |
|---|---|---|
| `onboarding_page.dart` | "Task created: Meeting" bubble with auto_awesome icon | **Remove** — replace with a non-AI demo |
| `onboarding_page.dart` | "Smart Categorization" feature item | **Replace** with "Organize Your Way" — manual folders |
| `onboarding_page.dart` | "Our AI handles the transcription and structure" text | **Change** to "Capture ideas instantly. Organize them your way." |
| `note_detail_page.dart` | "Ask AI" floating button | **Remove entirely** |
| `note_detail_page.dart` | "AI Follow-up Questions" section (lines ~299-336) | **Remove entirely** |
| `note_detail_page.dart` | `_AiSuggestion` widget class | **Remove entirely** |
| `folder_detail_page.dart` | "AI Insights" stat chip | **Remove** or replace with "Notes" count |
| `folder_detail_page.dart` | "AI Project Summary" section (lines ~113-157) | **Remove entirely** |
| `folders_page.dart` | "Smart organized by AI" subtitle | **Change** to "Your folders" |
| `folders_page.dart` | "Smart Topics" section header | **Change** to "Topics" |
| `folders_page.dart` | "AI Organization Tip" card section (lines ~173-237) | **Remove entirely** |
| `settings_page.dart` | "AUDIO & AI" group header | **Change** to "AUDIO" |
| `settings_page.dart` | "AI Follow-up" toggle setting | **Remove entirely** |
| `settings_page.dart` | "Smart Reminders" toggle | **Change** to "Reminders" (manual) |
| `search_page.dart` | `auto_awesome_rounded` icon at end of results | **Replace** with `check_circle_outline` or similar |

### Note Model Fields — Keep but Leave Unused

These fields in `lib/models/note.dart` should **remain in the model** (for Phase 2 compatibility) but should **not be populated or displayed** in Phase 1:

- `followUpQuestions` — always `null`
- `hasFollowUpTrigger` — always `false`
- `isProcessed` — always `true` (on-device transcription = immediately processed)
- `actions`, `todos`, `reminders` — empty lists (user can manually add in Phase 2)
- `topics` — empty list (manual folder assignment only)

---

## Tech Stack (Phase 1 MVP)

| Component | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.6.0) |
| Local database | Hive (AES-256 encrypted) |
| State management | Riverpod 3.x (Notifier/NotifierProvider) |
| Navigation | go_router |
| Audio recording | record package |
| Audio playback | just_audio |
| Speech-to-text | speech_to_text (on-device, free) |
| Notifications | flutter_local_notifications |
| Typography | Google Fonts (Plus Jakarta Sans, Inter) |
| App icon | `assets/icons/logo.png` (used for launcher icon + in-app branding) |

---

## Project Structure

```
lib/
├── main.dart                         # App entry point (Hive init + ProviderScope)
├── nav.dart                          # GoRouter routes and AppRoutes constants
├── theme.dart                        # Material 3 theme (light + dark)
├── models/
│   ├── note.dart                     # Hive model (typeId: 0)
│   ├── action_item.dart              # Hive model (typeId: 1)
│   ├── todo_item.dart                # Hive model (typeId: 2)
│   ├── reminder_item.dart            # Hive model (typeId: 3)
│   ├── folder.dart                   # Hive model (typeId: 4)
│   ├── user_settings.dart            # Hive model (typeId: 5)
│   ├── project_document.dart         # Hive model (typeId: 6) — PLANNED (Step 4.5)
│   ├── project_block.dart            # Hive model (typeId: 7) — PLANNED (Step 4.5)
│   └── transcript_version.dart       # Hive model (typeId: 8) — PLANNED (Step 4.5)
├── services/
│   ├── audio_recorder_service.dart   # Audio recording (working)
│   ├── audio_player_service.dart     # Audio playback via just_audio
│   ├── hive_service.dart             # Encrypted Hive initialization + storage usage
│   ├── notes_repository.dart         # CRUD for notes
│   ├── folders_repository.dart       # CRUD for folders
│   ├── settings_repository.dart      # Settings persistence
│   ├── transcription_service.dart    # On-device STT via speech_to_text
│   ├── notification_service.dart     # Local notifications + scheduling
│   └── project_documents_repository.dart  # CRUD for project documents — PLANNED (Step 4.5)
├── providers/
│   ├── notes_provider.dart           # NotesNotifier + notesProvider
│   ├── folders_provider.dart         # FoldersNotifier + foldersProvider
│   ├── settings_provider.dart        # SettingsNotifier + settingsProvider
│   ├── recording_provider.dart       # RecordingNotifier
│   ├── connectivity_provider.dart    # ConnectivityNotifier
│   └── project_documents_provider.dart  # ProjectDocumentsNotifier — PLANNED (Step 4.5)
├── pages/
│   ├── splash_page.dart              # Animated splash → onboarding or home
│   ├── onboarding_page.dart          # 4-page Quick Guide (swipeable)
│   ├── login_page.dart               # NOT IN USE (Phase 2)
│   ├── home_page.dart                # Dashboard with notes feed (AppBar header)
│   ├── recording_page.dart           # Voice recording UI + live STT
│   ├── note_detail_page.dart         # Full note view + playback + reminders
│   ├── folders_page.dart             # Folder list (AppBar with back button)
│   ├── folder_detail_page.dart       # Notes within a folder (AppBar with folder name)
│   ├── settings_page.dart            # Preferences, pickers, storage, danger zone
│   ├── search_page.dart              # Search and filter
│   ├── project_documents_page.dart   # Project Documents list — PLANNED (Step 4.5)
│   ├── project_document_detail_page.dart  # Project Document detail/canvas — PLANNED (Step 4.5)
│   ├── note_picker_page.dart         # Multi-select note picker — PLANNED (Step 4.5)
│   └── version_history_page.dart     # Transcript version history — PLANNED (Step 4.5)
├── widgets/                          # Reusable widgets — PLANNED (Step 4.5)
│   ├── note_reference_block.dart     # Note reference block widget
│   ├── free_text_block.dart          # Free text block widget
│   ├── section_header_block.dart     # Section header block widget
│   └── project_document_card.dart    # Project document card for list
└── utils/                            # Helpers and constants
```

---

## Pages NOT IN USE (MVP Phase 1)

| File | Reason | When Active |
|---|---|---|
| `lib/pages/login_page.dart` | No authentication in MVP | Phase 2 |

---

## Implementation Steps (Phase 1)

1. **Project Alignment & Branding** ✅ Done
2. **State Management Migration (Riverpod)** ✅ Done
3. **Data Models & Hive Database** ✅ Done
4. **Wire UI to Data Layer** ✅ Done (AI UI elements removed, all pages wired to Riverpod/Hive)
4.5. **Project Documents** ⏳ Approved (rich composite documents from voice notes — see [FEATURE_PROJECT_DOCUMENTS.md](documents/FEATURE_PROJECT_DOCUMENTS.md))
5. **On-Device Speech-to-Text** ✅ Done (speech_to_text package, on-device, free)
6. **Waveform, Playback & Notifications** ✅ Done (amplitude waveform, just_audio playback, manual reminders)
7. **Testing, Polish & Release** ✅ Done (splash screen, quick guide, settings overhaul, compact AppBar headers)

**Phase 2 Steps (future, not in scope):**
8. Whisper API Transcription
9. AI Categorization & Structuring
10. n8n Integration & Advanced Features (includes Project Documents Phase 2: AI summary, export, voice commands)

---

## Routes (go_router)

| Path | Screen | MVP Status |
|---|---|---|
| `/` | Splash | Active (initial route, animated branding) |
| `/onboarding` | Quick Guide | Active (4-page swipeable guide) |
| `/login` | Login | NOT IN USE |
| `/home` | Home/Dashboard | Active |
| `/recording` | Recording | Active |
| `/note_detail` | Note Detail | Active (accepts `recordingPath` extra) |
| `/folders` | Folders List | Active |
| `/folder_detail` | Folder Detail | Active |
| `/settings` | Settings | Active |
| `/search` | Search | Active |
| `/project-documents` | Project Documents List | PLANNED (Step 4.5) |
| `/project-documents/:id` | Project Document Detail | PLANNED (Step 4.5) |
| `/project-documents/:id/add-notes` | Note Picker | PLANNED (Step 4.5) |
| `/project-documents/:id/version-history/:noteId` | Version History | PLANNED (Step 4.5) |

---

## Coding Conventions

- **Dart style:** Follow official Dart style guide and `analysis_options.yaml` linting
- **File naming:** snake_case for all Dart files
- **Widget structure:** One widget per file for pages, can combine small widgets
- **State management:** Use Riverpod Notifier/NotifierProvider (NOT StateNotifier, NOT Provider)
- **Database:** All persistence through Hive repositories (never direct Hive access from UI)
- **Error handling:** Graceful fallbacks, show user-friendly messages
- **Privacy:** Never send user-identifying data to external services. Never log sensitive content.
- **No AI in Phase 1:** All features must function without any cloud API dependency

---

## Commands

```bash
# Run the app
flutter run

# Build for Android
flutter build apk

# Run tests
flutter test

# Generate Hive adapters (after creating models)
dart run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze
```

---

## Important Notes for Agents

1. **Always read the concept document** (`documents/voicenotes-ai-concept.md`) for product decisions.
2. **Check PROJECT_STATUS.md** before starting work to understand current state.
3. **Follow IMPLEMENTATION_PLAN.md** step order — each step depends on the previous.
4. **Phase 1 = NO AI.** Remove/hide all AI UI elements. See the AI exclusion table above.
5. **DO NOT implement cloud API calls** (OpenAI, Anthropic, Whisper) — these are Phase 2.
6. **DO NOT add cloud sync, authentication, or user accounts** — these are Phase 2.
7. **DO NOT modify login_page.dart** — it is not in use for MVP.
8. **Hive is the database** — not sqflite, not Drift, not Isar. Use Hive with encryption.
9. **Privacy is non-negotiable** — local-first, no telemetry, no tracking.
10. **Use speech_to_text package** for transcription — on-device, free, no API key needed.
11. **Read the Project Documents feature spec** (`documents/FEATURE_PROJECT_DOCUMENTS.md`) before implementing Step 4.5.
12. **Always update documentation** after every change:
    - `documents/CHANGELOG.md` — log all changes
    - `documents/PROJECT_STATUS.md` — update after major updates
    - `documents/IMPLEMENTATION_PLAN.md` — update when major changes are implemented
    - This is mandatory for all agents without exception.
