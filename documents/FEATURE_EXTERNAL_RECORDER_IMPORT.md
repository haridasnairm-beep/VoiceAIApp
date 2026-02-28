# VoiceNotes AI — Feature Spec: External Recorder Import (Pro)

**Version:** 1.0
**Date:** 2026-02-27
**Status:** Draft — Pending Option Selection
**Phase:** Phase 2 (Pro Feature)
**Tier:** Pro Users Only
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md)

---

## 1. Feature Overview

**External Recorder Import** allows pro users to import audio files recorded on standalone voice recorder devices (such as Sony ICD, Zoom, Olympus, TASCAM, Philips VoiceTracer) into VoiceNotes AI for transcription, structuring, and organization — the same AI pipeline applied to in-app recordings.

**Core Concept:** Users record voice notes on a dedicated recorder device throughout their day — during meetings, commutes, fieldwork, or any situation where pulling out a phone isn't practical. Later, at their convenience, they transfer the audio files to their phone and import them into VoiceNotes AI. The app processes each file through the full AI pipeline: transcription, language detection, and intelligent structuring into todos, actions, reminders, and notes.

**Why this matters:** Professional users — journalists, researchers, medical professionals, field workers, students in lectures — often prefer dedicated recording hardware for superior microphone quality, longer battery life, and distraction-free capture. This feature bridges the gap between professional recording workflows and VoiceNotes AI's intelligent structuring capabilities.

**Why Pro-only:** External recorder import serves a specific power-user segment. It involves heavier AI processing (longer recordings, batch imports) and adds complexity that casual users don't need. Positioning it as a Pro feature reinforces the premium tier's value proposition without restricting core functionality.

---

## 2. Target Devices & Audio Formats

### 2.1 Common Standalone Voice Recorders

| Brand | Popular Models | Typical Output Formats | Transfer Method |
|---|---|---|---|
| **Sony ICD Series** | ICD-UX570, ICD-TX660 | MP3, LPCM (WAV) | USB cable, drag-and-drop to phone storage |
| **Zoom** | H1n, H6, H1 XLR | WAV, MP3 | SD card (via adapter or reader), USB |
| **Olympus / OM System** | WS-883, LS-P5 | MP3, WAV, FLAC | USB, Bluetooth (select models), companion app |
| **TASCAM** | DR-05X, DR-40X | WAV, MP3, BWF | SD card, USB |
| **Philips VoiceTracer** | DVT4110, DVT6110 | MP3, WAV, PCM | USB, WiFi (select models), companion app |

### 2.2 Audio Formats to Support

**Must support (Phase 1 of this feature):**
- MP3 (.mp3)
- WAV (.wav)
- M4A / AAC (.m4a, .aac)

**Should support (Phase 2 of this feature):**
- FLAC (.flac)
- OGG (.ogg)
- WMA (.wma)
- LPCM / BWF (.wav variant — typically handled by standard WAV decoders)

**Max file size:** 500 MB per file (covers roughly 8+ hours of MP3 or 2+ hours of uncompressed WAV)

**Max duration:** No hard limit — processing time scales with duration. UI should set expectations for long files (e.g., "This 2-hour recording may take a few minutes to process").

---

## 3. User Stories

1. **As a pro user**, I want to import an audio file from my phone's storage into VoiceNotes AI so that it gets transcribed and structured like a regular voice note.
2. **As a pro user**, I want to import multiple audio files at once (batch import) so I can process a full day's recordings in one go.
3. **As a pro user**, I want to see the import progress for each file so I know what's been processed and what's pending.
4. **As a pro user**, I want the app to preserve the original recording date/time from the file metadata so my notes are correctly timestamped.
5. **As a pro user**, I want to assign imported recordings to a folder or Project Document during or after import.
6. **As a pro user**, I want to preview an audio file before importing so I can confirm it's the right recording.
7. **As a pro user**, I want imported notes to be visually distinguishable from in-app recordings so I know their source.
8. **As a pro user**, I want the app to remember the last import source folder so I don't have to navigate to it every time.
9. **As a pro user**, I want to be warned if I try to import a file that's already been imported (duplicate detection).
10. **As a pro user**, I want my imported audio files processed with the same privacy guarantees as in-app recordings — stateless AI, no cloud retention.

