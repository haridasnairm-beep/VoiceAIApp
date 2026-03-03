# VoiceNotes AI - Project Specification

**Version:** 3.0
**Last Updated:** 2026-03-03
**Platform:** Cross-platform (iOS + Android) via Flutter
**Dart SDK:** ^3.6.0
**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [VoiceNotes AI Concept Document](voicenotes-ai-concept.md) | [Tasks & Reminders Feature Spec](FEATURE_TASKS_AND_REMINDERS.md) | [Project Documents Feature Spec](FEATURE_PROJECT_DOCUMENTS.md) | [Phase 1 Value Gaps](FEATURE_PHASE1_VALUE_GAPS.md) | [UX Audit](UX_PRODUCT_AUDIT.md)

---

## 1. Product Overview

VoiceNotes AI is a **privacy-first, voice-driven** note-taking and task management mobile app. Users capture thoughts, tasks, and ideas by voice. The app transcribes audio in real-time, auto-detects the spoken language, and intelligently structures content into actions, todos, reminders, and general notes — without requiring the user to type a single word.

**Core Positioning:** Record your voice. Get organized notes. 100% private.

**Core Principles:**
- **Privacy-first** — All data stored locally on-device (Hive). AI interactions are stateless with zero data retention.
- **No ads, ever** — Revenue through fair freemium model only.
- **Voice as primary interface** — Every core feature is voice-accessible.
- **Generous free tier** — All core features free. No login required.
- **Progressive disclosure** — Simple on the surface, powerful underneath. New users see only what they need; advanced features reveal themselves contextually.

**Design Style:** Warm and friendly UI inspired by Otter.ai — soft rounded corners, inviting color palette (warm whites, soft blues, gentle greens), clean typography, minimal visual clutter. The app should feel calm and effortless. Micro-interactions (haptic feedback, subtle animations, sound cues) reinforce quality at every touch point.

---

## 2. Privacy Architecture

### 2.1 Local-First Storage (Hive)
- All recordings, transcriptions, structured notes, preferences, and conversation groupings stored locally using **Hive** (encrypted with AES-256).
- No user data uploaded to any cloud server.

### 2.2 Stateless AI Processing
- Audio sent to AI service → transcribed → structured → response returned → **nothing retained**.
- Zero memory across requests. Each voice note processed in complete isolation.
- API calls use TLS 1.3, no user-identifying information beyond what is necessary.

### 2.3 User Control
- Users can view all data on their device at any time.
- Single-action delete for any or all data.
- No analytics/tracking/telemetry without explicit opt-in.
- Opt-in anonymous crash reporting available (no personal data included).

---

## 3. Target Languages

Auto-detection and transcription support for: English, Spanish, French, German, Italian, Portuguese, Arabic, Hindi, Mandarin, Japanese, Korean, Russian, Turkish, Dutch, Polish, and more. Mixed-language notes handled by transcribing each segment in its spoken language.

---

## 4. Screens & Features

> **No login required.** App is fully functional without account creation.

### 4.1 Onboarding Screen (Quick Guide)
- 5-page swipeable Quick Guide: Welcome, Record & Transcribe, Organize Your Way, Prepare Your App (Whisper setup), Privacy First
- Skip button on first run, dot page indicators
- Accessible again from Settings
- "Prepare Your App" page checks Whisper model status and offers a "Let's Set It Up" button that navigates to Settings with auto-scroll + highlight on the download section
- Navigation directly to Home (no login gate)

### 4.2 Guided First Recording
- On first launch after onboarding, instead of an empty home screen, a coached overlay prompts the user to make their first recording
- "Let's try it! Tap the mic and say something." with animated pointer to the record button
- Guides through: record → save → view the resulting note
- Dismissible, one-time only, stored in `UserSettings.guidedRecordingCompleted`
- Highest-leverage retention moment — the "wow, it worked" experience

### 4.3 Login Screen
> **STATUS: NOT IN USE (Phase 1)**
> This screen exists in the codebase but is not part of the Phase 1 flow. No authentication is required. Will be activated in Phase 2 when optional accounts are introduced.

### 4.4 Home / Dashboard
- **Stats cards row** — 2 compact cards always visible at top: Notes count, Folders count. Each card shows icon + count in a row, label below. Tapping navigates to the respective section. Cards hidden until user has 5+ notes and 2+ folders (progressive disclosure).
- **Tab bar** — segmented control below stats: `[ Notes ]  [ Tasks ]`
  - **Notes tab** (default) — notes feed in reverse chronological order (default sort; additional sort options: title A-Z/Z-A, duration, date oldest)
  - **Tasks tab** — aggregated view of all unchecked todos, actions, and reminders from every note (see 4.16)
