# VoiceNotes AI - Implementation Plan

**Version:** 1.0
**Last Updated:** 2026-02-25
**Scope:** MVP (Phase 1) — Full implementation roadmap
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md)

---

## Overview

This plan covers the complete implementation path from the current UI-only scaffold to a fully functional MVP. Work is organized into 8 sequential steps. Each step builds on the previous one.

**Current state:** UI shells for all screens + working audio recorder.
**Target state:** Privacy-first voice note app with transcription, AI categorization, local Hive storage, offline support, and reminder notifications.

---

## Step 1: Project Alignment & Branding Fixes

**Goal:** Align the codebase with the concept document before building new features.

### Tasks:
1. **Update Android app label** — Change "dreamflow" to "VoiceNotes AI" in `android/app/src/main/AndroidManifest.xml`
2. **Update iOS app name** — Update display name in `ios/Runner/Info.plist`
3. **Fix app title** — Set `title: 'VoiceNotes AI'` in `lib/main.dart`
4. **Rename app icon** — Rename `dreamflow_icon.jpg` to `voicenotes_ai_icon.jpg` (or replace with proper icon) and update all references
5. **Mark login_page.dart as Not In Use** — Add header comment indicating it's a Phase 2 feature
6. **Update onboarding flow** — Onboarding should navigate to Home, not Login
7. **Update initial route** — Consider whether to keep onboarding or go directly to Home after first launch
8. **Clean up pubspec.yaml** — Update description, verify all dependency versions

### Deliverables:
- App displays "VoiceNotes AI" everywhere
- Login page clearly marked as not in use
- Onboarding → Home flow (no login gate)

### Estimated effort: Small

---

## Step 2: State Management Migration

**Goal:** Replace Provider with Riverpod (or Bloc) as specified in the concept document.

### Decision Required: Riverpod vs Bloc
| Criteria | Riverpod | Bloc |
|---|---|---|
| Boilerplate | Less | More |
| Learning curve | Moderate | Steeper |
| Testability | Excellent | Excellent |
| Community | Growing fast | Well-established |
| Compile-safe | Yes | Yes |
| **Recommendation** | **Riverpod** | — |

### Tasks:
1. **Add riverpod dependencies** — `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` (dev)
2. **Remove provider dependency** from pubspec.yaml
3. **Wrap app with ProviderScope** in `main.dart`
4. **Create initial providers:**
   - `settingsProvider` — user preferences (language, audio quality, theme)
   - `notesProvider` — CRUD for notes (will connect to Hive in Step 3)
   - `foldersProvider` — folder management
   - `recordingStateProvider` — recording session state
   - `connectivityProvider` — network status
5. **Update all pages** to use `ConsumerWidget` / `ConsumerStatefulWidget`

### Deliverables:
- Riverpod fully wired across all active pages
- Provider dependency removed
- All state reactive and testable

### Estimated effort: Medium

---

## Step 3: Data Models & Hive Database

**Goal:** Implement persistent local storage with encrypted Hive.

### Tasks:
1. **Add dependencies:**
   - `hive: ^2.2.3`, `hive_flutter: ^1.1.0`
   - `hive_generator` (dev), `build_runner` (dev)
   - `uuid` for unique IDs
2. **Create Hive model classes** in `lib/models/`:
   - `note.dart` — Note with HiveType annotation
   - `action_item.dart` — ActionItem
   - `todo_item.dart` — TodoItem
   - `reminder_item.dart` — ReminderItem
   - `folder.dart` — Folder
   - `user_settings.dart` — UserSettings
3. **Generate Hive adapters** — Run `build_runner` to generate `.g.dart` files
4. **Initialize Hive in main.dart:**
   - Call `Hive.initFlutter()` before `runApp`
   - Register all type adapters
   - Open encrypted boxes (generate encryption key from device)
5. **Create repository layer** in `lib/services/`:
   - `notes_repository.dart` — CRUD operations for notes
   - `folders_repository.dart` — CRUD for folders
   - `settings_repository.dart` — Read/write settings
6. **Connect repositories to Riverpod providers** from Step 2
7. **Implement Hive box integrity check** on app start (corruption guard)

### File structure after this step:
```
lib/
├── models/
│   ├── note.dart
│   ├── note.g.dart (generated)
│   ├── action_item.dart
│   ├── action_item.g.dart (generated)
│   ├── todo_item.dart
│   ├── todo_item.g.dart (generated)
│   ├── reminder_item.dart
│   ├── reminder_item.g.dart (generated)
│   ├── folder.dart
│   ├── folder.g.dart (generated)
│   └── user_settings.dart
├── services/
│   ├── audio_recorder_service.dart (existing)
│   ├── notes_repository.dart
│   ├── folders_repository.dart
│   └── settings_repository.dart
```

### Deliverables:
- All data models defined with Hive annotations
- Encrypted Hive boxes for notes, folders, settings
- CRUD operations working through repository layer
- Data persists across app restarts

