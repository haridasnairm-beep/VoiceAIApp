# Vaanix - Project Status

**Last Updated:** 2026-03-14
**Current Version:** 1.0.0 (Phase 1 — Release)
**Overall Progress:** Phase 1 core complete (100%). Value gap features: Steps 8–10.7 done (8/8). **All 7 Phase 1.5 waves complete** (Steps 11–17). Post-wave: Permission Management (Issue #13) + Gesture FAB (Issue #14) + Auto-Naming Preference + Persistent Counters + UX Fixes + Auto-Backup + Collapsible Backup Sections + Download Pause/Resume + Transcription Mode Redesign + Note Organize Section + GestureFab Library/Folder + Stats Projects Card + Folder Unified Timeline + Splash Timing + Ready Page Go Back + Media Resume After Recording + Note Card Capsules + Project GestureFab + Note Picker Filtering + Live V-Prefix Fix + Transcription Duplication Fix + Version History Fix + Calendar Page Redesign (Issue #15) + Audio Focus Hardening + Version History Deletion + Live Recording Info Banner + Pinned Projects + Project Swipe/Long Press Actions + Smart Filters Functional + Project Search + Voice Commands in Live Mode + Calendar New Project Dialog + Support Page Legal Section + Find & Replace in Project Documents + Task Capsule Layout (Issue #16) + Reminder Delete Fix (Issue #17) + Photo Upload Fix (Issue #18) + Backup Restore UX (Issue #19) + Reminder Reschedule Fix (Issue #20) + Share-to-Vaanix (Step 19P) + User Guide & Home Tip Tile (Step 20P) + Native Audio Conversion + Re-transcribe Page + Tip Tile Session Behavior + Widget UX Redesign + App Lock Widget Bypass Fix + PIN Length Storage + Widget Live Updates + Widget Deep Link Pre-check + Tips User Guide Navigation + Support Page Highlight + Tips Silent Dismiss + Tips 30-Day Expiry + Quick Guide 7 Pages + In-App Review Prompt + App Update Check (GitHub Releases API) done. **Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md)

---

## Status Summary

Phase 1 core is fully complete and production-ready. All 7 implementation steps are done: branding, Riverpod state management, Hive encrypted database, UI wired to data, on-device speech-to-text, audio playback + reminder notifications, and testing/polish. Additional features: splash screen with animated branding, multi-page quick guide (onboarding), interactive settings, compact AppBar headers, HDMPixels branding, project documents, interactive tasks, sharing/export with PDF, rich text editing, photo attachments, voice commands for task creation, and post-release UI polish.

**Phase 1 = No AI.** All AI-related UI elements have been removed or replaced. See the AI exclusion table in CLAUDE.md.

**All 8 value proposition gap features (Steps 8–10.7) are complete.** **All 7 Phase 1.5 waves (Steps 11–17) are complete.** App is **Play Store ready**. Next: Phase 2 (AI-powered features). See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).

---

## Completed Steps

### Step 1: Project Alignment & Branding ✅
- App name changed to "Vaanix" (Android, iOS, web, main.dart)
- Login page marked as NOT IN USE
- Onboarding navigates to Home (not Login)
- pubspec.yaml cleaned up

### Step 2: State Management Migration ✅
- Migrated from Provider to Riverpod 3.x
- 5 providers created: notes, folders, settings, recording, connectivity
- Uses Notifier/NotifierProvider (not deprecated StateNotifier)
- All providers backed by Hive repositories

### Step 3: Data Models & Hive Database ✅
- 10 Hive models with generated type adapters (Note, ActionItem, TodoItem, ReminderItem, Folder, UserSettings, ProjectDocument, ProjectBlock, TranscriptVersion, ImageAttachment)
- AES-256 encrypted boxes: notes, folders, settings, project_documents, image_attachments
- Repository layer (notes, folders, settings, project_documents, image_attachments)
- HiveService singleton with initialization, migration helpers, and deleteAllData()

### Step 4: Wire UI to Data Layer ✅
- All 8 active pages converted to ConsumerWidget/ConsumerStatefulWidget
- All AI-related UI elements removed or replaced (15 elements across 6 pages)
- Navigation extras wired (noteId, folderId)
- Theme mode live-switching from settings provider
- Onboarding completion persisted in Hive
- CRUD operations: create/rename/delete folders, edit/delete notes
- Live search across notes
- Empty states for all list pages
- App logo set as launcher icon and in-app branding

### Step 5: On-Device Speech-to-Text ✅
- Added `speech_to_text: ^7.0.0` dependency
- Created `TranscriptionService` singleton wrapping speech_to_text
- Recording page shows live transcription (finalized + interim text)
- Auto-restart sessions for long recordings (>59s timeout handling)
- Pause/resume support for both transcription and timer
- Notes saved with real transcription text, duration, and detected language
- **Known limitation:** `record` package and `speech_to_text` can't share mic on Android — STT runs exclusively, audio file recording deferred