- **Sort selector** (Notes tab) — dropdown or icon to change note sort order; persists in settings
- **Pinned section** (Notes tab, when pinned notes exist) — collapsible section header "Pinned (N)" with pin icon; pinned notes sorted by `pinnedAt` desc; max 10 pinned notes; pin icon shown on card top-right
- **Notes feed** (Notes tab) — "Recent" section header followed by cards showing:
  - Auto-generated title (smart extraction after filler removal, or task-based fallback)
  - Date/time of recording
  - Detected language tag (small pill/badge)
  - Category icons (action, todo, reminder, note)
  - Brief transcription preview (first 2 lines)
  - Folder capsule chip (tappable — opens picker with Save/Cancel)
  - Tag pills (displayed inline, tappable for filtering)
  - Overdue task badge (red indicator when note contains overdue tasks)
- **Swipe gestures on note cards:**
  - Swipe right → Pin/Unpin
  - Swipe left → Reveal Delete / Move to Folder options
  - First-time tip shown on initial swipe
- **Multi-select mode** — long-press a note to enter selection mode:
  - Tap notes to toggle selection, AppBar shows selected count with Select All / Deselect All
  - **Single-select bottom bar:** Open, Edit Title, Change Folder, Delete
  - **Multi-select bottom bar:** Add to Folder, Add Tags, Delete
  - Delete confirmation dialog with warning icon and white-on-red button
  - All folder picker sheets include "+ New Folder" inline creation at the top of the list; newly created items are auto-selected
- **SpeedDialFab** — prominent floating button with actions: Record Note, New Folder, New Text Note. "New Text Note" opens template picker sheet (Blank Note + 6 built-in templates). Actions auto-switch to Notes tab if currently on Tasks tab.
- **Search bar** — top of screen, searches by keyword, language, category, tag, date
- **Task count badge** — shown on Tasks tab label when not selected (e.g., "3" open tasks)

### 4.5 Recording Screen
- **Two transcription modes:**
  - **Live Transcription** — real-time text as user speaks via on-device `speech_to_text`; no audio file saved
  - **Whisper (Record & Transcribe)** — records WAV audio, then transcribes via on-device Whisper model; supports playback
- **Mode explanation** — one-line description below mode selector: "Live: instant text, no audio replay" / "Whisper: audio saved, transcribed after recording"
- **Waveform visualizer** — real-time amplitude waveform during recording; subtle pulse animation on mic icon when speech detected vs silence
- **Pause / Resume button** — pause without ending session
- **Cancel button** — discard recording entirely
- **"Save" button** — end recording, save note with animated "Saving…" transition (note visually "lands" in the feed)
- **Recording timer** — elapsed time display
- **Folder dropdown** (Whisper mode) — assign to folder before saving, with "+ New Folder" inline creation
- **Default folder** — pre-selected from Settings (default: "General")
- **Whisper model check** — if model not downloaded, shows popup that navigates to Settings with auto-scroll + highlight on the download section
- **Voice Command auto-linking** (Whisper mode) — say "Folder \<name\> Tag \<name\> Start \<content\>" to auto-assign folder/tags and strip the command from saved transcription
- **Voice command confirmation** — brief toast showing created items: "Created: Todo — buy groceries" with 5-second undo option
- **Haptic feedback** — on record start, stop, pause, resume, save
- **Sound cue** — subtle audio tone on recording start and stop
- **Live word count** — shown after recording stops, during review before save

### 4.6 Note Detail Screen
- **Full transcription** with detected language label
- **Structured output sections** (visually separated):
  - **Actions** — extracted from "I need to...", "let's make sure we...", "action item:...". Interactive checkbox, strikethrough when completed, overflow menu (edit/delete). Soft check animation + haptic on completion.
  - **Todos** — task items with optional due dates. Interactive checkbox, overdue date highlighting (red badge), strikethrough when completed, overflow menu (edit/delete/set due date). Soft check animation + temporary green highlight on completion.
  - **Reminders** — from "remind me to...", "don't forget...". Shows scheduled time. Reschedule action available. Option to "Also add to OS" (calendar event via `add_2_calendar`).
  - **General Notes** — everything else, preserved as formatted text.
- **Manual task creation** — "Add Task" button on Todos section, "Add Action" button on Actions section. Inline text field + optional due date picker for instant task creation.
- **Photo attachments** — "Attachments" section below structured output; horizontal scrollable thumbnails (or 2-column grid for 3+); tap for full-screen viewer with pinch-to-zoom; "Add Photo" button (gallery or camera); long-press/overflow to delete or edit caption
- **Tags** — displayed as editable tag pills below metadata; tap "+" to add new tag; tap existing tag to remove; voice command tags auto-populated
- **Share button** — opens Share Preview bottom sheet with:
  - Toggle controls: Include Title (on), Include Timestamp (off), Plain Text Only (off)
  - Live scrollable preview of assembled share text
  - "Share as Text" button — shares via OS share sheet with email subject line
  - "Export as PDF" button — generates formatted PDF with rich text, tasks, and footer
  - "Export as Markdown" button — generates .md file
  - Rich text preserved as Markdown formatting when Plain Text Only is off
