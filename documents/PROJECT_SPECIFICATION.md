# VoiceNotes AI - Project Specification

**Version:** 2.8
**Last Updated:** 2026-03-02
**Platform:** Cross-platform (iOS + Android) via Flutter
**Dart SDK:** ^3.6.0
**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [VoiceNotes AI Concept Document](voicenotes-ai-concept.md) | [Tasks & Reminders Feature Spec](FEATURE_TASKS_AND_REMINDERS.md) | [Project Documents Feature Spec](FEATURE_PROJECT_DOCUMENTS.md) | [Phase 1 Value Gaps](FEATURE_PHASE1_VALUE_GAPS.md)

---

## 1. Product Overview

VoiceNotes AI is a **privacy-first, voice-driven** note-taking and task management mobile app. Users capture thoughts, tasks, and ideas by voice. The app transcribes audio in real-time, auto-detects the spoken language, and intelligently structures content into actions, todos, reminders, and general notes — without requiring the user to type a single word.

**Core Principles:**
- **Privacy-first** — All data stored locally on-device (Hive). AI interactions are stateless with zero data retention.
- **No ads, ever** — Revenue through fair freemium model only.
- **Voice as primary interface** — Every core feature is voice-accessible.
- **Generous free tier** — All core features free. No login required.

**Design Style:** Warm and friendly UI inspired by Otter.ai — soft rounded corners, inviting color palette (warm whites, soft blues, gentle greens), clean typography, minimal visual clutter. The app should feel calm and effortless.

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

---

## 3. Target Languages

Auto-detection and transcription support for: English, Spanish, French, German, Italian, Portuguese, Arabic, Hindi, Mandarin, Japanese, Korean, Russian, Turkish, Dutch, Polish, and more. Mixed-language notes handled by transcribing each segment in its spoken language.

---

## 4. Screens & Features (Phase 1)

> **No login required.** App is fully functional without account creation.

### 4.1 Onboarding Screen (Quick Guide)
- 5-page swipeable Quick Guide: Welcome, Record & Transcribe, Organize Your Way, Prepare Your App (Whisper setup), Privacy First
- Skip button on first run, dot page indicators
- Accessible again from Settings
- "Prepare Your App" page checks Whisper model status and offers a "Let's Set It Up" button that navigates to Settings with auto-scroll + highlight on the download section
- Navigation directly to Home (no login gate)

### 4.2 Login Screen
> **STATUS: NOT IN USE (Phase 1)**
> This screen exists in the codebase but is not part of the Phase 1 flow. No authentication is required. Will be activated in Phase 2 when optional accounts are introduced.

### 4.3 Home / Dashboard
- **Stats cards row** — 3 compact cards always visible at top: Notes count, Folders count, Projects count. Each card shows icon + count in a row, label below. Tapping navigates to the respective section.
- **Tab bar** — segmented control below stats: `[ Notes ]  [ Tasks ]`
  - **Notes tab** (default) — notes feed in reverse chronological order
  - **Tasks tab** — aggregated view of all unchecked todos, actions, and reminders from every note (see 4.14)
- **Pinned section** (Notes tab, when pinned notes exist) — collapsible section header "Pinned (N)" with pin icon; pinned notes sorted by `pinnedAt` desc; max 10 pinned notes; pin icon shown on card top-right
- **Notes feed** (Notes tab) — "Recent" section header followed by cards showing:
  - Auto-generated title (smart extraction after filler removal, or task-based fallback)
  - Date/time of recording
  - Detected language tag (small pill/badge)
  - Category icons (action, todo, reminder, note)
  - Brief transcription preview (first 2 lines)
  - Folder/project capsule chips (tappable — opens picker with Save/Cancel)
- **Multi-select mode** — long-press a note to enter selection mode:
  - Tap notes to toggle selection, AppBar shows selected count with Select All / Deselect All
  - **Single-select bottom bar:** Open, Edit Title, Change Folder, Change Project, Delete
  - **Multi-select bottom bar:** Add to Folder, Add to Project, Delete
  - Delete confirmation dialog with warning icon and white-on-red button
  - All folder/project picker sheets include "+ New Folder" / "+ New Project" inline creation at the top of the list; newly created items are auto-selected
- **SpeedDialFab** — prominent floating button with actions: Record Note, New Folder, New Project, New Text Note. "New Text Note" opens template picker sheet (Blank Note + 6 built-in templates). Actions auto-switch to Notes tab if currently on Tasks tab.
- **Search bar** — top of screen, searches by keyword, language, category, date
- **Task count badge** — shown on Tasks tab label when not selected (e.g., "3" open tasks)

