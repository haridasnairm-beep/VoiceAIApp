# Vaanix — Feature Spec: Share to Vaanix

**Version:** 1.0
**Date:** 2026-03-07
**Status:** Draft — Ready for Implementation
**Phase:** Phase 1 (Free Tier)
**Tier:** Free — All Users
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md) | [External Recorder Import](FEATURE_EXTERNAL_RECORDER_IMPORT.md)

---

## 1. Feature Overview

**Share to Vaanix** enables users to share audio files from any app on their device — WhatsApp, Telegram, Signal, Google Messages, or any other app — directly into Vaanix for transcription, speaker labelling, and organization. Once received, the audio is processed through the same on-device Whisper pipeline as in-app recordings, producing a fully structured note with identical privacy guarantees.

**Core Concept:** A user receives a voice note in WhatsApp (or any messaging app), taps Share, selects Vaanix, and the audio is immediately processed into a private, transcribed, organized note — stored locally, encrypted, and never uploaded to any cloud service.

**Why this matters:** Voice notes in messaging apps are a primary communication mode, particularly in the Indian market. Users receive business instructions, personal commitments, and important information via audio that currently lives in Meta's or another third-party's ecosystem. Share to Vaanix gives users a one-tap path to rescue those recordings into a private, organized, searchable local store.

**Why free tier:** Unlike External Recorder Import (which targets power users with professional hardware and batch workflows), Share to Vaanix serves everyday users with a single casual action. Gating it behind Pro would conflict with the brand promise and limit adoption of the feature most likely to generate organic word-of-mouth.

**Why Phase 1:** No new ML models are required. The feature reuses the existing on-device Whisper pipeline unchanged. The only new additions are OS-level Share Sheet registration (manifest/entitlement changes) and Opus/OGG format support — both low-risk and low-effort.

---

## 2. Why This Is NOT Folded Into External Recorder Import

| Dimension | Share to Vaanix | External Recorder Import |
|---|---|---|
| **Target user** | All free users | Pro power users |
| **Entry point** | OS Share Sheet (from another app) | In-app file picker |
| **Mental model** | "Save this voice note someone sent me" | "Import my professional recordings" |
| **Tier** | Free | Pro |
| **Phase** | Phase 1 | Phase 2 Wave 3 |
| **Batch support** | Single file per share action | Up to 20 files per batch |
| **Typical duration** | Seconds to ~5 minutes | Minutes to hours |

Keeping them separate preserves clean architecture, correct tier gating, and distinct UX flows.

---

## 3. Target Use Cases & Source Apps

### 3.1 Primary Use Cases

| Use Case | Example | Frequency |
|---|---|---|
| Business instruction via WhatsApp | Manager sends a voice note with tasks for the day | Daily |
| Family / personal voice messages | Long voice note with plans, commitments, or reminders | Several times/week |
| Study group messages | Classmate sends lecture summary or assignment instructions | Weekly |
| Telegram voice notes | Community or channel audio message worth saving | Occasional |
| Signal private messages | Private voice note to keep a record of | Occasional |

### 3.2 Source Apps & Audio Formats

| App | Android Format | iOS Format | Notes |
|---|---|---|---|
| **WhatsApp** | `.opus` (OGG container) | `.m4a` (AAC) | Primary use case. Opus needs explicit Android support. |
| **Telegram** | `.ogg` (Opus codec) | `.ogg` / `.m4a` | Same codec family as WhatsApp. |
| **Signal** | `.aac` | `.m4a` | Already in supported formats list. |
| **Google Messages** | `.ogg` / `.opus` | n/a | Android-only. Same as WhatsApp. |
| **Instagram DMs** | `.aac` / `.mp4` audio | `.m4a` | Already supported. |
| **Messenger (Meta)** | `.aac` | `.m4a` | Already supported. |
| **iMessage** | n/a | `.caf` → `.m4a` | iOS Share Sheet converts to `.m4a` before sharing — no extra work needed. |