- **Edit capability** — user can manually edit transcription or structured items; undo/redo supported via Flutter Quill
- **Find & Replace** — search icon in AppBar opens toolbar with match navigation, replace/replace all
- **Audio playback** — replay original recording from this screen
- **Pin/Unpin** — available in AppBar overflow menu; "Pin to Top" or "Unpin" based on current state
- **Delete note** — moves to Trash (soft delete) with 30-day recovery; confirmation prompt updated
- **Word & character count** — stats row below transcription, live updates during editing

### 4.7 Library (Folders)
- **Unified view** — folders shown with project documents nested inside each folder
- **Folder cards** — user-created folders with note count, project document count, folder color accent, last updated timestamp
- **Folder reordering** — drag-and-drop to manually order folders; persisted in Hive
- **Archived section** — collapsible section at bottom showing archived folders; archived folders remain searchable
- **SpeedDialFab** — Record Note, New Folder actions
- **Topics chips** — horizontally scrollable topic tags extracted from folders

### 4.8 Folder Detail Screen
- **Mixed content view** — notes and project documents shown together with visual distinction (note cards vs project document cards with document icon)
- **Toggle/filter** — option to show Notes only, Projects only, or All
- **Folder management** (rename, change color, archive, delete)
- **"New Project" button** — create a project document inside this folder
- **Note and project counts** in header

### 4.9 Search Screen
- **Sectioned results** with color-coded grouping:
  - **Notes** section (blue) — matches in title or transcription, **matched keywords highlighted inline**
  - **Action Items** section (orange) — matches in action item text, with parent note reference
  - **Todos** section (green) — matches in todo text, with parent note reference
  - **Reminders** section (purple) — matches in reminder text, with parent note reference
  - Each section has a color-coded header with icon, label, and match count badge
  - **Match count per note** shown alongside each result
- Filter by keyword, date, language, category, folder, tag
- **Recent searches** — stored locally, clearable
- **Tag filter** — filter results by one or more tags

### 4.10 App Menu (3-dot Overflow Menu)
> The monolithic Settings page has been replaced with a 3-dot overflow menu on the Home AppBar. Each menu item opens a dedicated sub-page.

**Menu items:**
| Menu Item | Icon | Route | Page |
|---|---|---|---|
| Preferences | `tune_rounded` | `/preferences` | PreferencesPage |
| Audio & Recording | `mic_rounded` | `/audio_settings` | AudioSettingsPage |
| Security | `lock_rounded` | `/security` | SecurityPage |
| Storage | `storage_rounded` | `/storage` | StoragePage |
| Backup & Restore | `backup_rounded` | `/backup_restore` | BackupRestorePage |
| Help & Support | `help_outline_rounded` | `/support` | SupportPage |
| About | `info_outline_rounded` | `/about` | AboutPage |
| Danger Zone | `warning_amber_rounded` | `/danger_zone` | DangerZonePage |

**Preferences page** (`/preferences`):
- Your Name — speaker label for transcription timestamps
- Note Prefix — prefix for auto-generated note names (e.g., "VOICE" → VOICE001)
- Text Prefix — prefix for text note names (e.g., "TXT" → TXT001)
- Language Detection — 13 languages + Automatic (auto-detect)
- Reminders — enable/disable notifications
- Action Items — enable/disable action items section in note detail
- To-Dos — enable/disable to-dos section in note detail
- Appearance — System / Light / Dark / AMOLED Dark with live switching

**Audio & Recording page** (`/audio_settings`):
- Audio Quality — Standard / High Quality picker
- Transcription Mode — Live Transcription or Record & Transcribe (Whisper) with one-line description of each mode's tradeoff
- Whisper Model Status — download status/progress (visible only when Whisper mode selected); supports auto-scroll + flash highlight when navigated from recording popup or onboarding
- Default Folder — picker to choose default folder for new recordings
- Voice Commands — toggle for "Folder/Tag \<name\> Start" voice command parsing (Whisper mode only)
- Block Offensive Words — filters profanity from transcription output

**Security page** (`/security`):
- App Lock — PIN setup, change, and removal
- Biometric Authentication — fingerprint / face as alternative to PIN
- Auto-lock Timeout — immediately, 1 min, 5 min, 15 min
- Widget Privacy — controls Dashboard widget visibility when App Lock enabled (Full / Record-Only / Minimal)

