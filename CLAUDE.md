# CLAUDE.md — Vaanix Agent Reference

This file provides context for AI agents (Claude Code, Copilot, etc.) working on this project.

**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Branch:** main

---

## Project Summary

**Vaanix** is a privacy-first, voice-driven note-taking and task management mobile app built with Flutter. Users record voice notes, the app transcribes audio on-device, and organizes content into folders with manual categorization.

**Current Phase:** Phase 1 (Release) — 100% complete. All 7 core steps + Steps 4.5/4.6/4.7 + post-release enhancements (Issues #7–#12) + all 8 value proposition gap features (Steps 8–10.7) + Steps 19P–21P. Version 1.0.5. **Next:** Phase 2 (AI-powered features).

---

## Phase Architecture

| Phase | Scope | AI Required |
|---|---|---|
| **Phase 1 (Complete)** | On-device recording, transcription (speech_to_text + whisper_flutter_new), local storage, manual organization, playback, notifications, project documents, tasks, sharing/export, rich text, image blocks, pinned notes, AMOLED theme, auto-title, note templates, trash/soft-delete, app lock (PIN/biometric), home screen widgets, local backup & restore | **No AI** |
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
| Biometric / PIN auth | local_auth (Step 10.5 — App Lock) |
| Cryptographic hashing | crypto (SHA-256 PIN hashing + backup key derivation) |
| Home screen widgets | home_widget (Step 10.6 — Quick Record + Dashboard) |
| Backup archive | archive (Step 10.7 — ZIP encode/decode) |
| Backup encryption | encrypt (Step 10.7 — AES-256-CBC) |
| Backup file picker | file_picker (Step 10.7 — restore file selection) |
| Permission management | permission_handler (runtime permission checks + app settings) |
| Typography | Google Fonts (Plus Jakarta Sans, Inter) |
| App icon | `assets/icons/logo.png` (used for launcher icon + in-app branding) |

---

## Project Structure

```
lib/
├── main.dart                         # App entry point (Hive init + ProviderScope + widget/lock init)
├── nav.dart                          # GoRouter routes (31 routes) and AppRoutes constants
├── theme.dart                        # Material 3 theme (light + dark + AMOLED)
├── models/
│   ├── note.dart                     # Hive model (typeId: 0) — includes isPinned, isDeleted, toMap/fromMap
│   ├── action_item.dart              # Hive model (typeId: 1) — toMap/fromMap
│   ├── todo_item.dart                # Hive model (typeId: 2) — toMap/fromMap
│   ├── reminder_item.dart            # Hive model (typeId: 3) — toMap/fromMap
│   ├── folder.dart                   # Hive model (typeId: 4) — includes isDeleted, toMap/fromMap
│   ├── user_settings.dart            # Hive model (typeId: 5) — HiveFields 0–46, toMap/fromMap
│   ├── project_document.dart         # Hive model (typeId: 6) — toMap/fromMap
│   ├── project_block.dart            # Hive model (typeId: 7) + BlockType enum (typeId: 9) — toMap/fromMap
│   ├── transcript_version.dart       # Hive model (typeId: 8) — toMap/fromMap
│   ├── image_attachment.dart         # Hive model (typeId: 10) — toMap/fromMap
│   ├── task_item.dart                # View model for aggregated tasks (NOT Hive)
│   └── *.g.dart                      # Generated Hive type adapters
├── services/
│   ├── audio_recorder_service.dart   # Audio recording
│   ├── audio_player_service.dart     # Audio playback via just_audio
│   ├── hive_service.dart             # Encrypted Hive init + storage usage + migration helpers
│   ├── notes_repository.dart         # CRUD for notes + tasks + versioning + trash
│   ├── folders_repository.dart       # CRUD for folders + trash
│   ├── settings_repository.dart      # Settings persistence
│   ├── transcription_service.dart    # On-device STT via speech_to_text
│   ├── whisper_service.dart          # On-device Whisper transcription
│   ├── notification_service.dart     # Local notifications + scheduling
│   ├── project_documents_repository.dart  # CRUD for project documents + trash
│   ├── image_attachment_repository.dart   # Image CRUD + file management
│   ├── sharing_service.dart          # Assemble share text, export PDF/MD/TXT
│   ├── voice_command_processor.dart  # Voice command lookup/auto-create
│   ├── os_reminder_service.dart      # OS calendar bridge via add_2_calendar
│   ├── app_lock_service.dart         # PIN hash verify + biometric auth (Step 10.5)
│   ├── home_widget_service.dart      # Home screen widget data push + privacy (Step 10.6)
│   ├── backup_service.dart           # AES-256 encrypted ZIP backup/restore (Step 10.7)
│   └── title_generator_service.dart  # Auto-title generation from transcription (Step 8)
├── providers/
│   ├── notes_provider.dart           # NotesNotifier + notesProvider
│   ├── folders_provider.dart         # FoldersNotifier + foldersProvider
│   ├── settings_provider.dart        # SettingsNotifier + settingsProvider
│   ├── project_documents_provider.dart  # ProjectDocumentsNotifier
│   └── tasks_provider.dart           # Derived provider: aggregated tasks view
├── pages/
│   ├── splash_page.dart              # Animated splash → lock screen / onboarding / home
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
│   ├── security_page.dart            # App Lock: PIN setup, biometric, auto-lock, widget privacy (Step 10.5/10.6)
│   ├── trash_page.dart               # Soft-deleted notes/folders/projects — 30-day retention (Step 10)
│   ├── backup_restore_page.dart      # Encrypted backup creation & restore UI (Step 10.7)
│   ├── lock_screen_page.dart         # PIN / biometric unlock screen (Step 10.5)
│   ├── permission_page.dart         # Post-onboarding permission request (mic + notifications)
│   ├── user_guide_page.dart          # Full User Guide with 14 collapsible sections (Step 20P)
│   ├── retranscribe_page.dart        # Bulk re-transcription: multi-select, progress, confirm (Step 21P)
│   ├── about_page.dart               # App info, credits, legal
│   ├── feedback_page.dart            # User feedback form
│   ├── support_us_page.dart          # Buy Me a Coffee
│   ├── calendar_page.dart            # Calendar view of notes by date
│   ├── tags_page.dart                # Tags management page
│   ├── privacy_policy_page.dart      # Privacy policy
│   └── terms_conditions_page.dart    # Terms & conditions
├── widgets/
│   ├── note_card.dart                # Note card for lists
│   ├── speed_dial_fab.dart           # Multi-action floating button (SpeedDialItem model)
│   ├── gesture_fab.dart              # Gesture FAB: swipe-up to record, tap to expand SpeedDial
│   ├── share_preview_sheet.dart      # Share preview with toggles + PDF export
│   ├── find_replace_bar.dart         # Find & Replace toolbar
│   ├── settings_widgets.dart         # Reusable settings UI components
│   ├── download_progress_sheet.dart  # Whisper model download progress
│   ├── image_block_widget.dart       # Image block for project documents
│   ├── note_attachments_section.dart # Photo section on Note Detail
│   ├── task_list_item.dart           # Task row in aggregated tasks view
│   ├── tasks_tab.dart                # Tasks tab content for Home page
│   ├── reminder_destination_sheet.dart  # "Keep in-app / Also add to OS" choice
│   ├── template_picker_sheet.dart    # Note template selection bottom sheet (Step 9)
│   ├── share_receive_sheet.dart      # Share-to-Vaanix bottom sheet (Step 19P)
│   └── home_tip_tile.dart            # Dismissible tip card for home page (14 tips, Step 20P)
└── utils/
    ├── voice_command_parser.dart      # Voice command keyword parsing
    └── profanity_filter.dart          # Offline profanity filter (whole-word regex)
```

---

## Pages NOT IN USE (Phase 1)

| File | Reason | When Active |
|---|---|---|
| `lib/pages/login_page.dart` | No authentication in Phase 1 | Phase 2 |
| `lib/pages/whats_new_page.dart` | Orphaned — no route defined | TBD |

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
- **Step 8: Pinned Notes + AMOLED + Auto-Title** ✅ Done (pin notes to top, AMOLED dark theme, auto-title from transcription)
- **Step 9: Note Templates** ✅ Done (template picker bottom sheet, pre-filled note content/title)
- **Step 10: Trash / Soft Delete** ✅ Done (30-day retention, restore, purge on startup)
- **Step 10.5: App Lock — PIN / Biometric** ✅ Done (PIN setup/change, biometric via local_auth, auto-lock timeout, lock screen)
- **Step 10.6: Home Screen Widget** ✅ Done (Quick Record 2×1 + Dashboard 4×2 Android widgets, Widget Privacy setting)
- **Step 10.7: Local Backup & Restore** ✅ Done (AES-256-CBC encrypted .vnbak archives, passphrase key derivation, full restore)
- **Permission Management (Issue #13)** ✅ Done (post-onboarding permission page, permissions section in audio settings, permission_handler)
- **Gesture FAB (Issue #14)** ✅ Done (swipe-up to record, icon crossfade, pulse animation, haptic feedback, subtitle hint label, session count tracking)
- **Auto-Backup** ✅ Done (scheduled encrypted backups, frequency/retention settings, passphrase in flutter_secure_storage, silent on-launch execution, auto-rotation)

**Phase 2 Steps (future, not in scope):**
- Whisper API Transcription (cloud-based, higher accuracy)
- AI Categorization & Structuring (auto-extract actions/todos/reminders)
- n8n Integration & Advanced Features (includes Project Documents Phase 2: AI summary)

---

## Routes (go_router) — 33 routes

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
| `/security` | Security | Active (App Lock PIN/biometric setup, auto-lock, widget privacy) |
| `/trash` | Trash | Active (soft-deleted notes/folders/projects, 30-day retention) |
| `/danger_zone` | Danger Zone | Active |
| `/backup_restore` | Backup & Restore | Active (create encrypted .vnbak, restore from file) |
| `/about` | About | Active |
| `/feedback` | Feedback | Active |
| `/support_us` | Support Us | Active |
| `/privacy_policy` | Privacy Policy | Active |
| `/terms_conditions` | Terms & Conditions | Active |
| `/project_documents` | Project Documents List | Active |
| `/project_document_detail` | Project Document Detail | Active |
| `/note_picker` | Note Picker | Active |
| `/version_history` | Version History | Active |
| `/permissions` | Permission Request | Active (post-onboarding, one-time mic + notifications) |
| `/user_guide` | User Guide | Active (14 collapsible sections, accepts `openSectionIndex` extra) |
| `/retranscribe` | Re-transcribe | Active (bulk re-transcription with multi-select) |
| `/calendar` | Calendar | Active (calendar view of notes by date) |
| `/tags` | Tags | Active (tags management) |

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

1. **Read PROJECT_SPECIFICATION.md** for product decisions (authoritative source).
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
    - `CLAUDE.md` — update when new files, routes, dependencies, or features are added
    - This is mandatory for all agents without exception.