### 4.4 Recording Screen
- **Two transcription modes:**
  - **Live Transcription** — real-time text as user speaks via on-device `speech_to_text`; no audio file saved
  - **Whisper (Record & Transcribe)** — records WAV audio, then transcribes via on-device Whisper model; supports playback
- **Waveform visualizer** — real-time amplitude waveform during recording
- **Pause / Resume button** — pause without ending session
- **Cancel button** — discard recording entirely
- **"Save" button** — end recording, save note (and trigger background Whisper transcription if applicable)
- **Recording timer** — elapsed time display
- **Folder & Project dropdowns** (Whisper mode) — assign to folder/project before saving, with "+ New Folder" / "+ New Project" inline creation
- **Default folder** — pre-selected from Settings (default: "General")
- **Whisper model check** — if model not downloaded, shows popup that navigates to Settings with auto-scroll + highlight on the download section
- **Voice Command auto-linking** (Whisper mode) — say "Folder \<name\> Project \<name\> Start \<content\>" to auto-assign folder/project and strip the command from saved transcription

### 4.5 Note Detail Screen
- **Full transcription** with detected language label
- **Structured output sections** (visually separated):
  - **Actions** — extracted from "I need to...", "let's make sure we...", "action item:...". Interactive checkbox, strikethrough when completed, overflow menu (edit/delete).
  - **Todos** — task items with optional due dates. Interactive checkbox, overdue date highlighting (red badge), strikethrough when completed, overflow menu (edit/delete/set due date).
  - **Reminders** — from "remind me to...", "don't forget...". Shows scheduled time. Reschedule action available. Option to "Also add to OS" (calendar event via `add_2_calendar`).
  - **General Notes** — everything else, preserved as formatted text.
- **Manual task creation** — "Add Task" button on Todos section, "Add Action" button on Actions section. Inline text field + optional due date picker for instant task creation.
- **AI Follow-up Questions** — shown only when user includes voice trigger ("any suggestions?", "what should I consider?", "what am I missing?"). 2-3 contextually relevant questions.
- **Photo attachments** — "Attachments" section below structured output; horizontal scrollable thumbnails (or 2-column grid for 3+); tap for full-screen viewer with pinch-to-zoom; "Add Photo" button (gallery or camera); long-press/overflow to delete or edit caption
- **Share button** — opens Share Preview bottom sheet with:
  - Toggle controls: Include Title (on), Include Timestamp (off), Plain Text Only (off)
  - Live scrollable preview of assembled share text
  - "Share as Text" button — shares via OS share sheet with email subject line
  - "Export as PDF" button — generates formatted PDF with rich text, tasks, and footer
  - Rich text preserved as Markdown formatting when Plain Text Only is off
- **Edit capability** — user can manually edit transcription or structured items
- **Audio playback** — replay original recording from this screen
- **Pin/Unpin** — available in AppBar overflow menu; "Pin to Top" or "Unpin" based on current state
- **Delete note** — moves to Trash (soft delete) with 30-day recovery; confirmation prompt updated

### 4.6 Library (Folders & Projects)
- **Unified view** — folders and projects shown on one page with collapsible section headers (arrow toggle + count badge)
- **Folders section** — user-created folders with note count, last updated timestamp
- **Projects section** — project documents with note count, block count, last updated, description preview
- **SpeedDialFab** — Record Note, New Folder, New Project actions
- **Topics chips** — horizontally scrollable topic tags extracted from folders

### 4.7 Folder Detail Screen
- View all notes within a folder
- Folder management (rename, delete)

### 4.8 Search Screen
- Full-text search across all notes (title, transcription, action items, todos, reminders)
- **Sectioned results** when query is active — results grouped into:
  - **Notes** section (blue) — matches in title or transcription
  - **Action Items** section (orange) — matches in action item text, with parent note reference
  - **Todos** section (green) — matches in todo text, with parent note reference
  - **Reminders** section (purple) — matches in reminder text, with parent note reference
  - Each section has a color-coded header with icon, label, and match count badge
- Filter by keyword, date, language, category, folder, project

### 4.9 App Menu (3-dot Overflow Menu)
> The monolithic Settings page has been replaced with a 3-dot overflow menu on the Home AppBar. Each menu item opens a dedicated sub-page.

**Menu items:**
| Menu Item | Icon | Route | Page |
|---|---|---|---|
| Preferences | `tune_rounded` | `/preferences` | PreferencesPage |
| Audio & Recording | `mic_rounded` | `/audio_settings` | AudioSettingsPage |
| Storage | `storage_rounded` | `/storage` | StoragePage |
| Help & Support | `help_outline_rounded` | `/support` | SupportPage |
| About | `info_outline_rounded` | `/about` | AboutPage |
| Security | `lock_rounded` | `/security` | SecurityPage |
| Trash | `delete_rounded` | `/trash` | TrashPage |
| Backup & Restore | `backup_rounded` | `/backup_restore` | BackupRestorePage |
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
- Transcription Mode — Live Transcription or Record & Transcribe (Whisper)
- Whisper Model Status — download status/progress (visible only when Whisper mode selected); supports auto-scroll + flash highlight when navigated from recording popup or onboarding
- Default Folder — picker to choose default folder for new recordings
- Voice Commands — toggle for "Folder/Project \<name\> Start" voice command parsing (Whisper mode only)