### Step 6: Waveform, Audio Playback & Notifications ✅
- Amplitude-driven waveform bars during recording
- `AudioPlayerService` singleton with just_audio for playback
- Play/pause/seek controls on Note Detail page
- `NotificationService` singleton with flutter_local_notifications
- Manual reminder creation (date/time picker dialog)
- Scheduled notifications with deep-link to note on tap
- Reminder CRUD: add, toggle complete, delete with notification cancellation
- Settings toggle cancels all notifications when disabled
- "Delete All Data" cancels all pending notifications
- Android permissions: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, boot receiver

### Step 7: Testing, Polish & Release Prep ✅
- Fixed onboarding loop — returning users skip to /home via router redirect
- Fixed NoteDetailPage back navigation crash (context.canPop check)
- Fixed ref.watch() anti-pattern — use ref.read() outside build
- Changed applicationId from `com.mycompany.CounterApp` to `com.vaanix.app`
- Removed dead `WaveformPainter` class
- Fixed version string (v1.0.0)
- Replaced hardcoded storage display with real note/folder counts
- Wired dead UI stubs: "See All" buttons, search icons on folders pages
- Fixed search page hour formatting
- Fixed withOpacity deprecation warnings across 3 files

### Bonus: Splash Screen & Quick Guide ✅
- Animated splash screen with logo, tagline "Your voice, perfectly organized.", and "by HDMPixels" branding
- 5-second timer then navigates to onboarding (first launch) or home (returning user)
- Multi-page Quick Guide (5 swipeable pages): Welcome, Record & Transcribe, Organize Your Way, Prepare Your App (Whisper setup), Privacy First
- Skip button on first run, dot indicators, accessible from Settings

### Bonus: Settings Overhaul ✅
- Language Detection picker with 13 languages + Automatic option
- Audio Quality picker with Standard and High Quality options
- Storage utilization showing actual disk usage (HiveService.getStorageUsage)
- Removed Help Center and Terms of Service (deferred)
- Danger Zone section for Delete All Data
- AppBar with back button on Settings page

### Bonus: UI Polish — Compact Headers ✅
- Replaced manual header Rows with AppBar on Home, Folders, and Folder Detail pages
- Back button added to Folders page
- Folder name moved to AppBar title on Folder Detail page
- Reduced excessive spacing between headers and Android status bar

---

## Step 4.5 — Project Documents ✅ COMPLETED

**Status:** Complete | **Effort:** Large | **Spec:** [FEATURE_PROJECT_DOCUMENTS.md](FEATURE_PROJECT_DOCUMENTS.md)

| Sub-step | Description | Status |
|---|---|---|
| A | Data Model & Storage (3 new Hive models, Note model changes, migration) | ✅ Done |
| B | Repository & Provider Layer (ProjectDocumentsRepository, versioning) | ✅ Done |
| C | UI — Project Documents List Screen | ✅ Done |
| D | UI — Project Document Detail Screen (block rendering, editing) | ✅ Done |
| E | UI — Note Picker & Supporting Screens (version history) | ✅ Done |
| F | Integration & Polish (home page entry, migration, build verified) | ✅ Done |

**Created:** 13 files (3 models + 3 generated, 1 repository, 1 provider, 4 pages)
**Modified:** 8 files (Note model, HiveService, NotesRepository, NotesProvider, nav, Home, main)

---

## Step 4.6 — Interactive Tasks & Reminder Enhancement ✅ COMPLETED

**Status:** Complete | **Effort:** Medium-Large | **Spec:** [FEATURE_TASKS_AND_REMINDERS.md](FEATURE_TASKS_AND_REMINDERS.md)

| Sub-step | Description | Status |
|---|---|---|
| A | Data Layer — 8 CRUD methods in NotesRepository + NotesProvider + reschedule | ✅ Done |
| B | Interactive Checkboxes on Note Detail (toggle, strikethrough, manual create, CRUD) | ✅ Done |
| C | Checkboxes in Project Document Blocks (collapsible tasks sub-section) | ✅ Done |
| D | Aggregated Tasks View (Home tab, tasksProvider, filters, sorting) | ✅ Done |
| E | Dependency, OS reminder service, polish & build verified | ✅ Done |

**Created:** 6 files (task_item model, tasks_provider, tasks_tab, task_list_item, reminder_destination_sheet, os_reminder_service)
**Modified:** 6 files (notes_repository, notes_provider, note_detail, home, project_document_detail, pubspec.yaml)
**New dependency:** `add_2_calendar: ^3.0.1`

---

## Step 4.7 — Sharing, Rich Text & Image Blocks ✅ COMPLETED

**Status:** Complete | **Effort:** Large | **Spec:** [FEATURE_PROJECT_DOCUMENTS.md — Addendum A](FEATURE_PROJECT_DOCUMENTS.md)