**Phase 1 format scope:** Add Opus/OGG support. All other formats (AAC, M4A, MP4 audio, MP3, WAV) are already handled. `.caf` (iMessage) is converted by iOS before sharing — no action required. `.amr` (WeChat) is deferred.

---

## 4. User Stories

1. **As a free user**, I want to share a WhatsApp voice note to Vaanix so it is transcribed and saved as a private note on my device.
2. **As a free user**, I want to label who sent the voice note so the note is correctly attributed in my library.
3. **As a free user**, I want to be told if a recording contains multiple voices so I know what to expect from the transcript.
4. **As a free user**, I want to choose which folder the shared note goes into before processing starts.
5. **As a free user**, I want shared audio to be visually distinct from my own recordings so I can tell them apart at a glance.
6. **As a free user**, I want the same privacy guarantee for shared audio as for my own recordings — no cloud upload, no retention.
7. **As a free user**, I want the share flow to be fast — a single bottom sheet, one tap to confirm, done.
8. **As a free user**, I want to add a personal note or context alongside the shared audio before saving.

---

## 5. User Flow

### 5.1 End-to-End Flow

```
[User receives voice note in WhatsApp / Telegram / any app]
    ↓
[Long-press audio → Share → Select Vaanix from OS Share Sheet]
    ↓
[Vaanix receives share intent]
    ├── App was closed → opens directly to Share Bottom Sheet
    └── App was open → Share Bottom Sheet overlays current screen
    ↓
[Share Bottom Sheet shown]
    ├── Audio preview strip (waveform + duration + 10-sec playback)
    ├── "Who sent this?" — free text field (optional)
    ├── "Multiple voices?" — toggle (off by default)
    ├── Folder selector (defaults to last-used folder)
    └── Optional context note field
    ↓
[Tap "Save & Transcribe"]
    ↓
[Audio copied to Vaanix encrypted local storage]
    ↓
[On-device Whisper transcription runs in background]
    ↓
[Persistent notification: "Voice note from [Sender] is ready."]
    ↓
[Tap notification → Note Detail screen]
```

### 5.2 Step-by-Step

| Step | Actor | What Happens |
|---|---|---|
| 1. Trigger share | User | Long-presses audio in source app, taps Share, selects Vaanix |
| 2. App opens | System / Vaanix | Vaanix receives audio Intent/Extension payload. Opens to Share Bottom Sheet. |
| 3. Bottom sheet shown | Vaanix | Sheet appears with audio preview, speaker fields, folder selector, context field, and CTA |
| 4. Fill speaker info | User | Types sender name (or skips — defaults to "Unknown"). Toggles multiple voices if applicable. |
| 5. Select folder | User | Picks folder or creates one inline. Defaults to last-used folder. |
| 6. Save & Transcribe | User | Sheet dismisses. Processing begins immediately in background. |
| 7. Processing | Vaanix / Whisper | Audio transcribed on-device via existing Whisper pipeline. |
| 8. Completion | Vaanix | Notification fired. Note created with full transcript and structured output. |
| 9. Note Detail | User | Full transcript, speaker label, shared badge, todos/actions/reminders. |

---

## 6. Share Bottom Sheet — UI Spec

The Share Bottom Sheet is the primary UI surface for this feature. It must be fast, minimal, and require as few taps as possible — the user is in the middle of another app.

### 6.1 Components

| Component | Description | Required? |
|---|---|---|
| **Header** | "Save Voice Note to Vaanix" title + source app name if detectable | Yes |
| **Audio preview strip** | Waveform thumbnail + duration + 10-second tap-to-play. Lets user verify the right file. | Yes |
| **"From" field** | Text input: "Who sent this?" Placeholder: "e.g. Rahul, Mom, Unknown". Pre-fills nothing. | No (skippable) |
| **"Multiple voices?" toggle** | Off by default. If toggled on: "Transcript will be combined. Speaker labels coming in a future update." Sets `multiSpeaker: true` on note metadata. | No |
| **Folder selector** | Chip row / dropdown of existing folders. Defaults to last-used folder. `+ New Folder` inline creation. | Yes (has default) |
| **Context note field** | Single-line: "Add context (optional)" — saved as annotation alongside transcript. | No |
| **"Save & Transcribe" button** | Primary CTA. Triggers processing and dismisses sheet. | Yes |
| **"Cancel" link** | Below primary button. Dismisses without saving. | Yes |

