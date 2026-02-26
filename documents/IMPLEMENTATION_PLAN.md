# VoiceNotes AI - Implementation Plan

**Version:** 2.2
**Last Updated:** 2026-02-26
**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Project Documents Feature Spec](FEATURE_PROJECT_DOCUMENTS.md)

---

## Overview

This plan is split into two phases:

- **Phase 1 (On-Device):** A fully functional voice note-taking app with recording, on-device transcription, local storage, folders, search, playback, and notifications — all without any AI/cloud dependency.
- **Phase 2 (AI-Powered):** Adds AI categorization, smart structuring, Whisper API transcription, auto-folder assignment, and n8n integration.

**Current state:** Phase 1 core complete (all 7 steps done + bonus features). Step 4.5 (Project Documents) approved for development.
**Phase 1 target:** Privacy-first voice note app with on-device transcription, local Hive storage, audio playback, reminder notifications, and project documents. **Core achieved; Project Documents pending.**

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

## Step 4.5: Project Documents ⏳ APPROVED — NOT YET STARTED

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

# PHASE 2 — AI-Powered Features (Requires n8n / Cloud APIs)

---

## Step 8: AI Transcription (Whisper API)

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

## Step 9: AI Categorization & Structuring

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

## Step 10: n8n Integration & Advanced Features

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
├── Step 4.5: Project Documents ─────────────── [Large]  ⏳ APPROVED
│   ├── A: Data Model & Storage
│   ├── B: Repository & Provider Layer
│   ├── C: UI — Project Documents List
│   ├── D: UI — Project Document Detail
│   ├── E: UI — Note Picker & Supporting Screens
│   └── F: Integration & Polish
├── Step 5: On-Device Speech-to-Text ────────── [Medium] ✅ DONE
├── Step 6: Waveform, Playback & Notifications ─ [Medium] ✅ DONE
└── Step 7: Testing, Polish & Release ────────── [Large]  ✅ DONE
    + Bonus: Splash Screen & Multi-page Quick Guide
    + Bonus: Settings Overhaul (pickers, storage, danger zone)
    + Bonus: Compact AppBar Headers across all pages
                                                    │
                                             PHASE 1 RELEASE (after Step 4.5)

PHASE 2 — AI-Powered
├── Step 8: Whisper API Transcription ────────── [Medium]
├── Step 9: AI Categorization & Structuring ──── [Large]
└── Step 10: n8n Integration & Advanced ──────── [Large]
    + Project Documents Phase 2: AI summary, export, voice commands
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
