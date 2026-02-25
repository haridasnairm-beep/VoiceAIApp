# VoiceNotes AI - Project Status

**Last Updated:** 2026-02-25
**Current Version:** 0.1.0 (Initial Scaffolding)
**Overall Progress:** ~15% of MVP (Phase 1)
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md)

---

## Status Summary

The project has a solid Flutter scaffold with all core screens built as UI shells and a working audio recording service. However, **no backend services, data persistence, AI processing, or business logic are implemented yet**. The app can record audio but cannot transcribe, categorize, or store notes.

**Key architectural alignment needed:** The concept document specifies Hive (not sqflite), Riverpod/Bloc (not Provider), no login for MVP, and privacy-first local-only storage. The current codebase uses Provider and includes a login screen that is not needed for MVP.

---

## Component Status

### Infrastructure & Setup
| Component | Status | Progress | Notes |
|---|---|---|---|
| Project Setup | Done | 100% | Flutter project initialized |
| Theme System | Done | 100% | Light/dark mode, Material 3, custom fonts |
| Navigation | Done | 90% | 9 routes — needs initial route change (onboarding→home for MVP) |
| Audio Recording Service | Done | 90% | Recording works, needs waveform data stream |

### Screens (UI Only — No Business Logic)
| Screen | Status | MVP Use | Notes |
|---|---|---|---|
| Onboarding Page | UI Done | Active | Needs to navigate to Home (not Login) |
| **Login Page** | UI Done | **NOT IN USE** | **No login required in MVP Phase 1. Phase 2 feature.** |
| Home / Dashboard | UI Done | Active | Needs real data binding, filter chips |
| Recording Page | UI Done | Active | Missing waveform visualizer, live transcription |
| Note Detail Page | UI Done | Active | Needs structured sections, audio playback, edit/delete |
| Folders Page | UI Done | Active | Needs Hive data binding |
| Folder Detail Page | UI Done | Active | Needs Hive data binding |
| Settings Page | UI Done | Active | Needs privacy dashboard, storage management |
| Search Page | UI Done | Active | No search logic implemented |

### Core Services (NOT STARTED)
| Component | Status | Priority | Notes |
|---|---|---|---|
| Data Models (Hive) | Not Started | P0 | Note, ActionItem, TodoItem, ReminderItem, Folder, UserSettings |
| Hive Database Setup | Not Started | P0 | Encrypted Hive boxes, CRUD operations |
| State Management | Not Started | P0 | Replace Provider with Riverpod or Bloc |
| Speech-to-Text Service | Not Started | P0 | Whisper API or Google STT (stateless) |
| Language Detection | Not Started | P0 | Bundled with STT service |
| AI Categorization Service | Not Started | P0 | OpenAI/Anthropic API (stateless) |
| Waveform Visualizer | Not Started | P1 | Real-time audio visualization |
| Live Transcription Preview | Not Started | P1 | Streaming text during recording |
| Contextual Grouping | Not Started | P1 | Topic linking across notes |
| Follow-up Questions | Not Started | P1 | Voice-triggered AI questions |
| Search Logic | Not Started | P1 | Full-text search with Hive |
| Reminder Notifications | Not Started | P1 | flutter_local_notifications |
| Offline Queue | Not Started | P1 | Queue pending AI processing |
| Audio Playback | Not Started | P1 | Play recordings from note detail |

---

## What Works Today

1. App launches with onboarding flow
2. Navigation between all screens
3. Light and dark theme switching (system-based)
4. Audio recording (start, pause, resume, stop, cancel)
5. Recordings saved as M4A files locally
6. Real-time amplitude monitoring during recording
7. UI layouts for all 9 core screens

---

## What Does NOT Work Yet

1. No speech-to-text transcription (core feature)
2. No AI-powered categorization of notes
3. No language detection
4. No data persistence — notes are not saved or retrievable
5. No search functionality beyond UI shell
6. No folder/conversation auto-grouping
7. No reminders or notifications
8. No waveform visualizer on recording screen
9. No live transcription preview during recording
10. No offline processing queue
11. No audio playback on note detail
12. No edit/delete capability for notes

---

## Known Issues & Alignment Gaps

| # | Severity | Description |
|---|---|---|
| 1 | **High** | State management uses Provider — concept doc specifies Riverpod or Bloc |
| 2 | **High** | No Hive database — concept doc requires Hive with AES-256 encryption |
| 3 | **High** | Login page exists but MVP requires no login |
| 4 | Medium | Android app label is "dreamflow" instead of "VoiceNotes AI" |
| 5 | Medium | App title in `main.dart` is empty string |
| 6 | Medium | Initial route is onboarding → should flow to home (not login) |
| 7 | Low | App icon asset named "dreamflow_icon.jpg" — should be rebranded |
| 8 | Low | google_logo.svg asset not needed for MVP (no login) |

---

## Pages Not In Use (MVP Phase 1)

The following pages exist in the codebase but are **not part of the MVP flow**. AI agents and developers should **disregard** these files during MVP implementation:

| File | Reason | Target Phase |
|---|---|---|
| `lib/pages/login_page.dart` | No authentication required in MVP. App works without login. | Phase 2 |

---

## File Structure Overview

```
lib/
├── main.dart                    [Done — needs title fix, Provider→Riverpod migration]
├── nav.dart                     [Done — needs initial route update, remove login for MVP]
├── theme.dart                   [Done]
├── pages/
│   ├── onboarding_page.dart     [UI Done — Active]
│   ├── login_page.dart          [UI Done — NOT IN USE (Phase 2)]
│   ├── home_page.dart           [UI Done — Active]
│   ├── recording_page.dart      [UI Done — Active]
│   ├── note_detail_page.dart    [UI Done — Active]
│   ├── folders_page.dart        [UI Done — Active]
│   ├── folder_detail_page.dart  [UI Done — Active]
│   ├── settings_page.dart       [UI Done — Active]
│   └── search_page.dart         [UI Done — Active]
├── models/                      [NOT CREATED — Hive models needed]
├── services/
│   └── audio_recorder_service.dart  [Done]
├── providers/                   [NOT CREATED — Riverpod/Bloc providers needed]
└── utils/                       [NOT CREATED]
```

---

## Metrics

- **Total Dart files:** 12
- **Total lines of Dart code:** ~5,500
- **Screens implemented (UI):** 9 (8 active for MVP, 1 not in use)
- **Services implemented:** 1 (AudioRecorderService)
- **Features functional end-to-end:** 0
