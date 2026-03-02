# CLAUDE.md — VoiceNotes AI Agent Reference

This file provides context for AI agents (Claude Code, Copilot, etc.) working on this project.

**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Branch:** main

---

## Project Summary

**VoiceNotes AI** is a privacy-first, voice-driven note-taking and task management mobile app built with Flutter. Users record voice notes, the app transcribes audio on-device, and organizes content into folders with manual categorization.

**Current Phase:** Phase 1 (Release) — Core 100% complete (all 7 steps + Steps 4.5/4.6/4.7 + bonus features + post-release enhancements Issues #7–#12). Version 1.0.0. **Next:** Value Proposition Gaps (Steps 8–10.7).

---

## Phase Architecture

| Phase | Scope | AI Required |
|---|---|---|
| **Phase 1 (Current)** | On-device recording, transcription (speech_to_text + whisper_flutter_new), local storage, manual organization, playback, notifications, project documents, tasks, sharing/export, rich text, image blocks | **No AI** |
| Phase 2 (Future) | Whisper API transcription, AI categorization, auto-folders, n8n integration | Yes |

---

## Core Principles (MUST follow)

1. **Privacy-first** — All data stored locally in encrypted Hive. No cloud storage in Phase 1.
2. **No login required** — Phase 1 works without any account creation or sign-in.
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
6. **USE** `speech_to_text` (live mode) and `whisper_flutter_new` (record & transcribe mode) for on-device transcription — NOT cloud Whisper API
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
| `audio_settings_page.dart` | "AUDIO & AI" group header | **Done** — changed to "AUDIO" |
| `preferences_page.dart` | "AI Follow-up" toggle setting | **Done** — removed |
| `preferences_page.dart` | "Smart Reminders" toggle | **Done** — changed to "Reminders" (manual) |
| `search_page.dart` | `auto_awesome_rounded` icon at end of results | **Replace** with `check_circle_outline` or similar |

### Note Model Fields — Keep but Leave Unused

These fields in `lib/models/note.dart` should **remain in the model** (for Phase 2 compatibility) but should **not be populated or displayed** in Phase 1:

- `followUpQuestions` — always `null`
- `hasFollowUpTrigger` — always `false`
- `isProcessed` — always `true` (on-device transcription = immediately processed)
- `actions`, `todos`, `reminders` — manually created by user (auto-extraction is Phase 2)
- `topics` — empty list (manual folder assignment only)

---

## Tech Stack (Phase 1)

| Component | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.6.0) |
| Local database | Hive (AES-256 encrypted) |
| Encryption key storage | flutter_secure_storage (Android Keystore / iOS Keychain) |
| State management | Riverpod 3.x (Notifier/NotifierProvider) |
| Navigation | go_router |
| Audio recording | record package |
| Audio playback | just_audio |
| Speech-to-text (live) | speech_to_text (on-device, free) |
| Speech-to-text (whisper) | whisper_flutter_new (on-device ggml-base model) |
| Notifications | flutter_local_notifications |
| OS calendar bridge | add_2_calendar |
| Sharing | share_plus |
| Rich text editor | flutter_quill |
| Image picker/viewer | image_picker, image_cropper, photo_view, flutter_image_compress |
| PDF generation | pdf (pure Dart, on-device) |
| Screen wakelock | wakelock_plus |
| Typography | Google Fonts (Plus Jakarta Sans, Inter) |
| App icon | `assets/icons/logo.png` (used for launcher icon + in-app branding) |

---

## Project Structure

