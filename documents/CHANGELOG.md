# VoiceNotes AI - Changelog

All notable changes to this project will be documented in this file.

---

## [Unreleased] - 2026-03-02 - Step 10.7: Local Backup & Restore

### Added
- **`BackupService`** — creates AES-256-CBC encrypted `.vnbak` backup files; file format: 4-byte magic + 4-byte version + 16-byte salt + 16-byte IV + encrypted ZIP; key derived via 10,000 rounds of SHA-256 from user passphrase + random salt
- **Backup archive contents** — `manifest.json` (metadata), `data.json` (all Hive records serialized to JSON), `images/` (image attachments), `audio/` (recordings, optional)
- **`BackupRestorePage`** — full backup/restore UI: passphrase input, include-audio toggle, progress indicator, share sheet on backup; file picker, passphrase entry, backup preview (manifest card showing counts + creation date), confirmation dialog, and restore progress on restore
- **`/backup_restore` route** — new `GoRoute` in `AppRouter`; accessible from Home screen overflow menu (new "Backup & Restore" entry)
- **`toMap()` / `fromMap()`** serialization methods on all Hive models: `Note`, `ActionItem`, `TodoItem`, `ReminderItem`, `Folder`, `ProjectDocument`, `ProjectBlock`, `TranscriptVersion`, `ImageAttachment`, `UserSettings`
- **`lastBackupDate`** (HiveField 24, `DateTime?`) on `UserSettings` — persists the timestamp of the last successful backup
- **`setLastBackupDate()`** on `SettingsRepository` and `SettingsNotifier`; `lastBackupDate` field wired through `SettingsState` / `copyWith` / `build()`

### Changed
- `pubspec.yaml` — added `archive: ^4.0.0`, `encrypt: ^5.0.3`, `file_picker: ^8.0.0`
- `home_page.dart` — added "Backup & Restore" entry to overflow popup menu (between Storage and Help & Support)

### New Dependencies
- `archive: ^4.0.0` — pure-Dart ZIP encode/decode (in-memory)
- `encrypt: ^5.0.3` — AES-256-CBC encryption via PointyCastle
- `file_picker: ^8.0.0` — cross-platform file selection for restore

---

## [Unreleased] - 2026-03-02 - Step 10.6: Home Screen Widget

### Added
- **Quick Record widget (2×1)** — tap anywhere to open the Recording screen directly; no content displayed, always safe regardless of App Lock state
- **Dashboard widget (4×2)** — shows note count, open task count, and latest note preview; content adapts to Widget Privacy setting when App Lock is enabled
- **Widget Privacy setting** — new option in Settings → Security (visible only when App Lock is on); three levels: Full (counts + preview), Record-Only (counts only, default), Minimal (icon + record only)
- `HomeWidgetService` — Flutter service that pushes note/task data to the widget; respects App Lock + Widget Privacy to determine what data to expose
- `VoiceNotesWidgetSmall.kt` — Android AppWidgetProvider for the Quick Record widget
- `VoiceNotesWidgetDashboard.kt` — Android AppWidgetProvider for the Dashboard widget; reads `HomeWidgetPreferences` SharedPreferences written by `home_widget`
- Widget layout XML: `widget_small.xml`, `widget_dashboard.xml`
- Widget info XML: `widget_small_info.xml`, `widget_dashboard_info.xml`
- Widget drawable resources: `widget_background.xml`, `widget_btn_background.xml`
- Widget click deep-link via `HomeWidgetLaunchIntent` — widget record taps emit `voicenotesai://record` URI to `HomeWidget.widgetClicked` stream
- `_onWidgetClicked` / `_checkWidgetLaunch` in `main.dart` — routes widget tap URI to `/recording` screen
- Widget data refresh on app foreground (`didChangeAppLifecycleState` resumed)

### Changed
- `UserSettings` — added `widgetPrivacyLevel` (HiveField 23, default `'record_only'`)
- `SettingsRepository` — added `setWidgetPrivacyLevel()`
- `SettingsState` / `SettingsNotifier` — expose `widgetPrivacyLevel` field and setter
- `AndroidManifest.xml` — added `VoiceNotesWidgetSmall` and `VoiceNotesWidgetDashboard` widget receivers; added `HOME_WIDGET_LAUNCH_ACTION` intent-filter to MainActivity
- `SecurityPage` — added Widget Privacy picker row (only shown when App Lock enabled); updated info text
- `main.dart` — `HomeWidgetService.initialize()` on startup; `HomeWidget.widgetClicked` stream listener; widget refresh on resume

### New Dependencies
- `home_widget: ^0.9.0` — cross-platform home screen widget support

### Platform Notes
- **Android:** Fully functional. Add the widget via long-press on home screen → Widgets → VoiceNotes AI.
- **iOS:** Requires additional Xcode setup (App Group, WidgetKit extension). `HomeWidgetService.initialize()` sets the app group ID; native extension not yet created.

---

## [Unreleased] - 2026-03-02 - Step 10.5: App Lock — PIN / Biometric Authentication

### Added
- **`AppLockService`** — singleton managing lock state, PIN hashing (salted SHA-256 via `crypto`, salt stored in `flutter_secure_storage`), timeout tracking, and progressive lockout (30 s / 1 min / 5 min after repeated failed attempts)
- **`LockScreenPage`** — full-screen overlay with app logo, biometric auto-prompt on open, custom PIN keypad with obscured dot indicators, shake animation on wrong PIN, `PopScope` prevents back-button bypass
- **`SecurityPage`** — App Lock toggle (triggers inline PIN-setup flow), Change PIN flow (current → new → confirm), Biometric Unlock toggle (tests biometric availability before enabling), Auto-Lock Timeout picker (Immediately / 1 min / 5 min / 15 min), informational warning about PIN recovery
- **`/security` route** — new `GoRoute` in `AppRouter`; accessible from Home screen overflow menu (new "Security" entry)
- `appLockEnabled`, `appLockPinHash`, `biometricEnabled`, `autoLockTimeoutSeconds` (HiveFields 19–22) on `UserSettings`
- `setAppLockEnabled()`, `setPinHash()`, `setBiometricEnabled()`, `setAutoLockTimeout()` on `SettingsRepository` and `SettingsNotifier`

### Changed
- `main.dart` — converted to `ConsumerStatefulWidget` with `WidgetsBindingObserver`; auto-locks on app pause/resume via `AppLockService`; shows `LockScreenPage` on cold start when App Lock is enabled
- `home_page.dart` — added "Security" `PopupMenuItem` to overflow menu
- `AndroidManifest.xml` — added `USE_BIOMETRIC` permission
- `pubspec.yaml` — added `local_auth: ^2.3.0`, `crypto: ^3.0.6`

### New Dependencies
- `local_auth: ^2.3.0` — biometric (fingerprint / face) authentication
- `crypto: ^3.0.6` — SHA-256 PIN hashing

---

## [Unreleased] - 2026-03-02 - Step 10: Trash / Soft Delete (30-day Retention)

### Added
- **`TrashPage`** — displays trashed Notes, Folders, and Projects in three sections; per-item Restore and Permanent Delete actions; "Empty Trash" button to wipe all trashed items; "X days remaining" badge on each item
- **`/trash` route** — new `GoRoute` in `AppRouter`; accessible from Home screen overflow menu (new "Trash" entry)
- **`isDeleted`** / **`deletedAt`** fields on `Note` (HiveFields), `Folder`, and `ProjectDocument` models — enable soft-delete without removing from Hive
- **`previousFolderId`** on `Note` — remembers the original folder so restore correctly reassigns the note
- **Auto-purge on startup** — `main.dart` calls purge at launch; items in trash for > 30 days are permanently deleted (audio + image files removed from disk)
- **Undo SnackBar** — delete actions show a 5-second undo snackbar before the soft-delete is committed