---

## 4. Import Options — Three Approaches

This section outlines three implementation approaches. **Only one will be selected for initial development.** Each has different trade-offs in effort, device compatibility, and user experience.

---

### Option A: Manual File Import (Recommended for Initial Build)

**How it works:** User transfers audio files from recorder to phone (via USB cable, SD card reader, AirDrop, or file manager). Then opens VoiceNotes AI and uses an "Import Recording" action to pick files from device storage.

**User flow:**
```
[Record on device]
    ↓
[Transfer files to phone]
    ├── USB OTG cable (Android)
    ├── SD card reader / Lightning-SD adapter (iOS)
    ├── AirDrop / Nearby Share
    ├── Wired file transfer via computer as intermediary
    └── Files app (iOS) / File Manager (Android)
    ↓
[Open VoiceNotes AI]
    ↓
[Tap "Import Recording" on Home screen or FAB menu]
    ↓
[OS file picker opens — select one or multiple audio files]
    ↓
[Import confirmation screen — shows file list, sizes, estimated processing time]
    ↓
[Tap "Import & Process"]
    ↓
[App copies files to local storage, queues for AI processing]
    ↓
[Processing runs — transcription, language detection, structuring]
    ↓
[Notes appear in note list with "Imported" badge]
```

**Pros:**
- Works with every recorder on the market — no device-specific integration
- Simplest to implement — uses OS-native file picker APIs
- Fully aligned with privacy-first architecture (all local)
- No dependency on any third-party companion app or protocol
- User has full control over what gets imported and when

**Cons:**
- Requires manual transfer step (user must get files onto phone first)
- Slightly more friction than automatic sync options
- User needs to know how to transfer files from their recorder to their phone

**Implementation effort:** Small–Medium

**Key technical considerations:**
- Flutter: Use `file_picker` package for cross-platform file selection
- Copy selected files into app's local storage (Hive-managed directory) before processing
- Support multi-file selection in a single picker session
- Read file metadata (creation date, duration) using `ffprobe` or `just_audio` for preview
- Process files through existing AI transcription pipeline (same as in-app recordings)
- Handle large files gracefully — background processing with progress indicator

---

### Option B: Bluetooth / WiFi Transfer from Smart Recorders

**How it works:** Certain modern recorders (Olympus WS-883, Philips DVT6110, etc.) have Bluetooth or WiFi built in and offer companion apps or open transfer protocols. VoiceNotes AI could receive files directly from these devices.

**User flow:**
```
[Record on Bluetooth/WiFi-enabled device]
    ↓
[On phone: Open VoiceNotes AI → "Connect Recorder" in settings]
    ↓
[App scans for available devices via Bluetooth / WiFi Direct]
    ↓
[Select recorder from list → Pair / Connect]
    ↓
[App displays list of recordings on the device]
    ↓
[User selects recordings to import]
    ↓
[Files transfer wirelessly to app → queued for AI processing]
    ↓
[Processing runs — transcription, language detection, structuring]
    ↓
[Notes appear with "Imported" badge and device source tag]
```

**Pros:**
- More seamless UX — no cable or intermediary needed
- Feel of native integration with the recording device
- Could support auto-sync (detect new recordings and offer to import)

**Cons:**
- Only works with recorders that have Bluetooth/WiFi (subset of market)
- Each manufacturer uses proprietary protocols — significant reverse-engineering or SDK dependency
- Bluetooth file transfer (OBEX/FTP profile) is inconsistent across devices and OS versions
- WiFi Direct requires both devices on same network or ad-hoc pairing — reliability issues
- iOS is very restrictive about Bluetooth file transfer (no OBEX FTP support natively)
- High maintenance burden — device manufacturers change protocols with firmware updates
- Needs per-device testing with actual hardware

**Implementation effort:** Large — and ongoing per device

**Key technical considerations:**
- Flutter: `flutter_blue_plus` for BLE scanning, but file transfer over BLE is slow and limited
- Classic Bluetooth (RFCOMM/OBEX) is better for file transfer but poorly supported in Flutter
- WiFi Direct: No mature Flutter package; would require platform channels (native code per OS)
- Would need a "Supported Devices" list that users can reference before purchasing hardware
- Must handle partial transfers, reconnection, and transfer resumption
- Real hardware testing required for each claimed supported device