| Sub-step | Description | Status |
|---|---|---|
| A | Data Model & Storage Extensions (ImageAttachment model, BlockType update, HiveField additions) | ✅ Done |
| B | Repository & Provider Extensions (ImageAttachmentRepository, SharingService) | ✅ Done |
| C | UI — Sharing & Export (share notes/projects via share_plus, export .md/.txt) | ✅ Done |
| D | UI — Rich Text Formatting (flutter_quill editor, formatting toolbar, Quill Delta storage) | ✅ Done |
| E | UI — Image Blocks in Projects (image_picker, photo_view, full-screen viewer) | ✅ Done |
| F | Note Detail — Photo Attachments (attachments section, add/view/delete photos) | ✅ Done |
| G | Integration & Polish (cleanup on delete, storage display update, build verified) | ✅ Done |

**Created:** 6 files (image_attachment model, image repo, sharing service, image_block_widget, note_attachments_section, image_viewer_page)
**Modified:** 10 files (project_block, note, hive_service, project_documents_repo, notes_repo, project_documents_provider, notes_provider, project_document_detail, note_detail, pubspec.yaml)
**New dependencies:** `share_plus`, `flutter_quill`, `image_picker`, `image_cropper`, `photo_view`, `flutter_image_compress`

---

## Value Proposition Gap Features (Steps 8–10.7)

### Step 8+9: Pinned Notes, AMOLED Theme, Auto-Title, Note Templates ✅
- Pinned notes float to top of home list; pin/unpin from overflow menu
- AMOLED dark theme (true black) as a third theme option
- Auto-title generated from first non-empty line of transcription (unless user manually edited title)
- Note templates: bottom sheet picker with pre-defined content/title structures; accessible from SpeedDialFab

### Step 10: Trash / Soft Delete ✅
- Soft delete for notes, folders, and project documents (30-day retention before permanent purge)
- Trash page: browse, restore, or permanently delete soft-deleted items
- Purge of expired items runs on app startup
- Notes show "(Deleted)" badge when in trash; folder soft-delete moves notes to trash too

### Step 10.5: App Lock — PIN / Biometric ✅
- PIN setup and change flow in Security settings page
- Biometric authentication via `local_auth` (fingerprint / face unlock)
- Auto-lock timeout options: immediately, 1 min, 5 min, 15 min
- Lock screen page with PIN entry + biometric trigger
- SHA-256 PIN hashing (never store raw PIN) via `crypto` package
- `AppLockService` for hash verification and biometric auth
- Variable-length PIN (4-6 digits) with stored `pinLength` (HiveField 46) for exact auto-verify
- Widget deep links route through lock screen when app is locked (except recording)

### Step 10.6: Home Screen Widget ✅
- Quick Record widget (2×1): REC button at right-center; tap to open Recording screen directly
- Dashboard widget (4×2): background image with scrim; tappable Notes/Tasks cells linking to Home tabs; note count, task count, latest note preview; minimal mode with centered REC
- Widget Privacy setting (Security page): Full / Record-Only (default) / Minimal — controls what data is shown when App Lock is enabled
- `HomeWidgetService` pushes data on foreground resume + on note/task CRUD + on privacy/lock setting changes
- Android `VaanixWidgetSmall.kt` + `VaanixWidgetDashboard.kt` (AppWidgetProvider)
- Widget picker shows live preview layout (API 31+)
- `singleTask` launch mode prevents multiple app windows from widget taps
- Quick capture mode: floating lock icon on recording page when accessed via widget bypass

### Step 15 (Wave 5): Discoverability & Polish ✅
- **Overdue task badge** on NoteCard — red badge with overdue count next to pin icon
- **Smart backup reminder** — banner on Home screen when 10+ notes and no/old backup; dismissible
- **Folder colors** — `colorValue` (HiveField 10) on Folder; `FolderColorPicker` with 10 presets; color picker in creation dialog; colored folder icons
- **Contextual tips system** — `TipService` + `ContextualTip` widget; 5 tip IDs; `dismissedTips` (HiveField 28) persistence
- **What's New screen** — version-aware (`lastSeenAppVersion` HiveField 29); 6 feature entries; shows on version change
- **Loading skeletons** — `NoteCardSkeleton` with shimmer animation; `SkeletonNoteList` for list placeholders
- **Auto-title edge case fixes** — improved fallback for non-English/short sentences

### Step 17 (Wave 7): Differentiation ✅
- **Calendar/Timeline view** — monthly grid with color-coded dots; day detail list; upcoming reminders; `/calendar` route + Home AppBar icon
- **Export ecosystem** — Markdown note export, CSV task export, JSON full-data export for data portability
- **Voice command feedback** — `voiceCommandFeedbackProvider` notifies UI of parsed commands
- **Smart Filters** — "This Week", "Open Tasks", "Unorganized" auto-computed filter chips in Library