**Storage page** (`/storage`):
- Storage breakdown: Whisper model, voice recordings, notes & database, images
- Note/folder counts
- "All data is stored locally" info banner

**Backup & Restore page** (`/backup_restore`):
- Last backup date display
- Create Backup — AES-256 encrypted, passphrase-protected, shares as .vnbak file
- Restore from Backup — file picker, passphrase entry, manifest preview, confirm
- Smart backup reminder banner (shown if no backup in 30+ days)

**Help & Support page** (`/support`):
- Quick Guide — re-open onboarding pages
- Send Feedback — opens Feedback page (category selector, text field with 20-char minimum, sends via share sheet)

**About page** (`/about`):
- App logo, version, description
- AI features notice — "AI-powered auto-categorization and smart structuring arriving in a future update"
- Development credits (HDMPixels + Claude Code)
- Feature request tile → links to Feedback page
- Support Development (Buy Me a Coffee)
- Legal (Privacy Policy + Terms & Conditions)
- Technical details

**Danger Zone page** (`/danger_zone`):
- Delete Whisper Model — free up ~140 MB
- Delete Voice Recordings — remove audio files, keep text
- Delete All Data — with confirmation dialog, clears all notes, folders, projects, settings, and cancels notifications

### 4.11 Project Documents List Screen
- **Access:** From within a folder (Folder Detail screen) — project documents live inside folders
- **Project document cards** — title, description preview, linked note count, last updated timestamp
- **Empty state** — contextual illustration + "Create your first project document" prompt showing a brief visual of what a project document looks like and why it's useful
- **Search** — filter project documents by title/description keyword

### 4.12 Project Document Detail Screen
- **Scrollable canvas** displaying all blocks (note references, free text, section headers, images) in user-defined order
- **Header area:** editable title, description, metadata (created, updated, block count), action buttons
- **Note Reference Block:** mic icon, original recording timestamp, language badge, linked note title, full editable transcript, audio duration, photo attachment indicator (📎 N photos), overflow menu (remove, view original, version history). Rich text notes display with matching font size/color via QuillEditor `customStyles`; inline editing uses QuillEditor + toolbar for rich text notes (preserves delta JSON), plain TextField for plain text notes.
- **Free-Text Block:** rich text editing via `flutter_quill` with formatting toolbar (bold, italic, bullets, H1, H2, links); stored as Quill Delta JSON; overflow menu (remove). Undo/redo supported.
- **Section Header Block:** large/bold editable text with optional divider, overflow menu (remove)
- **Image Block:** full-width image with aspect ratio preserved, optional caption below, tap for full-screen viewer (pinch-to-zoom via `photo_view`), overflow menu (edit caption, replace, remove, view full screen)
- **Add Block action sheet:** Add Voice Note (opens note picker), Add Free Text, Add Section Header, Add Image (gallery or camera)
- **Reorder Mode:** drag handles on each block (including image blocks), "Done" button to exit
- **Bi-directional editing:** editing a transcript within a project document creates a new version on the original note and updates it everywhere
- **Share button:** opens Share Preview bottom sheet (same as note share)
- **Popup menu:** Rename, Delete

### 4.13 Note Picker Screen
- **Multi-select** from all existing notes (reverse chronological)
- **Search bar** to filter by keyword
- **"Already linked" indicator** on notes already in the project
- **"Add Selected" button** to confirm and append as note_reference blocks

### 4.14 Transcript Version History Screen
- **Version list** showing: version number, date, edit source (e.g., "Note Detail", "Project: Kitchen Renovation")
- **Rich text preview** per version — versions with `richContentJson` render formatting (bold, italic, etc.) via read-only QuillEditor; older plain-text versions display as plain text
- **"Restore this version"** action — creates a new version with restored text (non-destructive)

### 4.15 Image Viewer Screen
- **Full-screen image display** with pinch-to-zoom and pan (via `photo_view`)
- **Caption overlay** at bottom if present
- **Close button** to return to previous screen

### 4.16 Aggregated Tasks View (Tasks Tab on Home)
- **Header area:** open task count ("12 open tasks"), filter chips (All / Todos / Actions / Reminders), "Show completed" toggle
- **Multi-select mode** — long-press to enter selection; bulk complete, bulk delete, bulk reschedule
- **Task list** — each row shows:
  - Interactive checkbox (toggles completion, persists to Hive) with soft check animation + haptic + temporary green highlight
  - Task text (strikethrough + muted when completed) with smooth collapse animation
  - Source note name + date (tappable, navigates to Note Detail)
  - Due date badge (red if overdue, for todos)
  - Reminder time (for reminders, with bell icon)
  - Type indicator (todo vs action vs reminder)