### 6.2 Behaviour Rules

- Sheet appears **immediately** on share intent received — no splash or loading delay
- Sheet is **not dismissible by swipe** — user must tap Cancel or Save (prevents accidental data loss)
- If Whisper model is **not downloaded**, the primary button is replaced with "Set Up Whisper First" — navigates to Settings → Whisper download section. Audio intent is held until user returns.
- If App Lock is enabled with **Full** Widget Privacy, authentication is required before the sheet is shown
- Maximum sheet height: **70% of screen**. Scrollable if content overflows.

---

## 7. Speaker Handling — Phase 1 Approach

> **Phase 1 constraint:** On-device Whisper (ggml-base) produces a flat transcript with no speaker segmentation. True diarization (who said what) requires a separate ML model and is deferred to Phase 2 (P2-11: Speaker Diarization). Phase 1 takes a pragmatic, user-driven approach.

### 7.1 Single Speaker (Default)

- User enters sender name in the "From" field
- Name stored as `sharedFrom` in note metadata
- Note header shows: **From: [Name]** with shared badge icon
- Transcript attributed entirely to this speaker

### 7.2 Multiple Speakers (User-Flagged)

- User toggles "Multiple voices?" on
- Inline info shown: *"Transcript will be combined. Speaker labels coming in a future update."*
- Note saved with `multiSpeaker: true` flag in metadata
- Note header shows: **Multiple Speakers** label with shared badge
- In Phase 2, notes with `multiSpeaker: true` are candidates for retroactive diarization via P2-11

### 7.3 Unknown / Skipped

- If "From" field is left blank and toggle is off, `sharedFrom` defaults to `"Unknown"`
- Displayed as **From: Unknown** — user can edit at any time in Note Detail

---

## 8. Shared Note — Visual Identity

Shared notes must be visually distinct from in-app recordings across all list views and the Note Detail screen, without being disruptive.

### 8.1 Note List (Home, Folder, Search Results)

- Small **shared badge icon** on note card: arrow-into-box symbol (share/receive)
- **"From: [Name]"** shown as secondary line below note title
- Badge colour: gold (Vaanix palette), small and unobtrusive

### 8.2 Note Detail Screen

- **"Shared Note" section** at top (collapsible), showing:
  - Source app name (if detectable from Intent data)
  - From: [Speaker Name]
  - Shared on: [date + time]
  - Original filename (if available)
  - Multiple Speakers indicator (if flagged)
  - Audio format + duration
- All other Note Detail sections (transcript, todos, actions, reminders, audio player) are identical to in-app recordings

---

## 9. Audio Format & Platform Handling

### 9.1 Android

| Format | Handling | Method | APK Size Impact |
|---|---|---|---|
| `.opus` / `.ogg` | Native via Android MediaCodec (API 21+) | `just_audio` (existing) | **+0 MB** |
| `.m4a` / `.aac` | Native | `just_audio` (existing) | +0 MB |
| `.mp3` | Native | `just_audio` (existing) | +0 MB |
| `.wav` | Native | `just_audio` (existing) | +0 MB |
| `.amr` | Deferred | — | +0 MB |

### 9.2 iOS

| Format | Handling | Method | IPA Size Impact |
|---|---|---|---|
| `.m4a` / `.aac` | Native via AVFoundation | `just_audio` (existing) | +0 MB |
| `.mp3` | Native | `just_audio` (existing) | +0 MB |
| `.wav` | Native | `just_audio` (existing) | +0 MB |
| `.ogg` / `.opus` | Transcode using `ffmpeg_kit_flutter_audio` (audio-only variant) | `ffmpeg_kit_flutter_audio` | **~3–5 MB** |
| `.caf` (iMessage) | iOS Share Sheet converts to `.m4a` before sharing — no action needed | n/a | +0 MB |