**Storage page** (`/storage`):
- Storage breakdown: Whisper model, voice recordings, notes & database, images
- Note/folder counts
- "All data is stored locally" info banner

**Help & Support page** (`/support`):
- Quick Guide — re-open onboarding pages
- Send Feedback — opens Feedback page (category selector, text field with 20-char minimum, sends via share sheet)

**About page** (`/about`):
- App logo, version, description
- Development credits (HDMPixels + Claude Code)
- Coming Soon (Phase 2 roadmap)
- Feature request tile → links to Feedback page
- Support Development (Buy Me a Coffee)
- Legal (Privacy Policy + Terms & Conditions)
- Technical details

**Danger Zone page** (`/danger_zone`):
- Delete Whisper Model — free up ~140 MB
- Delete Voice Recordings — remove audio files, keep text
- Delete All Data — with confirmation dialog, clears all notes, folders, projects, settings, and cancels notifications

**Security page** (`/security`):
- App Lock — toggle (enable/disable requires PIN/biometric)
- Change PIN — opens PIN change flow (current PIN → new PIN → confirm)
- Biometric Unlock — toggle (hidden if no biometric hardware)
- Auto-Lock Timeout — picker: Immediately (default) / 1 min / 5 min / 15 min
- Widget Privacy — picker: Full / Record-Only (default) / Minimal (visible only when App Lock ON and widget active)

### 4.10 Project Documents List Screen
- **"New Project" button** — prominent FAB or top button
- **Project document cards** — title, description preview, linked note count, last updated timestamp
- **Empty state** — illustration + "Create your first project document" prompt
- **Search** — filter project documents by title/description keyword
- **Access:** From Home page (navigation alongside Folders)

### 4.11 Project Document Detail Screen
- **Scrollable canvas** displaying all blocks (note references, free text, section headers, images) in user-defined order
- **Header area:** editable title, description, metadata (created, updated, block count), action buttons
- **Note Reference Block:** mic icon, original recording timestamp, language badge, linked note title, full editable transcript, audio duration, photo attachment indicator (📎 N photos), overflow menu (remove, view original, version history). Rich text notes display with matching font size/color via QuillEditor `customStyles`; inline editing uses QuillEditor + toolbar for rich text notes (preserves delta JSON), plain TextField for plain text notes.
- **Free-Text Block:** rich text editing via `flutter_quill` with formatting toolbar (bold, italic, bullets, H1, H2, links); stored as Quill Delta JSON; overflow menu (remove)
- **Section Header Block:** large/bold editable text with optional divider, overflow menu (remove)
- **Image Block:** full-width image with aspect ratio preserved, optional caption below, tap for full-screen viewer (pinch-to-zoom via `photo_view`), overflow menu (edit caption, replace, remove, view full screen)
- **Add Block action sheet:** Add Voice Note (opens note picker), Add Free Text, Add Section Header, Add Image (gallery or camera)
- **Reorder Mode:** drag handles on each block (including image blocks), "Done" button to exit
- **Bi-directional editing:** editing a transcript within a project document creates a new version on the original note and updates it everywhere
- **Share button:** opens Share Preview bottom sheet with:
  - Toggle controls: Include Title (on), Include Timestamp (off), Plain Text Only (off)
  - Live scrollable preview of assembled share text
  - "Share as Text" button — shares via OS share sheet with email subject line: "Title — Project from VoiceNotes AI"
  - "Export as PDF" button — generates formatted PDF with section headers, note reference cards, rich text, and footer
  - "Export as Markdown" button — generates .md file with heading/quote formatting
  - Separator lines use title-length underscores (not fixed-width)
- **Popup menu:** Rename, Delete (export options moved to share preview sheet)

### 4.12 Note Picker Screen
- **Multi-select** from all existing notes (reverse chronological)
- **Search bar** to filter by keyword
- **"Already linked" indicator** on notes already in the project
- **"Add Selected" button** to confirm and append as note_reference blocks

### 4.13 Transcript Version History Screen
- **Version list** showing: version number, date, edit source (e.g., "Note Detail", "Project: Kitchen Renovation")
- **Rich text preview** per version — versions with `richContentJson` render formatting (bold, italic, etc.) via read-only QuillEditor; older plain-text versions display as plain text
- **"Restore this version"** action — creates a new version with restored text (non-destructive); restoring a rich text version restores Delta JSON + contentFormat; restoring a plain text version reverts note to plain mode