### Changed
- All repository `getAll*()` methods (`NotesRepository`, `FoldersRepository`, `ProjectDocumentsRepository`) — now filter out `isDeleted == true` items so trashed content is invisible in normal views
- Permanent delete — removes the Hive record and cleans up associated audio / image files on disk
- Search — excludes trashed items at repository level
- Tasks provider — automatically excludes tasks belonging to trashed notes
- Bulk delete — uses soft-delete pattern (moves to trash, not immediate permanent delete)
- `home_page.dart` — added "Trash" `PopupMenuItem` to overflow menu

---

## [Unreleased] - 2026-03-02 - Step 8+9: Pinned Notes, AMOLED Theme, Auto-Title, Note Templates

### Added (Step 8 — Pinned Notes, AMOLED Theme, Auto-Title Generation)
- **Pinned Notes** — `isPinned` / `pinnedAt` fields on `Note` model; pinned notes appear in a dedicated "Pinned" section at the top of Home and Folder Detail; maximum 10 pinned notes enforced with user-facing warning; pin/unpin available from note card long-press selection bar and Note Detail overflow menu; pin icon overlay on note cards
- **AMOLED Dark Theme** — pure-black (`#000000`) background and near-black card surfaces; fourth option ("AMOLED Dark") in the theme picker alongside System/Light/Dark; `isAmoled` flag exposed in `SettingsState`; `theme.dart` extended with `amoledDark` `ThemeData`
- **Auto-Title Generation (`TitleGeneratorService`)** — strips common filler phrases, extracts the first meaningful sentence, applies task-based fallbacks (action items, todos), truncates to 60 characters; called automatically after Whisper transcription completes; `isUserEditedTitle` flag on `Note` prevents overwriting manually typed titles

### Added (Step 9 — Note Templates)
- **6 built-in templates** — Meeting Notes, Daily Journal, Idea Capture, Grocery List, Project Planning, Quick Checklist; stored as constants in `lib/constants/note_templates.dart`
- **`TemplatePicker` bottom sheet (`template_picker_sheet.dart`)** — shown from SpeedDialFab "Text Note" action; displays template cards with name + preview; selecting a template pre-fills the Quill editor and auto-generates a title from the template name + current date
- **Template content pre-fill** — `NoteDetailPage` accepts `templateContent` and `templateTitle` extras from the router so template data flows cleanly from picker to editor

### Changed
- `Note` model — added `isPinned` (HiveField), `pinnedAt` (HiveField), `isUserEditedTitle` (HiveField)
- `NotesProvider` — added `pinNote()` / `unpinNote()` methods; notes sorted: pinned first (by `pinnedAt` desc), then remaining (by `createdAt` desc)
- `SettingsState` / `SettingsNotifier` — added `isAmoled` field and `setThemeMode()` AMOLED support
- `preferences_page.dart` — theme picker shows four options including AMOLED Dark
- `home_page.dart` — Pinned section at top of Notes tab; SpeedDialFab "Text Note" now opens template picker before navigating to Note Detail
- `note_detail_page.dart` — pin/unpin action in overflow menu; respects `isUserEditedTitle` to protect manual title edits
- `note_card.dart` — pin icon overlay when `note.isPinned == true`

---

## [Unreleased] - 2026-03-02 - Documentation: Release Status & Value Gaps Integration

### Documentation
- **Project status updated to Release** — removed all "MVP" and "pre-release" language across CLAUDE.md, PROJECT_STATUS.md, IMPLEMENTATION_PLAN.md, and PROJECT_SPECIFICATION.md. App is now a full-fledged release, not an MVP.
- **Phase 1 Value Proposition Gaps integrated** — 8 new features (Steps 8–10.7) added to IMPLEMENTATION_PLAN.md (v3.0) and PROJECT_SPECIFICATION.md (v2.8): Pinned Notes, AMOLED Dark Theme, Auto-Title Generation, Note Templates, Trash/Soft Delete, App Lock (PIN/Biometric), Home Screen Widget, Local Backup & Restore
- **Phase 2 steps renumbered** — Steps 8/9/10 → Steps 11/12/13 to make room for value gap features
- **New feature spec added:** `FEATURE_PHASE1_VALUE_GAPS.md` — detailed specifications for all 8 pre-launch features with user flows, data model changes, dependency maps, and effort estimates
- **Image cropper wired** — `image_cropper` (already in pubspec) now active in project document image blocks and note photo attachments
- **Splash screen Terms link** — hyperlink limited to "Terms & Conditions" text only, split to two lines

---

## [Unreleased] - 2026-03-02 - Rich Text Version History & Picker Enhancements

### Added
- **Rich text in version history** — `TranscriptVersion` model now stores `richContentJson` (Quill Delta JSON) alongside plain text; version history page renders formatting (bold, italic, etc.) via read-only QuillEditor
- **"New Folder" option in folder pickers** — all folder picker bottom sheets (single-select and bulk) now show a "New Folder" tile at the top; creates folder inline and auto-selects it
- **"New Project" option in project pickers** — all project picker bottom sheets (single-select and bulk) now show a "New Project" tile at the top; creates project inline and auto-selects it

### Changed
- `TranscriptVersion` model — added `richContentJson` HiveField(6) for storing Quill Delta JSON
- `NotesRepository.addTranscriptVersion()` — accepts optional `richContentJson` parameter
- `NotesRepository.updateNoteRichContent()` — stores Delta JSON in version's `richContentJson` and plain text in `text`
- `NotesRepository.restoreTranscriptVersion()` — restores rich content (Delta JSON + contentFormat) when available; reverts to plain text when restoring a plain version
- `NotesRepository.ensureTranscriptVersion()` — captures rich content for existing notes during migration
- `note_detail_page.dart` — `_saveTranscription()` passes Delta JSON to `addTranscriptVersion()` via `richContentJson` parameter
- `version_history_page.dart` — renders rich text preview via `_buildRichPreview()` using read-only QuillEditor; falls back to plain text for older versions
- `home_page.dart` — added `_showNewNameDialog()` helper; all 4 picker sheets use `var` for folder/project lists to allow refresh after creation

---

## [Unreleased] - 2026-03-01 - Note Detail Refactor & Share Preview Fix

### Changed
- **Note Detail — Tab system for sections** — Action Items, Todos, Reminders, and Photos now display as tabs instead of stacked vertical sections, reducing page length and improving navigation
- **Note Detail — Photo attachments grid** — Photos tab shows a 2-column grid layout (~170px thumbnails) instead of the previous 100px horizontal scroll row; tap for full-screen, long-press to delete
- **Note Detail — Audio player simplified** — Replaced separate waveform + slider + times layout with a single compact row: play button + current time + tappable waveform (seek on tap) + total time
- **Note Detail — Tab container card** — Tab content wrapped in bordered Container card with divider between tab selector and content, giving a cohesive grouped appearance
- **Note Detail — Custom tab selector** — Replaced SegmentedButton with custom Row of icon+label columns for cleaner dual-line tab presentation with badge counts
- **Note Detail — Metadata two-row layout** — Metadata changed from single overflowing Row to two explicit Rows: timestamp on first row, duration/language/model on second row
- **Onboarding logo enhanced** — Logo size 120→140px, border radius 36→40, shadow matched to splash screen (0.3 alpha, 50px blur, 8px spread), added scale-in animation (0.85→1.0, 800ms, easeOutBack)

### Fixed
- **Share preview rich text not showing** — `_previewText` getter in SharePreviewSheet was hardcoded to `plainTextOnly: true`, ignoring the user's toggle; now correctly uses `_options` to respect the Plain Text Only switch

---

## [Unreleased] - 2026-03-01 - UI Polish & Voice Command Fixes

### Fixed
- **Voice command "Todo" not creating tasks** — Whisper transcribes "Todo" as "To do" (two words) or "To-do" (hyphenated); added `_normalizeTaskKeywords()` to merge these variants before parsing
- **Home page Notes stat tile mismatched styling** — Notes tile now uses same surface background, border, and icon-color pattern as Folders and Projects tiles
- **Storage page Total at top was confusing** — moved Total to the bottom with a divider and bold styling; individual items listed first, summary total last