### App Update Check (GitHub Releases API) ✅
- Checks for new app versions on launch using public GitHub Releases API (no user data sent)
- Two criticality levels: Force (blocks app with full-screen non-dismissible page) and Optional (dismissible banner on home)
- 24-hour check throttle (`lastUpdateCheckDate` HiveField 51), dismissed version tracking (`dismissedUpdateVersion` HiveField 52)
- Runs during splash animation (zero added latency)
- New dependencies: `http`, `package_info_plus`, `url_launcher`
- New files: `update_check_service.dart`, `update_banner.dart`, `force_update_page.dart`
- New route: `/force_update`

### Step 16 (Wave 6): Power User Features ✅
- **Android app shortcuts** — long-press icon shows Record + Search; deep-links to recording/search screens
- **Note sorting** — 5 sort options (Newest/Oldest/A-Z/Z-A/Longest) on home feed; `noteSortOrder` (HiveField 30) persisted
- **Swipe gestures** — swipe right to pin/unpin, swipe left to delete with confirmation; haptic feedback
- **Folder archive** — `isArchived` (HiveField 11), `sortOrder` (HiveField 12); archive from folder detail; archived section in Library
- **Accessibility** — semantic label on recording save button

### Step 14 (Wave 4): Quality Foundation ✅
- **55 unit tests** — voice command parser (25), title generator (17), profanity filter (13); all passing
- **Crash reporting** — `sentry_flutter` with opt-in `CrashReportingService`; `crashReportingEnabled` (HiveField 27) in UserSettings; toggle on Preferences page; no personal data
- **Data integrity validation** — `HiveService.validateIntegrity()` runs on startup; auto-repairs broken references (notes→folders, folders→notes, folders→projects, notes→projects)
- **Play Store submission point** — Waves 1–4 complete; app ready for Play Store

### Step 13 (Wave 3): Structural Redesign ✅
- **Projects inside folders** — `ProjectDocument` gets `folderId` (HiveField 8), `Folder` gets `projectDocumentIds` (HiveField 9); migration assigns unlinked projects to folders on startup
- **Folder Detail** shows projects alongside notes with `_FolderProjectCard`; "New Project" in overflow menu
- **Library simplified** — removed separate Projects section, collapsible headers; folders-only view with note+project counts; tags quick-access row
- **Home simplified** — 2 stat cards (Notes + Folders); all project-related code removed (stat card, bulk picker, capsule chips, SpeedDial item)
- **Recording simplified** — project dropdown removed; folder-only assignment
- **Tags system** — `tags: List<String>` (HiveField 28) on Note; full CRUD in repository/provider; `tagsProvider` derived provider
- **Tags UI** — `TagPills` widget; tags section on Note Detail with add dialog + autocomplete; tag chips on NoteCard; `TagsPage` management (rename, delete); `/tags` route
- **Voice command tags** — "Tag \<name\>" keyword in parser; multiple tags per command; auto-assigned on transcription
- **Search tags** — tag filter chips replace project chips; search matches tag content
- **Progressive disclosure audit** — documented 3 tiers (immediate/first week/power user); verified stats+banner implementations

### Step 12 (Wave 2): Core Feel ✅
- `HapticService` — static utility wrapping `HapticFeedback` (light/medium/heavy/selection); wired to recording start/stop/pause/discard and all task checkbox toggles
- `SoundService` — programmatic WAV generator (no binary assets); plays 523 Hz start cue and 392 Hz stop cue via `just_audio`; guarded by `soundCuesEnabled` preference (HiveField 25)
- Recording pulse animation — dot pulses with 0.6→1.0 scale loop; "Saving…" overlay prevents duplicate saves
- `EmptyStateIllustrated` widget — reusable illustrated empty state (icon circle, title, subtitle, optional CTA); replaces all 4 empty states: Home notes tab, Tasks tab, Library, Search
- Progressive disclosure — stats cards hidden until user has ≥5 notes and ≥2 folders
- Guided first recording banner — coaching card on Home for new users; auto-dismisses on first note; persisted via `guidedRecordingCompleted` flag (HiveField 26)
- Task completion micro-interactions — `TaskListItem` scale-bounce animation + 450ms green highlight on completion; haptic on every checkbox tap

### Step 11 (Wave 1): UX Launch Blockers ✅
- AI expectation section added to About page (on-device Whisper explanation + AI features coming soon)
- Recording mode description text below timer (Live vs Whisper one-liner, dynamically updates)
- Transcription mode info tooltip in Audio Settings (AlertDialog comparing Live vs Whisper tradeoffs)
- Live mode no-audio message on Note Detail (descriptive text instead of empty player)
- `SettingsItem` widget extended with optional `trailing: Widget?` parameter
- Fixed 4 spec contradictions in `PROJECT_SPECIFICATION.md` (AI Follow-up Questions removed, `/backup` → `/backup_restore`, `appLockPin` → `appLockPinHash`, `autoLockTimeoutMinutes` → `autoLockTimeoutSeconds`)