### 4.14 Image Viewer Screen
- **Full-screen image display** with pinch-to-zoom and pan (via `photo_view`)
- **Caption overlay** at bottom if present
- **Close button** to return to previous screen

### 4.15 Aggregated Tasks View (Tasks Tab on Home)
- **Header area:** open task count ("12 open tasks"), filter chips (All / Todos / Actions), "Show completed" toggle
- **Task list** — each row shows:
  - Interactive checkbox (toggles completion, persists to Hive)
  - Task text (strikethrough + muted when completed)
  - Source note name + date (tappable, navigates to Note Detail)
  - Due date badge (red if overdue, for todos)
  - Reminder time (for reminders, with bell icon)
  - Type indicator (todo vs action vs reminder)
- **Sorting:** overdue first → due date soonest → creation date newest. Undated items after dated.
- **Completed tasks:** grouped under "Completed" sub-header when "Show completed" is on
- **Reminders** included alongside todos and actions with distinct bell icon
- **Empty state:** "No open tasks — you're all caught up!"
- **Data layer:** derived `tasksProvider` reads from `notesProvider`, assembles flat `TaskItem` list (view model, not Hive model)

### 4.16 Reminder Enhancement (Hybrid Model)
- **Existing in-app reminders preserved** — local notifications with deep-link back to note
- **"Also add to OS" option** — after creating a reminder, bottom sheet offers:
  - "Keep in VoiceNotes AI" — existing behavior (in-app notification)
  - "Also add to OS Reminders" — creates in-app reminder AND opens native calendar with pre-filled event (via `add_2_calendar`)
- **Per-reminder choice** — not a global setting; user decides per reminder
- **In-app reminder always created** — OS push is additive (ensures deep-link back to note context)
- **Reschedule** — clock icon or overflow menu on reminder items; opens date/time picker pre-filled with current time; cancels old notification and schedules new one
- **Snooze** (stretch goal) — notification action buttons "Done" and "Snooze 1hr" on Android

### 4.17 Trash Screen
- **Header** — "Trash" with total item count
- **Info bar** — "Items are permanently deleted after 30 days"
- **Sections** — Notes, Folders, Projects (with per-section counts)
- **Each item shows:** title/name, "Deleted X days ago", days remaining badge ("23 days left")
- **Actions per item:** Restore (re-links to original folder/projects), Delete Permanently
- **"Empty Trash" button** — with confirmation dialog, permanently removes all trashed items
- **Undo SnackBar** — shown after soft-deleting an item: "Note moved to Trash [Undo]" (5 seconds)
- **Auto-purge** — on app launch, items older than 30 days are permanently deleted

### 4.18 Backup & Restore Screen
- **Last backup info** — "Last backup: [date] ([size])" or "No backups created"
- **Create Backup** — passphrase dialog (with confirm field, strength indicator, warning about passphrase loss) → progress indicator → share sheet to save `.vnbak` file
- **Restore from Backup** — warning dialog (offer "Create Backup First" / "Continue Without Backup" / "Cancel") → file picker for `.vnbak` → passphrase entry → validation and preview (date, counts, size) → "Restore" button → progress → app restart
- **Backup contents:** notes, folders, projects, settings (JSON), audio files, images, manifest with version info
- **Encryption:** AES-256 with PBKDF2 key derivation from user passphrase
- **Format:** `.vnbak` (renamed ZIP with `manifest.json`, `data/*.json`, `audio/*`, `images/*`)

### 4.19 Template Picker Sheet
- **Bottom sheet** shown when user taps "New Text Note" from SpeedDialFab
- **Options:** Blank Note (default, current behavior) + 6 built-in templates:
  - Meeting Notes, Daily Journal, Idea Capture, Grocery List, Project Planning, Quick Checklist
- **Each template shows:** icon + name + brief description
- **On selection:** creates new note with template content pre-filled in Quill editor; auto-generates title from template name + date

### 4.20 App Lock Screen
- **Full-screen overlay** (pushed via Navigator, not a route — prevents back-button bypass)
- **App logo** centered, matching splash screen style; "VoiceNotes AI" title
- **Biometric auto-prompt** (if enabled) — fingerprint / Face ID / Android face unlock via `local_auth`
  - Success → unlock → resume to last screen
  - 3 failures → auto-fallback to PIN
- **"Use PIN" button** (always visible) → custom PIN keypad (4-6 digits, obscured dots)
  - Success → unlock
  - Wrong PIN → shake animation, "Incorrect PIN"
  - Progressive lockout: 30s → 1min → 5min after repeated failures (resets on app restart)