### Changed
- **Voice commands popup expanded** — added Task/Action/Reminder command documentation with examples (e.g. "Todo Call the dentist tomorrow") and a Limitations section explaining one-command-per-recording, 30-char description limit, and reminder default timing
- **Voice commands popup scroll visibility** — wrapped content in `Scrollbar(thumbVisibility: true)` so users can see the dialog is scrollable; compacted "Got it" button spacing
- **Whisper download Cancel button restyled** — changed from plain `TextButton` to `OutlinedButton` with error-colored border and label "Cancel Download" for better discoverability
- **Keep Screen Awake default changed to disabled** — `keepScreenAwake` now defaults to `false` in both HiveField annotation and constructor (was `true`)

---

## [Unreleased] - 2026-03-01 - Codebase Audit Fixes

### Security
- **Encryption key moved to flutter_secure_storage** — AES-256 key now stored in Android Keystore / iOS Keychain instead of plain Hive box. Legacy keys auto-migrated on first launch.

### Fixed
- **Raw language codes replaced with friendly names** — note cards, folder detail, and search results now show "English", "Hindi" etc. instead of "en", "hi"
- **`auto_awesome_rounded` icon replaced** with `tune_rounded` in audio settings (AI icon removal)
- **"Whisper AI" renamed to "Whisper"** across 5 files (audio_settings, danger_zone, recording, privacy_policy, terms_conditions)
- **`isProcessed` default changed to `true`** in note.dart (was `false`, violating Phase 1 spec)
- **Navigator.push replaced with GoRouter** in splash_page.dart for Terms & Conditions link
- **ProjectDocumentsNotifier.search() fixed** to filter provider state instead of reading from repository directly
- **Dead `hasUpdate` parameter removed** from _FolderCard in folders_page.dart

### Removed
- **Deleted `settings_page.dart`** — 1,505 lines of dead code (no route existed, replaced by sub-pages)
- **Deleted `connectivity_provider.dart`** and **`recording_provider.dart`** — unused providers never consumed
- **Deleted unused assets** — `dreamflow_icon.jpg` and `google_logo.svg`

### Changed
- **Java version bumped to 17** in Gradle build files (required by flutter_secure_storage v10)
- **`android/key.properties` added to .gitignore** — prevents accidental credential commits
- **Linter rules enabled** in analysis_options.yaml — `avoid_print`, `prefer_const_constructors`, `prefer_const_declarations`, `prefer_final_locals`, `unnecessary_this`
- **Deduplicated storage calculation** — `getStorageUsage()` now delegates to `getStorageBreakdown()`

### Documentation
- **All doc versions aligned to 1.0.0** (pre-release) — CHANGELOG, PROJECT_STATUS, IMPLEMENTATION_PLAN
- **CLAUDE.md fully updated** — project structure reflects actual 75+ files, routes table shows all 23 routes, tech stack includes all dependencies, AI exclusion rule #6 updated to reflect on-device Whisper design decision, removed references to deleted files
- **PROJECT_SPECIFICATION.md fixed** — replaced stale `connectivity_plus` and `delta_to_markdown` entries, corrected provider count
- **FEATURE_PROJECT_DOCUMENTS.md updated** — Addendum A features marked as COMPLETE
- **PROJECT_STATUS.md updated** — version 1.0.0, correct route count (23), correct provider count (7)

---

## [Unreleased] - 2026-03-01 - Voice Commands for Tasks + Share Preview Fixes (Issue #12)

### Added
- **Voice commands for task creation** — say a keyword at the start of a Whisper recording to auto-create a task item:
  - `"ToDo <description>"` — creates a TodoItem on the note
  - `"Action <description>"` — creates an ActionItem on the note
  - `"Reminder <description>"` — creates a ReminderItem with next-day default time
- Task keywords work alongside existing folder/project voice commands (e.g., "Folder Work ToDo finish report")
- Task description auto-truncated to first 30 characters
- One task type per voice command (simple and predictable)
- **Include Note Titles toggle** — project document share preview now has a toggle to show/hide individual note titles

### Fixed
- **Share preview now uses full screen** — expanded from small bottom sheet (maxHeight 200px) to 85% screen height for better readability
- **Rich text no longer shows as raw codes** — preview always renders plain text instead of showing markdown syntax like `**bold**`

### Changed
- `lib/utils/voice_command_parser.dart` — added `todo`, `action`, `reminder` keyword detection; added `taskType` and `taskDescription` fields to `VoiceCommandResult`
- `lib/services/voice_command_processor.dart` — added `taskType` and `taskDescription` pass-through in `VoiceCommandProcessResult`
- `lib/providers/notes_provider.dart` — auto-creates task items in `transcribeInBackground()` based on detected voice command task type
- `lib/services/sharing_service.dart` — added `includeNoteTitles` to `ShareOptions`, respected in text and PDF export
- `lib/widgets/share_preview_sheet.dart` — full-height preview, plain text display, "Include Note Titles" toggle for projects
- `lib/pages/note_detail_page.dart` — increased share sheet size (initialChildSize 0.85)
- `lib/pages/project_document_detail_page.dart` — increased share sheet size (initialChildSize 0.85)

---

## [Unreleased] - 2026-03-01 - Word Count, Find & Replace, Profanity Filter

### Added
- **Word & Character Count** — compact stats row below each note's transcription section showing `Words: N · Characters: N`. Updates live during editing via QuillController listener.
- **Find & Replace** — search icon in note detail AppBar opens a compact toolbar with:
  - Find text field with match counter (`2/5`) and up/down navigation arrows
  - Expandable Replace row with "Replace" (single) and "All" (replace all) buttons
  - Case-insensitive search, auto-enters edit mode when opened
  - Works with both plain text and Quill Delta rich text notes
- **Block Offensive Words** — new toggle in Settings > AUDIO group. When enabled, filters profanity from:
  - Live STT transcription output (speech_to_text)
  - Whisper transcription output
  - Uses whole-word regex matching to avoid false positives
  - Replaces matched words with asterisks of matching length
  - Privacy-first: hardcoded word list, no network fetch, no external package

### New Files
- `lib/widgets/find_replace_bar.dart` — reusable Find & Replace toolbar widget
- `lib/utils/profanity_filter.dart` — offline profanity filter with common English words

### Changed
- `lib/models/user_settings.dart` — added `blockOffensiveWords` field (HiveField 18)
- `lib/services/transcription_service.dart` — added `textFilter` callback for filtering transcription output
- `lib/pages/note_detail_page.dart` — added word count stats, find & replace toolbar, search icon in AppBar
- `lib/pages/recording_page.dart` — wires profanity filter to transcription service when enabled
- `lib/providers/notes_provider.dart` — applies profanity filter to Whisper transcription output
- `lib/providers/settings_provider.dart` — added `blockOffensiveWords` to SettingsState
- `lib/services/settings_repository.dart` — added `setBlockOffensiveWords()` method
- `lib/pages/settings_page.dart` — added "Block Offensive Words" toggle in AUDIO group

---

## [Unreleased] - 2026-03-01 - Share Preview, PDF Export, Rich Text Sharing (Issue #11)

### Added
- **Share Preview bottom sheet** — new `SharePreviewSheet` widget shown before sharing for both notes and project documents. Includes:
  - **Include Title** toggle (default: on)
  - **Include Timestamp** toggle (default: off)
  - **Plain Text Only** toggle (default: off) — strips rich text formatting when enabled
  - Live scrollable preview of the assembled share text
  - "Share as Text", "Export as PDF", and "Export as Markdown" (projects only) action buttons
- **PDF export** — generate formatted PDF documents locally using the `pdf` package (pure Dart, no cloud). Supports:
  - Note title as bold header with divider
  - Rich text content with bold/italic/font size/color preserved
  - Action items, todos, reminders as checkbox lists with strikethrough for completed
  - Project documents with section headers, note reference cards (bordered), image captions
  - Multi-page automatic pagination
  - Footer: "Shared from VoiceNotes AI"