```
lib/
├── main.dart                         # App entry point (Hive init + ProviderScope)
├── nav.dart                          # GoRouter routes (23 routes) and AppRoutes constants
├── theme.dart                        # Material 3 theme (light + dark)
├── models/
│   ├── note.dart                     # Hive model (typeId: 0)
│   ├── action_item.dart              # Hive model (typeId: 1)
│   ├── todo_item.dart                # Hive model (typeId: 2)
│   ├── reminder_item.dart            # Hive model (typeId: 3)
│   ├── folder.dart                   # Hive model (typeId: 4)
│   ├── user_settings.dart            # Hive model (typeId: 5)
│   ├── project_document.dart         # Hive model (typeId: 6)
│   ├── project_block.dart            # Hive model (typeId: 7)
│   ├── transcript_version.dart       # Hive model (typeId: 8)
│   ├── image_attachment.dart         # Hive model (typeId: 9)
│   ├── task_item.dart                # View model for aggregated tasks (NOT Hive)
│   └── *.g.dart                      # Generated Hive type adapters
├── services/
│   ├── audio_recorder_service.dart   # Audio recording
│   ├── audio_player_service.dart     # Audio playback via just_audio
│   ├── hive_service.dart             # Encrypted Hive init + storage usage
│   ├── notes_repository.dart         # CRUD for notes + tasks + versioning
│   ├── folders_repository.dart       # CRUD for folders
│   ├── settings_repository.dart      # Settings persistence
│   ├── transcription_service.dart    # On-device STT via speech_to_text
│   ├── whisper_service.dart          # On-device Whisper transcription
│   ├── notification_service.dart     # Local notifications + scheduling
│   ├── project_documents_repository.dart  # CRUD for project documents
│   ├── image_attachment_repository.dart   # Image CRUD + file management
│   ├── sharing_service.dart          # Assemble share text, export PDF/MD/TXT
│   ├── voice_command_processor.dart  # Voice command lookup/auto-create
│   └── os_reminder_service.dart      # OS calendar bridge via add_2_calendar
├── providers/
│   ├── notes_provider.dart           # NotesNotifier + notesProvider
│   ├── folders_provider.dart         # FoldersNotifier + foldersProvider
│   ├── settings_provider.dart        # SettingsNotifier + settingsProvider
│   ├── project_documents_provider.dart  # ProjectDocumentsNotifier
│   └── tasks_provider.dart           # Derived provider: aggregated tasks view
├── pages/
│   ├── splash_page.dart              # Animated splash → onboarding or home
│   ├── onboarding_page.dart          # 5-page Quick Guide (swipeable)
│   ├── login_page.dart               # NOT IN USE (Phase 2)
│   ├── home_page.dart                # Dashboard: Notes/Tasks tabs, stats, SpeedDialFab
│   ├── recording_page.dart           # Voice recording UI + live STT / Whisper
│   ├── note_detail_page.dart         # Full note view + playback + tasks + reminders
│   ├── folders_page.dart             # Unified Library: Folders + Projects
│   ├── folder_detail_page.dart       # Notes within a folder
│   ├── search_page.dart              # Sectioned search (notes, actions, todos, reminders)
│   ├── project_documents_page.dart   # Project Documents list
│   ├── project_document_detail_page.dart  # Project Document detail/canvas
│   ├── note_picker_page.dart         # Multi-select note picker
│   ├── version_history_page.dart     # Transcript version history
│   ├── image_viewer_page.dart        # Full-screen image viewer
│   ├── preferences_page.dart         # User preferences (name, theme, toggles)
│   ├── audio_settings_page.dart      # Audio quality, transcription mode, Whisper
│   ├── storage_page.dart             # Storage breakdown display
│   ├── support_page.dart             # Quick Guide + Send Feedback
│   ├── danger_zone_page.dart         # Delete Whisper model / recordings / all data
│   ├── about_page.dart               # App info, credits, legal
│   ├── feedback_page.dart            # User feedback form
│   ├── support_us_page.dart          # Buy Me a Coffee
│   ├── privacy_policy_page.dart      # Privacy policy
│   └── terms_conditions_page.dart    # Terms & conditions
├── widgets/
│   ├── note_card.dart                # Note card for lists
│   ├── speed_dial_fab.dart           # Multi-action floating button
│   ├── share_preview_sheet.dart      # Share preview with toggles + PDF export
│   ├── find_replace_bar.dart         # Find & Replace toolbar
│   ├── settings_widgets.dart         # Reusable settings UI components
│   ├── download_progress_sheet.dart  # Whisper model download progress
│   ├── project_document_card.dart    # Project document card for list
│   ├── image_block_widget.dart       # Image block for project documents
│   ├── note_attachments_section.dart # Photo section on Note Detail
│   ├── task_list_item.dart           # Task row in aggregated tasks view
│   ├── tasks_tab.dart                # Tasks tab content for Home page
│   └── reminder_destination_sheet.dart  # "Keep in-app / Also add to OS" choice
└── utils/
    ├── voice_command_parser.dart      # Voice command keyword parsing
    └── profanity_filter.dart          # Offline profanity filter (whole-word regex)
```