### Estimated effort: Medium

---

## Step 4: Wire UI to Data Layer

**Goal:** Connect all screen UIs to real Hive data through Riverpod providers.

### Tasks:
1. **Home Page:**
   - Display notes from Hive via `notesProvider`
   - Note cards show: title, date, language tag, category icons, preview text
   - Filter chips (All, Actions, Todos, Reminders, Notes) filter the note list
   - Search bar queries notes by keyword
   - Record button navigates to recording screen
   - Tapping a note card opens Note Detail

2. **Note Detail Page:**
   - Display full transcription from Hive note
   - Render structured sections (actions, todos, reminders, general notes)
   - Checkboxes toggle `isCompleted` and persist to Hive
   - Edit button allows editing transcription text
   - Delete button with confirmation dialog removes note from Hive
   - Show detected language label

3. **Folders Page:**
   - List all folders from `foldersProvider`
   - Show note count per folder
   - Create new folder dialog
   - Auto-generated folders labeled differently from manual ones

4. **Folder Detail Page:**
   - Display notes belonging to selected folder
   - Chronological timeline view
   - Folder rename/delete

5. **Settings Page:**
   - Read/write settings from Hive via `settingsProvider`
   - Language preference toggle (auto-detect vs specific)
   - Audio quality selector
   - Notification toggle
   - Storage usage display (calculate Hive box sizes + recording files)
   - Privacy dashboard (data summary, delete all data button)

6. **Search Page:**
   - Query notes by keyword (search rawTranscription, title, topics)
   - Filter by date range, language, category
   - Display results as note cards

### Deliverables:
- All screens display and mutate real persistent data
- CRUD operations work end-to-end through the UI
- Notes persist, appear in lists, can be edited and deleted

### Estimated effort: Large

---

## Step 5: Speech-to-Text Integration

**Goal:** Add real-time transcription to the recording flow.

### Decision Required: Whisper API vs Google Speech-to-Text
| Criteria | Whisper API (OpenAI) | Google Cloud STT |
|---|---|---|
| Language support | 99+ languages | 125+ languages |
| Auto language detection | Yes | Yes |
| Streaming support | No (batch only) | Yes (streaming) |
| Privacy | Stateless, no retention (with policy) | Configurable data logging |
| Cost | ~$0.006/min | ~$0.006-0.024/min |
| **Recommendation** | **For batch processing** | **For live preview** |

### Possible approach: Hybrid
- **Live preview:** Use on-device speech recognition (speech_to_text package) for rough real-time text
- **Final transcription:** Send completed recording to Whisper API for accurate, language-detected transcription

### Tasks:
1. **Add dependencies:**
   - `http` or `dio` for API calls
   - `speech_to_text` for on-device live preview (optional)
   - `connectivity_plus` for network status
2. **Create transcription service** — `lib/services/transcription_service.dart`
   - Method: `transcribe(String audioFilePath)` → returns `TranscriptionResult` (text + detected language)
   - Stateless API call — send audio, get text, done
   - Handle API errors gracefully
   - Support for Whisper API format (multipart file upload)
3. **Integrate live preview** (optional/stretch):
   - Use `speech_to_text` package for on-device recognition during recording
   - Display rough text in recording screen below waveform
   - This is an approximation — final transcription comes from Whisper
4. **Update recording flow:**
   - User taps "Save & Process"
   - Show processing indicator
   - Send audio to Whisper API
   - Receive transcription + language
   - Save to Hive note
   - Navigate to Note Detail
5. **Handle no-internet scenario:**
   - Save note with `isProcessed: false`
   - Add to offline queue
   - Show queue indicator on Home

### API Configuration:
- API key stored securely (flutter_secure_storage or dart env)
- Endpoint configurable for future n8n integration (Phase 2)
- No user-identifying data sent beyond the audio itself

### Deliverables:
- Recording → Transcription → Saved Note flow works end-to-end
- Language auto-detected
- Offline recordings queued for later processing

### Estimated effort: Large

---

## Step 6: AI Categorization & Structuring

**Goal:** Parse transcriptions into actions, todos, reminders, and general notes using AI.

### Tasks:
1. **Create AI service** — `lib/services/ai_structuring_service.dart`
   - Method: `structureNote(String transcription)` → returns structured JSON
   - Stateless API call to OpenAI or Anthropic
   - Prompt engineering for accurate extraction:
     - Actions: "I need to...", "we should...", "action item:..."
     - Todos: "by Friday...", "before the meeting...", task-like statements
     - Reminders: "remind me to...", "don't forget...", "remember to..."
     - General notes: everything else
   - Extract topics for contextual grouping
   - Detect follow-up trigger phrases ("any suggestions?", "what should I consider?")
   - Generate follow-up questions only if trigger detected

