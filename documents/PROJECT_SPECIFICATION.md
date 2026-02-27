# VoiceNotes AI - Project Specification

**Version:** 2.2
**Last Updated:** 2026-02-27
**Platform:** Cross-platform (iOS + Android) via Flutter
**Dart SDK:** ^3.6.0
**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [VoiceNotes AI Concept Document](voicenotes-ai-concept.md)

---

## 1. Product Overview

VoiceNotes AI is a **privacy-first, voice-driven** note-taking and task management mobile app. Users capture thoughts, tasks, and ideas by voice. The app transcribes audio in real-time, auto-detects the spoken language, and intelligently structures content into actions, todos, reminders, and general notes — without requiring the user to type a single word.

**Core Principles:**
- **Privacy-first** — All data stored locally on-device (Hive). AI interactions are stateless with zero data retention.
- **No ads, ever** — Revenue through fair freemium model only.
- **Voice as primary interface** — Every core feature is voice-accessible.
- **Generous free tier** — All core features free. No login required for MVP.

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

## 4. MVP Screens & Features (Phase 1)

> **No login required.** App is fully functional without account creation.

### 4.1 Onboarding Screen (Quick Guide)
- 5-page swipeable Quick Guide: Welcome, Record & Transcribe, Organize Your Way, Prepare Your App (Whisper setup), Privacy First
- Skip button on first run, dot page indicators
- Accessible again from Settings
- "Prepare Your App" page checks Whisper model status and offers a "Let's Set It Up" button that navigates to Settings with auto-scroll + highlight on the download section
- Navigation directly to Home (no login gate)

### 4.2 Login Screen
> **STATUS: NOT IN USE (Phase 1 MVP)**
> This screen exists in the codebase but is not part of the MVP flow. No authentication is required. Will be activated in Phase 2 when optional accounts are introduced.

### 4.3 Home / Dashboard
- **Prominent floating "Record" button** — large mic icon, bottom center, always visible
- **Recent notes feed** — cards in reverse chronological order showing:
  - Auto-generated title (derived from content)
  - Date/time of recording
  - Detected language tag (small pill/badge)
  - Category icons (action, todo, reminder, note)
  - Brief transcription preview (first 2 lines)
- **Search bar** — top of screen, searches by keyword, language, category, date
- **Filter chips** — below search bar: All, Actions, Todos, Reminders, Notes

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
  - **Actions** — extracted from "I need to...", "let's make sure we...", "action item:..."
  - **Todos** — task items with optional due dates ("by Friday"). Each has checkbox.
  - **Reminders** — from "remind me to...", "don't forget...". Shows scheduled time.
  - **General Notes** — everything else, preserved as formatted text.
- **AI Follow-up Questions** — shown only when user includes voice trigger ("any suggestions?", "what should I consider?", "what am I missing?"). 2-3 contextually relevant questions.
- **Edit capability** — user can manually edit transcription or structured items
- **Audio playback** — replay original recording from this screen
- **Delete note** — with confirmation prompt

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
- Full-text search across all notes
- Filter by keyword, date, language, category, conversation/topic

### 4.9 Settings Screen
- **PREFERENCES section:**
  - Your Name — speaker label for transcription timestamps
  - Note Prefix — prefix for auto-generated note names (e.g., "VOICE" → VOICE001)
  - Language Detection — 13 languages + Automatic (auto-detect)
  - Theme — System / Light / Dark with live switching
- **AUDIO section:**
  - Audio Quality — Standard / High Quality picker
  - Transcription Mode — Live Transcription or Record & Transcribe (Whisper)
  - Whisper Model Status — download status/progress (visible only when Whisper mode selected); supports auto-scroll + flash highlight when navigated from recording popup or onboarding
  - Default Folder — picker to choose default folder for new recordings
  - Voice Commands — toggle for "Folder/Project \<name\> Start" voice command parsing (Whisper mode only)
- **NOTIFICATIONS section:**
  - Enable/disable reminders
- **STORAGE section:**
  - Storage utilization showing actual disk usage (Hive data + recordings)
- **DANGER ZONE section:**
  - Delete All Data — with confirmation dialog, clears all notes, folders, projects, settings, and cancels notifications
- **Quick Guide** — button to re-open onboarding pages

### 4.10 Project Documents List Screen
- **"New Project" button** — prominent FAB or top button
- **Project document cards** — title, description preview, linked note count, last updated timestamp
- **Empty state** — illustration + "Create your first project document" prompt
- **Search** — filter project documents by title/description keyword
- **Access:** From Home page (navigation alongside Folders)

### 4.11 Project Document Detail Screen
- **Scrollable canvas** displaying all blocks (note references, free text, section headers) in user-defined order
- **Header area:** editable title, description, metadata (created, updated, block count), action buttons
- **Note Reference Block:** mic icon, original recording timestamp, language badge, linked note title, full editable transcript, audio duration, overflow menu (remove, view original, version history)
- **Free-Text Block:** editable text area with pen icon, overflow menu (remove)
- **Section Header Block:** large/bold editable text with optional divider, overflow menu (remove)
- **Add Block action sheet:** Add Voice Note (opens note picker), Add Free Text, Add Section Header
- **Reorder Mode:** drag handles on each block, "Done" button to exit
- **Bi-directional editing:** editing a transcript within a project document creates a new version on the original note and updates it everywhere