**Recommendation:** Defer this option. The compatibility surface is too fragmented and the maintenance cost doesn't justify the UX improvement for MVP. If pursued later, start with one specific device model as a pilot.

---

### Option C: Watched Folder / Cloud Folder Sync

**How it works:** User configures a folder on their device (or a cloud storage folder like Google Drive, Dropbox, iCloud) as a "watch folder." VoiceNotes AI monitors this folder and automatically detects new audio files, offering to import them.

**User flow:**
```
[Record on any device]
    ↓
[Transfer recordings to the designated folder]
    ├── Recorder auto-syncs to Dropbox/Drive (some devices support this)
    ├── User manually drops files into local folder
    └── Computer → cloud sync → phone
    ↓
[VoiceNotes AI detects new audio files in watched folder]
    ↓
[Notification: "3 new recordings found. Import?"]
    ↓
[User taps notification or opens app → confirmation screen]
    ↓
[Tap "Import & Process"]
    ↓
[App copies files to local storage, removes from watched folder (optional)]
    ↓
[Processing runs — transcription, language detection, structuring]
    ↓
[Notes appear with "Imported" badge and source folder tag]
```

**Pros:**
- Semi-automatic — reduces manual steps after initial setup
- Works with any recorder (files just need to end up in the folder)
- Familiar pattern for users who already use cloud storage
- Could feel very seamless once configured

**Cons:**
- **Privacy concern:** If using cloud folders (Drive, Dropbox), audio files pass through third-party cloud storage — conflicts with privacy-first positioning
- Local folder watching: iOS severely restricts background file system monitoring; Android allows it but with battery implications
- Cloud folder integration requires OAuth, API integration per provider, and ongoing maintenance
- Adds complexity to onboarding ("Which folder? Which cloud? How to set up auto-upload on my recorder?")
- Background monitoring consumes battery and requires persistent service
- Cloud sync timing is unpredictable — files may appear partially uploaded

**Implementation effort:** Medium (local folder) to Large (cloud providers)

**Key technical considerations:**
- Local folder watch on Android: `FileObserver` or polling via `WorkManager` background task
- Local folder watch on iOS: Very limited — no true folder monitoring in background; can only check when app comes to foreground
- Cloud sync: Would need Google Drive API, Dropbox API, iCloud integration — each with OAuth flows
- Privacy mitigation: If cloud folders are supported, audio is downloaded locally then deleted from cloud after import? Adds more complexity
- Must handle: partial files, non-audio files in folder, duplicates, folder permission changes

**Recommendation:** The local folder variant is worth considering as a Phase 2 enhancement to Option A (user sets a default import folder, app checks it on launch). The cloud folder variant should only be explored if users explicitly request it, and would require a clear privacy disclosure.

---

## 5. Option Comparison Summary

| Criteria | Option A: Manual Import | Option B: Bluetooth/WiFi | Option C: Watched Folder |
|---|---|---|---|
| **Device compatibility** | ✅ All recorders | ⚠️ Select models only | ✅ All recorders |
| **Privacy alignment** | ✅ Fully local | ✅ Fully local | ⚠️ Cloud variants break privacy model |
| **User friction** | ⚠️ Manual transfer step | ✅ Low after pairing | ✅ Low after setup |
| **Implementation effort** | ✅ Small–Medium | ❌ Large + ongoing | ⚠️ Medium–Large |
| **Maintenance burden** | ✅ Minimal | ❌ High (per-device) | ⚠️ Medium (per cloud provider) |
| **iOS support** | ✅ Full | ❌ Very limited | ⚠️ Limited (no background watch) |
| **Reliability** | ✅ High (user-controlled) | ⚠️ Variable | ⚠️ Variable (sync timing) |
| **Time to ship** | ✅ Fast | ❌ Slow | ⚠️ Medium |
| **Scales to future devices** | ✅ Automatically | ❌ Requires new integrations | ✅ Automatically |