- **Email subject line** — `Share.share()` now passes a subject: `"Title — Notes from VoiceNotes AI"` (notes) or `"Title — Project from VoiceNotes AI"` (projects)
- **Real Quill Delta → Markdown conversion** — `_deltaToMarkdown()` now properly converts bold→`**text**`, italic→`*text*`, headers→`#`/`##`, bullet lists→`- item`
- **Temp file cleanup** — `SharingService.cleanupTempExports()` runs at app startup to remove leftover .pdf/.md/.txt files from temp directory

### Changed
- **Shorter separator lines** — replaced fixed 30-character separators (`─`/`═`) with title-length underscores (`_`) (minimum 10 characters)
- **Project detail popup menu** — removed "Export as Markdown" and "Export as Plain Text" items (now available in share preview sheet). Kept "Rename" and "Delete".
- **APK size** — increased from 64.6MB to 66.4MB (+1.8MB from `pdf` package). No runtime storage impact — PDF files are written to system temp and cleaned up on next launch.

### New Dependencies
- `pdf: ^3.11.1` — pure Dart PDF generation, no native binaries, no cloud

### New Files
- `lib/widgets/share_preview_sheet.dart` — share preview bottom sheet with toggles and export buttons

---

## [Unreleased] - 2026-03-01 - Project Detail Rich Text Fixes (Issue #10)

### Fixed
- **Rich text display styling mismatch** — QuillEditor in note reference cards now uses `customStyles` with `fontSize: 14` and theme `onSurface` color, matching the plain text display exactly. Previously rich text blocks appeared with a different font size and color than plain text blocks.
- **Rich text inline editing not saving** — note reference cards with `quill_delta` format now edit with a full QuillEditor + toolbar (bold, italic, headers, font sizes, colors) instead of a plain TextField. Edits are saved as delta JSON via new `updateNoteRichContent()` repository method, preserving all formatting. Previously, editing a rich text note from the project page would silently discard changes because `addTranscriptVersion()` skipped overwriting `rawTranscription` for quill_delta notes.

### Added
- `NotesRepository.updateNoteRichContent()` — saves rich text (delta JSON) directly to `rawTranscription` and updates `contentFormat`, with version history entry
- `ProjectDocumentsNotifier.editNoteTranscriptRich()` — provider method for rich text saves from project documents
- `_NoteReferenceCard.onSaveRichEdit` callback — routes rich text saves through the new provider method

---

## [Unreleased] - 2026-03-01 - Home Multi-Select, Layout Redesign, Sectioned Search

### Added — GitHub Issue #7: Home Dashboard Tiles
- **Multi-select mode** — long-press a note to enter selection mode; tap to toggle, select all/deselect all in AppBar
- **Single-select actions** — bottom action bar with Open, Edit Title, Folder, Project, Delete
- **Bulk actions** — Add to Folder, Add to Project, Delete for multiple selected notes
- **Folder/Project capsule taps** — tapping folder or project chip on a note card opens a picker with Save/Cancel
- **Improved delete dialog** — warning icon, detailed message, white-on-red "Delete Permanently" button

### Changed — GitHub Issue #8: Home Page Layout
- **Stats cards** — 3 cards now fit in screen width (Row of Expanded instead of horizontal scroll)
- **Compact category cards** — icon + count in same row, label below, smaller padding
- **Tab bar moved below stats** — segmented button now sits under stats cards so stats are always visible
- **Projects card** — now navigates to project documents (was incorrectly going to folders)
- **Speed dial** — actions switch to Notes tab before executing
- **Removed** "Recent Notes" header and "See All" button

### Added — GitHub Issue #9: Sectioned Search
- **Search across all content types** — queries now match action items, todos, and reminders text (not just note title/transcription)
- **Sectioned results** — results grouped into Notes, Action Items, Todos, Reminders sections with color-coded headers, icons, and counts
- **Section headers** — each section shows icon, label, and match count in a styled row

---

## [Unreleased] - 2026-03-01 - Rich Text Persistence Fix + Whisper Noise Filters + Project View Rich Text

### Fixed
- **CRITICAL: Rich text formatting now persists after save** — `addTranscriptVersion()` in `notes_repository.dart` was overwriting `rawTranscription` (delta JSON) with plain text after every save. Fixed by skipping the overwrite for `quill_delta` format notes.
- **Keep Screen Awake toggle** — added `await` to `WakelockPlus.enable()`/`disable()` calls so the toggle actually takes effect immediately.
- **Note card preview** — notes with rich text (quill_delta) now show plain text preview on home page instead of raw JSON.
- **Folder detail page** — same plain text extraction fix for note previews.
- **Search page** — same fix for search result previews.
- **Sharing service** — sharing/exporting notes now strips delta JSON to plain text for note references.

### Added
- **Whisper transcription noise filter** — strips common Whisper artifacts from transcriptions:
  - Bracketed markers: `[inaudible]`, `[BLANK_AUDIO]`, `[MUSIC]`, `[SILENCE]`, `[NOISE]`, `[STATIC]`, etc.
  - Parenthesized markers: `(speaking in foreign language)`, `(soft music)`, `(background noise)`, `(unintelligible)`, etc.
  - Hallucination loops: repeated "Thank you", "Thanks for watching", "Please subscribe" patterns.
- **Rich text display in project view** — note reference cards in project documents now render rich formatting (bold, italic, colors, font sizes, newlines) via read-only QuillEditor instead of plain text.
- **"Rich text edit" menu option** in note reference card 3-dot menu — navigates to note detail page for full toolbar editing, back returns to project.
- **Model picker download status icons** — 4 distinct states: filled check (selected+downloaded), radio button (selected+not downloaded), outline check (not selected+downloaded), download icon (not selected+not downloaded). Also shows "Not downloaded" subtitle.

### Changed
- **Recording page** — removed redundant "Recording in progress" text (whisper indicator already shows status). Now only shows "Starting…" or "Paused" when relevant.

---

## [Unreleased] - 2026-02-28 - Animated Download Experience + Recording Screen Toggle

### Added
- **Animated download experience** — Whisper model download now shows a full-screen branded experience with animated waveform bars, app logo, progress bar with percentage, and rotating feature tips (Privacy First, No Cloud Required, On-Device AI, No Ads/Tracking, Rich Text Notes). Replaces the plain AlertDialog progress bar.
- **Keep Screen Awake toggle on recording screen** — toggle is now directly accessible on the recording page (both whisper and live modes) so users can enable/disable mid-recording without leaving the screen.
- New `lib/widgets/download_progress_sheet.dart` — reusable animated download widget.

### Changed
- **Custom rich text toolbar** — replaced `QuillSimpleToolbar` (invisible icons in dark theme) with custom Flutter `IconButton` toolbar that properly shows Bold, Italic, Bullets, H1, H2 with correct theme colors in both light and dark modes. Applied to note editing, free text blocks, and section headers.
- Consolidated all download dialogs (`_ModelDownloadDialog`, `WhisperDownloadDialog`, `_WhisperDownloadDialog`) into single `DownloadProgressSheet` widget.

### Removed
- `_ModelDownloadDialog` from `audio_settings_page.dart`
- `WhisperDownloadDialog` from `settings_widgets.dart`
- `_WhisperDownloadDialog` from `settings_page.dart`

---

## [Unreleased] - 2026-02-28 - Keep Screen Awake + Rich Text Editing + Support Us Page

### Added
- **Keep Screen Awake** toggle in Audio & Recording settings — prevents screen from locking during long recordings (meetings, lectures). Default: ON. Uses `wakelock_plus` to keep screen on while recording, disables on save/discard.
- **Rich text editing for regular notes** — note transcription edit now uses `flutter_quill` editor with formatting toolbar (Bold, Italic, Bullet Lists, Headers, Links). Rich text stored as Quill Delta JSON in new `contentFormat` field on Note model. Backward compatible — existing plain text notes still display normally.
- **Rich text editing for Section Headers** in Project Documents — section headers now support Bold and Italic formatting via Quill editor.
- **Support Us page** — dedicated page accessible from Help & Support, with promises (free, no ads, no tracking, on-device), "Buy Me a Coffee" button, and share encouragement.
- New `contentFormat` field on Note model (HiveField 20) for rich text format tracking.
- New `keepScreenAwake` field on UserSettings model (HiveField 17).
- New `/support_us` route and `SupportUsPage`.