### 4.12 Note Picker Screen
- **Multi-select** from all existing notes (reverse chronological)
- **Search bar** to filter by keyword
- **"Already linked" indicator** on notes already in the project
- **"Add Selected" button** to confirm and append as note_reference blocks

### 4.13 Transcript Version History Screen
- **Version list** showing: version number, date, edit source (e.g., "Note Detail", "Project: Kitchen Renovation")
- **Full text** per version
- **"Restore this version"** action — creates a new version with restored text (non-destructive)

---

## 5. Key Behaviors (Phase 1 MVP)

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

**Phase 2 behaviors (not yet implemented):** AI smart categorization, contextual grouping, follow-up intelligence, auto-folder assignment.

---

## 6. Technical Architecture

### 6.1 Framework & Language
- **Flutter** (Dart) for cross-platform UI
- Material Design 3 with custom theme (Plus Jakarta Sans, Inter fonts)

### 6.2 State Management
- **Riverpod 3.x** — Notifier/NotifierProvider pattern (migration from Provider completed in Step 2)
- 6 providers: notes, folders, settings, recording, connectivity, project_documents
- All providers backed by Hive repositories

### 6.3 Navigation
- **go_router** for declarative routing with extras for data passing
- Active routes: splash, onboarding, home, recording, note_detail, folders, folder_detail, settings, search, project_documents, project_document_detail, note_picker, version_history
- Inactive route (Phase 2): login
- Settings route accepts `highlightWhisper` extra for auto-scroll + flash highlight

### 6.4 Audio Recording
- **record** package (>=5.1.2) for audio capture
- Format: AAC-LC, 128kbps, 44.1kHz, M4A container
- Storage: `Documents/recordings/voicenote_[timestamp].m4a`
- Real-time amplitude monitoring via ValueNotifier

### 6.5 Local Database — Hive (Encrypted)
- **Hive** — lightweight, fast, no-SQL database for Flutter/Dart
- AES-256 encryption at rest with device-derived key
- Hive boxes for: notes, folders, settings, offline queue
- No cloud persistence in MVP

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

### 6.9 Notifications
- **flutter_local_notifications** for reminder alerts
- Manual reminder creation with date/time picker
- Scheduled notifications with deep-link to specific note on tap

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
└── projectDocumentIds: List<String> (reverse lookup for linked projects)

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
└── updatedAt: DateTime

UserSettings
├── defaultLanguage: String? (null = auto-detect)
├── audioQuality: String (standard / high)
├── notificationsEnabled: bool
├── quietHoursStartMinutes: int? (stored as minutes from midnight)
├── quietHoursEndMinutes: int? (stored as minutes from midnight)
├── themeMode: String (system / light / dark)
├── onboardingCompleted: bool
├── transcriptionMode: String (live / whisper)
├── speakerName: String (default: "Speaker 1")
├── notePrefix: String (default: "VOICE" → VOICE001, VOICE002...)
├── defaultFolderId: String? (ID of default folder for new recordings)
└── voiceCommandsEnabled: bool (parse voice commands in Whisper mode)

ProjectDocument
├── id: String (UUID)
├── title: String
├── description: String? (optional subtitle)
├── blocks: List<ProjectBlock> (ordered list — order = display order)
├── createdAt: DateTime
└── updatedAt: DateTime

ProjectBlock
├── id: String (UUID)
├── type: BlockType (note_reference | free_text | section_header)
├── sortOrder: int (position in the document)
├── noteId: String? (required when type = note_reference)
├── content: String? (required when type = free_text or section_header)
├── createdAt: DateTime
└── updatedAt: DateTime

TranscriptVersion
├── id: String (UUID)
├── text: String (transcript text at this version)
├── versionNumber: int (1, 2, 3...)
├── editSource: String (where the edit was made)
├── createdAt: DateTime
└── isOriginal: bool (true only for the first version from STT)
```

---

## 8. Permissions Required

| Permission | Platform | Purpose |
|---|---|---|
| Microphone | Android, iOS | Voice recording |
| Storage | Android | Save recordings locally |
| Notifications | Android, iOS | Reminder alerts |
| Internet | Android, iOS | Transcription and AI processing (transactional only) |

---

## 9. Project Documents — Relationship to Folders

| Aspect | Folders | Project Documents |
|---|---|---|
| **Purpose** | Organize / group notes | Compose / build a document from notes |
| **Note relationship** | A note belongs to one folder | A note can appear in many project documents |
| **Content** | Container of note references | Rich canvas: note transcripts + free text + headers |
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
| Quick capture widget | Phase 2 |
| Export (Markdown, PDF, plain text) | Phase 2 |
| AI-generated Project Document summary | Phase 2 |
| AI-suggested note additions for projects | Phase 2 |
| ~~Voice command to add note to project~~ | ~~Phase 2~~ → **Implemented in Phase 1** (v1.3.0) |
| Project Document export (Markdown/PDF) | Phase 2 |
| Music note capture | Phase 3 |
| Smart automations | Phase 3 |
| Ambient listening mode | Phase 3 |
| Collaborative features | Phase 3 |
| Template-based capture | Phase 3 |
| Third-party integrations (CRM, calendars) | Phase 3 |

---

## 11. MVP Tech Stack (Phase 1 — Actual)

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
| connectivity_plus | Network status monitoring | Active |
| cupertino_icons | iOS-style icons | Active |
| hive_generator + build_runner | Hive model code generation (dev) | Active |