### Step 10.7: Local Backup & Restore ✅
- Creates AES-256-CBC encrypted `.vnbak` backup files (ZIP archive wrapped in encryption)
- Key derived via 10,000 rounds of SHA-256 from user passphrase + random 16-byte salt
- Archive includes: `manifest.json`, `data.json` (all Hive records), `images/`, `audio/` (optional)
- Restore: decrypt → unzip → clear Hive → populate from JSON → copy files
- `BackupRestorePage`: passphrase + confirm, include-audio toggle, progress bar, share sheet on backup; file picker, passphrase, manifest preview card, restore progress on restore
- `lastBackupDate` persisted in `UserSettings` (HiveField 24)
- `toMap()` / `fromMap()` added to all 10 Hive model classes

---

## Post-Release Enhancements (GitHub Issues #7–#12)

### Issue #7: Home Dashboard Tiles ✅ COMPLETED
- Multi-select mode (long-press to enter, tap to toggle, select all/deselect all)
- Single-select bottom action bar (Open, Edit Title, Folder, Project, Delete)
- Bulk actions (Add to Folder, Add to Project, Delete) for multi-select
- Folder/project capsule taps open picker with Save/Cancel
- Improved delete dialog with warning icon, white-on-red button

### Issue #8: Home Page Layout ✅ COMPLETED
- 3 compact stats cards in a Row (not horizontal scroll)
- Tab bar moved below stats (stats always visible)
- Projects card navigates to project documents (was incorrectly going to folders)
- Speed dial switches to Notes tab before executing
- Removed "Recent Notes" header and "See All" button

### Issue #9: Search Notes Page ✅ COMPLETED
- Search now matches action items, todos, and reminders text
- Sectioned results: Notes, Action Items, Todos, Reminders with color-coded headers
- Section headers show icon, label, and match count

### Issue #10: Project Details Page ✅ COMPLETED
- QuillEditor in note reference cards uses `customStyles` matching plain text (fontSize 14, onSurface color)
- Rich text inline editing now uses QuillEditor + toolbar (was plain TextField)
- New `updateNoteRichContent()` repository method saves delta JSON directly
- New `editNoteTranscriptRich()` provider method for rich text saves

### Issue #11: Share Option Project & Notes ✅ COMPLETED
- Share Preview bottom sheet with toggles: Include Title, Include Timestamp, Plain Text Only
- Live scrollable preview of assembled share text
- PDF export via `pdf` package (pure Dart, no cloud, ~1.8MB APK increase)
- Email subject line: "Title — Notes/Project from Vaanix"
- Real Quill Delta → Markdown conversion (bold, italic, headers, bullets)
- Shorter separator lines (title-length underscores instead of fixed 30-char)
- Temp file cleanup at app startup
- Project popup menu simplified (Rename/Delete only; exports moved to share sheet)

**New files:** `lib/widgets/share_preview_sheet.dart`
**New dependency:** `pdf: ^3.11.1`
**APK size:** 64.6MB → 66.4MB

### Issue #12: Word Count, Find & Replace, Profanity Filter ✅ COMPLETED
- Word & character count stats row below transcription (live updates during editing)
- Find & Replace toolbar — search icon in AppBar, match navigation, replace/replace all
- Block Offensive Words toggle in Settings > AUDIO — filters profanity from STT and Whisper output
- Whole-word regex matching with asterisk replacement, privacy-first (hardcoded word list)

**New files:** `lib/widgets/find_replace_bar.dart`, `lib/utils/profanity_filter.dart`
**New model field:** `UserSettings.blockOffensiveWords` (HiveField 18)
**APK size:** 66.4MB (unchanged)

---

## Security Hardening (v1.0.0-dev.4) ✅ COMPLETED

Comprehensive security audit and fix wave addressing 6 security issues, 2 privacy policy gaps, and 3 code quality items:

- **A1:** PIN salt hardened — `Random.secure()` replaces timestamp-based salt
- **A2:** PIN lockout persists across app restarts (HiveFields 44-45)
- **A3:** Backup KDF iterations increased 10x (10k → 100k) with backward-compatible fallback
- **A4:** Backup HMAC-SHA256 integrity verification (schema v2) detects corruption/tampering
- **A5:** File intent validation — extension, existence, and size checks before restore
- **A6:** PIN hash removed from Riverpod state — reads/writes via `AppLockService` only
- **B1-B2:** Privacy policy and Terms updated — Sentry disclosure, biometric/widget sections, encryption clarification, audio/image OS sandboxing
- **C1:** 14 bare `print()` calls replaced with `debugPrint()` (stripped in release builds)

---

## Component Status