- **Sorting:** overdue first → due date soonest → creation date newest. Undated items after dated.
- **Completed tasks:** grouped under "Completed" sub-header when "Show completed" is on
- **Empty state:** "Tasks you create in your notes appear here" with link to voice commands help
- **Data layer:** derived `tasksProvider` reads from `notesProvider`, assembles flat `TaskItem` list

### 4.17 Reminder Enhancement (Hybrid Model)
- **Existing in-app reminders preserved** — local notifications with deep-link back to note
- **"Also add to OS" option** — after creating a reminder, bottom sheet offers:
  - "Keep in VoiceNotes AI" — existing behavior (in-app notification)
  - "Also add to OS Reminders" — creates in-app reminder AND opens native calendar with pre-filled event (via `add_2_calendar`)
- **Per-reminder choice** — not a global setting; user decides per reminder
- **Reschedule** — clock icon or overflow menu; opens date/time picker pre-filled with current time; cancels old notification and schedules new one

### 4.18 Tags
- **Lightweight organization** — tags are simple strings stored on each note; a note can have multiple tags
- **Creation:** during note save, from Note Detail, via voice commands ("Tag \<name\> Start..."), or during multi-select bulk operations
- **Display:** tag pills on note cards (home feed), tag section on Note Detail, tag filter in Search
- **Management:** Tags page accessible from Library; rename, merge, or delete tags; shows tag count
- **Voice command integration:** "Folder Kitchen Tag Budget Tag Urgent Start the countertop quote came in"

### 4.19 Contextual First-Time Tips
- One-time dismissible tooltips that appear when a user first encounters a feature context
- Examples: first note with tasks → voice command tip; first project document → reorder tip; first search → filter tip; first swipe gesture → swipe actions tip
- Tracked via `Set<String>` in UserSettings (`dismissedTips`)
- Non-intrusive, contextual, not tutorial-style

### 4.20 What's New Screen
- Shown once after app update (version comparison)
- Brief list of new features with icons
- Dismissible, navigates to Home
- Solves returning-user discoverability for new features

### 4.21 Trash
- **Soft delete** for notes, folders, and project documents — moved to Trash with 30-day retention
- **Trash page:** browse all deleted items, restore individually, permanently delete, purge all
- **Expired items** (>30 days) purged automatically on app startup

### 4.22 App Lock
- **PIN setup** — 4-6 digit PIN with confirmation
- **Biometric authentication** — fingerprint / Face ID as alternative via `local_auth`
- **Auto-lock timeout** — immediately, 1 min, 5 min, 15 min
- **Lock screen** — PIN entry pad + biometric trigger button
- **Widget privacy** — controls what Dashboard widget shows when locked

### 4.23 Home Screen Widgets
- **Quick Record widget** (2×1) — tap to open Recording screen; no content shown
- **Dashboard widget** (4×2) — note count, open task count, latest note preview
- **Widget Privacy** — respects App Lock settings

### 4.24 Backup & Restore
- **Create backup** — AES-256 encrypted with user passphrase; includes all data + optionally audio; shares as .vnbak file
- **Restore** — select file → enter passphrase → preview manifest → confirm → restore
- **Smart backup reminder** — prompts after 10 notes if no backup exists; reminds every 30 days

---

## 5. Key Behaviors

| Behavior | Details |
|---|---|
| **Voice command parsing** | In Whisper mode, speak "Folder/Tag \<name\> Start \<content\>" to auto-organize recordings. Confirmation toast with 5-second undo. |
| **On-device transcription** | All transcription happens locally — `speech_to_text` for live mode, Whisper model for record & transcribe mode. |
| **Offline recording** | Recording and transcription work without internet (both modes are on-device). |
| **Local-only storage** | All data in encrypted Hive on-device. No cloud sync. |
| **No login required** | App fully functional without account creation or sign-in. |
| **Default folder** | New recordings automatically assigned to default folder (configurable in Settings). |
| **Project documents** | Compose rich documents from voice notes with free text and section headers. Projects live inside folders. |
| **Tags** | Lightweight cross-cutting organization. A note belongs to one folder but can have multiple tags. |
| **Interactive tasks** | Todos, actions, and reminders have tappable checkboxes with micro-interactions (animation, haptic, highlight) across all surfaces. |
| **Aggregated tasks view** | All open tasks from every note in one filterable list with multi-select bulk operations. |
| **Progressive disclosure** | Home screen starts simple; features reveal contextually as user's content grows. |
| **Contextual tips** | One-time tooltips appear at the right moment to teach power features. |
| **Haptic feedback** | Consistent tactile feedback on record, save, complete, pin, drag, and other key interactions. |
| **Swipe gestures** | Quick pin/unpin and delete/move actions on note cards without opening the note. |