### Changed
- **About page** "Support Development" section — rephrased from "AI Free & Ad-Free" to clearer "completely free to use with no ads, no subscriptions, and no data tracking" wording.
- **Whisper download cancel** now properly stops the HTTP connection (added `cancelDownload()` to WhisperService).
- All "Tap the download button to resume" messages updated to "Tap on Whisper Model to try again."

---

## [Unreleased] - 2026-02-28 - Whisper Model Status Capsule Badge + Download Re-trigger Fix

### Changed
- **Whisper Model item** now shows a **capsule status badge** next to the label:
  - **Red "Not Downloaded"** badge when model needs downloading
  - **Green "Ready"** badge when model is downloaded
  - **Grey "Checking..."** badge while verifying status
- **Download re-trigger fix** — tapping Whisper Model when current model is not downloaded now correctly triggers the download dialog (was silently returning because `picked == currentModel`)
- All **"Download failed"** SnackBar messages replaced with resume-friendly wording: `"Download couldn't be completed. Tap the download button to resume."`
- Updated across `audio_settings_page.dart` (3 locations) and `settings_page.dart` (2 locations)

---

## [Unreleased] - 2026-02-28 - Default Folder Moved + Download Resume & Wakelock

### Changed
- **Default Folder** setting moved from Audio & Recording page to **Preferences** page (better UX grouping)
- **Whisper model download** now keeps screen awake via `wakelock_plus` during download — prevents OS from killing the connection when screen dims
- **HTTP resume support** added to model download — if download is interrupted (app minimized, network drop), the next attempt **resumes from where it left off** instead of starting from scratch
- Download dialog messages updated: "Keep the app open — screen will stay on."
- Partial `.tmp` download files are preserved for resume (no longer deleted on failure)

### Added
- `wakelock_plus` package dependency for screen wakelock during downloads

---

## [Unreleased] - 2026-02-28 - Speaking Language for All Modes + Mixed-Language Guidance

### Changed
- **Speaking Language** picker now visible for **both** Whisper and Live transcription modes (was Whisper-only)
- **Dynamic sublabel** adapts based on mode and language:
  - English (any mode): "Language you speak during recording"
  - Whisper + non-English: "Language you speak — choose note output below"
  - Live + non-English: "Output will be in this language (no translation)"
- **Transcription Mode picker** updated descriptions:
  - Whisper: mentions "Supports English translation for other languages"
  - Live: mentions "Output is always in the speaking language — no translation"
- **Note Output** remains Whisper-only (Live mode has no translation capability)

---

## [Unreleased] - 2026-02-28 - Speaking Language + Note Output Mode (Two-Part Language UX)

### Added
- **Speaking Language picker** in Audio & Recording — user selects the language they speak during recording (English default). No more "Auto" mode.
- **Note Output picker** — when speaking language is not English, user chooses between:
  - **English Translation** — speech translated to English notes (`isTranslate: true`), works on Standard model
  - **Native Script** — notes in native script (e.g. हिन्दी, العربية, 中文), requires Enhanced model
- **`noteOutputMode` setting** — persisted in Hive (HiveField 16), defaults to `'english'`
- **`isTranslate` parameter** added to `WhisperService.transcribe()` — enables Whisper translation mode
- **Automatic Enhanced model enforcement** — selecting "Native Script" output triggers download if Enhanced model not present

### Changed
- **Removed "Auto/Automatic"** from language options — unreliable on Standard model, confusing for users
- **Default language changed** from Auto (`null`) to English (`'en'`) — existing users with Auto migrated to English
- **Moved language setting** from Preferences page to Audio & Recording page (where it belongs with transcription settings)
- **Removed old language recommendation dialog** from Preferences (replaced by inline Note Output enforcement in Audio Settings)

### How It Works
Whisper's `isTranslate` param translates any language to English text output. This enables:
- Hindi speaker wanting English notes → `language: 'hi', isTranslate: true` (Standard model works fine)
- Hindi speaker wanting Devanagari notes → `language: 'hi', isTranslate: false` (Enhanced model required)

---

## [Unreleased] - 2026-02-28 - Unified Whisper Model Item

### Changed
- **Unified Whisper Model item** in Audio Settings — merged the separate "Whisper Model" (download status) and "Transcription Model" (Standard/Enhanced picker) into ONE item showing model name + size + download status in the sublabel (e.g. "Standard (142 MB) · Ready")
- **Removed** old `WhisperModelStatusItem` widget from `settings_widgets.dart`

---

## [Unreleased] - 2026-02-28 - Selectable Whisper Model (Standard / Enhanced)

### Added
- **Transcription Model picker** in Audio Settings — users can choose between:
  - **Standard (142 MB)** — `ggml-base.bin`, fast transcription, best for English
  - **Enhanced (466 MB)** — `ggml-small.bin`, better accuracy, supports Hindi and other languages in native script (Devanagari, Arabic, CJK, etc.)
- **Dynamic model switching** in `WhisperService` — supports loading any model at runtime (`switchModel()`, `isSpecificModelDownloaded()`, `deleteSpecificModel()`, `getSpecificModelSizeBytes()`)
- **Download flow** for Enhanced model — confirmation dialog with size warning, progress bar, auto-switch on completion
- **`whisperModel` setting** — persisted in Hive (HiveField 15), defaults to `'base'`

### Changed
- `WhisperService` — refactored from hardcoded `ggml-base.bin` to configurable model selection
- `recording_page.dart` — reads `settings.whisperModel` and applies it before transcription starts

### Why
The Whisper `base` model (74M parameters) cannot reliably output non-Latin scripts like Devanagari for Hindi. It romanizes instead (e.g., "Mera naam Haridas hai" instead of "मेरा नाम हरिदास है"). The `small` model (244M parameters) has enough capacity for native script output and significantly better multilingual accuracy.

---

## [Unreleased] - 2026-02-28 - Fix: Wire Language Setting to Transcription Engines

### Fixed
- **CRITICAL: Language setting was completely disconnected** — the "Detection Language" preference was stored but never forwarded to either transcription engine. All recordings used engine defaults regardless of user selection.
- **Whisper engine** — now passes `language:` param to `TranscribeRequest` (e.g. `'hi'` for Hindi, `'auto'` for auto-detect). Previously always auto-detected, causing wrong results on mixed-language speech.
- **Live STT engine** — now passes `localeId:` to `speech_to_text.listen()` with BCP-47 locale (e.g. `'hi-IN'` for Hindi). Previously used OS default locale only.
- **Note detectedLanguage field** — now stores the actual language setting instead of hardcoded `'auto'` (Whisper) or `'en'` (Live).
- **ISO → BCP-47 mapping** — added locale mapping for all 12 supported languages (speech_to_text requires `'hi-IN'` format, not `'hi'`).

### Changed
- `WhisperService.transcribe()` — new `language` parameter (default: `'auto'`)
- `TranscriptionService.startListening()` — new `localeId` parameter (default: `null` = OS default)
- `NotesNotifier.transcribeInBackground()` — new `language` parameter forwarded to Whisper
- `recording_page.dart` — reads `settings.defaultLanguage` and passes to both engines

---

## [Unreleased] - 2026-02-28 - Audio Settings UX + Preferences Toggles

### Changed
- **Transcription mode picker** — "Record & Transcribe" now listed first with "(Recommended)" label; on-device privacy messaging added ("nothing leaves your phone"); Live Transcription moved to second option with clearer description
- **Transcription sublabel** — shows "On-device Whisper AI — high accuracy" (whisper) or "Real-time text, no audio saved" (live) instead of generic descriptions
- **Voice Commands** — sublabel changed to "Organize recordings by voice — tap to learn more"; tapping now shows a detailed info dialog with format, examples, and tips
- **Default Folder picker** — removed "None" option; General folder is always the mandatory default; users can only switch between existing folders