**Recommended path:** Start with **Option A**, with a UX so polished that the manual transfer step feels effortless. Enhance later with Option C (local folder variant only) for semi-automatic detection. Option B is not recommended unless a partnership with a specific recorder manufacturer materializes.

---

## 6. Data Model

### 6.1 Modified Note Model

```
Note (MODIFIED)
├── ... (all existing fields remain unchanged)
│
├── sourceType: NoteSourceType     ← NEW
│     enum: in_app | imported
│
├── importMetadata: ImportMetadata? ← NEW (null for in-app recordings)
│
└── ... (existing fields)
```

### 6.2 New Models

```
ImportMetadata
├── originalFilename: String          (e.g., "ICD_0042.mp3")
├── originalFileSize: int             (bytes)
├── originalDuration: Duration        (parsed from file metadata)
├── originalRecordedAt: DateTime?     (from file metadata, if available)
├── importedAt: DateTime              (when user imported into app)
├── sourceDevice: String?             (user-provided or auto-detected, e.g., "Sony ICD-UX570")
├── fileFormat: String                (e.g., "mp3", "wav")
├── fileHash: String                  (SHA-256 hash for duplicate detection)
└── importBatchId: String?            (groups files imported together)

ImportBatch
├── id: String (UUID)
├── importedAt: DateTime
├── fileCount: int
├── processedCount: int
├── status: ImportBatchStatus
│     enum: pending | processing | completed | partial_failure
├── noteIds: List<String>             (references to created notes)
└── errors: List<ImportError>?        (any files that failed)

ImportError
├── filename: String
├── reason: String
└── timestamp: DateTime

NoteSourceType (enum)
├── in_app       (recorded within VoiceNotes AI)
└── imported     (imported from external file)
```

### 6.3 Hive Storage

| Box | Contents |
|---|---|
| `notesBox` (EXISTING) | Updated Note objects with new `sourceType` and `importMetadata` fields |
| `importBatchesBox` (NEW) | ImportBatch tracking objects, AES-256 encrypted |

### 6.4 Duplicate Detection

Before importing a file, compute its SHA-256 hash and check against all existing `importMetadata.fileHash` values. If a match is found, warn the user: "This file appears to have been imported already on [date]. Import again?"

---

## 7. Screens & UI

### 7.1 Import Entry Points

The import action should be accessible from:

1. **Home screen FAB menu** — alongside the existing "Record" action, add "Import Recording" option
2. **Home screen action bar** — import icon (file + arrow) in the top bar
3. **Folder detail screen** — "Import into this folder" option
4. **Project Document detail** — "Import and add to this project" option

### 7.2 Import Flow Screens

**Screen 1: File Picker (OS Native)**
- Triggered by any import entry point
- Uses OS native file picker filtered to supported audio MIME types
- Multi-select enabled
- Returns list of selected file URIs

**Screen 2: Import Confirmation**
- Shows list of selected files as cards, each displaying:
  - Filename
  - File size (human readable, e.g., "24.3 MB")
  - Duration (parsed from metadata, e.g., "12:34")
  - Recording date (from metadata, or "Unknown")
  - Format badge (MP3, WAV, etc.)
  - Duplicate warning indicator (if hash matches existing import)
- Bottom section:
  - "Import to:" selector — default location (Home), specific folder, or Project Document
  - Estimated processing time (rough calculation based on total duration)
  - "Import & Process" primary button
  - "Cancel" secondary button
- Audio preview: tap any file card to play a short preview (first 15 seconds)

**Screen 3: Import Progress**
- Shows batch progress:
  - Overall progress bar ("3 of 7 files processed")
  - Per-file status: queued → processing → done / failed
  - Current file: shows transcription progress if available
- "Process in Background" button — minimizes to a persistent notification
- "Cancel Remaining" button — stops unprocessed files, keeps completed ones
- On completion: "All done! View imported notes" button

### 7.3 Imported Note Indicators

On any screen where notes are displayed (Home list, Folder, Project Document, Search results):
- Imported notes show a subtle badge or icon (e.g., small download arrow icon) next to the timestamp
- Note detail screen shows an "Import Info" section (collapsible) with:
  - Original filename
  - Source device (if set)
  - Original recording date
  - Import date
  - File format and size

