# VoiceNotes AI - Project Specification

**Version:** 2.0
**Last Updated:** 2026-02-25
**Platform:** Cross-platform (iOS + Android) via Flutter
**Dart SDK:** ^3.6.0
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

### 4.1 Onboarding Screen
- Welcome flow introducing key features (voice recording, AI structuring, privacy)
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
- **Waveform visualizer** — real-time audio waveform showing input levels
- **Live transcription preview** — text appears below waveform as user speaks
- **Pause / Resume button** — pause without ending session
- **Cancel button** — discard recording entirely
- **"Save & Process" button** — end recording, trigger AI processing
- **Recording timer** — elapsed time display

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

### 4.6 Conversations / Folders View
- **Auto-grouped conversations** — AI groups notes referencing same topic/project/person
- **Manual folders/tags** — user-created organizational folders
- **Auto-filing** — new notes matching existing topics auto-added to conversations
- **Conversation timeline** — chronological display within each conversation

### 4.7 Folder Detail Screen
- View all notes within a folder/conversation
- Folder management (rename, delete)

### 4.8 Search Screen
- Full-text search across all notes
- Filter by keyword, date, language, category, conversation/topic

### 4.9 Settings Screen
- **Language preferences** — default language or auto-detect
- **Audio quality** — standard vs high quality (affects storage)
- **Notification settings** — enable/disable reminders, quiet hours
- **Storage management** — view usage, clear old recordings (keep transcriptions), export data
- **Privacy dashboard** — view what data exists, delete all data, view AI processing policy
- **About / Help** — app version, FAQ, support contact

---

## 5. Key Behaviors (MVP)

| Behavior | Details |
|---|---|
| Auto language detection | Detects spoken language without user selection. Mixed-language notes transcribed per-segment. |
| Smart categorization | AI parses natural language cues to tag content as actions, todos, reminders, or general notes. No manual sorting. |
| Contextual grouping | AI compares new note content against existing notes and auto-links related topics into conversations. |
| Follow-up intelligence | Only activated by voice trigger. AI generates relevant follow-up questions based on note content. |
| Offline recording | Recording works without internet. Queue indicator shows pending items. Processing happens on reconnect. |
| Local-only storage | All data in Hive on-device. No cloud sync in MVP. |
| No login required | App fully functional without account creation or sign-in. |

---

## 6. Technical Architecture

### 6.1 Framework & Language
- **Flutter** (Dart) for cross-platform UI
- Material Design 3 with custom theme (Plus Jakarta Sans, Inter fonts)

### 6.2 State Management
- **Riverpod** or **Bloc** (to be decided — concept doc recommends either)
- Current codebase has Provider dependency — will need migration

### 6.3 Navigation
- **go_router** for declarative routing
- MVP active routes: onboarding, home, recording, note_detail, folders, folder_detail, settings, search
- Inactive route (Phase 2): login

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

### 6.6 Speech-to-Text
- **Whisper API** (stateless, transactional calls) or **Google Speech-to-Text API**
- Must support streaming transcription for live preview
- Must support auto language detection
- All interactions stateless — no data retention on server

### 6.7 AI Structuring
- **OpenAI API** or **Anthropic API** (stateless, no memory, no data retention)
- Entity extraction: actions, todos (with dates), reminders (with times), general notes
- Topic extraction for contextual grouping
- Follow-up question generation (voice-triggered only)

### 6.8 Notifications
- **flutter_local_notifications** for reminder alerts

### 6.9 Offline Support
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
├── rawTranscription: String
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
└── hasFollowUpTrigger: bool (user said "any suggestions?" etc.)

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
├── quietHoursStart: TimeOfDay?
├── quietHoursEnd: TimeOfDay?
└── themeMode: String (system / light / dark)
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

## 9. Out of Scope (Phase 2+)

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
| Music note capture | Phase 3 |
| Smart automations | Phase 3 |
| Ambient listening mode | Phase 3 |
| Collaborative features | Phase 3 |
| Template-based capture | Phase 3 |
| Third-party integrations (CRM, calendars) | Phase 3 |

---

## 10. MVP Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (cross-platform iOS + Android) |
| Local database | Hive (encrypted with AES-256) |
| Audio recording | record package |
| Speech-to-text | Whisper API or Google Speech-to-Text (stateless) |
| AI structuring | OpenAI API or Anthropic API (stateless) |
| State management | Riverpod or Bloc |
| Navigation | go_router |
| Notifications | flutter_local_notifications |
| Typography | Google Fonts (Plus Jakarta Sans, Inter) |

---

## 11. Dependencies

### Current (in pubspec.yaml)
| Package | Version | Purpose | MVP Status |
|---|---|---|---|
| flutter | SDK | UI framework | Active |
| path_provider | ^2.0.0 | File system access | Active |
| record | >=5.1.2 | Audio recording | Active |
| cupertino_icons | ^1.0.8 | iOS-style icons | Active |
| google_fonts | ^6.1.0 | Custom typography | Active |
| provider | ^6.1.2 | State management | To be replaced (Riverpod/Bloc) |
| go_router | ^16.2.0 | Declarative routing | Active |

### To Be Added for MVP
| Package | Purpose |
|---|---|
| hive + hive_flutter | Local encrypted database |
| hive_generator + build_runner | Hive model code generation (dev) |
| flutter_riverpod / flutter_bloc | State management |
| http or dio | API calls (transcription, AI) |
| flutter_local_notifications | Reminder notifications |
| connectivity_plus | Network status monitoring |
| uuid | Unique ID generation |
| intl | Date/time formatting |
| audio_waveforms | Real-time waveform visualization |
| permission_handler | Runtime permission management |
| just_audio | Audio playback on note detail screen |