---

## Pages NOT IN USE (Phase 1)

| File | Reason | When Active |
|---|---|---|
| `lib/pages/login_page.dart` | No authentication in Phase 1 | Phase 2 |

---

## Implementation Steps (Phase 1)

1. **Project Alignment & Branding** ✅ Done
2. **State Management Migration (Riverpod)** ✅ Done
3. **Data Models & Hive Database** ✅ Done
4. **Wire UI to Data Layer** ✅ Done (AI UI elements removed, all pages wired to Riverpod/Hive)
4.5. **Project Documents** ✅ Done (rich composite documents — see [FEATURE_PROJECT_DOCUMENTS.md](documents/FEATURE_PROJECT_DOCUMENTS.md))
4.6. **Interactive Tasks & Reminders** ✅ Done (checkboxes, aggregated tasks view, OS calendar bridge)
4.7. **Sharing, Rich Text & Image Blocks** ✅ Done (share_plus, flutter_quill, image_picker, PDF export)
5. **On-Device Speech-to-Text** ✅ Done (speech_to_text + whisper_flutter_new, on-device)
6. **Waveform, Playback & Notifications** ✅ Done (amplitude waveform, just_audio playback, manual reminders)
7. **Testing, Polish & Release** ✅ Done (splash screen, quick guide, settings overhaul, compact AppBar headers)
- **Post-release enhancements:** Issues #7–#12 ✅ Done (multi-select, layout, search, rich text, share preview, word count, find & replace, profanity filter, voice commands for tasks)

**Phase 2 Steps (future, not in scope):**
8. Whisper API Transcription (cloud-based, higher accuracy)
9. AI Categorization & Structuring (auto-extract actions/todos/reminders)
10. n8n Integration & Advanced Features (includes Project Documents Phase 2: AI summary)

---

## Routes (go_router) — 23 routes

| Path | Screen | Status |
|---|---|---|
| `/` | Splash | Active (initial route, animated branding) |
| `/onboarding` | Quick Guide | Active (5-page swipeable guide) |
| `/login` | Login | NOT IN USE (Phase 2) |
| `/home` | Home/Dashboard | Active (Notes/Tasks tabs, stats, SpeedDialFab) |
| `/recording` | Recording | Active (live STT + Whisper modes) |
| `/note_detail` | Note Detail | Active (accepts `recordingPath`, `noteId` extras) |
| `/folders` | Library | Active (unified Folders + Projects) |
| `/folder_detail` | Folder Detail | Active |
| `/search` | Search | Active (sectioned results) |
| `/preferences` | Preferences | Active (name, theme, toggles) |
| `/audio_settings` | Audio & Recording | Active (accepts `highlightWhisper` extra) |
| `/storage` | Storage | Active |
| `/support` | Help & Support | Active |
| `/danger_zone` | Danger Zone | Active |
| `/about` | About | Active |
| `/feedback` | Feedback | Active |
| `/support_us` | Support Us | Active |
| `/privacy_policy` | Privacy Policy | Active |
| `/terms_conditions` | Terms & Conditions | Active |
| `/project_documents` | Project Documents List | Active |
| `/project_document_detail` | Project Document Detail | Active |
| `/note_picker` | Note Picker | Active |
| `/version_history` | Version History | Active |

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
7. **DO NOT modify login_page.dart** — it is not in use for Phase 1.
8. **Hive is the database** — not sqflite, not Drift, not Isar. Use Hive with encryption.
9. **Privacy is non-negotiable** — local-first, no telemetry, no tracking.
10. **Use speech_to_text** (live mode) or **whisper_flutter_new** (record & transcribe mode) for transcription — both on-device, no cloud API.
11. **Read the feature specs** in `documents/` before modifying related features.
12. **Always update documentation** after every change:
    - `documents/CHANGELOG.md` — log all changes
    - `documents/PROJECT_STATUS.md` — update after major updates
    - `documents/IMPLEMENTATION_PLAN.md` — update when major changes are implemented
    - This is mandatory for all agents without exception.