2. **Design the AI prompt** — Critical for quality:
   ```
   You are a note structuring assistant. Given a voice note transcription,
   extract and categorize the content into:
   1. Actions — specific things to do
   2. Todos — task items (include due dates if mentioned)
   3. Reminders — time-based reminders
   4. General Notes — everything else
   5. Topics — key subjects/projects/people mentioned
   6. Follow-up Questions — only if the user asked for suggestions

   Return as structured JSON. Be precise. Do not invent items not present
   in the transcription.
   ```

3. **Integrate with recording flow:**
   - After transcription (Step 5), send text to AI service
   - Parse JSON response into Hive model objects
   - Save structured note to Hive
   - Display on Note Detail screen

4. **Contextual grouping logic:**
   - After AI returns topics, compare against existing folder topics
   - If match found (fuzzy matching), auto-assign note to that folder
   - If new topic, create auto-generated folder
   - Store topic associations in folder model

5. **Follow-up questions:**
   - Check `hasFollowUpTrigger` flag
   - If true, display AI-generated questions in Note Detail
   - If false, hide the section entirely

### API Configuration:
- Same security practices as Step 5
- Stateless — no conversation memory, no data retention
- Configurable model (gpt-4o-mini for cost efficiency, or Claude Haiku)

### Deliverables:
- Transcriptions automatically categorized into actions/todos/reminders/notes
- Notes auto-filed into topic-based folders
- Follow-up questions shown when voice-triggered
- Complete recording → transcription → structuring → display pipeline

### Estimated effort: Large

---

## Step 7: Waveform, Audio Playback & Notifications

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
   - Playback position synced with transcription (stretch goal)

3. **Reminder notifications:**
   - Add `flutter_local_notifications` package
   - When AI extracts a reminder with a time, schedule a local notification
   - Notification taps open the relevant note
   - Respect quiet hours from settings
   - Cancel notifications when reminder marked complete

4. **Offline queue indicator:**
   - Show badge/indicator on Home when notes are pending processing
   - Auto-process queue when connectivity detected
   - Visual feedback when processing completes

### Deliverables:
- Rich waveform visualization during recording
- Audio playback from note detail screen
- Reminders trigger device notifications at scheduled times
- Offline queue visible and auto-processes

### Estimated effort: Medium

---

## Step 8: Testing, Polish & Release Prep

**Goal:** Ensure quality, fix edge cases, prepare for release.

### Tasks:
1. **Unit tests:**
   - Test Hive repository CRUD operations
   - Test AI response parsing
   - Test transcription service error handling
   - Test offline queue logic

2. **Widget tests:**
   - Test key UI flows (record → save → view note)
   - Test filter/search behavior
   - Test settings persistence

3. **Integration tests:**
   - End-to-end: record → transcribe → categorize → display → search
   - Offline → online queue processing
   - Reminder notification scheduling

4. **Edge cases & error handling:**
   - Very long recordings (>30 min)
   - Empty recordings (user records silence)
   - API failures (graceful fallback, retry logic)
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
   - Create proper app icon (replace dreamflow icon)
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

## Implementation Order Summary

```
Step 1: Project Alignment & Branding ──────────── [Small]  ← START HERE
   │
Step 2: State Management Migration (Riverpod) ─── [Medium]
   │
Step 3: Data Models & Hive Database ───────────── [Medium]
   │
Step 4: Wire UI to Data Layer ─────────────────── [Large]
   │
Step 5: Speech-to-Text Integration ────────────── [Large]
   │
Step 6: AI Categorization & Structuring ───────── [Large]
   │
Step 7: Waveform, Playback & Notifications ────── [Medium]
   │
Step 8: Testing, Polish & Release Prep ────────── [Large]
                                                      │
                                                  MVP READY
```

---

## Decisions to Make Before Starting

| # | Decision | Options | Impact |
|---|---|---|---|
| 1 | State management | Riverpod vs Bloc | Affects all providers and page widgets |
| 2 | STT provider | Whisper API vs Google STT vs hybrid | Affects transcription quality and live preview |
| 3 | AI provider | OpenAI vs Anthropic | Affects structuring quality and cost |
| 4 | API key management | flutter_secure_storage vs dart_define env | Affects security approach |
| 5 | Live transcription | On-device (speech_to_text) vs skip for MVP | Affects recording UX complexity |

---

## Risk Register

| Risk | Mitigation |
|---|---|
| Whisper API doesn't support streaming → no live preview | Use on-device speech_to_text for rough preview, Whisper for final |
| AI categorization quality varies | Invest in prompt engineering, allow manual re-categorization |
| Hive database corruption | Implement integrity checks, local backup mechanism |
| API costs escalate with usage | Monitor per-note cost, consider on-device models long-term |
| Large recordings fail API upload | Implement chunked uploads, set max recording duration |
| Mixed-language detection unreliable for short phrases | Default to user-preferred language for ambiguous segments |