> **Net size impact:** Android +0 MB (Opus natively supported via MediaCodec). iOS +3–5 MB (audio-only ffmpeg_kit variant). Current APK is 66.4 MB. This does not warrant a downloadable module. No on-demand download mechanism needed.

---

## 10. Platform Integration

### 10.1 Android — Intent Filter

Add to `AndroidManifest.xml` inside `<activity>` for `MainActivity`:

```xml
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="audio/*" />
</intent-filter>
```

- Use `receive_sharing_intent` package (pub.dev) to handle both cold-start and warm-start share intents cleanly
- In `MainActivity.kt`: intercept `Intent` in `onNewIntent` and `onStart`, extract URI from `Intent.EXTRA_STREAM`, pass to Flutter via MethodChannel

### 10.2 iOS — Share Extension

- Add a **Share Extension** target to the Xcode project
- Configure `NSExtensionActivationRule` to accept `kUTTypeAudio`, `public.audio`
- Extension passes the file URL to the main app via **App Group shared container**
- Main app reads the file from shared container on launch / foreground
- Add audio background mode entitlement if processing should begin while app is backgrounded

---

## 11. Data Model

### 11.1 Modified Note Model

```
Note (MODIFIED)
├── ... (all existing fields unchanged)
├── sourceType: NoteSourceType     ← UPDATED (adds `shared` value)
└── sharedNoteMetadata: SharedNoteMetadata?   ← NEW (null for in_app notes)
```

### 11.2 New: SharedNoteMetadata

```
SharedNoteMetadata
├── sharedFrom: String?            (speaker/sender name entered by user; null if skipped; display default: "Unknown")
├── multiSpeaker: bool             (true if user flagged multiple voices; default: false)
├── sourceApp: String?             (detected source app if available from Intent data; e.g. "WhatsApp"; may be null)
├── originalFilename: String?      (original filename from share payload, if available)
├── originalFormat: String         (audio format: "opus", "ogg", "m4a", "aac", "mp3", "wav")
├── originalDuration: Duration?    (parsed from file metadata; may be null if unreadable)
└── sharedAt: DateTime             (timestamp when share intent was received)
```

### 11.3 NoteSourceType Enum — Updated

```dart
enum NoteSourceType {
  in_app,    // Recorded within Vaanix (existing)
  shared,    // Received via OS Share Sheet (new — this feature)
  imported,  // Imported via file picker (Phase 2 — External Recorder Import)
}
```

### 11.4 Hive Storage

| Box | Change |
|---|---|
| `notesBox` (existing) | Updated `Note` objects with new `sourceType` and `sharedNoteMetadata` fields |
| No new boxes required | `SharedNoteMetadata` is embedded within the `Note` model |

---

## 12. Processing Pipeline

```
[Share intent received]
    ↓
[1. Validate file]
    ├── Check MIME type is audio
    ├── Check file is readable (not corrupt)
    ├── Check file size (warn if > 100 MB)
    └── Compute SHA-256 hash for duplicate detection
    ↓
[2. Format conversion (if needed)]
    └── iOS only: transcode .ogg/.opus → .m4a using ffmpeg_kit_flutter_audio
    ↓
[3. Show Share Bottom Sheet]
    └── User confirms sender, folder, optional context
    ↓
[4. On "Save & Transcribe"]
    ├── Copy audio to Vaanix AES-256 encrypted local storage
    └── Create Note record with pending transcription status + SharedNoteMetadata populated
    ↓
[5. Whisper transcription]
    └── Same on-device pipeline as in-app recordings (reuse TranscriptionService)
    ↓
[6. Structured output extraction]
    └── Todos, actions, reminders parsed from transcript (same as in-app)
    ↓
[7. Note complete]
    └── Fire persistent notification: "Voice note from [Sender] is ready."
        Tap → navigates to Note Detail
```

> **Privacy:** Shared audio is copied into Vaanix's AES-256 encrypted local storage immediately on save. The original file in the source app is never modified or deleted. No audio is uploaded to any cloud service.