### Infrastructure & Setup
| Component | Status | Notes |
|---|---|---|
| Project Setup | ✅ Done | Flutter project, branding aligned |
| Theme System | ✅ Done | Light/dark mode, Material 3, Google Fonts |
| Navigation | ✅ Done | 34 routes via go_router with extras, onboarding redirect |
| Audio Recording Service | ✅ Done | Record, pause, resume, stop, cancel |
| Audio Player Service | ✅ Done | Play, pause, seek via just_audio |
| Transcription Service | ✅ Done | On-device STT via speech_to_text |
| Notification Service | ✅ Done | Schedule, cancel, deep-link notifications |
| Hive Database | ✅ Done | AES-256 encrypted, 5 boxes (notes, folders, settings, project_documents, image_attachments) |
| Riverpod Providers | ✅ Done | 7 providers connected to repositories (notes, folders, settings, project_documents, tasks + 2 repo providers) |
| App Logo/Icon | ✅ Done | `assets/icons/logo.png` — launcher + in-app |

### Screens
| Screen | UI | Data Wired | Notes |
|---|---|---|---|
| Splash | ✅ | ✅ | Animated logo, timer → onboarding or home |
| Onboarding | ✅ | ✅ | 5-page Quick Guide (incl. Whisper setup), skip button, accessible from Settings |
| Login | ✅ | — | NOT IN USE (Phase 2) |
| Home | ✅ | ✅ | AppBar header, dynamic notes + folders, "See All" wired |
| Recording | ✅ | ✅ | Live STT transcription + waveform |
| Note Detail | ✅ | ✅ | Edit/delete, audio playback, reminders |
| Library | ✅ | ✅ | Unified Folders + Projects with collapsible sections, SpeedDialFab |
| Folder Detail | ✅ | ✅ | AppBar with folder name, notes filtered by folder |
| Settings | ✅ | ✅ | Language/quality pickers, storage display, whisper highlight scroll, danger zone |
| Search | ✅ | ✅ | Live search, dynamic results, hour padding fixed |

### Phase 1 Services
| Service | Status | Notes |
|---|---|---|
| Notes Repository | ✅ Done | CRUD operations |
| Folders Repository | ✅ Done | CRUD operations |
| Settings Repository | ✅ Done | Read/write settings |
| On-Device Transcription | ✅ Done | speech_to_text package |
| Audio Playback | ✅ Done | just_audio package |
| Local Notifications | ✅ Done | flutter_local_notifications + timezone |

### Phase 2 Services (NOT IN SCOPE)
| Service | Status | Notes |
|---|---|---|
| Whisper API Transcription | ❌ Phase 2 | Cloud-based, higher accuracy |
| AI Categorization | ❌ Phase 2 | Auto-extract actions/todos/reminders |
| AI Follow-up Questions | ❌ Phase 2 | Voice-triggered suggestions |
| Auto-Folder Assignment | ❌ Phase 2 | Topic-based grouping |
| n8n Integration | ❌ Phase 2 | Workflow automation |
| Offline Queue | ❌ Phase 2 | Queue for cloud processing |

---

## What Works Today