- **No cancel button** — user must authenticate or close the app
- **Background matches current theme** (light/dark/AMOLED); no note content visible behind lock
- **Auto-lock behavior:**
  - App backgrounded → start timer based on timeout setting (Immediately / 1 min / 5 min / 15 min)
  - App returns within timeout → no lock
  - App killed and relaunched → always lock
  - Incoming call during recording → do NOT lock, timer pauses
  - Notification deep-link → lock screen first → authenticate → navigate
  - Widget record tap (Full/Record-Only) → skip lock (recording is write-only)
  - Widget record tap (Minimal) → lock screen → authenticate → record
  - Widget content tap → lock screen → authenticate → navigate
- **Task switcher protection:** Android `FLAG_SECURE` hides content; iOS background blur overlay
- **Notification privacy:** When App Lock enabled, reminder notifications use `VISIBILITY_SECRET` — shows "VoiceNotes AI reminder" without note content

### 4.21 PIN Setup Screen
- **Create PIN flow:** "Create a 4-6 digit PIN" → PIN keypad → "Confirm PIN" → warning: "If you forget your PIN, you'll need to reinstall. Make sure you have a backup first."
- **Biometric prompt** (if hardware available): "Enable fingerprint/Face ID unlock?" → [Enable] / [Skip]
- **Auto-lock timeout picker:** Immediately (default), 1 min, 5 min, 15 min
- **Widget Privacy prompt** (only shown if widget is active): Full / Record-Only (default) / Minimal
- **Change PIN flow:** requires current PIN/biometric → new PIN → confirm
- **Disable App Lock:** requires current PIN/biometric confirmation → widget reverts to full display

---

## 5. Key Behaviors (Phase 1)