---

## 13. Edge Cases

| Scenario | Handling |
|---|---|
| **Whisper model not downloaded** | Replace "Save & Transcribe" with "Set Up Whisper First" — navigates to Settings → Whisper download. Share intent held until user returns. |
| **App Lock enabled (Full privacy mode)** | Require authentication before showing Share Bottom Sheet. |
| **File is not audio** | Show error: "This file doesn't appear to be an audio recording." Cancel button only. |
| **File too large (> 100 MB)** | Show warning: "This file is [X] MB. Transcription may take a few minutes." Allow proceed or cancel. |
| **File is corrupt / unreadable** | Show error: "This audio file could not be read. It may be corrupt or in an unsupported format." Cancel only. |
| **User cancels bottom sheet** | No file saved, no note created. Intent discarded cleanly. |
| **App cold-started by share intent** | App opens directly to Share Bottom Sheet. Home screen loads behind the sheet. |
| **Multiple share intents received quickly** | Queue them. One bottom sheet at a time. Indicator if more are waiting. |
| **Storage space low** | Check available space before copying audio. Warn if < 200 MB free. |
| **Duplicate share (same file shared twice)** | SHA-256 hash check. If match found: "You may have already saved this audio on [date]. Save again?" |

---

## 14. Privacy Considerations

| Principle | Application |
|---|---|
| **Local storage** | Shared audio stored in Vaanix AES-256 encrypted local storage. Never uploaded to cloud. |
| **Stateless transcription** | On-device Whisper. No network call required. |
| **No source app access** | Vaanix only receives the audio file payload. No access to the source app's data, contacts, or message history. |
| **User control** | User can delete any shared note and its audio at any time. Deletion is permanent. |
| **No tracking** | Share activity is not logged externally or used for analytics. |
| **App Lock respected** | Share flow respects existing App Lock settings. Full privacy mode requires auth before sheet is shown. |

---

## 15. Implementation Tasks

### Sub-step A: Data Model

1. Add `shared` value to `NoteSourceType` enum
2. Create `SharedNoteMetadata` Hive model with TypeAdapter
3. Add `sourceType` and `sharedNoteMetadata` fields to `Note` model (next available HiveField indices)
4. Write and register TypeAdapters, run `build_runner`

### Sub-step B: Platform Integration

1. **Android:** Add `audio/*` Intent filter to `AndroidManifest.xml`
2. **Android:** Add `receive_sharing_intent` package, handle cold-start and warm-start intents in `MainActivity`
3. **Android:** Implement MethodChannel bridge to pass URI to Flutter layer
4. **iOS:** Add Share Extension target to Xcode project
5. **iOS:** Configure `NSExtensionActivationRule` for audio MIME types
6. **iOS:** Set up App Group shared container for file handoff between extension and main app
7. **iOS:** Add `ffmpeg_kit_flutter_audio` dependency for Opus/OGG transcoding

### Sub-step C: Share Bottom Sheet UI

1. Create `ShareBottomSheet` widget (non-swipe-dismissible, 70% max height)
2. Audio preview strip: waveform thumbnail + tap-to-play (first 10 seconds)
3. "From" text field with placeholder
4. "Multiple voices?" toggle with inline info text
5. Folder selector (reuse existing folder picker component)
6. Optional context note field
7. "Save & Transcribe" primary button + "Cancel" link
8. "Set Up Whisper First" fallback button state when model not downloaded
9. App Lock gate: check auth requirement before showing sheet

### Sub-step D: Processing Pipeline

1. `ShareIntentService`: validate file, compute SHA-256, check duplicates
2. Format detection: read MIME type and extension, route to transcoder if Opus on iOS
3. Copy audio to encrypted local storage
4. Create `Note` record with pending status and `SharedNoteMetadata` populated
5. Trigger existing Whisper transcription pipeline (reuse `TranscriptionService`)
6. On completion: fire local notification with "From: [Name]" label, navigate to Note Detail on tap

### Sub-step E: Shared Note Visual Identity