1. Animated splash screen → onboarding (first launch) or home (returning user)
2. Multi-page Quick Guide with skip option on first run
3. Navigation between all active screens with data passing
4. Light and dark theme switching (live from settings)
5. Audio recording (start, pause, resume, stop, cancel)
6. On-device speech-to-text transcription during recording
7. Real-time amplitude waveform during recording
8. Live transcription text display while speaking
9. Notes saved with transcription, duration, and detected language
10. Audio playback with play/pause/seek on note detail
11. Encrypted Hive database initialized on startup
12. Riverpod state management wired to Hive repositories
13. Create, rename, delete folders through UI
14. View, edit, delete notes through UI
15. Live search across all notes
16. Manual reminder creation with date/time picker
17. Scheduled notifications for reminders
18. Notification deep-link to specific note
19. Reminder toggle complete and delete with notification cancellation
20. Empty states on all list pages
21. Custom app icon from logo.png on Android and iOS
22. "Delete All Data" with notification cleanup in Danger Zone
23. Language detection picker (13 languages + Automatic)
24. Audio quality picker (Standard / High Quality)
25. Real storage utilization display (Hive data + recordings)
26. Compact AppBar headers on Home, Folders, Folder Detail pages
27. Back button navigation on Folders, Folder Detail, Settings pages
28. HDMPixels branding on splash screen
29. Speaker name setting ("Your Name") for transcription timestamps
30. Transcription timestamp header showing speaker + date/time
31. Audio player hidden for live transcription notes (no audio file)
32. Reminders section hidden when notifications disabled in settings
33. Whisper transcription failure feedback (SnackBar warning)
34. Interactive action item checkboxes on Note Detail (toggle complete with strikethrough)
35. Interactive todo checkboxes on Note Detail with due date badges and overdue highlighting
36. Manual task creation — "Add Action" and "Add Todo" buttons with creation dialogs
37. Task overflow menus (Edit/Delete) on all action items, todos, and reminders
38. Aggregated Tasks view on Home page (Notes/Tasks tab bar)
39. Task filter chips (All/Todos/Actions/Reminders) and "Show completed" toggle
40. Open task count badge on Tasks tab icon
41. Reminder reschedule from overflow menu (cancel old + schedule new notification)
42. "Also add to Calendar" bottom sheet after reminder creation (OS calendar bridge via add_2_calendar)
43. Collapsible tasks sub-section in Project Document note reference blocks
44. Cross-surface task state sync (Note Detail ↔ Project Document ↔ Tasks View)
45. Share single note via OS share sheet (formatted text with actions/todos/reminders)
46. Share project document via OS share sheet (assembled blocks with section headers)
47. Export project document as Markdown (.md) file with heading/quote formatting
48. Export project document as plain text (.txt) file
49. Rich text formatting in free-text blocks (bold, italic, bullet lists, headings, links) via flutter_quill
50. Quill Delta JSON storage for rich text with backward-compatible plain text fallback
51. Image blocks in project documents (gallery/camera picker, compress, full-width display with caption)
52. Full-screen image viewer with pinch-to-zoom and pan (photo_view)
53. Image block overflow menu (view full screen, edit caption, move up/down, remove with cascade delete)
54. Photo attachments on Note Detail (horizontal thumbnail row, add from gallery/camera, long-press delete)
55. Storage calculation includes image files; Delete All Data clears images directory
56. Multi-select mode on home page with bulk folder/project assignment and deletion
57. Compact 3-card stats row with Notes/Folders/Projects counts
58. Sectioned search results across notes, action items, todos, and reminders
59. QuillEditor rich text editing in project document note reference cards
60. Share preview bottom sheet with toggles (title, timestamp, plain text)
61. PDF export for notes and project documents (pure Dart, no cloud)
62. Email subject line auto-populated when sharing via email
63. Quill Delta → Markdown conversion for formatted sharing
64. Temp export file cleanup on app startup
65. Word & character count stats row below each note's transcription (live updates during editing)
66. Find & Replace toolbar in note detail (search icon in AppBar, match navigation, replace/replace all)
67. Block Offensive Words setting — filters profanity from live STT and Whisper transcription output
68. Voice command Todo/Action/Reminder task creation with Whisper transcription normalization ("to do" / "to-do" → "todo")
69. Voice commands help popup with scrollable content, task examples, and limitations section
70. Storage page breakdown with Total at bottom (divider + bold)
71. Note Detail tab system — Action Items, Todos, Reminders, Photos as selectable tabs with badge counts
72. Photo attachments in 2-column grid layout with larger thumbnails (tap to view, long-press to delete)
73. Simplified audio player — single-row compact layout with tappable waveform for seeking
74. Metadata two-row layout — timestamp on first line, duration/language/model on second line
75. Onboarding logo matches splash screen feel — larger size, matching shadow, scale-in animation
76. Share preview respects Plain Text Only toggle — rich text markdown formatting visible when toggle is off
77. Version history preserves and displays rich text formatting (Quill Delta JSON stored per version)
78. Restoring a rich text version restores formatting; restoring plain text version reverts to plain mode
79. "New Folder" and "New Project" inline creation in all folder/project picker bottom sheets
80. Pinned notes float to top of home list with pin icon badge; pin/unpin from overflow menu
81. AMOLED dark theme (true-black) as a third theme option alongside light and system dark
82. Auto-title generated from first non-empty transcription line (respects user-edited titles)
83. Note templates: SpeedDialFab → "From Template" → pre-filled note with title and content
84. Soft delete for notes, folders, and project documents — moved to Trash, 30-day retention
85. Trash page: browse all deleted items, restore individually, permanently delete, purge all
86. Expired trash items (>30 days) purged automatically on app startup
87. App Lock: PIN setup, change, and removal via Security settings
88. Biometric authentication (fingerprint / face) as alternative to PIN unlock
89. Auto-lock timeout: immediately, 1 min, 5 min, 15 min — configurable in Security settings
90. Lock screen page with PIN entry pad + biometric trigger button
91. Quick Record home screen widget (2×1): tap to open Recording screen; always safe, no content shown
92. Dashboard home screen widget (4×2): note count, open task count, latest note preview
93. Widget Privacy setting controls what the Dashboard widget shows when App Lock is enabled
94. Widget data refreshed on every app foreground resume
95. AES-256 encrypted backup: passphrase + confirm, progress bar, shares as .vnbak file
96. Backup includes all notes, folders, settings, project documents, images, and optionally audio
97. Restore: select .vnbak file → enter passphrase → verify & preview manifest → confirm → restore
98. Backup manifest preview shows creation date, app version, note/folder/image counts before restoring
99. Last backup date displayed on Backup & Restore page header
100. Share-to-Vaanix: share audio from any app into Vaanix for transcription; sender field, folder picker, Whisper check
101. Native audio format conversion: shared .opus/.ogg/.mp3/.aac files auto-converted to WAV via Android MediaCodec before Whisper transcription
102. User Guide: 14 collapsible sections covering all features; accessible from Help & Support; deep-link support via `openSectionIndex`
103. Home tip tile: shuffled tips per session, auto-hide after 1 minute, session-only dismiss, snackbar with permanent disable link
104. Re-transcribe page: multi-select bulk re-transcription with progress, confirmation dialog, rich text warnings, version history preservation
105. Share receive sheet: default folder pre-selected from user preferences; nav bar safe button sizing
106. App update check via GitHub Releases API — runs during splash, zero added latency, 24-hour throttle
107. Force update page — full-screen non-dismissible blocker when critical update is required
108. Optional update banner — dismissible banner on home page; dismissed version tracked to avoid repeat prompts