**Phase 2 behaviors (not yet implemented):** AI smart categorization, contextual grouping, follow-up intelligence, auto-folder assignment, cloud sync, web companion.

---

## 6. Technical Architecture

### 6.1 Framework & Language
- **Flutter** (Dart) for cross-platform UI
- Material Design 3 with custom theme (Plus Jakarta Sans, Inter fonts)

### 6.2 State Management
- **Riverpod 3.x** — Notifier/NotifierProvider pattern
- 8 providers: notes, folders, settings, project_documents, tasks, tags + 2 repository providers
- All providers backed by Hive repositories

### 6.3 Navigation
- **go_router** for declarative routing with extras for data passing
- Active routes: splash, onboarding, guided_recording, home, recording, note_detail, library, folder_detail, preferences, audio_settings, security, storage, backup, support, danger_zone, search, project_document_detail, note_picker, version_history, privacy_policy, terms_conditions, about, feedback, trash, lock_screen, tags, whats_new
- Inactive route (Phase 2): login

### 6.4 Audio Recording
- **record** package (>=5.1.2) for audio capture
- Format: AAC-LC, 128kbps, 44.1kHz, M4A container
- Storage: `Documents/recordings/voicenote_[timestamp].m4a`
- Real-time amplitude monitoring via ValueNotifier
- Haptic feedback on start/stop/pause/resume
- Sound cue on recording start and stop

### 6.5 Local Database — Hive (Encrypted)
- **Hive** — lightweight, fast, no-SQL database for Flutter/Dart
- AES-256 encryption at rest with device-derived key
- Hive boxes for: notes, folders, settings, projectDocuments, imageAttachments, offline queue
- **Integrity checks** on app startup — validate all boxes can open; recovery screen on corruption
- No cloud persistence in Phase 1

### 6.6 Speech-to-Text (Phase 1 — On-Device)
- **Live mode:** `speech_to_text` package — on-device, free, no API key needed, real-time transcription
- **Whisper mode:** `whisper_flutter_new` package — on-device Whisper model (ggml-base.bin, ~140 MB)
- Both modes fully on-device — no cloud API calls, no data leaves the phone

### 6.7 Voice Command Parsing
- **`VoiceCommandParser`** — keyword extraction from transcription text
- Supported format: "Folder \<name\> Tag \<name\> Start \<content\>"
- "Start" is required delimiter — everything after it is the note content
- Tags supported alongside folders in voice commands
- **`VoiceCommandProcessor`** — looks up or auto-creates folders/tags by name (case-insensitive match)
- **Confirmation toast** — shows created items with 5-second undo window
- Controlled by `voiceCommandsEnabled` setting (default: true)

### 6.8 Notifications & Reminders
- **flutter_local_notifications** for in-app reminder alerts
- Manual reminder creation with date/time picker
- Scheduled notifications with deep-link to specific note on tap
- **Hybrid model:** in-app reminder always created; optional "Also add to OS" pushes a pre-filled calendar event via `add_2_calendar`
- **Reschedule:** update reminder time, cancel old notification, schedule new one

### 6.9 Crash Reporting
- **Opt-in anonymous crash reporting** — user explicitly enables in Settings or during onboarding
- No personal data, no note content, no audio — only crash stack traces and device metadata
- Integration via Sentry or Firebase Crashlytics
- Supports 99.5% crash-free rate monitoring target

### 6.10 Accessibility
- Semantic labels on all interactive elements (waveform, recording controls, checkboxes, drag handles)
- Screen reader support tested with TalkBack (Android) and VoiceOver (iOS)
- Minimum contrast ratios on all themes including AMOLED Dark
- Dynamic text scaling support
- Drag-and-drop alternatives (move up/down buttons) for reorder modes

---

## 7. Data Models