1. Add shared badge icon to `NoteCard` widget (arrow-into-box icon, gold)
2. Add "From: [Name]" secondary line to `NoteCard`
3. Add collapsible "Shared Note" metadata section to `NoteDetail` screen
4. Display source app, sender, share date, format, duration, multi-speaker flag

### Sub-step F: Edge Cases & Polish

1. Duplicate detection (SHA-256 comparison against existing `SharedNoteMetadata` records)
2. File size warning (> 100 MB)
3. Storage space check (< 200 MB free)
4. Corrupt file error handling
5. Intent queue for multiple rapid shares
6. Haptic feedback on bottom sheet appear, save, cancel

---

## 16. Effort Estimate

| Sub-step | Effort | Risk |
|---|---|---|
| A: Data Model | 0.5 days | Low |
| B: Platform Integration (Android) | 1 day | Low — `receive_sharing_intent` is well-documented |
| B: Platform Integration (iOS Share Extension) | 1.5 days | Medium — App Group setup, cold-start handling |
| B: iOS Opus transcoding (`ffmpeg_kit_flutter_audio`) | 0.5 days | Low — audio-only variant, well-tested |
| C: Share Bottom Sheet UI | 1 day | Low |
| D: Processing Pipeline | 1 day | Low — reuses `TranscriptionService` |
| E: Shared Note Visual Identity | 0.5 days | Low |
| F: Edge Cases & Polish | 1 day | Low–Medium |
| **Total** | **~7 days** | **Overall: Low–Medium** |

---

## 17. Phase 2 Upgrade Path

This feature is architectured to feed directly into Phase 2 improvements with zero migration work:

| Phase 2 Feature | How This Feature Prepares It |
|---|---|
| **P2-11: Speaker Diarization** | Notes with `multiSpeaker: true` are candidates for retroactive diarization. `sharedFrom` provides the primary speaker hint. |
| **P2-5: External Recorder Import** | `NoteSourceType` enum already includes `imported`. `SharedNoteMetadata` pattern directly informs `ImportMetadata` design. |
| **P2-1: AI Auto-Categorization** | Shared notes feed the same transcript into the same categorization pipeline. No additional work needed. |

---

## 18. Future Enhancements

These are explicitly out of scope for Phase 1 but inform the architecture:

| Enhancement | Description |
|---|---|
| **Batch share (multiple files)** | Accept multiple audio files in a single share action. Requires queue UI. |
| **Contact name auto-fill** | On Android, some share intents include sender metadata. Auto-populate "From" field where available. |
| **`.amr` format support** | Needed for WeChat voice notes. Low priority unless user demand confirms it. |
| **Retroactive diarization** | When P2-11 ships, offer to re-process existing `multiSpeaker: true` notes with full speaker separation. |
| **Share from URL** | Accept a direct URL to an audio file (e.g. from a voice message service) as a share payload. |

---

## 19. Decision Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-03-07 | Feature scoped as Phase 1, free tier | No new ML required; reuses existing Whisper pipeline; high-frequency use case at launch |
| 2026-03-07 | Kept separate from External Recorder Import | Different user segment, tier, entry point, and mental model |
| 2026-03-07 | Opus/OGG added as the only new format | Covers WhatsApp, Telegram, Google Messages in one addition; all other formats already supported |
| 2026-03-07 | No downloadable module for Opus support | Android: native MediaCodec, 0 MB. iOS: audio-only ffmpeg_kit, ~3–5 MB. Below threshold for on-demand download. |
| 2026-03-07 | Multiple-speaker handling via user toggle, not auto-detection | Whisper provides no speaker segmentation. Auto-detection requires diarization (Phase 2). Toggle is honest and future-proof. |
| 2026-03-07 | Share Bottom Sheet is not swipe-dismissible | Prevents accidental data loss when user receives a share intent they intended to save. |
| 2026-03-07 | SHA-256 duplicate detection included | Prevents accidental duplicate notes from sharing the same voice note twice. Consistent with External Recorder Import spec. |

---

*End of FEATURE_SHARE_TO_VAANIX.md*