### Added
- **Action Items toggle** in Preferences — enables/disables action items section in note detail (`actionItemsEnabled`, HiveField 13)
- **To-Dos toggle** in Preferences — enables/disables to-dos section in note detail (`todosEnabled`, HiveField 14)
- **Note detail page** — Action Items and To-Dos sections now conditionally hidden when disabled in Preferences (both voice notes and text notes)

---

## [Unreleased] - 2026-02-27 - About Page Fixes + Spec Update

### Fixed
- **About page: Support Development section** — now uses theme-aware colors (`errorContainer`, `error`) instead of hardcoded `Colors.red.shade50` / `Colors.pink.shade50` that clashed with dark mode
- **About page: "Have a feature in mind?" tile** — now tappable, navigates directly to Feedback page with chevron indicator
- **About page: Legal info text** — updated from "visit Settings > About" to "Review below"
- **About page: Phase 2 roadmap** — updated to match actual implementation plan (Whisper API, AI categorization, AI task extraction, AI project summaries, semantic search, n8n)

### Updated
- `documents/PROJECT_SPECIFICATION.md` — v2.5: Settings → App Menu (3-dot menu + sub-pages), all routes updated, "planned" statuses changed to "implemented/active", TextNotePrefix added to UserSettings model

---

## [Unreleased] - 2026-02-27 - Settings Redesign: 3-dot Menu + Sub-pages

### Changed
- **Home AppBar**: Replaced gear icon with 3-dot overflow menu (`PopupMenuButton`)
- **Settings page split** into 5 focused sub-pages:
  - **Preferences** (`/preferences`) — name, note prefix, text prefix, detection language, reminders, appearance
  - **Audio & Recording** (`/audio_settings`) — audio quality, transcription mode, whisper model, default folder, voice commands
  - **Storage** (`/storage`) — storage breakdown (whisper, recordings, notes, images)
  - **Help & Support** (`/support`) — quick guide, send feedback
  - **Danger Zone** (`/danger_zone`) — delete whisper model, delete recordings, delete all data
- **About page** remains unchanged, accessible from 3-dot menu
- **Feedback page**: Send button now requires minimum 20 characters (anti-spam)
- Deep links from onboarding and recording pages updated to point to Audio & Recording page

### Added
- `lib/widgets/settings_widgets.dart` — shared settings UI components (SettingsGroup, SettingsItem, DangerItem, StorageBreakdownSection, WhisperModelStatusItem, WhisperDownloadDialog)
- `lib/pages/preferences_page.dart` — Preferences sub-page
- `lib/pages/audio_settings_page.dart` — Audio & Recording sub-page
- `lib/pages/storage_page.dart` — Storage sub-page
- `lib/pages/support_page.dart` — Help & Support sub-page
- `lib/pages/danger_zone_page.dart` — Danger Zone sub-page

### Modified
- `lib/nav.dart` — replaced `/settings` route with 5 new routes
- `lib/pages/home_page.dart` — gear icon → 3-dot PopupMenuButton
- `lib/pages/feedback_page.dart` — 20-char minimum for send button
- `lib/pages/onboarding_page.dart` — updated deep link to `/audio_settings`
- `lib/pages/recording_page.dart` — updated deep link to `/audio_settings`

### Removed
- `/settings` route (replaced by sub-page routes)
- `lib/pages/settings_page.dart` is no longer used as a route destination

---

## [Unreleased] - 2026-02-27 - Send Feedback Page

### Added
- **Send Feedback page** — category dropdown (Bug Report, Feature Request, General Feedback), text field with 1000 char limit, sends via share sheet to hdmpixels@gmail.com
- Accessible from Settings > Support > Send Feedback

### Files Added
- `lib/pages/feedback_page.dart` — feedback page

### Files Modified
- `lib/nav.dart` — added `/feedback` route
- `lib/pages/settings_page.dart` — added "Send Feedback" item in SUPPORT group

---

## [Unreleased] - 2026-02-27 - About Page

### Added
- **About VoiceNotes AI page** — full about screen with app logo, version, description, development credits (HDMPixels + Claude Code), Phase 2 roadmap, "Buy Me a Coffee" support section, legal links (Privacy Policy & Terms), and technical details
- Accessible from Settings > About > About VoiceNotes AI

### Files Added
- `lib/pages/about_page.dart` — About page

### Files Modified
- `lib/nav.dart` — added `/about` route
- `lib/pages/settings_page.dart` — added "About VoiceNotes AI" item in ABOUT group

---

## [Unreleased] - 2026-02-27 - Privacy Policy & Terms and Conditions Pages

### Added
- **Privacy & Data Policy page** — comprehensive privacy policy accessible from Settings > About
- **Terms & Conditions page** — full legal terms accessible from Settings > About
- Both pages cover local-first architecture, copyright, user rights, and HDMPixels branding
- Styled with section headers, bullet lists, highlight boxes, and copyright footer
- New routes `/privacy_policy` and `/terms_conditions` added to GoRouter
- "ABOUT" settings group with both links (shield icon + document icon)

### Files Added
- `lib/pages/privacy_policy_page.dart` — privacy policy page
- `lib/pages/terms_conditions_page.dart` — terms & conditions page

### Files Modified
- `lib/nav.dart` — added privacy policy and terms & conditions routes
- `lib/pages/settings_page.dart` — added "About" settings group with both links

---

## [Unreleased] - 2026-02-27 - Strip [BLANK_AUDIO] from Whisper Transcriptions

### Fixed
- **[BLANK_AUDIO] tag removal** — Whisper transcriptions no longer contain `[BLANK_AUDIO]` or `[BLANK AUDIO]` tags that appeared when the user paused during recording
- Tags are stripped in WhisperService before text is returned, and any resulting double-spaces are collapsed

### Files Modified
- `lib/services/whisper_service.dart` — added regex cleanup for Whisper artifacts after transcription

---

## [Unreleased] - 2026-02-27 - Whisper Download Popup & General Folder Fix

### Changed
- **Whisper model not ready popup** — when user tries to record in whisper mode without the model downloaded, shows a 3-option dialog: "Go to Settings" (download), "Use Live Mode" (switch to live transcription for this session), or "Cancel"
- Previously redirected to settings page with no alternative

### Fixed
- **Live transcript notes now go to General folder** — live mode recordings that had no folder selected are automatically assigned to the General folder
- **Folder noteIds sync** — live mode note creation in note_detail_page now properly calls `addNoteToFolder` to update the folder's noteIds list

### Files Modified
- `lib/pages/recording_page.dart` — 3-option whisper popup, auto-General folder for live mode
- `lib/pages/note_detail_page.dart` — add `addNoteToFolder` call when creating note with folderId

---

## [Unreleased] - 2026-02-27 - Text Note Prefix & Auto-General Folder

### Added
- **Text Note Prefix setting** — separate prefix for text notes (default "TXT"), configurable in Settings
- Auto-sequence: TXT001, TXT002, TXT003... (independent from voice note sequence)
- **Auto-assign General folder** — text notes automatically placed in General folder when created
- New "Text Prefix" setting in Preferences section with orange edit_note icon
- `textNotePrefix` HiveField(12) on UserSettings model

### Changed
- `_generateTitle()` refactored into `_generateTitleWithPrefix()` shared helper
- `addNote()` detects text notes (empty audioFilePath) and uses text prefix + General folder

### Files Modified
- `lib/models/user_settings.dart` — added `textNotePrefix` HiveField(12), default "TXT"
- `lib/models/user_settings.g.dart` — regenerated Hive adapter
- `lib/providers/settings_provider.dart` — added `textNotePrefix` to SettingsState + `setTextNotePrefix()`
- `lib/services/settings_repository.dart` — added `setTextNotePrefix()` method
- `lib/providers/notes_provider.dart` — added `_generateTextNoteTitle()`, auto-assign General folder for text notes
- `lib/pages/settings_page.dart` — added Text Prefix setting item in Preferences group