```
Note
├── id: String (UUID)
├── title: String (auto-generated from content)
├── rawTranscription: String (always reflects latest version text)
├── detectedLanguage: String
├── audioFilePath: String
├── audioDurationSeconds: int
├── createdAt: DateTime
├── updatedAt: DateTime
├── folderId: String? (nullable)
├── tags: List<String> (lightweight cross-cutting organization)
├── topics: List<String>
├── actions: List<ActionItem>
├── todos: List<TodoItem>
├── reminders: List<ReminderItem>
├── generalNotes: List<String>
├── followUpQuestions: List<String>?
├── isProcessed: bool (false if in offline queue)
├── hasFollowUpTrigger: bool
├── transcriptVersions: List<TranscriptVersion>
├── projectDocumentIds: List<String>
├── imageAttachmentIds: List<String>
├── isPinned: bool (default: false)
└── pinnedAt: DateTime? (for pin sort order)

ActionItem
├── id: String
├── text: String
├── isCompleted: bool
└── createdAt: DateTime

TodoItem
├── id: String
├── text: String
├── isCompleted: bool
├── dueDate: DateTime?
└── createdAt: DateTime

ReminderItem
├── id: String
├── text: String
├── reminderTime: DateTime
├── isCompleted: bool
├── notificationId: int?
└── createdAt: DateTime

Folder
├── id: String
├── name: String
├── color: String? (hex color for accent, e.g., "#4A90D9")
├── isAutoGenerated: bool
├── isArchived: bool (default: false)
├── sortOrder: int (for manual reordering)
├── topics: List<String>
├── noteIds: List<String>
├── projectDocumentIds: List<String> (projects live inside folders)
├── createdAt: DateTime
└── updatedAt: DateTime

UserSettings
├── defaultLanguage: String? (null = auto-detect)
├── audioQuality: String (standard / high)
├── notificationsEnabled: bool
├── quietHoursStartMinutes: int?
├── quietHoursEndMinutes: int?
├── themeMode: String (system / light / dark / amoled)
├── onboardingCompleted: bool
├── guidedRecordingCompleted: bool
├── transcriptionMode: String (live / whisper)
├── speakerName: String (default: "Speaker 1")
├── notePrefix: String (default: "VOICE")
├── textNotePrefix: String (default: "TXT")
├── defaultFolderId: String?
├── voiceCommandsEnabled: bool
├── actionItemsEnabled: bool
├── todosEnabled: bool
├── blockOffensiveWords: bool
├── noteSortOrder: String (date_desc / date_asc / title_asc / title_desc / duration)
├── dismissedTips: List<String> (IDs of dismissed contextual tips)
├── lastBackupDate: DateTime?
├── crashReportingEnabled: bool (default: false)
├── appLockEnabled: bool
├── appLockPinHash: String?
├── biometricEnabled: bool
├── autoLockTimeoutSeconds: int (0 = immediately)
├── widgetPrivacyMode: String (full / record_only / minimal)
└── lastSeenAppVersion: String (for What's New screen)

ProjectDocument
├── id: String (UUID)
├── title: String
├── description: String?
├── folderId: String (required — projects live inside folders)
├── blocks: List<ProjectBlock>
├── createdAt: DateTime
└── updatedAt: DateTime

ProjectBlock
├── id: String (UUID)
├── type: BlockType (note_reference | free_text | section_header | image_block)
├── sortOrder: int
├── noteId: String? (required when type = note_reference)
├── content: String? (required when type = free_text or section_header)
├── contentFormat: String? ("plain" or "quill_delta")
├── imageAttachmentId: String? (required when type = image_block)
├── createdAt: DateTime
└── updatedAt: DateTime

TranscriptVersion
├── id: String (UUID)
├── text: String
├── versionNumber: int
├── editSource: String
├── createdAt: DateTime
├── isOriginal: bool
└── richContentJson: String?

ImageAttachment
├── id: String (UUID)
├── filePath: String
├── fileName: String
├── caption: String?
├── width: int
├── height: int
├── fileSizeBytes: int
├── createdAt: DateTime
└── sourceType: String ("gallery" | "camera")

TaskItem (UI view model — NOT stored in Hive)
├── type: TaskType (todo | action | reminder)
├── id: String
├── text: String
├── isCompleted: bool
├── dueDate: DateTime?
├── reminderTime: DateTime?
├── createdAt: DateTime
├── sourceNoteId: String
├── sourceNoteTitle: String
└── sourceNoteDate: DateTime
```

---

## 8. Permissions Required

| Permission | Platform | Purpose |
|---|---|---|
| Microphone | Android, iOS | Voice recording |
| Storage | Android | Save recordings locally |
| Notifications | Android, iOS | Reminder alerts |
| Camera | Android, iOS | Photo capture for image blocks/attachments |
| Photo Library | Android, iOS | Gallery access for image picker |
| Internet | Android, iOS | Crash reporting (opt-in), future AI processing |
| Biometrics | Android, iOS | App Lock fingerprint/face authentication |

---

## 9. Information Architecture — Folders, Projects & Tags

| Aspect | Folders | Project Documents | Tags |
|---|---|---|---|
| **Purpose** | Organize / group notes and projects | Compose / build documents from notes | Cross-cutting categorization |
| **Hierarchy** | Flat (no subfolders) | Nested inside folders | Flat (no hierarchy) |
| **Note relationship** | A note belongs to one folder | A note can appear in many project documents | A note can have many tags |
| **Content** | Contains notes + project documents | Rich canvas: transcripts + free text + headers + images | Labels only (no content) |
| **Editing** | No editing within folder view | Full inline editing with version history | Rename, merge, delete |
| **Sorting** | Manual drag-and-drop reorder | Block reorder within document | Alphabetical |