---

## APK Size Optimization (2026-03-14) ✅

- Enabled R8 code shrinking (`minifyEnabled true`) and resource shrinking (`shrinkResources true`) in `android/app/build.gradle` release buildType
- Added ProGuard keep rules for Sentry, flutter_secure_storage, local_auth, and home_widget in `android/app/proguard-rules.pro`
- Optimized build command: `flutter build apk --release --target-platform android-arm64` (arm64-only, eliminates armv7 + x86_64)
- **Result: APK size reduced from 76 MB to 31.5 MB (58% reduction)**
- For Play Store distribution: use `flutter build appbundle` for automatic per-device ABI splitting

---

## iOS Readiness Assessment (2026-03-14)

**Score:** ~45/100 | **Status:** Not App Store ready | **Critical blockers:** 5

The app targets cross-platform via Flutter but currently has Android-specific platform channel implementations (audio conversion, file intents), missing iOS configurations (Info.plist permissions, PrivacyInfo.xcprivacy), uncertain whisper_flutter_new iOS support, and Android-only home screen widgets (needs WidgetKit). Full assessment documented in [PROJECT_SPECIFICATION.md Section 13](PROJECT_SPECIFICATION.md).

**Fixes applied (2026-03-14):**
1. Privacy policy updated — Section 11C added for GitHub API update check disclosure; Section 6 bullet updated
2. Platform-aware store URLs in `update_check_service.dart` (iOS App Store + Android Play Store)
3. Review prompt text in `home_page.dart` now platform-aware ("App Store" on iOS, "Play Store" on Android)
4. Tags page back button added for consistent navigation

---

## Known Limitations (Phase 1)

1. `record` and `speech_to_text` can't share mic on Android — STT notes are transcription-only (no audio file for playback)
2. Waveform is flat during STT mode (recorder not running)
3. No unit/widget/integration tests (to be added)
4. Terms of Service / Privacy Policy pages not yet implemented (deferred)

---

## Pages Not In Use (Phase 1)

| File | Reason | Target Phase |
|---|---|---|
| `lib/pages/login_page.dart` | No authentication required in Phase 1 | Phase 2 |

---

## Next Steps

### Phase 1 — Value Proposition Gaps ✅ ALL COMPLETE (8/8)
- ~~Step 8: Pinned Notes + AMOLED + Auto-Title~~ ✅
- ~~Step 9: Note Templates~~ ✅
- ~~Step 10: Trash / Soft Delete~~ ✅
- ~~Step 10.5: App Lock — PIN / Biometric~~ ✅
- ~~Step 10.6: Home Screen Widget~~ ✅
- ~~Step 10.7: Local Backup & Restore~~ ✅

### Phase 1.5 — UX & Launch Readiness
- ~~Step 11 (Wave 1): Launch Blockers~~ ✅
- Step 12 (Wave 2): Core Feel ⬜
- Step 13 (Wave 3): Structural Redesign ⬜
- Step 14 (Wave 4): Quality Foundation ⬜
- 🚀 **Play Store Submission** (after Wave 4)
- Step 15 (Wave 5): Discoverability ⬜ *(post-launch)*
- Step 16 (Wave 6): Power User Features ⬜ *(post-launch)*
- Step 17 (Wave 7): Differentiation ⬜ *(post-launch)*

### Post-Wave Enhancements
- ~~Permission Management (Issue #13)~~ ✅
- ~~Gesture FAB (Issue #14)~~ ✅
- ~~Auto-Naming Preference~~ ✅ — `noteNamingStyle` setting (Prefix + Auto / Prefix Only / Auto Only), default prefixes V/T

### Phase 2 — AI-Powered
1. **Step 11:** Whisper API Transcription (cloud-based, higher accuracy)
2. **Step 12:** AI Categorization & Structuring (auto-extract actions/todos/reminders, smart due dates)
3. **Step 13:** n8n Integration & Advanced Features
   - Includes Project Documents Phase 2: AI summary, AI-suggested note additions
   - Includes Tasks Phase 2: recurring reminders, priority levels, Todoist/Apple Reminders API/Google Tasks API