---

## [Unreleased] - 2026-02-27 - Text Notes Support

### Added
- **Text Note creation** — new "Text Note" option in speed dial FAB on home page
- Creates a note with no audio file, opens directly in edit mode (title + transcription editable)
- **Note card differentiation** — text notes show pen icon (orange chip) vs voice notes with mic icon (green chip)
- Same swipe gestures, long-press menu, and detail page experience as voice notes
- Audio player section automatically hidden for text-only notes

### Files Modified
- `lib/pages/home_page.dart` — added Text Note speed dial item
- `lib/pages/note_detail_page.dart` — added `isNewTextNote` flag, auto-enter edit mode for new text notes
- `lib/nav.dart` — pass `isNewTextNote` extra to note detail route
- `lib/widgets/note_card.dart` — differentiate icon/color for text vs voice notes

---

## [Unreleased] - 2026-02-27 - Issue #5: Voice Notes Detail Page Redesign

### Changed
- **AppBar title** — editable inline with pen icon (tap title to edit, check to save)
- **Removed bottom edit bar** — no more fixed "Edit Note" / "Save Note" button at bottom
- **Transcription editing** — pen icon on section header for inline editing with save/cancel
- **Each save creates a new version** — uses `addTranscriptVersion` to track edits
- **Inline version history** — collapsible section below transcription, newest first
- **Version selection mode** — long press versions to enter selection, select all, bulk delete
- **Original version protection** — deleting original triggers double confirmation (deletes entire note)
- **Audio player moved below transcription** — treated as secondary content
- **Audio waveform animation** — animated bar visualization during playback (30 bars, progress-colored)
- **Usage section** — shows which folders and projects the note belongs to (colored chips)
- **Delete moved to bottom** — red outlined button at bottom of scrollable content
- **Delete confirmation** — warns about removal from folders/projects with names listed
- **3-dot menu simplified** — only Share remains (delete removed from overflow menu)

### Files Modified
- `lib/pages/note_detail_page.dart` — complete redesign with all changes above

---

## [Unreleased] - 2026-02-27 - Issue #4: Speed Dial FAB Overlay Fix

### Fixed
- **Main FAB button** now renders above the blur overlay when speed dial is open
- Previously the blur scrim covered the FAB making it appear blurry/unfocused
- Added a duplicate FAB in the overlay layer so it sits on top of the backdrop filter

### Files Modified
- `lib/widgets/speed_dial_fab.dart` — render main FAB above blur scrim in overlay

---

## [Unreleased] - 2026-02-27 - Issue #3: General Folder Protection

### Changed
- **General folder** — rename and delete options hidden for the "General" folder
- **New installs** — General folder created with `isAutoGenerated: true` flag
- **Existing installs** — also guarded by folder name check for backward compatibility

### Files Modified
- `lib/pages/folder_detail_page.dart` — hide overflow menu for General folder
- `lib/services/hive_service.dart` — set `isAutoGenerated: true` on General folder creation

---

## [Unreleased] - 2026-02-27 - Issue #2: Search Notes Page

### Changed
- **Removed recording FAB** from search page — search is now purely for finding notes
- **AppBar header** — replaced manual padded header with standard AppBar for consistent spacing/alignment
- **Removed search bar** from home dashboard — was just redirecting to search page
- **Folder/project filter chips** — scrollable chips for every folder and project, tap to filter results
- **Contextual search** — searching from folder detail page pre-selects that folder filter
- **Search route** — accepts optional `folderId`/`projectId` extras for contextual filtering

### Files Modified
- `lib/pages/search_page.dart` — full rewrite
- `lib/pages/home_page.dart` — removed search bar
- `lib/pages/folder_detail_page.dart` — passes folderId to search
- `lib/nav.dart` — search route accepts extras

---

## [Unreleased] - 2026-02-27 - Issue #1: Voice Note Tile Redesign

### Added
- **Compact NoteCard widget** (`lib/widgets/note_card.dart`) — extracted and redesigned note tile from home page into reusable widget
- **Metadata row** — timestamp, duration (Xm Ys format), and language displayed with icons and dot separators
- **Folder labels** — colored chips showing all folders containing the note (reverse-lookup from folder noteIds)
- **Project labels** — colored chips showing linked project document titles
- **Photo count indicator** — badge showing number of attached images
- **Swipe gestures** — left swipe to delete (red, with confirmation), right swipe to open note (blue)
- **Long-press context menu** — bottom sheet with: Open, Edit Title, Add to Folder, Add to Project, Delete
- **Edit Title dialog** — inline title editing from long-press menu
- **Folder picker** — scrollable bottom sheet to toggle folder membership, with "Create New" option
- **Project picker** — scrollable bottom sheet to link note to projects, with "Create New" option

### Changed
- **Note tile layout** — compact design with 16px padding (was 24px), 8px margin (was 16px), regular weight title (was bold)
- **Title width** — full width with ellipsis (was capped at 150px)
- **Tags** — use `Wrap` for better multi-tag layout (was fixed `Row`)
- **Removed** — old inline `_NoteCard`, `_NoteTag`, `_TranscribingProgress` classes from home_page.dart (moved to note_card.dart)

### Files Created
- `lib/widgets/note_card.dart`

### Files Modified
- `lib/pages/home_page.dart`

---

## [Unreleased] - 2026-02-27 - Step 4.6: Interactive Tasks & Reminder Enhancement

### Added
- **Interactive checkboxes on Note Detail** — action items and todos are now tappable; checkbox toggles `isCompleted` with strikethrough + muted styling
- **Todos section on Note Detail** — previously missing; now rendered with interactive checkboxes, due date badges, and overdue highlighting
- **Manual task creation** — "Add Action" and "Add Todo" buttons on Note Detail with inline creation dialogs (text + optional due date for todos)
- **Task overflow menus** — Edit and Delete options on every action item, todo, and reminder via 3-dot PopupMenuButton
- **Aggregated Tasks View** — new "Tasks" tab on Home page (SegmentedButton) showing all todos, actions, and reminders from every note in one sorted, filterable list
- **Task filter chips** — All / Todos / Actions / Reminders filter on Tasks tab
- **Show completed toggle** — hide/show completed tasks with count indicator
- **Open task count badge** — badge on Tasks tab icon showing number of open tasks
- **Reminder reschedule** — reschedule any reminder via date/time picker from overflow menu; cancels old notification, schedules new one
- **Overdue highlighting** — todos and reminders with past due dates shown in red across all surfaces
- **OS calendar bridge** — "Also add to Calendar" bottom sheet after creating a reminder; uses `add_2_calendar` to create pre-filled OS calendar event
- **Reminder destination sheet** — bottom sheet widget offering "Keep in VoiceNotes AI" or "Also add to Calendar" after reminder creation
- **Collapsible tasks in Project Documents** — note reference blocks now show a collapsible "Tasks" sub-section with interactive checkboxes for the linked note's todos and actions
- **Task count summary** — collapsed state shows "N tasks (M completed)" in note reference blocks
- **TaskItem view model** — `lib/models/task_item.dart` with `TaskType` enum (todo/action/reminder) for aggregated tasks
- **tasksProvider** — derived Riverpod provider aggregating all tasks from all notes with sorting (overdue first → due date → creation date)
- **OsReminderService** — `lib/services/os_reminder_service.dart` wrapping `add_2_calendar` for OS calendar event creation

### Changed
- **Home page** — converted from `ConsumerWidget` to `ConsumerStatefulWidget` to hold tab state
- **NoteReferenceCard** — converted from `StatefulWidget` to `ConsumerStatefulWidget` for Riverpod access
- **NotesRepository** — added 8 new CRUD methods: toggleTodoCompleted, toggleActionCompleted, addTodoItem, addActionItem, updateTodoItem, updateActionItem, deleteTodoItem, deleteActionItem, plus rescheduleReminder
- **NotesProvider** — exposed all 8 repository methods + rescheduleReminder with notification cancel/reschedule logic
- **Action Items section** — now always visible (not gated by `isNotEmpty`) to allow adding new actions

