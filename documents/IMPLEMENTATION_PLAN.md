# VoiceNotes AI - Implementation Plan

**Version:** 3.0
**Last Updated:** 2026-03-02
**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Project Documents Feature Spec](FEATURE_PROJECT_DOCUMENTS.md) | [Tasks & Reminders Feature Spec](FEATURE_TASKS_AND_REMINDERS.md) | [Phase 1 Value Gaps](FEATURE_PHASE1_VALUE_GAPS.md)

---

## Overview

This plan is split into two phases:

- **Phase 1 (On-Device):** A fully functional voice note-taking app with recording, on-device transcription, local storage, folders, search, playback, and notifications — all without any AI/cloud dependency.
- **Phase 2 (AI-Powered):** Adds AI categorization, smart structuring, Whisper API transcription, auto-folder assignment, and n8n integration.

**Current state:** Phase 1 core complete (all 7 steps + Steps 4.5/4.6/4.7 + bonus features + post-release enhancements Issues #7–#12). Current version: **v1.0.0** (Release). **Next:** Phase 1 Value Proposition Gaps (Steps 8–10.7, 8 features) — features to match competitor expectations before Play Store launch.
**Phase 1 target:** Privacy-first voice note app with on-device transcription, local Hive storage, audio playback, reminder notifications, project documents, voice command auto-linking, interactive tasks & aggregated tasks view, hybrid reminders with OS calendar bridge, sharing/export with PDF, rich text editing, share preview with toggles, photo attachments, word count, find & replace, profanity filter, voice commands for task creation, **pinned notes, AMOLED dark theme, auto-title generation, note templates, trash/soft delete, home screen widget, app lock (PIN/biometric), and local backup & restore**.

---

# PHASE 1 — On-Device Features (No AI Required)

---

## Step 1: Project Alignment & Branding Fixes ✅ COMPLETED

**Goal:** Align the codebase with the concept document.

### Tasks:
1. ~~Update Android app label — "VoiceNotes AI"~~
2. ~~Update iOS app name~~
3. ~~Fix app title in main.dart~~
4. ~~Mark login_page.dart as Not In Use~~
5. ~~Update onboarding flow → Home (no login gate)~~
6. ~~Clean up pubspec.yaml~~

---

## Step 2: State Management Migration (Riverpod) ✅ COMPLETED

**Goal:** Replace Provider with Riverpod.

### Tasks:
1. ~~Add flutter_riverpod, wrap app with ProviderScope~~
2. ~~Create providers: settings, notes, folders, recording, connectivity~~
3. ~~Use Notifier/NotifierProvider (Riverpod 3.x API)~~

---

## Step 3: Data Models & Hive Database ✅ COMPLETED

**Goal:** Implement encrypted local storage with Hive.

### Tasks:
1. ~~Create 6 Hive models (Note, ActionItem, TodoItem, ReminderItem, Folder, UserSettings)~~
2. ~~Generate type adapters with build_runner~~
3. ~~AES-256 encrypted boxes for notes, folders, settings~~
4. ~~Repository layer (notes, folders, settings)~~
5. ~~Connect repositories to Riverpod providers~~

---

## Step 4: Wire UI to Data Layer ✅ COMPLETED

**Goal:** Connect all screen UIs to real Hive data through Riverpod providers.

### Tasks:
1. **Home Page:**
   - Display notes from Hive via `notesProvider`
   - Note cards show: title, date, language tag, preview text
   - Filter chips (All, Actions, Todos, Reminders, Notes) filter the note list
   - Search bar queries notes by keyword
   - Record button navigates to recording screen
   - Tapping a note card opens Note Detail

2. **Note Detail Page:**
   - Display full transcription from Hive note
   - Render sections (actions, todos, reminders, general notes) — manually added for now
   - Checkboxes toggle `isCompleted` and persist to Hive
   - Edit button allows editing transcription text
   - Delete button with confirmation dialog
   - Show detected language label

3. **Folders Page:**
   - List all folders from `foldersProvider`
   - Show note count per folder
   - Create new folder dialog
   - Rename / delete folder

4. **Folder Detail Page:**
   - Display notes belonging to selected folder
   - Chronological timeline view
   - Remove note from folder

5. **Settings Page:**
   - Read/write settings from Hive via `settingsProvider`
   - Language preference toggle (auto-detect vs specific)
   - Audio quality selector
   - Notification toggle
   - Storage usage display (Hive box sizes + audio files)
   - Privacy dashboard (data summary, delete all data button)
   - Theme mode toggle (light/dark/system)

6. **Search Page:**
   - Query notes by keyword (rawTranscription, title)
   - Filter by date range, language
   - Display results as note cards

### Deliverables:
- All screens display and mutate real persistent data
- CRUD operations work end-to-end through the UI
- Notes persist, appear in lists, can be edited and deleted

### Estimated effort: Large

---

## Step 4.5: Project Documents ✅ COMPLETED

**Goal:** Implement the Project Documents feature — rich, composite documents assembled from individual voice notes with free-text blocks, section headers, drag-and-drop reordering, bi-directional transcript editing, and version history. All on-device, no AI.

**Feature Spec:** [FEATURE_PROJECT_DOCUMENTS.md](FEATURE_PROJECT_DOCUMENTS.md)

### Sub-step A: Data Model & Storage

1. Create `ProjectDocument` Hive model (typeId: 6) — id, title, description, blocks, createdAt, updatedAt
2. Create `ProjectBlock` Hive model (typeId: 7) — id, type, sortOrder, noteId, content, createdAt, updatedAt
3. Create `TranscriptVersion` Hive model (typeId: 8) — id, text, versionNumber, editSource, createdAt, isOriginal
4. Create `BlockType` enum (note_reference, free_text, section_header)
5. Add `projectDocumentsBox` to HiveService initialization (AES-256 encrypted)
6. Modify existing `Note` model:
   - Add `transcriptVersions: List<TranscriptVersion>` field
   - Add `projectDocumentIds: List<String>` field
7. Write data migration: on app start, if a Note has no transcriptVersions, create v1 from rawTranscription
8. Run `build_runner` to regenerate type adapters

### Sub-step B: Repository & Provider Layer

1. Create `ProjectDocumentsRepository` — CRUD for project documents and blocks
2. Add transcript versioning methods to `NotesRepository` (addTranscriptVersion, getTranscriptVersions, restoreTranscriptVersion)
3. Add projectDocumentIds management methods to `NotesRepository`
4. Create `projectDocumentsProvider` (Notifier/NotifierProvider)
5. Wire provider to repository with proper state management

### Sub-step C: UI — Project Documents List Screen

1. Create `/project-documents` route and `project_documents_page.dart`
2. Implement project document card widget (title, description, block count, last updated)
3. Implement "New Project" creation dialog (title + optional description)
4. Implement rename and delete actions with confirmation
5. Implement search/filter within project documents
6. Implement empty state
7. Add "Projects" navigation entry from Home page

### Sub-step D: UI — Project Document Detail Screen

1. Create `/project-documents/:id` route and `project_document_detail_page.dart`
2. Implement block rendering engine (switch on block type → render card)
3. Implement Note Reference Block widget (transcript, timestamp, language badge, in-place editing, overflow menu)
4. Implement Free-Text Block widget (editable text area, overflow menu)
5. Implement Section Header Block widget (large/bold editable text, optional divider)
6. Implement "Add Block" action sheet (Add Voice Note / Add Free Text / Add Section Header)
7. Implement reorder mode with drag handles
8. Wire all edit/save/delete actions to provider

### Sub-step E: UI — Note Picker & Supporting Screens

1. Create note picker screen with search and multi-select
2. Show "already linked" indicator on notes in picker
3. Implement "Add to Project" action on Note Detail page
4. Implement "Linked Projects" section on Note Detail page
5. Implement optional "Add to Project?" prompt after saving a new recording
6. Create Version History screen/bottom sheet (list versions, "Restore this version" action)

### Sub-step F: Integration & Polish

1. Handle note deletion — update project document blocks to show "Note deleted" placeholder
2. Handle project document deletion — clean up note references (remove documentId from all linked notes)
3. Ensure search indexes include project document titles
4. Test with large documents (50+ blocks) — use ListView.builder for lazy rendering
5. Accessibility: screen reader labels, drag-and-drop alternatives (move up/down buttons)
6. Empty states for all new screens

### New Files:
| File | Purpose |
|---|---|
| `lib/models/project_document.dart` | ProjectDocument Hive model |
| `lib/models/project_block.dart` | ProjectBlock Hive model |
| `lib/models/transcript_version.dart` | TranscriptVersion Hive model |
| `lib/services/project_documents_repository.dart` | CRUD for project documents |
| `lib/providers/project_documents_provider.dart` | Riverpod provider |
| `lib/pages/project_documents_page.dart` | List screen |
| `lib/pages/project_document_detail_page.dart` | Detail / canvas screen |
| `lib/pages/note_picker_page.dart` | Multi-select note picker |
| `lib/pages/version_history_page.dart` | Transcript version history |
| `lib/widgets/note_reference_block.dart` | Block widget |
| `lib/widgets/free_text_block.dart` | Block widget |
| `lib/widgets/section_header_block.dart` | Block widget |
| `lib/widgets/project_document_card.dart` | Card for list screen |

### Modified Files:
| File | Change |
|---|---|
| `lib/models/note.dart` | Add `transcriptVersions` and `projectDocumentIds` fields |
| `lib/services/hive_service.dart` | Add `projectDocumentsBox` initialization |
| `lib/services/notes_repository.dart` | Add versioning and project reference methods |
| `lib/providers/notes_provider.dart` | Expose new repository methods |
| `lib/nav.dart` | Add 4 new routes |
| `lib/pages/home_page.dart` | Add Projects navigation entry |
| `lib/pages/note_detail_page.dart` | Add "Linked Projects" section and "Add to Project" button |
| `lib/pages/recording_page.dart` | Add optional "Add to Project" prompt post-save |

### Estimated effort: Large

---

## Step 4.6: Interactive Tasks & Reminder Enhancement ✅ COMPLETED

**Goal:** Make todos, actions, and reminders interactive across all surfaces; add aggregated tasks view on Home page; enhance reminders with OS calendar bridge and reschedule capability. All on-device, no AI.

**Feature Spec:** [FEATURE_TASKS_AND_REMINDERS.md](FEATURE_TASKS_AND_REMINDERS.md)

### Sub-step A: Interactive Checkboxes on Note Detail

1. Update todo item rendering — add interactive checkbox widget with strikethrough + muted styling when completed
2. Update action item rendering — add interactive checkbox widget with same visual treatment
3. Add overdue date highlighting (red badge) for todos with past due dates
4. Wire checkbox taps to `NotesProvider.toggleTodoCompleted()` / `toggleActionCompleted()`
5. Add "Add Task" button to Todos section — inline text field + optional due date picker
6. Add "Add Action" button to Actions section — inline text field
7. Add overflow menu (⋮) on each item: Edit text, Delete, Set/change due date (todos only)
8. Implement `NotesRepository` methods: `toggleTodoCompleted`, `toggleActionCompleted`, `addTodoItem`, `addActionItem`, `updateTodoItem`, `updateActionItem`, `deleteTodoItem`, `deleteActionItem`
9. Expose above methods through `NotesProvider`

### Sub-step B: Checkboxes in Project Document Blocks

1. Add collapsible "Tasks" sub-section to `note_reference_block` widget
2. Render todos and actions from the linked note with interactive checkboxes
3. Show task count indicator in collapsed state: "3 tasks (1 completed)"
4. Wire checkbox taps to `NotesProvider` (same as Note Detail — bi-directional sync)
5. Auto-expand when tasks exist, collapse when none

### Sub-step C: Aggregated Tasks View

1. Create `TaskItem` view model class (`lib/models/task_item.dart`) — NOT a Hive model
2. Create `TaskType` enum: `todo`, `action`, `reminder`
3. Create `tasksProvider` — derived Riverpod provider that reads `notesProvider` and assembles flat `TaskItem` list
4. Add segmented control / tab bar to Home page: `[ Notes ]  [ Tasks ]`
5. Implement Tasks tab UI: open task count header, filter chips (All / Todos / Actions), task list
6. Implement task list row: checkbox, text, source note link (tappable → Note Detail), due date badge, type indicator
7. Include reminders in the aggregated view with bell icon and scheduled time
8. Implement "Show completed" toggle — completed items grouped at bottom with strikethrough
9. Implement sorting: overdue first → due date soonest → creation date newest
10. Implement open task count badge on Tasks tab label
11. Implement empty states ("No open tasks — you're all caught up!" / filter-specific messages)
12. Wire checkbox taps and source note navigation

### Sub-step D: Reminder Enhancement (Hybrid Model)

1. Add `add_2_calendar` package to `pubspec.yaml`
2. Create `lib/services/os_reminder_service.dart` — bridge to OS calendar via `add_2_calendar`
3. Create reminder destination bottom sheet (`lib/widgets/reminder_destination_sheet.dart`):
   - "Keep in VoiceNotes AI" (existing behavior)
   - "Also add to OS Reminders" (creates in-app + opens native calendar pre-filled)
4. Show bottom sheet after each reminder creation — user chooses per-reminder
5. Implement calendar event creation with pre-filled title, description ("From VoiceNotes AI: [note title]"), start time
6. Add "Reschedule" action to reminder items on Note Detail (clock icon / overflow menu)
7. Implement reschedule date/time picker pre-filled with current time; cancel old notification, schedule new
8. Add `NotesRepository.rescheduleReminder(noteId, reminderId, newTime)` method
9. Handle edge case: no calendar app available → SnackBar fallback
10. (Stretch) Add notification action buttons: "Done" (marks complete) and "Snooze 1hr" (reschedules +1 hour)

### Sub-step E: Polish & Integration

1. Ensure checkbox state syncs across all surfaces (Note Detail ↔ Project Document ↔ Tasks View) via `ref.watch()`
2. Test with notes that have many tasks (20+ items per note, 100+ total across notes)
3. Verify reminder notification deep-links still work
4. Update "Delete All Data" to handle any new state
5. Accessibility: checkbox labels, screen reader support for task counts
6. Test OS calendar integration on Android + iOS (calendar app not installed edge case)
7. Validate overdue sorting, empty states, filter combinations

### New Files:

| File | Purpose |
|---|---|
| `lib/models/task_item.dart` | TaskItem view model + TaskType enum for aggregated tasks |
| `lib/providers/tasks_provider.dart` | Derived provider aggregating todos + actions + reminders across all notes |
| `lib/widgets/task_list_item.dart` | Reusable task row widget (checkbox + text + source + date) |
| `lib/widgets/tasks_tab.dart` | Tasks tab content for Home page |
| `lib/widgets/interactive_todo_item.dart` | Todo item with checkbox, strikethrough, overflow menu |
| `lib/widgets/interactive_action_item.dart` | Action item with checkbox, strikethrough, overflow menu |
| `lib/widgets/reminder_destination_sheet.dart` | Bottom sheet for "Keep in-app / Also add to OS" choice |
| `lib/widgets/task_creation_inline.dart` | Inline text field for adding new tasks |
| `lib/services/os_reminder_service.dart` | Bridge to OS calendar/reminders via add_2_calendar |

### Modified Files:

| File | Change |
|---|---|
| `lib/pages/note_detail_page.dart` | Interactive checkboxes, manual task/action creation, reschedule, "Also add to OS" flow |
| `lib/pages/home_page.dart` | Add Tasks tab with segmented control, task count badge |
| `lib/widgets/note_reference_block.dart` | Add collapsible Tasks sub-section with interactive checkboxes |
| `lib/services/notes_repository.dart` | Add toggle, CRUD, and reschedule methods for todos/actions/reminders |
| `lib/providers/notes_provider.dart` | Expose new repository methods |
| `lib/services/notification_service.dart` | Add reschedule method, (stretch) notification action buttons |
| `pubspec.yaml` | Add `add_2_calendar` dependency |

### Estimated effort: Medium-Large

---

## Step 4.7: Sharing, Rich Text & Image Blocks ✅ COMPLETED

**Goal:** Extend Project Documents with sharing/export, rich text formatting in free-text blocks, and image blocks (photos). Add note-level sharing and photo attachments. All on-device, no AI.

**Feature Spec:** [FEATURE_PROJECT_DOCUMENTS.md — Addendum A](FEATURE_PROJECT_DOCUMENTS.md)

### Sub-step A: Data Model & Storage Extensions

1. Create `ImageAttachment` Hive model with type adapter (typeId: 9)
2. Add `image_block` to `BlockType` enum
3. Add `imageAttachmentId: String?` field to `ProjectBlock` model
4. Add `contentFormat: String?` field to `ProjectBlock` model ("plain" or "quill_delta")
5. Add `imageAttachmentIds: List<String>` field to `Note` model
6. Add `imageAttachmentsBox` to HiveService initialization (AES-256 encrypted)
7. Create `Documents/images/` directory on app initialization
8. Run `build_runner` to regenerate all type adapters
9. Write migration: existing free-text blocks get `contentFormat: "plain"`

### Sub-step B: Repository & Provider Extensions

1. Create `ImageAttachmentRepository` — CRUD for imageAttachmentsBox + file management
   - `saveImage(file, sourceType)` → process, store, return ImageAttachment
   - `getImageAttachment(id)` → return metadata
   - `deleteImageAttachment(id)` → delete metadata AND file from disk
   - `getImageFile(id)` → return File reference for display
2. Add image methods to `NotesRepository`: `addImageAttachment`, `removeImageAttachment`
3. Add image block methods to `ProjectDocumentsRepository`: `addImageBlock(documentId, attachmentId, caption?)`
4. Extend `projectDocumentsProvider` with image, sharing, and export methods
5. Create `SharingService` — assemble share text for notes and project documents, generate export files (.md, .txt)

### Sub-step C: UI — Sharing & Export

1. Add share button to Note Detail page — assemble note text → `share_plus`
2. Add share button to note card overflow menu on Home page
3. Add share button to Project Document Detail toolbar — assemble all blocks in order → `share_plus`
4. Add export option to Project Document overflow menu (⋮): Markdown (.md) or plain text (.txt)
5. Generate export file in temp directory → share via `share_plus` with file path
6. File naming: `[document_title]_[date].md` or `.txt`

### Sub-step D: UI — Rich Text Formatting (Free-Text Blocks)

1. Add `flutter_quill` package to `pubspec.yaml`
2. Integrate `flutter_quill` editor into free-text block widget
3. Implement compact formatting toolbar: `[ B ] [ I ] [ • ] [ H1 ] [ H2 ] [ 🔗 ]`
   - Toolbar appears only when editing a free-text block
   - Active formatting states highlighted
   - Link insertion: select text → tap link → enter URL dialog
4. Implement Quill Delta JSON serialization to/from `ProjectBlock.content`
5. Set `ProjectBlock.contentFormat = "quill_delta"` for rich text blocks
6. Implement Delta → Markdown conversion for export (`delta_to_markdown` or custom)
7. Implement Delta → plain text stripping for share
8. Migration: existing plain-text blocks converted to simple Delta on first load

### Sub-step E: UI — Image Blocks (Project Documents)

1. Add `image_picker`, `image_cropper`, `photo_view`, `flutter_image_compress` packages
2. Add "Add Image" option to "Add Block" action sheet (alongside Voice Note / Free Text / Section Header)
3. Implement image source selection bottom sheet (Gallery / Camera)
4. Implement crop/resize flow: free-form crop, auto-resize >2048px, JPEG 85% quality
5. Implement Image Block widget: full-width image, optional caption, overflow menu (edit caption, replace, remove, view full screen)
6. Implement full-screen image viewer page (pinch-to-zoom, pan via `photo_view`)
7. Image blocks support drag-and-drop reorder like other blocks

### Sub-step F: Note Detail — Photo Attachments

1. Add "Attachments" section to Note Detail page (below structured output, above audio playback)
2. Implement horizontal scrollable thumbnail row (or 2-column grid for 3+)
3. Implement "Add Photo" button — gallery/camera picker + crop/resize
4. Implement full-screen photo viewer on tap
5. Implement photo deletion with confirmation
6. Note reference blocks in Project Documents show photo indicator (📎 N photos)

### Sub-step G: Integration & Polish

1. Handle image cleanup on note deletion (delete associated ImageAttachments + files)
2. Handle image cleanup on project document deletion (delete image_block attachments + files)
3. Update "Delete All Data" to include imageAttachmentsBox and image files
4. Update storage display in Settings to include image file sizes
5. Handle edge cases: image file missing from disk (placeholder), camera/gallery permission denied (fallback), low storage (<100MB warning)
6. Test with large images, many photos (20+), low storage scenarios
7. Accessibility: image alt-text from caption, screen reader labels

### New Files:

| File | Purpose |
|---|---|
| `lib/models/image_attachment.dart` | ImageAttachment Hive model |
| `lib/services/image_attachment_repository.dart` | Image CRUD + file management |
| `lib/services/sharing_service.dart` | Assemble share text, generate export files |
| `lib/services/image_processing_service.dart` | Crop, resize, compress, save |
| `lib/widgets/image_block_widget.dart` | Image block for Project Document |
| `lib/widgets/note_attachments_section.dart` | Photo section on Note Detail |
| `lib/widgets/formatting_toolbar.dart` | Rich text toolbar for free-text blocks |
| `lib/pages/image_viewer_page.dart` | Full-screen image viewer |

### Modified Files:

| File | Change |
|---|---|
| `lib/models/project_block.dart` | Add `imageAttachmentId`, `contentFormat` fields, `image_block` to BlockType |
| `lib/models/note.dart` | Add `imageAttachmentIds` field |
| `lib/services/hive_service.dart` | Add `imageAttachmentsBox`, image directory creation |
| `lib/services/project_documents_repository.dart` | Add image block methods |
| `lib/services/notes_repository.dart` | Add image attachment methods |
| `lib/providers/project_documents_provider.dart` | Add image, sharing, export methods |
| `lib/pages/project_document_detail_page.dart` | Image blocks, rich text editor, share/export buttons |
| `lib/pages/note_detail_page.dart` | Attachments section, share button |
| `lib/widgets/free_text_block.dart` | Replace plain TextField with flutter_quill editor |
| `lib/pages/settings_page.dart` | Update storage display to include images |
| `pubspec.yaml` | Add 7 new packages |

### New Package Dependencies:

| Package | Purpose |
|---|---|
| `share_plus` | Native OS share sheet |
| `flutter_quill` | Rich text editing and viewing |
| `delta_to_markdown` | Export Delta → Markdown |
| `image_picker` | Gallery and camera photo selection |
| `image_cropper` | Crop and resize UI |
| `photo_view` | Full-screen image viewer with zoom |
| `flutter_image_compress` | Image compression and resizing |

### Estimated effort: Large

---

## Step 5: Speech-to-Text Integration (On-Device) ✅ COMPLETED

**Goal:** Add on-device transcription to the recording flow using `speech_to_text` package (free, no API key needed).

### How it works:
- Uses Google STT engine on Android and Apple Speech on iOS — both run on-device
- Supports 50+ languages with auto-detection
- Real-time text display while speaking
- No cloud API calls, no cost, fully private

### Tasks:
1. **Add dependency:** `speech_to_text` package
2. **Create transcription service** — `lib/services/transcription_service.dart`
   - Initialize speech recognizer
   - Start/stop listening tied to recording state
   - Capture interim and final transcription results
   - Detect language from recognition result
3. **Update Recording Page:**
   - Display live transcription text below waveform while recording
   - Show detected language indicator
   - Visual feedback when speech is detected vs silence
4. **Update recording flow:**
   - User records → speech is transcribed in real-time
   - User taps "Save" → transcription + audio saved to Hive note
   - Navigate to Note Detail to view saved note
5. **Handle edge cases:**
   - Microphone permission denied → show permission dialog
   - No speech detected → save note with empty transcription, allow manual entry
   - Long recordings → handle speech_to_text session timeouts by auto-restarting listener

### Deliverables:
- Recording → On-device transcription → Saved Note flow works end-to-end
- Language auto-detected
- No API key or internet connection required

### Estimated effort: Medium

---

## Step 6: Waveform, Audio Playback & Notifications ✅ COMPLETED

**Goal:** Polish the recording experience and add reminder notifications.

### Tasks:
1. **Waveform visualizer:**
   - Add `audio_waveforms` package
   - Display real-time waveform on Recording Page
   - Replace or complement current amplitude-based visualization
   - Smooth animation, matches app's warm design language

2. **Audio playback on Note Detail:**
   - Add `just_audio` package
   - Play/pause/seek controls on Note Detail screen
   - Show playback progress bar
   - Display recording duration

3. **Reminder notifications:**
   - Add `flutter_local_notifications` package
   - Manual reminder creation — user picks date/time from Note Detail
   - Notification taps open the relevant note
   - Respect quiet hours from settings
   - Cancel notifications when reminder marked complete

### Deliverables:
- Rich waveform visualization during recording
- Audio playback from note detail screen
- Manual reminders trigger device notifications at scheduled times

### Estimated effort: Medium

---

## Step 7: Testing, Polish & Release Prep ✅ COMPLETED

**Goal:** Ensure quality, fix edge cases, prepare for release.

### Tasks:
1. **Unit tests:**
   - Test Hive repository CRUD operations
   - Test transcription service
   - Test provider state management

2. **Widget tests:**
   - Test key UI flows (record → save → view note)
   - Test filter/search behavior
   - Test settings persistence

3. **Integration tests:**
   - End-to-end: record → transcribe (on-device) → save → search
   - Reminder notification scheduling

4. **Edge cases & error handling:**
   - Very long recordings (>30 min)
   - Empty recordings (user records silence)
   - Mixed-language edge cases
   - Hive corruption recovery
   - Low storage scenarios

5. **Performance:**
   - Profile app startup time (Hive initialization)
   - Ensure smooth scrolling with large note lists
   - Optimize recording memory usage

6. **Accessibility:**
   - Screen reader support for all interactive elements
   - Sufficient color contrast in both themes
   - Semantic labels on icons and buttons

7. **Release preparation:**
   - Create proper app icon
   - Write App Store / Play Store descriptions
   - Take screenshots for store listings
   - Set up signing configs (Android keystore, iOS provisioning)
   - Configure ProGuard rules for release build
   - Test release builds on physical devices

### Deliverables:
- Test coverage for critical paths
- App stable on both iOS and Android
- Ready for store submission

### Estimated effort: Large

---

# PHASE 1 — Value Proposition Gaps (Pre-Launch Enhancements)

**Spec:** [FEATURE_PHASE1_VALUE_GAPS.md](FEATURE_PHASE1_VALUE_GAPS.md)

These 8 features address competitive gaps that users expect at launch. They require no AI and remain fully on-device/privacy-first.

---

## Step 8: Pinned Notes + AMOLED Dark Theme + Auto-Title Generation ⬜ PENDING

**Goal:** Three small, independent features that can be implemented in parallel.

### Sub-step A: Pinned Notes

**Goal:** Allow users to pin important notes to the top of the Home page feed.

#### Tasks:
1. Add `isPinned` (bool) and `pinnedAt` (DateTime?) fields to Note Hive model → `build_runner`
2. Update `notesProvider` to return pinned list (sorted by `pinnedAt` desc) and unpinned list (sorted by `createdAt` desc)
3. Add "Pinned" section header (collapsible, with count badge) above regular notes feed on Home page
4. Add pin icon on pinned note cards (top-right corner)
5. Add "Pin to Top" / "Unpin" action in:
   - Long-press note card overflow menu
   - Note Detail AppBar overflow menu
   - Multi-select bottom action bar
6. Enforce max 10 pinned notes with warning SnackBar
7. Pinned notes still appear in folder views and search (without special positioning)

#### New files:
- `lib/widgets/pinned_section_widget.dart` — Pinned section header + list

#### Modified files:
- `lib/models/note.dart` — Add `isPinned`, `pinnedAt` HiveFields
- `lib/providers/notes_provider.dart` — Pinned/unpinned split
- `lib/pages/home_page.dart` — Pinned section above feed
- `lib/pages/note_detail_page.dart` — Pin/unpin in overflow menu

### Sub-step B: AMOLED Dark Theme

**Goal:** Add a pure black theme option for OLED screens.

#### Tasks:
1. Create `amoledDarkTheme` ThemeData in `lib/theme.dart` — copy `darkTheme`, override scaffold/surface/card/appbar backgrounds to `#000000`, cards to `#0A0A0A`, dividers to `#1A1A1A`
2. Add theme option to `UserSettings` model (string field: `'light'`, `'dark'`, `'amoled'`, `'system'`)
3. Update `MaterialApp` to select between three theme data objects
4. Update Settings → Appearance theme picker to show 4 options (Light, Dark, AMOLED Dark, System)

#### Modified files:
- `lib/theme.dart` — Add `amoledDarkTheme`
- `lib/models/user_settings.dart` — Add theme mode field
- `lib/providers/settings_provider.dart` — Expose new theme
- `lib/main.dart` — Select theme in MaterialApp
- `lib/pages/preferences_page.dart` — Theme picker update

### Sub-step C: Auto-Title Generation

**Goal:** Generate meaningful, scannable titles from transcription text using local heuristics (no AI).

#### Tasks:
1. Create `TitleGeneratorService` — pure Dart utility class
2. Implement algorithm: strip filler phrases → extract first meaningful sentence → apply fallback patterns (task-based titles) → truncate at 60 chars at word boundary
3. Call after transcription is finalized (both live STT and Whisper modes)
4. Only auto-generate if user has not manually edited the title
5. Add `isUserEditedTitle` flag to Note model to track manual edits

#### New files:
- `lib/services/title_generator_service.dart`

#### Modified files:
- `lib/models/note.dart` — Add `isUserEditedTitle` HiveField
- `lib/pages/recording_page.dart` — Call title generator after transcription
- `lib/pages/note_detail_page.dart` — Set `isUserEditedTitle = true` on manual title edit

### Estimated effort: Small (all three combined)

---

## Step 9: Note Templates ⬜ PENDING

**Goal:** Offer built-in note templates that pre-populate new text notes with structured placeholders.

### Tasks:
1. Create `NoteTemplate` data class and `lib/constants/note_templates.dart` with 6 built-in templates:
   - Meeting Notes, Daily Journal, Idea Capture, Grocery List, Project Planning, Quick Checklist
2. Create `TemplatePickerSheet` bottom sheet widget — shows Blank Note + 6 templates with icons
3. Integrate with SpeedDialFab "New Text Note" action — show template picker first
4. Pre-fill Quill Delta content in new note from selected template
5. Auto-generate title from template name (e.g., "Meeting Notes — Mar 2, 2026")

### New files:
- `lib/constants/note_templates.dart` — Template definitions
- `lib/widgets/template_picker_sheet.dart` — Bottom sheet picker UI

### Modified files:
- `lib/pages/home_page.dart` — SpeedDialFab "New Text Note" shows picker
- `lib/pages/note_detail_page.dart` — Accept pre-filled template content

### Estimated effort: Small

---

## Step 10: Trash / Soft Delete ⬜ PENDING

**Goal:** Replace permanent deletion with a Trash system offering 30-day recovery.

### Sub-step A: Data Model Changes

#### Tasks:
1. Add to Note model: `isDeleted` (bool), `deletedAt` (DateTime?), `previousFolderId` (String?), `previousProjectIds` (List<String>?)
2. Add to Folder model: `isDeleted` (bool), `deletedAt` (DateTime?)
3. Add to ProjectDocument model: `isDeleted` (bool), `deletedAt` (DateTime?)
4. Run `build_runner` for Hive adapter regeneration
5. Data migration: existing items get `isDeleted = false` by default

### Sub-step B: Repository & Provider Filtering

#### Tasks:
1. Update all note/folder/project queries to filter out `isDeleted == true` items
2. Add `softDeleteNote()`, `softDeleteFolder()`, `softDeleteProject()` methods to repositories
3. Add `restoreFromTrash()` methods — re-link to original folder/projects
4. Add `permanentlyDelete()` methods — actual Hive removal + file cleanup
5. Add `getTrashItems()` methods — return items where `isDeleted == true`
6. Add auto-purge logic on app launch — permanently delete items where `deletedAt` > 30 days ago
7. Update tasks provider to exclude tasks from trashed notes
8. Update search to exclude trashed items

### Sub-step C: Trash Screen UI

#### Tasks:
1. Create `TrashPage` with:
   - Header with item count
   - "Items are permanently deleted after 30 days" info bar
   - Sections for Notes, Folders, Projects (with counts)
   - Each item shows: title, "Deleted X days ago", days remaining badge
   - Swipe/overflow menu: Restore, Delete Permanently
   - "Empty Trash" button with confirmation dialog
2. Add route `/trash` to go_router
3. Add "Trash" entry to App Menu (3-dot overflow) with item count badge

### Sub-step D: Integration & Polish

#### Tasks:
1. Update all delete dialogs: "Move to Trash? You can restore within 30 days."
2. Add Undo SnackBar after soft delete (5 seconds): "Note moved to Trash [Undo]"
3. Project document blocks show "Note in Trash" placeholder for trashed notes (with Restore quick action)
4. Update storage display: show trash storage separately
5. "Delete All Data" in Danger Zone bypasses Trash (with explicit warning)
6. Stats cards exclude trashed items from counts

### New files:
- `lib/pages/trash_page.dart` — Trash screen

### Modified files:
- `lib/models/note.dart`, `lib/models/folder.dart`, `lib/models/project_document.dart` — Soft delete fields
- `lib/services/notes_repository.dart`, `lib/services/folders_repository.dart`, `lib/services/project_documents_repository.dart` — Soft delete/restore/purge
- `lib/providers/notes_provider.dart`, `lib/providers/folders_provider.dart`, `lib/providers/project_documents_provider.dart` — Query filtering
- `lib/providers/tasks_provider.dart` — Exclude trashed
- `lib/pages/home_page.dart` — Delete → soft delete, stats filtering
- `lib/pages/search_page.dart` — Exclude trashed
- `lib/pages/note_detail_page.dart` — Delete → soft delete
- `lib/pages/folders_page.dart` — Delete → soft delete
- `lib/pages/project_document_detail_page.dart` — Delete → soft delete, trashed note placeholder
- `lib/nav.dart` — Add `/trash` route

### Estimated effort: Medium

---

## Step 10.5: App Lock — PIN / Biometric ⬜ PENDING

**Goal:** Protect VoiceNotes AI with PIN and/or biometric authentication. Must be built before or in parallel with Home Screen Widget so Widget can read lock state for Widget Privacy.

**Spec:** [FEATURE_PHASE1_VALUE_GAPS.md — Feature 8](FEATURE_PHASE1_VALUE_GAPS.md)

### Sub-step A: Data Model & PIN Storage

#### Tasks:
1. Add to UserSettings model: `appLockEnabled` (bool), `appLockPinHash` (String?), `biometricEnabled` (bool), `autoLockTimeoutSeconds` (int, default 0 = immediately), `widgetPrivacyLevel` (String, default 'record_only')
2. Run `build_runner` for Hive adapter regeneration
3. Store PIN salt in `flutter_secure_storage` (not in Hive) — salted SHA-256 hash only, never raw PIN
4. Add `local_auth` and `crypto` dependencies

### Sub-step B: App Lock Service

#### Tasks:
1. Create `AppLockService` — manages lock state, timeout tracking, authentication orchestration
2. Use `WidgetsBindingObserver` to detect `didChangeAppLifecycleState` — track `lastBackgroundedAt` timestamp
3. Implement auto-lock logic: compare `lastBackgroundedAt` + timeout vs current time on resume
4. Lock screen is a full-screen overlay via `Navigator` (not a route — prevents back-button bypass)
5. Handle incoming notifications: lock screen → authenticate → navigate to deep-link target

### Sub-step C: Lock Screen UI

#### Tasks:
1. Create `LockScreenPage` — app logo (matching splash screen), "VoiceNotes AI" title, biometric auto-prompt (if enabled), "Use PIN" button
2. Create custom PIN keypad widget — obscured dots, 4-6 digit support, shake animation on wrong PIN
3. Implement biometric auth via `local_auth` — check `canCheckBiometrics`, handle success/failure, auto-fallback to PIN after 3 failed attempts
4. Implement progressive lockout: 30s → 1min → 5min cooldown after repeated wrong PINs (resets on app restart)
5. Background matches current theme (light/dark/AMOLED)

### Sub-step D: PIN Setup & Settings

#### Tasks:
1. Create `PinSetupPage` — create PIN flow (enter + confirm), change PIN flow, biometric enable prompt
2. Add Security section to Settings menu: App Lock toggle, Change PIN, Biometric Unlock toggle, Auto-Lock Timeout picker (Immediately / 1 min / 5 min / 15 min)
3. Widget Privacy picker (visible only when App Lock ON and widget active): Full / Record-Only / Minimal
4. Disabling App Lock requires current PIN/biometric confirmation
5. Show warning during setup: "If you forget your PIN, you'll need to reinstall the app. Make sure you have a backup first."

### Sub-step E: Task Switcher Protection & Notifications

#### Tasks:
1. Android: set `FLAG_SECURE` on window when App Lock enabled — hides content in task switcher
2. iOS: overlay blur when app enters background (via lifecycle observer)
3. Update notification service: use `VISIBILITY_SECRET` when App Lock enabled — shows "VoiceNotes AI reminder" without note content
4. Optional: FLAG_SECURE also blocks screenshots (user-configurable)

### New files:
- `lib/services/app_lock_service.dart` — Lock state, timeout, auth orchestration
- `lib/pages/lock_screen_page.dart` — PIN keypad + biometric prompt overlay
- `lib/pages/pin_setup_page.dart` — PIN creation and change flow
- `lib/widgets/widget_privacy_picker.dart` — Privacy level selector (for Widget × App Lock)

### Modified files:
- `lib/models/user_settings.dart` — App Lock fields (5 new HiveFields)
- `lib/main.dart` — Add `WidgetsBindingObserver` for auto-lock lifecycle
- `lib/services/notification_service.dart` — VISIBILITY_SECRET when locked
- Settings pages — New Security section
- `pubspec.yaml` — Add `local_auth`
- `android/app/src/main/AndroidManifest.xml` — FLAG_SECURE support

### New dependencies: `local_auth`, `crypto` (dart:crypto)

### Estimated effort: Medium

---

## Step 10.6: Home Screen Widget ✅ COMPLETED

**Goal:** Provide one-tap voice recording from the home screen and glanceable note/task stats. Widget behavior adapts when App Lock (Step 10.5) is enabled via Widget Privacy setting.

**Spec:** [FEATURE_PHASE1_VALUE_GAPS.md — Feature 4](FEATURE_PHASE1_VALUE_GAPS.md)

### Tasks:
1. Add `home_widget` dependency
2. Implement Small widget (2×1): App icon + "Tap to Record" → deep-links to Recording screen (unaffected by App Lock — no content displayed)
3. Implement Dashboard widget (4×2): Record button + note count + open task count + latest note preview
4. Android: widget layout XML, `AppWidgetProvider`, deep-link intent `voicenotesai://record`
5. iOS: WidgetKit extension, SwiftUI widget, app group for shared data
6. Background data refresh via WorkManager (every 30 min) or on app foreground
7. Widget update triggers on note creation/deletion
8. **App Lock integration:** Widget reads App Lock + Widget Privacy settings to determine display mode:
   - App Lock OFF → full display
   - App Lock ON + "Full" → show everything (user accepted tradeoff)
   - App Lock ON + "Record-Only" (default) → counts only, no text preview
   - App Lock ON + "Minimal" → icon + "Tap to Record" only
9. Record tap: skip App Lock in Full/Record-Only modes (recording is write-only); require auth in Minimal mode
10. Content tap (counts/preview): always show App Lock screen first if enabled
11. First-time Widget Privacy prompt when user enables App Lock while widget is active (or adds widget while App Lock is on)

### New files:
- `android/app/src/main/res/layout/widget_small.xml`
- `android/app/src/main/res/layout/widget_dashboard.xml`
- Android `AppWidgetProvider` classes
- iOS widget extension files

### Modified files:
- `pubspec.yaml` — Add `home_widget`
- `lib/main.dart` — Widget data refresh hooks

### New dependency: `home_widget`

### Estimated effort: Medium

---

## Step 10.7: Local Backup & Restore ✅ DONE

**Goal:** Allow users to export their entire database as an encrypted archive and restore from it.

### Sub-step A: Backup Service

#### Tasks:
1. Add `toMap()` / `fromMap()` serialization methods to all Hive models (Note, Folder, ProjectDocument, UserSettings, and nested models)
2. Create `BackupService` — serializes all Hive boxes to JSON, collects audio/image files, creates ZIP archive, encrypts with AES-256 using user passphrase (PBKDF2 key derivation)
3. File format: `.vnbak` (renamed ZIP) containing `manifest.json`, `data/*.json`, `audio/*`, `images/*`
4. `manifest.json` includes: appVersion, backupFormatVersion, creation timestamp, note/folder/project counts, total file count
5. Process in isolate to avoid UI jank; emit progress events

### Sub-step B: Restore Service

#### Tasks:
1. Decrypt `.vnbak` file with user passphrase
2. Validate ZIP integrity and `manifest.json` before proceeding
3. Check version compatibility (warn if from newer app version)
4. Preview screen: show backup date, counts, total size
5. Clear all existing Hive boxes → populate from backup JSON → copy audio/image files to app directories
6. Apply data migration logic for backups from older versions
7. Restart app after restore

### Sub-step C: Backup & Restore UI

#### Tasks:
1. Create `BackupRestorePage` with:
   - "Last backup: [date] ([size])" or "No backups created"
   - "Create Backup" button → passphrase dialog (with confirm, strength indicator, warning) → progress → share sheet
   - "Restore from Backup" button → warning dialog (offer "Create Backup First") → file picker → passphrase → preview → restore → progress → restart
2. Add route `/backup_restore` to go_router
3. Add "Backup & Restore" entry to Settings → Data & Storage (between Storage and Danger Zone)
4. Add `lastBackupDate` to UserSettings model

### New files:
- `lib/services/backup_service.dart` — Backup & restore logic
- `lib/pages/backup_restore_page.dart` — UI

### Modified files:
- All Hive models — Add `toMap()` / `fromMap()` methods
- `lib/models/user_settings.dart` — Add `lastBackupDate` HiveField
- `lib/nav.dart` — Add `/backup_restore` route
- Settings page — Add Backup & Restore section
- `pubspec.yaml` — Add `archive`, `encrypt`

### New dependencies: `archive`, `encrypt`

### Estimated effort: Medium-Large

---

# PHASE 2 — AI-Powered Features (Requires n8n / Cloud APIs)

---

## Step 11: AI Transcription (Whisper API)

**Goal:** Add high-accuracy cloud transcription as an upgrade over on-device STT.

### Tasks:
1. Integrate Whisper API (OpenAI) for batch transcription after recording
2. Hybrid approach: on-device STT for live preview, Whisper for final accurate text
3. Offline queue — save unprocessed notes, transcribe when internet available
4. Queue indicator on Home screen
5. Auto-process queue when connectivity detected

### API Configuration:
- API key stored securely (flutter_secure_storage or dart_define env)
- Stateless — no user-identifying data sent beyond the audio
- Configurable endpoint for future n8n integration

---

## Step 12: AI Categorization & Structuring

**Goal:** Parse transcriptions into actions, todos, reminders, and general notes using AI.

### Tasks:
1. **Create AI service** — `lib/services/ai_structuring_service.dart`
   - Stateless API call to OpenAI or Anthropic
   - Prompt engineering for extraction of actions, todos, reminders, general notes
   - Extract topics for contextual grouping
   - Detect follow-up trigger phrases
   - Generate follow-up questions only if trigger detected

2. **AI prompt design:**
   ```
   You are a note structuring assistant. Given a voice note transcription,
   extract and categorize into:
   1. Actions — specific things to do
   2. Todos — task items (include due dates if mentioned)
   3. Reminders — time-based reminders
   4. General Notes — everything else
   5. Topics — key subjects/projects/people mentioned
   6. Follow-up Questions — only if the user asked for suggestions

   Return as structured JSON. Be precise. Do not invent items.
   ```

3. **Auto-folder assignment:**
   - After AI returns topics, compare against existing folder topics
   - If match found (fuzzy matching), auto-assign note to folder
   - If new topic, create auto-generated folder

4. **Auto-reminder extraction:**
   - When AI detects "remind me to..." or time-based phrases
   - Auto-schedule local notification from extracted date/time

5. **Follow-up questions:**
   - Check `hasFollowUpTrigger` flag
   - Display AI-generated questions in Note Detail

---

## Step 13: n8n Integration & Advanced Features

**Goal:** Connect to n8n workflows for extensibility.

### Tasks:
1. n8n webhook integration for transcription + structuring pipeline
2. AI-generated folder summaries
3. Smart search (semantic search across notes)
4. Export capabilities (PDF, text, email)
5. Multi-device sync considerations

---

## Phase Summary

```
PHASE 1 — On-Device (No AI)
├── Step 1: Project Alignment & Branding ────── [Small]  ✅ DONE
├── Step 2: State Management (Riverpod) ─────── [Medium] ✅ DONE
├── Step 3: Data Models & Hive Database ─────── [Medium] ✅ DONE
├── Step 4: Wire UI to Data Layer ───────────── [Large]  ✅ DONE
├── Step 4.5: Project Documents ─────────────── [Large]  ✅ DONE
│   ├── A: Data Model & Storage
│   ├── B: Repository & Provider Layer
│   ├── C: UI — Project Documents List
│   ├── D: UI — Project Document Detail
│   ├── E: UI — Note Picker & Supporting Screens
│   └── F: Integration & Polish
├── Step 4.6: Interactive Tasks & Reminders ──── [Med-Lg] ✅ DONE
│   ├── A: Interactive Checkboxes on Note Detail
│   ├── B: Checkboxes in Project Document Blocks
│   ├── C: Aggregated Tasks View (Home tab)
│   ├── D: Reminder Enhancement (Hybrid Model)
│   └── E: Polish & Integration
├── Step 4.7: Sharing, Rich Text & Images ────── [Large]  ✅ DONE
│   ├── A: Data Model & Storage Extensions
│   ├── B: Repository & Provider Extensions
│   ├── C: UI — Sharing & Export
│   ├── D: UI — Rich Text Formatting
│   ├── E: UI — Image Blocks (Projects)
│   ├── F: Note Detail — Photo Attachments
│   └── G: Integration & Polish
├── Step 5: On-Device Speech-to-Text ────────── [Medium] ✅ DONE
├── Step 6: Waveform, Playback & Notifications ─ [Medium] ✅ DONE
└── Step 7: Testing, Polish & Release ────────── [Large]  ✅ DONE
    + Bonus: Splash Screen & Multi-page Quick Guide
    + Bonus: Settings Overhaul (pickers, storage, danger zone)
    + Bonus: Compact AppBar Headers across all pages
    + Bonus: Voice Commands (auto-link to folder/project)
    + Bonus: Unified Library (folders + projects)
    + Bonus: Whisper UX (auto-scroll + flash highlight)
    + Post-Release: Issues #7–#12 (multi-select, layout,
      sectioned search, project rich text, share preview + PDF,
      word count, find & replace, profanity filter)
    + Post-Release: UI Polish & Voice Command Fixes
      (Todo normalization, stats tile consistency, storage
      layout, voice commands help, whisper cancel button,
      keep-screen-awake default)
    + Post-Release: Note Detail Refactor
      (Tab system for Actions/Todos/Reminders/Photos,
      simplified audio player, metadata two-row layout,
      photo grid, onboarding logo animation,
      share preview rich text fix)
    + Post-Release: Rich Text Version History &
      Picker Enhancements (richContentJson in
      TranscriptVersion, QuillEditor preview in
      version history, restore rich/plain, inline
      New Folder/New Project in all pickers)
                                                    │
                                             PHASE 1 CORE COMPLETE (v1.0.0)

PHASE 1 — Value Proposition Gaps (Pre-Launch)
├── Step 8: Pinned Notes + AMOLED + Auto-Title ── [Small]
├── Step 9: Note Templates ───────────────────── [Small]
├── Step 10: Trash / Soft Delete ─────────────── [Medium]
├── Step 10.5: App Lock (PIN/Biometric) ──────── [Medium]
├── Step 10.6: Home Screen Widget ────────────── [Medium]  ✅ DONE
└── Step 10.7: Local Backup & Restore ────────── [Medium-Large]  (includes App Lock settings)
    (Spec: FEATURE_PHASE1_VALUE_GAPS.md — 8 features)
                                                    │
                                             PHASE 1 RELEASE (Play Store)

PHASE 2 — AI-Powered
├── Step 11: Whisper API Transcription ─────────── [Medium]
├── Step 12: AI Categorization & Structuring ───── [Large]
└── Step 13: n8n Integration & Advanced ────────── [Large]
    + Project Documents Phase 2: AI summary, AI-suggested note additions
    + Tasks Phase 2: AI auto-extraction, smart due dates, recurring reminders,
      priority levels, Todoist/Apple Reminders API/Google Tasks API
    (Note: voice commands moved to Phase 1 — v1.3.0)
    (Note: sharing/export + rich text + images moved to Phase 1 — Step 4.7)
    (Note: PDF export moved to Phase 1 — Issue #11, v1.15.0)
                                                    │
                                             PHASE 2 RELEASE
```

---

## Decisions to Make

| # | Decision | Phase | Options | Impact |
|---|---|---|---|---|
| 1 | ~~State management~~ | 1 | ~~Riverpod~~ | ✅ Decided |
| 2 | On-device STT language scope | 1 | All supported vs top 10 | Affects recording UX |
| 3 | Whisper API vs Google Cloud STT | 2 | Whisper (batch) vs Google (streaming) | Affects transcription quality |
| 4 | AI provider | 2 | OpenAI vs Anthropic | Affects structuring quality and cost |
| 5 | API key management | 2 | flutter_secure_storage vs dart_define env | Affects security approach |
| 6 | ~~Step numbering~~ | 1 | ~~Renumber Phase 2 to 11-13~~ | ✅ Decided — Steps 8-10.6 for value gaps |

---

## Risk Register

| Risk | Phase | Mitigation |
|---|---|---|
| On-device STT accuracy varies by language | 1 | Allow manual editing of transcription |
| speech_to_text session timeout on long recordings | 1 | Auto-restart listener, stitch results |
| Hive database corruption | 1 | Implement integrity checks, backup mechanism |
| Large note lists slow down UI | 1 | Lazy loading, pagination |
| Whisper API costs escalate with usage | 2 | Monitor per-note cost, keep on-device as default |
| AI categorization quality varies | 2 | Invest in prompt engineering, allow manual override |
| Large recordings fail API upload | 2 | Chunked uploads, max recording duration |
| Mixed-language detection unreliable | 2 | Default to user-preferred language for ambiguous segments |
| Backup passphrase loss = unrecoverable backup | 1 | Clear warning during backup creation; no recovery mechanism by design (privacy-first) |
| Soft delete increases storage usage (30-day retention) | 1 | Show trash storage in storage display; allow manual empty |
| Home screen widget platform differences (Android vs iOS) | 1 | Implement Android first; iOS WidgetKit as follow-up if needed |