Folders organize. Tags cross-reference. Projects compose.

---

## 10. Out of Scope (Phase 2+)

| Feature | Phase |
|---|---|
| User accounts / authentication | Phase 2 |
| Cloud backup (E2E encrypted) | Phase 2 |
| Cross-device sync | Phase 2 |
| n8n AI agent integration | Phase 2 |
| WiFi microphone support | Phase 2 |
| Multi-user voice detection / speaker diarization | Phase 2 |
| Keyword urgency tagging | Phase 2 |
| Voice search | Phase 2 |
| AI-generated Project Document summary | Phase 2 |
| AI-suggested note additions for projects | Phase 2 |
| Recurring reminders | Phase 2 |
| Push to Todoist / Apple Reminders API / Google Tasks API | Phase 2 |
| Notification action buttons (Done / Snooze) | Phase 2 |
| Task priority levels (Low / Medium / High) | Phase 2 |
| AI auto-extraction of todos/actions from transcription | Phase 2 |
| Smart due date extraction ("by Friday") | Phase 2 |
| Transcript-audio sync (tap word → jump to timestamp) | Phase 2 |
| Calendar / Timeline view | Phase 2 |
| Smart filters (virtual folders) | Phase 2 |
| Custom note templates (user-created) | Phase 2 |
| Web companion | Phase 2 |
| External recorder import | Phase 2 |
| Task assignment (multi-user) | Phase 3 |
| Numbered lists, checklists in rich text | Phase 2 |
| H3-H6 headings, inline images in text | Phase 2 |
| Markdown source editing mode | Phase 2 |
| Music note capture | Phase 3 |
| Smart automations | Phase 3 |
| Ambient listening mode | Phase 3 |
| Collaborative features | Phase 3 |
| Third-party integrations (CRM, calendars) | Phase 3 |

---

## 11. Tech Stack (Phase 1)

| Component | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.6.0) |
| Local database | Hive (AES-256 encrypted) |
| State management | Riverpod 3.x (Notifier/NotifierProvider) |
| Navigation | go_router |
| Audio recording | record package |
| Audio playback | just_audio |
| Speech-to-text (live) | speech_to_text (on-device, free) |
| Speech-to-text (whisper) | whisper_flutter_new (on-device, ggml-base model) |
| Notifications | flutter_local_notifications |
| OS calendar bridge | add_2_calendar |
| Sharing | share_plus |
| Rich text editor | flutter_quill |
| Image picker | image_picker |
| Image cropping | image_cropper |
| Image viewer | photo_view |
| Image compression | flutter_image_compress |
| PDF generation | pdf (pure Dart, on-device) |
| Biometric auth | local_auth |
| Home screen widget | home_widget |
| Backup archive | archive + encrypt |
| Crash reporting | sentry_flutter or firebase_crashlytics (opt-in) |
| Typography | Google Fonts (Plus Jakarta Sans, Inter) |
| App icon | assets/icons/logo.png (launcher + in-app branding) |

---

## 12. Dependencies

| Package | Purpose | Status |
|---|---|---|
| flutter | UI framework | Active |
| flutter_riverpod | Riverpod 3.x state management | Active |
| go_router | Declarative routing | Active |
| hive + hive_flutter | Local encrypted database | Active |
| record | Audio recording | Active |
| just_audio | Audio playback | Active |
| speech_to_text | On-device live transcription | Active |
| whisper_flutter_new | On-device Whisper model transcription | Active |
| flutter_local_notifications | Reminder notifications | Active |
| google_fonts | Custom typography | Active |
| path_provider | File system access | Active |
| uuid | Unique ID generation | Active |
| flutter_secure_storage | Secure encryption key storage | Active |
| cupertino_icons | iOS-style icons | Active |
| add_2_calendar | OS calendar event creation | Active |
| share_plus | Native OS share sheet | Active |
| flutter_quill | Rich text editing and viewing | Active |
| wakelock_plus | Keep screen awake during recording | Active |
| image_picker | Gallery and camera photo selection | Active |
| image_cropper | Crop and resize UI | Active |
| photo_view | Full-screen image viewer | Active |
| flutter_image_compress | Image compression and resizing | Active |
| pdf | Pure Dart PDF generation | Active |
| local_auth | Biometric authentication | Active |
| home_widget | Cross-platform home screen widget | Active |
| archive | ZIP archive for backup | Active |
| encrypt | AES-256 for backup encryption | Active |
| sentry_flutter | Opt-in crash reporting | Planned |
| hive_generator + build_runner | Hive model code generation (dev) | Active |