### Dependencies
- Added `add_2_calendar: ^3.0.1` for cross-platform OS calendar event creation

### Files Created (7 new)
- `lib/models/task_item.dart` — TaskItem view model + TaskType enum
- `lib/providers/tasks_provider.dart` — derived provider aggregating all tasks
- `lib/widgets/tasks_tab.dart` — Tasks tab content for Home page
- `lib/widgets/task_list_item.dart` — reusable task row widget
- `lib/widgets/reminder_destination_sheet.dart` — bottom sheet for reminder destination
- `lib/services/os_reminder_service.dart` — OS calendar bridge

### Files Modified (6)
- `lib/services/notes_repository.dart` — 8 CRUD methods + rescheduleReminder
- `lib/providers/notes_provider.dart` — exposed all new methods
- `lib/pages/note_detail_page.dart` — interactive todos/actions, create buttons, reschedule, OS reminder sheet
- `lib/pages/home_page.dart` — Notes/Tasks tab bar, ConsumerStatefulWidget conversion
- `lib/pages/project_document_detail_page.dart` — collapsible tasks in note reference blocks
- `pubspec.yaml` — added add_2_calendar

---

## [Unreleased] - 2026-02-27 - Step 4.7: Sharing, Rich Text & Image Blocks

### Added
- **Share single note** — share button in Note Detail overflow menu assembles formatted note text and opens OS share sheet via `share_plus`
- **Share project document** — share icon in Project Document AppBar assembles all blocks into shareable text
- **Export as Markdown** — overflow menu option generates `.md` file with proper heading/quote formatting and shares via OS sheet
- **Export as Plain Text** — overflow menu option generates `.txt` file and shares via OS sheet
- **Rich text formatting** — free-text blocks in Project Documents now use `flutter_quill` editor with formatting toolbar (Bold, Italic, Bullet List, H1, H2, Link)
- **Quill Delta storage** — rich text stored as Quill Delta JSON in `block.content` with `contentFormat: "quill_delta"`; plain text blocks auto-wrapped on first edit
- **Image blocks** — new block type `imageBlock` for Project Documents; pick from gallery or camera, compress/save, display full-width with caption
- **Image block overflow menu** — View full screen, Edit caption, Move up/down, Remove (cascade deletes file + metadata)
- **Full-screen image viewer** — `photo_view` based viewer with pinch-to-zoom and pan
- **Note photo attachments** — new Attachments section on Note Detail with horizontal scrollable thumbnails, Add Photo button (gallery/camera), long-press to delete
- **ImageAttachment Hive model** — `lib/models/image_attachment.dart` (typeId: 10) with id, filePath, fileName, caption, dimensions, fileSize, sourceType
- **Image attachment repository** — `lib/services/image_attachment_repository.dart` with save/get/delete/updateCaption methods + `flutter_image_compress` for optimization
- **Sharing service** — `lib/services/sharing_service.dart` for assembling note/document text and generating export files
- **Image block widget** — `lib/widgets/image_block_widget.dart` with full-width image, caption, overlay menu
- **Note attachments widget** — `lib/widgets/note_attachments_section.dart` with thumbnail row and photo management

### Changed
- **BlockType enum** — added `imageBlock` (HiveField 3)
- **ProjectBlock model** — added `imageAttachmentId` (HiveField 7) and `contentFormat` (HiveField 8) fields
- **Note model** — added `imageAttachmentIds` (HiveField 19) field
- **HiveService** — registered `ImageAttachmentAdapter`, opened `imageAttachmentsBox`, creates images directory on init, includes images in storage calculation, clears images on Delete All Data
- **Free-text blocks** — replaced plain `TextField` with `QuillEditor` + `QuillSimpleToolbar` for rich text editing
- **Project Document detail** — added image block rendering, "Add Image" option in add block sheet, share/export buttons
- **Note Detail page** — added share button, photo attachments section
- **NotesRepository** — added `addImageAttachment` and `removeImageAttachment` methods
- **NotesProvider** — exposed image attachment methods
- **ProjectDocumentsRepository** — added `addImageBlock` and `updateBlockContentFormat` methods
- **ProjectDocumentsProvider** — exposed image block and content format methods

### Dependencies
- Added `share_plus: ^10.1.4` — OS share sheet
- Added `flutter_quill: ^11.5.0` — rich text editing
- Added `image_picker: ^1.1.2` — gallery/camera photo selection
- Added `image_cropper: ^8.0.2` — crop and resize UI
- Added `photo_view: ^0.15.0` — full-screen image viewer with zoom
- Added `flutter_image_compress: ^2.3.0` — image compression

### Files Created (6 new)
- `lib/models/image_attachment.dart` — ImageAttachment Hive model (typeId: 10)
- `lib/services/image_attachment_repository.dart` — image CRUD + file management
- `lib/services/sharing_service.dart` — share text assembly + export file generation
- `lib/widgets/image_block_widget.dart` — image block card for Project Documents
- `lib/widgets/note_attachments_section.dart` — photo section on Note Detail
- `lib/pages/image_viewer_page.dart` — full-screen image viewer with pinch-to-zoom

### Files Modified (10)
- `lib/models/project_block.dart` — added imageBlock enum, imageAttachmentId, contentFormat fields
- `lib/models/note.dart` — added imageAttachmentIds field
- `lib/services/hive_service.dart` — ImageAttachment adapter, box, images dir, storage, deleteAll
- `lib/services/project_documents_repository.dart` — addImageBlock, updateBlockContentFormat
- `lib/services/notes_repository.dart` — addImageAttachment, removeImageAttachment
- `lib/providers/project_documents_provider.dart` — addImageBlock, updateBlockContentFormat
- `lib/providers/notes_provider.dart` — addImageAttachment, removeImageAttachment
- `lib/pages/project_document_detail_page.dart` — image blocks, rich text, share/export
- `lib/pages/note_detail_page.dart` — share button, attachments section
- `pubspec.yaml` — added 6 new packages

---

## [Unreleased] - 2026-02-27 - Library Merge, Whisper UX, UI Polish

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

## [Unreleased] - 2026-02-27 - Voice Command Auto-Linking

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

## [Unreleased] - 2026-02-26 - Edge-to-Edge Display & UI Fixes

### Fixed
- **Android navigation bar** — now truly transparent (edge-to-edge) by adding `android:navigationBarColor` and `android:statusBarColor` to both light and dark Android styles.xml
- **Nav bar icon brightness** — dynamically adapts to light/dark theme (light icons in dark mode, dark icons in light mode)
- **Edit Note button overlap** — bottom bar on note detail page now accounts for system navigation bar padding
- **SpeedDialFab overlap** — FAB on Home, Folders, and Project Documents pages no longer overlaps Android navigation buttons
- **FAB position consistency** — all pages now use `SafeArea(top: false)` wrapping the body Stack, ensuring consistent FAB positioning across Home, Folders, and Project Documents pages

---

## [Unreleased] - 2026-02-26 - Default Folder & Create from Recording Page

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

## [Unreleased] - 2026-02-26 - Recording Page Enhancements

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

## [Unreleased] - 2026-02-26 - Speed Dial FAB, Background Transcription & UI Polish

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

## [Unreleased] - 2026-02-26 - Project Documents Feature (Step 4.5)

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

## [Unreleased] - 2026-02-26 - Whisper Fix, Timestamps, Conditional UI

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

## [Unreleased] - 2026-02-26 - UI Polish & Compact Headers

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

## [Unreleased] - 2026-02-26 - Settings Overhaul, Splash Screen & Quick Guide

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

## [Unreleased] - 2026-02-25 - Concept Alignment & Documentation

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

## [Unreleased] - 2026-02-24 - Initial Scaffolding

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