### 7.4 Import History Screen

**Route:** Settings → Import History

- List of all import batches, newest first
- Each batch shows: date, file count, status
- Tap to expand: see individual files and their resulting notes
- Useful for tracking what's been imported and troubleshooting failures

---

## 8. Processing Pipeline

Imported audio files go through the same AI pipeline as in-app recordings, with minor adaptations:

```
[File selected for import]
    ↓
[1. Validate file]
    ├── Check format is supported
    ├── Check file isn't corrupted (can be opened/decoded)
    ├── Check file size within limits
    └── Compute SHA-256 hash for dedup
    ↓
[2. Extract metadata]
    ├── Duration
    ├── Recording date/time (from file metadata tags)
    ├── Sample rate, bit rate, channels
    └── Any embedded device info
    ↓
[3. Format conversion (if needed)]
    ├── Convert to format expected by AI transcription service
    ├── Downsample if excessively high quality (save bandwidth)
    └── Split into chunks if duration > threshold (e.g., 30 minutes)
    ↓
[4. AI Transcription]
    ├── Same stateless API as in-app recordings
    ├── Language auto-detection per segment
    └── Returns raw transcript
    ↓
[5. AI Structuring]
    ├── Same pipeline: extract todos, actions, reminders, general notes
    └── Returns structured data
    ↓
[6. Create Note]
    ├── Create Note object with sourceType = imported
    ├── Attach ImportMetadata
    ├── Store audio file in local encrypted storage
    ├── Assign to target folder/project if specified
    └── Save to Hive
    ↓
[7. Update batch status]
    └── Mark file as processed in ImportBatch
```

### 8.1 Long Recording Handling

External recorders often capture longer sessions (30 min — 2+ hours) compared to typical in-app voice notes (30 seconds — 5 minutes). This requires:

- **Chunked processing:** Split audio into segments (e.g., 10-minute chunks) for transcription to avoid API timeouts and memory issues
- **Progress reporting:** Show per-chunk progress so user sees movement during long processing
- **Merge results:** Stitch chunk transcriptions back into a single coherent transcript
- **Smart splitting:** If possible, split at silence gaps rather than at fixed intervals to avoid cutting mid-sentence
- **Option to create multiple notes:** For very long recordings (60+ min), offer the user a choice: "Create as one long note" or "Split into separate notes at natural breaks"

---

## 9. Edge Cases

| Scenario | Handling |
|---|---|
| **Unsupported file format** | Show clear error: "This file format (.xyz) is not supported. Supported formats: MP3, WAV, M4A, AAC." Do not import. |
| **Corrupted audio file** | Attempt to decode. If fails, show error: "This file couldn't be read. It may be corrupted or incomplete." |
| **Very large file (>500 MB)** | Warn user about processing time and storage impact. Allow import if user confirms. |
| **Very long recording (>2 hours)** | Process in chunks. Offer "split into multiple notes" option. Show estimated time. |
| **No metadata (recording date unknown)** | Use file modification date as fallback. If unavailable, use import timestamp. Mark as "Recording date: Unknown" in import info. |
| **Duplicate file detected** | Show warning with original import date. Let user choose: "Skip" or "Import Again." |
| **Import interrupted (app closed, phone dies)** | ImportBatch tracks per-file status. On next app launch, detect incomplete batch and offer: "You have 4 unprocessed imports. Continue?" |
| **File with no speech (music, silence, noise)** | AI returns empty or minimal transcript. Create note with audio attached, show: "No speech detected in this recording." |
| **Mixed-language long recording** | Language detection runs per chunk. Each segment tagged with detected language. Transcript shows language switches. |
| **Storage space low on device** | Before import, check available space. Warn if importing would use >80% of remaining storage. |
| **Batch with mixed success** | Complete successful files, report failures individually. Don't block the whole batch for one bad file. |
| **User cancels mid-batch** | Keep already-processed notes. Discard in-progress file. Update batch status to reflect partial completion. |

---

## 10. Privacy Considerations

External recorder import must maintain the same privacy guarantees as in-app recordings:

| Principle | Application to Import |
|---|---|
| **Local storage** | Imported audio files stored in Hive-managed encrypted local storage. Never uploaded to cloud. |
| **Stateless AI** | Audio sent to transcription API is processed and discarded. No retention. |
| **No cloud backup** | Imported files are NOT backed up to iCloud/Google Drive unless user explicitly enables OS-level backup for the app's data directory. |
| **User control** | User can delete any imported note and its associated audio file at any time. Deletion is permanent. |
| **No tracking** | Import activity is not tracked, logged externally, or used for analytics. |
| **File hash privacy** | SHA-256 hashes used for dedup are stored locally only. Never transmitted. |

If **Option C (cloud folder)** is ever implemented, additional privacy disclosures are required:
- "Audio files in your [cloud provider] folder are downloaded to your device then processed locally. VoiceNotes AI does not store your cloud credentials beyond the active session."
- Option to auto-delete files from cloud folder after successful import.
- Clear notice that cloud provider's own privacy policy applies to files in their storage.

---

## 11. Implementation Tasks

### For Option A (Manual File Import) — Recommended

**Estimated effort:** Medium

#### Sub-step A: Data Model & Storage

1. Create `NoteSourceType` enum
2. Create `ImportMetadata` Hive model with type adapter
3. Create `ImportBatch` Hive model with type adapter
4. Create `ImportError` Hive model with type adapter
5. Create `ImportBatchStatus` enum
6. Add `sourceType` and `importMetadata` fields to existing `Note` model
7. Add `importBatchesBox` to HiveService initialization (AES-256 encrypted)
8. Write data migration: set `sourceType = in_app` for all existing notes
9. Run `build_runner` to regenerate type adapters

#### Sub-step B: File Handling & Processing

1. Add `file_picker` package for cross-platform file selection
2. Implement audio file validation (format check, corruption detection)
3. Implement metadata extraction (duration, recording date, file info)
4. Implement SHA-256 hash computation for duplicate detection
5. Implement audio format conversion for non-standard formats (using `ffmpeg_kit_flutter` or equivalent)
6. Implement chunked audio splitting for long recordings (silence detection preferred)
7. Implement chunk result stitching for merged transcription
8. Create `ImportService` to orchestrate the full import pipeline
9. Wire into existing AI transcription and structuring pipeline

#### Sub-step C: Repository & Provider Layer

1. Create `ImportRepository` with batch CRUD and file tracking methods
2. Create `importBatchProvider` (Notifier/NotifierProvider)
3. Add import-related methods to `NotesRepository` (create note with importMetadata)
4. Implement background processing support (isolate or background service for heavy processing)

#### Sub-step D: UI — Import Flow

1. Add "Import Recording" option to Home screen FAB menu
2. Implement file picker trigger with audio MIME type filtering
3. Create Import Confirmation screen (file list, preview, destination picker)
4. Implement audio preview playback (first 15 seconds)
5. Create Import Progress screen (batch progress, per-file status)
6. Implement background processing notification
7. Implement "Import & add to folder" flow from Folder detail screen
8. Implement "Import & add to project" flow from Project Document detail screen

#### Sub-step E: UI — Indicators & History

1. Create imported note badge widget
2. Add "Import Info" collapsible section to Note Detail screen
3. Create Import History screen (Settings → Import History)
4. Implement batch detail expansion view
5. Add duplicate warning UI in import confirmation

#### Sub-step F: Testing & Polish

1. Test with common audio formats: MP3 (128kbps, 320kbps), WAV (16-bit, 24-bit), M4A, AAC
2. Test with various durations: 30 sec, 5 min, 30 min, 2 hours
3. Test batch import: 1 file, 5 files, 20 files
4. Test duplicate detection accuracy
5. Test interrupted import recovery
6. Test with files that have no metadata
7. Test storage space warnings
8. Accessibility: screen reader labels for import flow
9. Performance: ensure large file import doesn't freeze UI

---

## 12. Future Enhancements

These are explicitly out of scope for the initial implementation but inform the architecture:

| Enhancement | Description | Depends On |
|---|---|---|
| **Bluetooth device pairing (Option B)** | Direct wireless transfer from smart recorders. Start with one pilot device. | Hardware for testing, manufacturer SDK |
| **Local folder watch (Option C lite)** | User sets a default import folder. App checks it on launch and offers to import new files. | Android `WorkManager`, iOS foreground check |
| **Cloud folder sync (Option C full)** | Watch Google Drive / Dropbox folder for new recordings. Requires OAuth. | Cloud provider APIs, privacy disclosure |
| **Auto-split by speaker** | For imported meeting recordings, detect different speakers and split/label accordingly. | Speaker diarization AI model |
| **Recorder device profiles** | Pre-configured profiles for popular recorders (Sony, Zoom, etc.) that auto-set expected format and quality. | User research, device testing |
| **Scheduled import check** | Background task that periodically checks default folder for new files (Android only). | Background service permissions |
| **Import from URL** | Paste a direct link to an audio file (e.g., from a voice message service) and import. | URL fetching, format detection |
| **Wearable trigger** | Smartwatch companion app that starts a recording on the phone remotely. | Wear OS / watchOS companion app |

---

## 13. Impact on Existing Code

### Files to Modify

| File / Area | Change |
|---|---|
| **Note Hive model** | Add `sourceType` and `importMetadata` fields |
| **Note type adapter** | Regenerate with build_runner |
| **HiveService** | Add `importBatchesBox` initialization |
| **Home Page** | Add "Import Recording" to FAB menu |
| **Note Detail Page** | Add "Import Info" section for imported notes |
| **Note list widgets** | Show imported badge conditionally |
| **go_router config** | Add routes for import confirmation, progress, and history screens |
| **Settings Page** | Add "Import History" menu item |
| **Folder Detail Page** | Add "Import into folder" action |
| **Project Document Detail** | Add "Import and add to project" action |

### New Files to Create

| File | Purpose |
|---|---|
| `lib/models/import_metadata.dart` | ImportMetadata Hive model |
| `lib/models/import_batch.dart` | ImportBatch Hive model |
| `lib/models/import_error.dart` | ImportError model |
| `lib/models/note_source_type.dart` | NoteSourceType enum |
| `lib/services/import_service.dart` | Orchestrates full import pipeline |
| `lib/services/audio_metadata_service.dart` | Extract metadata from audio files |
| `lib/services/audio_conversion_service.dart` | Format conversion and chunking |
| `lib/services/duplicate_detection_service.dart` | SHA-256 hash comparison |
| `lib/repositories/import_repository.dart` | CRUD for import batches |
| `lib/providers/import_provider.dart` | Riverpod provider for import state |
| `lib/pages/import_confirmation_page.dart` | File list and confirmation screen |
| `lib/pages/import_progress_page.dart` | Batch processing progress screen |
| `lib/pages/import_history_page.dart` | Settings → Import History screen |
| `lib/widgets/imported_note_badge.dart` | Badge widget for note lists |
| `lib/widgets/import_info_section.dart` | Collapsible import details for Note Detail |
| `lib/widgets/audio_preview_player.dart` | Short audio preview widget |

---

## 14. Dependencies (New Packages)

| Package | Purpose |
|---|---|
| `file_picker` | Cross-platform native file selection |
| `ffmpeg_kit_flutter` | Audio format detection, conversion, and metadata extraction |
| `crypto` (dart) | SHA-256 hash computation for duplicate detection |

---

## 15. Open Questions (To Resolve Before Development)

1. **Which option to build first?** — Option A recommended. Confirm or select alternative.
2. **Should imported audio be stored permanently or discarded after transcription?** — Recommendation: Store it, matching behavior of in-app recordings where audio is kept alongside transcript.
3. **What's the maximum batch size?** — Suggested: 20 files per batch to keep UI manageable and avoid overwhelming the processing queue.
4. **Should long recordings auto-split into multiple notes?** — Suggested: Give user the choice. Default to single note, with "Split" as an option for 30+ minute recordings.
5. **Do we need actual recorder devices for testing?** — Yes, at least 1–2 devices (recommend Sony ICD-UX570 and Zoom H1n) to test real-world file outputs and edge cases.
6. **Pro tier pricing impact?** — Does this feature alone justify Pro, or is it part of a broader Pro feature bundle? To be defined alongside monetization strategy.

---

*End of Feature Specification*