| Behavior | Details |
|---|---|
| Auto language detection | Detects spoken language without user selection (both live STT and Whisper modes). |
| Manual organization | Users create folders and projects manually. Voice commands can auto-assign. |
| Voice command linking | In Whisper mode, speak "Folder/Project \<name\> Start \<content\>" to auto-organize recordings into folders/projects. |
| On-device transcription | All transcription happens locally — `speech_to_text` for live mode, Whisper model for record & transcribe mode. |
| Offline recording | Recording and transcription work without internet (both modes are on-device). |
| Local-only storage | All data in encrypted Hive on-device. No cloud sync. |
| No login required | App fully functional without account creation or sign-in. |
| Default folder | New recordings automatically assigned to default folder (configurable in Settings). |
| Project documents | Compose rich documents from voice notes with free text and section headers. |
| Interactive tasks | Todos, actions, and reminders have tappable checkboxes across all surfaces (Note Detail, Project Documents, Tasks View). |
| Aggregated tasks view | All open todos, actions, and reminders from every note in one filterable list on the Home page Tasks tab. |
| Manual task creation | Users can manually add todos and actions to notes directly (before AI auto-extraction in Phase 2). |
| Hybrid reminders | In-app reminders with local notifications + optional one-tap "Also add to OS" calendar event. |
| Reminder reschedule | Reschedule reminder time from Note Detail with notification update. |
| Sharing | Share individual notes or entire project documents via Share Preview sheet with toggles (title, timestamp, plain text). Email subject auto-populated. Rich text converted to Markdown when not in plain text mode. |
| Export | Export notes and project documents as PDF (formatted, with rich text, tasks, and branding footer) or Markdown (.md) files. Temp files cleaned up on next app launch. |
| Multi-select | Long-press notes on home page to enter selection mode with bulk folder/project assignment and deletion. |
| Rich text formatting | Free-text blocks in project documents support bold, italic, bullets, H1/H2 headings, and links via `flutter_quill`. |
| Photo attachments | Add photos from gallery or camera to notes and project documents. Stored locally with crop/resize. |
| Pinned notes | Users can pin up to 10 notes to the top of the Home feed. Pinned section is collapsible with pin icon on cards. |
| Trash / soft delete | Deleted items go to Trash with 30-day retention. Restore re-links to original folder/projects. Auto-purge on app launch. |
| Auto-title generation | Local heuristic: strip filler phrases → extract first meaningful sentence → fallback to task-based titles → truncate at 60 chars. No AI required. |
| AMOLED dark theme | Pure black backgrounds (#000000) for OLED battery savings. Fourth theme option alongside Light, Dark, System. |
| Note templates | 6 built-in templates (Meeting Notes, Daily Journal, etc.) shown when creating a new text note. |
| Local backup & restore | Export all data as encrypted `.vnbak` archive. Restore from archive with passphrase verification. |
| Home screen widget | One-tap voice recording from Android/iOS home screen. Dashboard variant shows note count and open tasks. Adapts display based on App Lock + Widget Privacy setting. |
| App lock | PIN (4-6 digit) + biometric (fingerprint/Face ID) authentication. Auto-lock on background timeout. Task switcher protection (FLAG_SECURE). Notification content hidden when locked. |

**Phase 2 behaviors (not yet implemented):** AI smart categorization, contextual grouping, follow-up intelligence, auto-folder assignment.

---

## 6. Technical Architecture

### 6.1 Framework & Language
- **Flutter** (Dart) for cross-platform UI
- Material Design 3 with custom theme (Plus Jakarta Sans, Inter fonts)

### 6.2 State Management
- **Riverpod 3.x** — Notifier/NotifierProvider pattern (migration from Provider completed in Step 2)
- 7 providers: notes, folders, settings, project_documents, tasks + 2 repository providers
- All providers backed by Hive repositories

### 6.3 Navigation
- **go_router** for declarative routing with extras for data passing
- Active routes (27): splash, onboarding, home, recording, note_detail, folders, folder_detail, preferences, audio_settings, storage, support, danger_zone, search, project_documents, project_document_detail, note_picker, version_history, privacy_policy, terms_conditions, about, feedback, support_us, **trash**, **backup_restore**, **security**, **pin_setup**
- Inactive route (Phase 2): login
- Audio settings route accepts `highlightWhisper` extra for auto-scroll + flash highlight

### 6.4 Audio Recording
- **record** package (>=5.1.2) for audio capture
- Format: AAC-LC, 128kbps, 44.1kHz, M4A container
- Storage: `Documents/recordings/voicenote_[timestamp].m4a`
- Real-time amplitude monitoring via ValueNotifier

### 6.5 Local Database — Hive (Encrypted)
- **Hive** — lightweight, fast, no-SQL database for Flutter/Dart
- AES-256 encryption at rest with device-derived key
- Hive boxes for: notes, folders, settings, projectDocuments, imageAttachments (planned), offline queue
- No cloud persistence in Phase 1 (privacy-first, local-only)

### 6.6 Speech-to-Text (Phase 1 — On-Device)
- **Live mode:** `speech_to_text` package — on-device, free, no API key needed, real-time transcription while recording
- **Whisper mode:** `whisper_flutter_new` package — on-device Whisper model (ggml-base.bin, ~140 MB one-time download), transcribes WAV files after recording
- Both modes are fully on-device — no cloud API calls, no data leaves the phone
- Auto language detection supported in both modes

### 6.7 AI Structuring (Phase 2 — Not Implemented)
- **Phase 2 only** — OpenAI API or Anthropic API (stateless, no memory, no data retention)
- Entity extraction: actions, todos (with dates), reminders (with times), general notes
- Topic extraction for contextual grouping
- Follow-up question generation (voice-triggered only)

### 6.8 Voice Command Parsing (Phase 1)
- **`VoiceCommandParser`** — keyword extraction from transcription text
- Supported format: "Folder \<name\> Project \<name\> Start \<content\>"
- "Start" is required delimiter — everything after it is the note content
- Keywords are case-insensitive; trailing punctuation stripped (Whisper adds periods)
- **`VoiceCommandProcessor`** — looks up or auto-creates folders/projects by name (case-insensitive match)
- Manual dropdown selections take priority over voice command results
- Controlled by `voiceCommandsEnabled` setting (default: true)

### 6.9 Notifications & Reminders
- **flutter_local_notifications** for in-app reminder alerts
- Manual reminder creation with date/time picker
- Scheduled notifications with deep-link to specific note on tap
- **Hybrid model:** in-app reminder always created; optional "Also add to OS" pushes a pre-filled calendar event via `add_2_calendar`
- **Reschedule:** update reminder time, cancel old notification, schedule new one
- **Snooze** (stretch): notification action buttons for "Done" / "Snooze 1hr" on Android

### 6.10 Offline Support
- Recording works without internet
- Offline queue stores pending items for processing
- Queue indicator visible to user
- Auto-process when connectivity restored

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
├── topics: List<String>
├── actions: List<ActionItem>
├── todos: List<TodoItem>
├── reminders: List<ReminderItem>
├── generalNotes: List<String>
├── followUpQuestions: List<String>?
├── isProcessed: bool (false if in offline queue)
├── hasFollowUpTrigger: bool (user said "any suggestions?" etc.)
├── transcriptVersions: List<TranscriptVersion> (full version history)
├── projectDocumentIds: List<String> (reverse lookup for linked projects)
├── imageAttachmentIds: List<String> (photos attached to this note — planned Step 4.7)
├── isPinned: bool (false — pin to top of Home feed)
├── pinnedAt: DateTime? (when pinned, for sort order within pinned section)
├── isUserEditedTitle: bool (false — tracks if user manually edited title; prevents auto-title overwrite)
├── isDeleted: bool (false — soft delete flag for Trash)
├── deletedAt: DateTime? (when moved to Trash; auto-purge after 30 days)
├── previousFolderId: String? (original folder before deletion, for restore)
└── previousProjectIds: List<String>? (original project links before deletion, for restore)

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
├── isAutoGenerated: bool
├── topics: List<String>
├── noteIds: List<String>
├── createdAt: DateTime
├── updatedAt: DateTime
├── isDeleted: bool (false — soft delete flag for Trash)
└── deletedAt: DateTime? (when moved to Trash)

UserSettings
├── defaultLanguage: String? (null = auto-detect)
├── audioQuality: String (standard / high)
├── notificationsEnabled: bool
├── quietHoursStartMinutes: int? (stored as minutes from midnight)
├── quietHoursEndMinutes: int? (stored as minutes from midnight)
├── themeMode: String (system / light / dark / amoled)
├── onboardingCompleted: bool
├── transcriptionMode: String (live / whisper)
├── speakerName: String (default: "Speaker 1")
├── notePrefix: String (default: "VOICE" → VOICE001, VOICE002...)
├── textNotePrefix: String (default: "TXT" → TXT001, TXT002...)
├── defaultFolderId: String? (ID of default folder for new recordings)
├── voiceCommandsEnabled: bool (parse voice commands in Whisper mode)
├── actionItemsEnabled: bool (show action items section in note detail, default: true)
├── todosEnabled: bool (show todos section in note detail, default: true)
├── lastBackupDate: DateTime? (timestamp of last successful backup creation)
├── appLockEnabled: bool (false — enable PIN/biometric lock)
├── appLockPinHash: String? (salted SHA-256 hash of PIN; salt stored in flutter_secure_storage)
├── biometricEnabled: bool (false — enable fingerprint/Face ID unlock)
├── autoLockTimeoutSeconds: int (0 = immediately, 60, 300, 900)
└── widgetPrivacyLevel: String ('record_only' — 'full', 'record_only', 'minimal'; visible only when App Lock ON + widget active)

ProjectDocument
├── id: String (UUID)
├── title: String
├── description: String? (optional subtitle)
├── blocks: List<ProjectBlock> (ordered list — order = display order)
├── createdAt: DateTime
├── updatedAt: DateTime
├── isDeleted: bool (false — soft delete flag for Trash)
└── deletedAt: DateTime? (when moved to Trash)

ProjectBlock
├── id: String (UUID)
├── type: BlockType (note_reference | free_text | section_header | image_block)
├── sortOrder: int (position in the document)
├── noteId: String? (required when type = note_reference)
├── content: String? (required when type = free_text or section_header)
├── contentFormat: String? ("plain" or "quill_delta" — for rich text in free_text blocks)
├── imageAttachmentId: String? (required when type = image_block)
├── createdAt: DateTime
└── updatedAt: DateTime

TranscriptVersion
├── id: String (UUID)
├── text: String (plain text at this version — always populated for search/display fallback)
├── versionNumber: int (1, 2, 3...)
├── editSource: String (where the edit was made)
├── createdAt: DateTime
├── isOriginal: bool (true only for the first version from STT)
└── richContentJson: String? (Quill Delta JSON for rich text versions; null = plain text only)

ImageAttachment (implemented)
├── id: String (UUID)
├── filePath: String (local path: Documents/images/[uuid].jpg)
├── fileName: String (original or generated filename)
├── caption: String? (optional user-entered caption)
├── width: int (pixels, after crop/resize)
├── height: int (pixels, after crop/resize)
├── fileSizeBytes: int
├── createdAt: DateTime
└── sourceType: String ("gallery" | "camera")

TaskItem (UI view model — NOT stored in Hive)
├── type: TaskType (todo | action | reminder)
├── id: String (the TodoItem, ActionItem, or ReminderItem id)
├── text: String
├── isCompleted: bool
├── dueDate: DateTime? (for todos)
├── reminderTime: DateTime? (for reminders)
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
| Camera | Android, iOS | Photo capture for image blocks/attachments (implemented) |
| Photo Library | Android, iOS | Gallery access for image picker (implemented) |
| Internet | Android, iOS | Transcription and AI processing (transactional only) |

---

## 9. Project Documents — Relationship to Folders

| Aspect | Folders | Project Documents |
|---|---|---|
| **Purpose** | Organize / group notes | Compose / build a document from notes |
| **Note relationship** | A note belongs to one folder | A note can appear in many project documents |
| **Content** | Container of note references | Rich canvas: note transcripts + free text + headers + images |
| **Editing** | No editing within folder view | Full inline editing with version history |
| **Structure** | Flat list of notes | Ordered, user-arranged blocks |

Both coexist — folders organize, projects compose.

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
| Sentiment & urgency tagging | Phase 2 |
| Voice search | Phase 2 |
| ~~Quick capture widget~~ | ~~Phase 2~~ → **Phase 1** (Step 10.5 — Home Screen Widget) |
| ~~Export (Markdown, plain text)~~ | ~~Phase 2~~ → **Phase 1** (Step 4.7 — Addendum A1) |
| ~~Export as PDF (formatted, professional)~~ | ~~Phase 2~~ → **Phase 1** (Issue #11, v1.15.0 — using `pdf` package, pure Dart) |
| Share audio file alongside transcript | Phase 2 |
| Share with embedded images | Phase 2 |
| AI-generated Project Document summary | Phase 2 |
| AI-suggested note additions for projects | Phase 2 |
| ~~Voice command to add note to project~~ | ~~Phase 2~~ → **Implemented in Phase 1** (v1.3.0) |
| Recurring reminders | Phase 2 |
| Push to Todoist / Apple Reminders API / Google Tasks API | Phase 2 |
| Notification action buttons (Done / Snooze) | Phase 2 (if too complex for Phase 1 stretch) |
| Task priority levels (Low / Medium / High) | Phase 2 |
| AI auto-extraction of todos/actions from transcription | Phase 2 |
| Smart due date extraction ("by Friday") | Phase 2 |
| Task assignment (multi-user) | Phase 3 |
| ~~Project Document export (Markdown/plain text)~~ | ~~Phase 2~~ → **Phase 1** (Step 4.7) |
| Numbered lists, checklists in rich text | Phase 2 |
| H3-H6 headings, inline images in text | Phase 2 |
| Markdown source editing mode | Phase 2 |
| Music note capture | Phase 3 |
| Smart automations | Phase 3 |
| Ambient listening mode | Phase 3 |
| Collaborative features | Phase 3 |
| ~~Template-based capture~~ | ~~Phase 3~~ → **Phase 1** (Step 9 — Note Templates, built-in only; custom templates deferred to Phase 2) |
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
| OS calendar bridge | add_2_calendar (implemented) |
| Sharing | share_plus (implemented) |
| Rich text editor | flutter_quill (implemented) |
| Image picker | image_picker (implemented) |
| Image cropping | image_cropper (implemented) |
| Image viewer | photo_view (implemented) |
| Image compression | flutter_image_compress (implemented) |
| PDF generation | pdf (pure Dart, on-device, implemented) |
| Typography | Google Fonts (Plus Jakarta Sans, Inter) |
| App icon | assets/icons/logo.png (launcher + in-app branding) |

---

## 12. Dependencies (Active in pubspec.yaml)

| Package | Purpose | Status |
|---|---|---|
| flutter | UI framework | Active |
| flutter_riverpod | Riverpod 3.x state management | Active |
| go_router | Declarative routing | Active |
| hive + hive_flutter | Local encrypted database | Active |
| record | Audio recording (WAV for Whisper, AAC for live) | Active |
| just_audio | Audio playback on note detail screen | Active |
| speech_to_text | On-device live transcription | Active |
| whisper_flutter_new | On-device Whisper model transcription | Active |
| flutter_local_notifications | Reminder notifications | Active |
| google_fonts | Custom typography (Plus Jakarta Sans, Inter) | Active |
| path_provider | File system access | Active |
| uuid | Unique ID generation | Active |
| flutter_secure_storage | Secure encryption key storage (Android Keystore / iOS Keychain) | Active |
| cupertino_icons | iOS-style icons | Active |
| add_2_calendar | OS calendar event creation for hybrid reminders | Active |
| share_plus | Native OS share sheet for notes and project documents | Active |
| flutter_quill | Rich text editing and viewing for free-text blocks | Active |
| wakelock_plus | Keep screen awake during recording | Active |
| image_picker | Gallery and camera photo selection | Active |
| image_cropper | Crop and resize UI before saving | Active |
| photo_view | Full-screen image viewer with pinch-to-zoom | Active |
| flutter_image_compress | Image compression and resizing | Active |
| pdf | Pure Dart PDF generation for export (notes + projects) | Active |
| hive_generator + build_runner | Hive model code generation (dev) | Active |
| archive | ZIP archive creation/extraction for backup (planned Step 10.6) | Planned |
| encrypt | AES-256 encryption for backup files (planned Step 10.6) | Planned |
| home_widget | Cross-platform home screen widget (planned Step 10.6) | Planned |
| local_auth | Biometric authentication — fingerprint, Face ID (planned Step 10.5) | Planned |
