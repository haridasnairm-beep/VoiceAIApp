# VoiceNotes AI — Feature Spec: Phase 1 Value Proposition Gaps

**Version:** 1.0
**Date:** 2026-03-02
**Status:** Draft — Pre-Launch Enhancements
**Phase:** Phase 1 (Pre-Play Store Release)
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md)

---

## Overview

This document specifies eight features identified as Phase 1 value proposition gaps — capabilities that competing note apps offer as standard and that users will expect at launch. These are not Phase 2 features; they are foundational gaps in the current v1.0.0 build that should be addressed **before or shortly after Play Store release** to maximize retention, ratings, and first-impression quality.

**Priority Order:**
1. Local Backup & Restore (Critical — data safety)
2. Trash / Soft Delete (Critical — accidental deletion protection)
3. App Lock — PIN / Biometric (Critical — privacy-first promise)
4. Pinned Notes (Quick win — high visibility, low effort)
5. Home Screen Widget (Quick win — high perceived value, interacts with App Lock)
6. Auto-Title Generation Improvements (UX polish)
7. AMOLED Dark Theme (UX polish — Play Store appeal)
8. Note Templates (Onboarding & adoption)

---

# Feature 1: Local Backup & Restore

## 1.1 Problem

VoiceNotes AI is a privacy-first, local-only app with no cloud backup. If a user uninstalls the app, switches phones, factory resets, or experiences data corruption, **all their notes, folders, projects, tasks, and recordings are permanently lost**. This is the single biggest risk to user trust and retention. Users of privacy-first apps expect a manual backup mechanism precisely because there is no cloud safety net.

## 1.2 Feature Summary

Allow users to export their entire VoiceNotes AI database (notes, folders, projects, settings, audio files, images) as a single encrypted archive file, and restore from that archive on the same or different device.

## 1.3 User Stories

1. **As a user**, I want to create a backup of all my data so I can restore it if I switch phones or reinstall the app.
2. **As a user**, I want the backup file to be encrypted so my voice notes remain private even if someone gets the file.
3. **As a user**, I want to restore from a backup file and have all my notes, folders, projects, and recordings come back exactly as they were.
4. **As a user**, I want to see when my last backup was created so I know if I need to make a new one.
5. **As a user**, I want to choose where to save my backup file (device storage, SD card, or share via any app).
6. **As a user**, I want to be warned before restoring that it will replace my current data.

## 1.4 Backup Contents

The backup archive must include:

| Data Type | Source | Format |
|---|---|---|
| Notes (all fields) | `notesBox` (Hive) | JSON |
| Folders | `foldersBox` (Hive) | JSON |
| Project Documents | `projectDocumentsBox` (Hive) | JSON |
| User Settings | `settingsBox` (Hive) | JSON |
| Audio recordings | App audio directory | WAV/AAC files |
| Photo attachments | App images directory | JPEG/PNG files |
| Backup metadata | Generated at export time | JSON (version, timestamp, note count, app version) |

## 1.5 Backup Format

```
voicenotes_backup_2026-03-02_143022.vnbak
├── manifest.json          ← Backup metadata (app version, creation date, counts)
├── data/
│   ├── notes.json         ← All notes serialized
│   ├── folders.json       ← All folders serialized
│   ├── projects.json      ← All project documents serialized
│   └── settings.json      ← User settings
├── audio/                 ← Audio recording files
│   ├── note_abc123.wav
│   └── note_def456.aac
└── images/                ← Photo attachments and image blocks
    ├── img_001.jpg
    └── img_002.png
```

- File extension: `.vnbak` (VoiceNotes Backup) — a renamed ZIP archive
- Encryption: AES-256 with a user-provided passphrase (prompted at backup creation)
- Compression: ZIP compression applied before encryption to reduce file size

## 1.6 User Flow — Create Backup

```
[Settings → Data & Storage → Backup & Restore]
    ↓
[Tap "Create Backup"]
    ↓
[Enter passphrase dialog — "Set a passphrase to protect your backup"]
    ├── Passphrase field (obscured, with show/hide toggle)
    ├── Confirm passphrase field
    ├── Strength indicator (weak/medium/strong)
    └── Warning: "If you forget this passphrase, the backup cannot be restored."
    ↓
[Progress indicator — "Creating backup... (X of Y files)"]
    ↓
[Backup complete — shows file size and note count]
    ↓
[Share sheet opens — user chooses where to save]
    ├── Save to device storage (Files / Downloads)
    ├── Google Drive / OneDrive / Dropbox (user's choice)
    ├── Share via email / messaging
    └── Save to SD card
```

## 1.7 User Flow — Restore from Backup

```
[Settings → Data & Storage → Backup & Restore]
    ↓
[Tap "Restore from Backup"]
    ↓
[Warning dialog: "Restoring will REPLACE all current data. This cannot be undone. Create a backup of your current data first?"]
    ├── [Create Backup First] → runs backup flow, then returns
    ├── [Continue Without Backup] → proceeds
    └── [Cancel]
    ↓
[File picker opens — select .vnbak file]
    ↓
[Enter passphrase dialog — "Enter the passphrase for this backup"]
    ↓
[Validation — check manifest.json, verify app version compatibility]
    ↓
[Preview screen — shows backup date, note count, folder count, project count, total size]
    ↓
[Tap "Restore"]
    ↓
[Progress indicator — "Restoring... (X of Y)"]
    ↓
[Complete — "Restored X notes, Y folders, Z projects. Restarting app..."]
    ↓
[App restarts with restored data]
```

## 1.8 UI Location

- **Settings → Data & Storage section** (new section, between existing storage display and Danger Zone)
- Shows: "Last backup: [date] ([size])" or "No backups created"
- Two buttons: "Create Backup" and "Restore from Backup"

## 1.9 Technical Considerations

- **Serialization**: Use `jsonEncode` on Hive model `.toMap()` methods (add `toMap()` / `fromMap()` to all Hive models if not present)
- **File handling**: Use `archive` (Dart package) for ZIP creation/extraction
- **Encryption**: Use `encrypt` (Dart package) with AES-256-CBC and PBKDF2 key derivation from passphrase
- **Large backups**: Process in isolate to avoid UI jank; show progress for each stage (serializing, copying files, compressing, encrypting)
- **Version compatibility**: `manifest.json` includes `appVersion` and `backupFormatVersion`; restore logic checks compatibility before proceeding
- **Audio files**: Copy by reference (file path in note model) → resolve to actual files during backup
- **Restore strategy**: Clear all existing Hive boxes → populate from backup JSON → copy audio/image files to app directories → restart

## 1.10 Edge Cases

| Scenario | Handling |
|---|---|
| Backup file too large for device storage | Show estimated size before creating; warn if < 500MB free |
| Restore on different OS (Android → iOS) | Audio format compatibility check; WAV works on both; AAC may need re-encoding |
| Backup from newer app version | Show warning: "This backup was created with a newer version. Some data may not restore correctly." |
| Backup from older app version | Apply data migration logic (same as app upgrade migrations) |
| Corrupt backup file | Validate ZIP integrity and manifest before starting restore; show error if invalid |
| Wrong passphrase | Show "Incorrect passphrase" after decryption attempt fails; allow retry |
| Backup interrupted (app killed) | Incomplete backup file is invalid; user must retry |
| Restore interrupted | App may be in inconsistent state; show "Restore incomplete — please restore again" on next launch |

## 1.11 New Dependencies

| Package | Purpose |
|---|---|
| `archive` | ZIP creation and extraction (pure Dart) |
| `encrypt` | AES-256 encryption/decryption with PBKDF2 |

## 1.12 Estimated Effort

**Medium-Large** — Data serialization for all models, file collection, encryption, progress UI, restore with migration logic.

---

# Feature 2: Trash / Soft Delete

## 2.1 Problem

Currently, deleting a note, folder, or project is permanent after a single confirmation dialog. Accidental deletion with no recovery path is a significant source of user frustration and negative Play Store reviews. Every major note-taking app (Google Keep, Apple Notes, Notion, Evernote) offers a trash/recycle bin.

## 2.2 Feature Summary

Instead of permanently deleting items, move them to a Trash folder with a 30-day retention period. Users can restore items from Trash or permanently delete them. After 30 days, items are auto-purged.

## 2.3 User Stories

1. **As a user**, I want deleted notes to go to Trash instead of being permanently deleted so I can recover them if I made a mistake.
2. **As a user**, I want to see all deleted items in one place so I can review what I've removed.
3. **As a user**, I want to restore a deleted note to its original folder and project so everything goes back to how it was.
4. **As a user**, I want deleted items to auto-delete after 30 days so Trash doesn't grow forever.
5. **As a user**, I want the option to permanently delete from Trash immediately if I'm sure.
6. **As a user**, I want to empty the entire Trash at once.

## 2.4 Scope

Soft delete applies to:

| Item Type | Soft Delete | Restore Behavior |
|---|---|---|
| Notes | ✅ | Restores note, reconnects to original folder and projects |
| Folders | ✅ | Restores folder; contained notes that were also trashed are restored with it |
| Project Documents | ✅ | Restores project; note references preserved if source notes still exist |

Items NOT in Trash (cascading behavior):
- Deleting a **folder** moves the folder to Trash; notes inside are **not** moved to Trash (they become unfiled)
- Deleting a **project document** moves it to Trash; linked notes are **not** affected
- Deleting a **note** that is referenced by a project document → project shows "Note deleted" placeholder (existing behavior) → restoring the note reconnects the reference

## 2.5 Data Model Changes

### Note Model — Add Fields

```dart
// Add to existing Note Hive model
bool isDeleted = false;              // Soft delete flag
DateTime? deletedAt;                 // When it was moved to trash
String? previousFolderId;            // To restore to original folder
List<String>? previousProjectIds;    // To restore project references
```

### Folder Model — Add Fields

```dart
bool isDeleted = false;
DateTime? deletedAt;
```

### ProjectDocument Model — Add Fields

```dart
bool isDeleted = false;
DateTime? deletedAt;
```

## 2.6 User Flow — Delete

```
[User taps Delete on a note/folder/project]
    ↓
[Confirmation: "Move to Trash? You can restore it within 30 days."]
    ├── [Move to Trash] → sets isDeleted=true, deletedAt=now, saves previousFolderId/previousProjectIds
    └── [Cancel]
    ↓
[Item disappears from active lists]
[SnackBar: "Note moved to Trash" with [Undo] action (5 seconds)]
```

## 2.7 User Flow — Trash Screen

```
[App Menu (3-dot) → Trash]
    ↓
[Trash Screen]
    ├── Header: "Trash" with item count
    ├── Info bar: "Items are permanently deleted after 30 days"
    ├── "Empty Trash" button (with confirmation dialog)
    ├── Tab bar or section headers: Notes | Folders | Projects
    └── Each item shows:
        ├── Item title/name
        ├── "Deleted X days ago" or "Deleted on [date]"
        ├── Days remaining badge ("23 days left")
        └── Swipe actions or overflow menu:
            ├── Restore
            └── Delete Permanently
```

## 2.8 User Flow — Restore

```
[Tap Restore on a trashed item]
    ↓
[Item restored:]
    ├── isDeleted = false
    ├── deletedAt = null
    ├── Note: re-assigned to previousFolderId (if folder still exists, else unfiled)
    ├── Note: re-linked to previousProjectIds (if projects still exist)
    └── previousFolderId / previousProjectIds cleared
    ↓
[SnackBar: "Note restored" with [View] action → navigates to item]
```

## 2.9 Auto-Purge Logic

- On app launch, check all trashed items
- If `deletedAt` is more than 30 days ago → permanently delete (remove from Hive, delete audio files, delete images)
- Also purge associated notifications for trashed reminders

## 2.10 UI Integration

| Location | Change |
|---|---|
| Home page note list | Filter out `isDeleted == true` items |
| Folder detail | Filter out deleted notes |
| Project document blocks | Show "Note in Trash" placeholder for trashed notes (with "Restore" quick action) |
| Search | Exclude trashed items from results (optionally add "Search Trash" toggle) |
| Tasks view | Exclude tasks from trashed notes |
| Stats cards | Exclude trashed items from counts |
| App menu (3-dot) | Add "Trash" entry with item count badge |
| Storage display | Show trash storage separately: "Trash: X MB (Y items)" |

## 2.11 Technical Considerations

- **Query filtering**: All existing note/folder/project queries must add `where isDeleted == false` filter
- **Hive adapter regeneration**: New fields require `build_runner` run
- **Data migration**: Existing items get `isDeleted = false` on first launch after update
- **Bulk operations**: Multi-select delete on Home page should also soft-delete (move to Trash)
- **"Delete All Data" in Danger Zone**: Bypasses Trash — truly permanent (with explicit warning)

## 2.12 Estimated Effort

**Medium** — Model changes, query filtering across all screens, Trash screen UI, auto-purge logic, undo SnackBar.

---

# Feature 3: Pinned Notes

## 3.1 Problem

Frequently referenced notes (ongoing projects, daily checklists, important contacts, reference material) get buried in the chronological feed as new notes are added. Users have no way to keep important notes easily accessible without scrolling.

## 3.2 Feature Summary

Allow users to pin notes to the top of the Home page notes feed. Pinned notes appear in a dedicated section above the chronological feed, sorted by pin date (most recently pinned first).

## 3.3 User Stories

1. **As a user**, I want to pin important notes so they always appear at the top of my notes list.
2. **As a user**, I want to unpin notes when they're no longer a priority.
3. **As a user**, I want to see a clear visual separation between pinned and regular notes.

## 3.4 Data Model Changes

```dart
// Add to existing Note Hive model
bool isPinned = false;
DateTime? pinnedAt;      // For sort order within pinned section
```

## 3.5 UI Design

### Home Page Notes Feed

```
┌─────────────────────────────────┐
│  📌 Pinned (3)                  │  ← Section header (collapsible)
├─────────────────────────────────┤
│  [Note Card - Kitchen Reno]     │  ← Pinned notes, sorted by pinnedAt desc
│  [Note Card - Weekly Goals]     │
│  [Note Card - API Reference]    │
├─────────────────────────────────┤
│  Recent                         │  ← Section header
├─────────────────────────────────┤
│  [Note Card - Today 2:30 PM]    │  ← Regular chronological feed
│  [Note Card - Today 10:15 AM]   │
│  [Note Card - Yesterday]        │
│  ...                            │
└─────────────────────────────────┘
```

### Pin/Unpin Actions

| Trigger | Action |
|---|---|
| Long-press note card → overflow menu | "Pin to Top" / "Unpin" option |
| Note Detail page → AppBar overflow menu | "Pin to Top" / "Unpin" option |
| Multi-select mode | "Pin" / "Unpin" in bottom action bar |
| Swipe gesture (optional) | Swipe right to pin/unpin |

### Visual Indicators

- Pinned note cards show a small 📌 pin icon in the top-right corner
- "Pinned" section header with pin icon and count badge
- Section header is collapsible (tap to expand/collapse pinned section)

## 3.6 Behavior Rules

- Maximum pinned notes: **10** (show warning if user tries to pin more: "Unpin a note first to pin this one")
- Pinned notes still appear in folder views and search results (but without special positioning)
- Pinned notes respect filter chips (if "Todos" filter is active, only pinned notes with todos are shown in pinned section)
- Trashed pinned notes lose their pin status on restore

## 3.7 Technical Considerations

- Add `isPinned` and `pinnedAt` to Note Hive model → `build_runner`
- Modify `notesProvider` to return two lists: pinned (sorted by `pinnedAt` desc) and unpinned (sorted by `createdAt` desc)
- Home page `ListView.builder` renders pinned section header + pinned items + regular section header + regular items
- Data migration: all existing notes get `isPinned = false`

## 3.8 Estimated Effort

**Small** — Two new fields, sort logic change, section header UI, pin/unpin actions.

---

# Feature 4: Home Screen Widget

## 4.1 Problem

Opening the app, waiting for splash screen, and navigating to the record screen adds friction to quick voice capture. Competing apps (Google Keep, Otter.ai) offer home screen widgets for instant recording. For a voice-first app, reducing capture friction is critical.

## 4.2 Feature Summary

A minimal home screen widget that provides one-tap access to start a voice recording, plus a glanceable view of recent notes or open task count. **Widget behavior adapts automatically when App Lock (Feature 8) is enabled** — see section 4.7 for the interaction model.

## 4.3 Widget Variants

### Variant A: Quick Record Widget (Small — 2×1)

```
┌─────────────────────────┐
│  🎙️ VoiceNotes AI       │
│  Tap to Record           │
└─────────────────────────┘
```

- Single tap → launches app directly into Recording Screen
- Shows app icon and "Tap to Record" text
- Minimal footprint
- **App Lock behavior:** Always works the same regardless of App Lock — no content is displayed

### Variant B: Dashboard Widget (Medium — 4×2)

```
┌─────────────────────────────────────┐
│  VoiceNotes AI              🎙️ REC  │
│                                     │
│  📝 42 Notes  ✅ 7 Open Tasks      │
│  Latest: "Kitchen renovation..."    │
└─────────────────────────────────────┘
```

- Record button → launches Recording Screen
- Note count and open task count (tappable → opens respective tab)
- Latest note preview (tappable → opens Note Detail)
- Refreshes periodically
- **App Lock behavior:** Content adapts based on Widget Privacy setting (see 4.7)

## 4.4 User Stories

1. **As a user**, I want to start recording a voice note from my home screen without opening the app first.
2. **As a user**, I want to see how many open tasks I have at a glance from my home screen.
3. **As a user**, I want to tap my latest note from the widget to quickly review it.
4. **As a user with App Lock enabled**, I want to control what information the widget shows so my notes stay private even on my home screen.
5. **As a user with App Lock enabled**, I still want to record quickly from the widget without unlocking the app every time.

## 4.5 Technical Implementation

### Android

- Use `home_widget` Flutter package
- Widget defined in `android/app/src/main/res/layout/widget_layout.xml`
- `AppWidgetProvider` class handles updates and click intents
- Deep-link intent to recording screen: `voicenotesai://record`
- Background data refresh via `WorkManager` (every 30 minutes) or on app foreground
- Widget reads App Lock and Widget Privacy settings from shared preferences to determine display mode

### iOS

- Use `WidgetKit` via `home_widget` package
- SwiftUI widget definition in iOS widget extension
- Timeline provider refreshes data periodically
- App Intent for launching into recording screen
- Shared `UserDefaults` (app group) for passing data from Flutter to widget
- Widget reads App Lock and Widget Privacy settings from shared UserDefaults

### Package

| Package | Purpose |
|---|---|
| `home_widget` | Cross-platform home screen widget support (Android + iOS) |

## 4.6 Estimated Effort

**Medium** — Platform-specific widget layouts, deep-link handling, background data refresh, widget update triggers on note creation/deletion, App Lock-aware display logic.

## 4.7 App Lock Interaction Model

> **Cross-reference:** This section defines how the Home Screen Widget interacts with App Lock (Feature 8). Both features must be aware of each other.

### The Conflict

App Lock protects note content behind authentication. The Dashboard Widget (Variant B) displays note content (counts, preview text) on the home screen without authentication. These two features contradict each other if not handled carefully.

### Widget Privacy Setting

When **both** App Lock and Home Screen Widget are active, a **Widget Privacy** setting appears in Settings → Security → Widget Privacy. This setting controls what the Dashboard Widget displays.

| Privacy Level | Widget Shows | Record Button Behavior | Default? |
|---|---|---|---|
| **Full** | Note count, task count, latest note preview | Records without auth | No |
| **Record-Only** | Note count, task count only (no text content) | Records without auth | **Yes (default)** |
| **Minimal** | App icon and "Tap to Record" only (no data) | Opens App Lock → then Recording Screen | No |

- The Quick Record Widget (Variant A) is unaffected by this setting — it never shows content
- Widget Privacy setting is **only visible** when App Lock is enabled; hidden otherwise
- When App Lock is disabled, Dashboard Widget always shows full content

### Key Design Principle

**Recording is a write operation (adding data), not a read operation (viewing data).** Allowing unauthenticated recording while requiring authentication for viewing is both secure and practical. The user is adding new encrypted data, not accessing existing data.

### Decision Flows

**Widget Display:**
```
[Widget Refresh Triggered]
    ↓
[Is App Lock enabled?]
    ├── NO → Show full widget (counts + preview text)
    └── YES → Read Widget Privacy setting
            ├── "Full" → Show everything (user accepted the tradeoff)
            ├── "Record-Only" → Show counts only, hide latest note preview
            └── "Minimal" → Show only app icon + "Tap to Record" text
```

**Widget Record Tap:**
```
[User Taps Record on Widget]
    ↓
[Is App Lock enabled?]
    ├── NO → Launch Recording Screen directly
    └── YES → Read Widget Privacy setting
            ├── "Full" or "Record-Only"
            │   → Launch Recording Screen directly (skip App Lock)
            │   → Note saved to encrypted Hive
            │   → If user opens app to view notes → App Lock triggers
            └── "Minimal"
                → Launch App → App Lock screen → Recording Screen
```

**Widget Content Tap (counts, preview):**
```
[User Taps Note Count / Task Count / Note Preview on Widget]
    ↓
[Is App Lock enabled?]
    ├── NO → Launch app to respective screen
    └── YES → Launch app → App Lock screen → then navigate to respective screen
```

### First-Time Setup Prompt

When a user enables App Lock and already has the Home Screen Widget active, show a one-time dialog:

```
┌─────────────────────────────────────────┐
│  🔒 Widget Privacy                       │
│                                          │
│  Your home screen widget may display     │
│  note information. How much should it    │
│  show when your app is locked?           │
│                                          │
│  ○ Full — counts + note preview          │
│  ● Record-Only — counts only (default)   │
│  ○ Minimal — icon + record button only   │
│                                          │
│  You can change this later in Settings.  │
│                                          │
│           [ Save ]                       │
└─────────────────────────────────────────┘
```

Conversely, when a user adds the Dashboard Widget and App Lock is already enabled, the same prompt appears.

### Edge Cases

| Scenario | Handling |
|---|---|
| User records via widget (Record-Only mode) then opens app | App Lock triggers before showing any content, including the just-recorded note |
| User disables App Lock | Widget Privacy setting hides from Settings; widget reverts to full display |
| User re-enables App Lock | Widget Privacy setting reappears with previous selection preserved |
| Widget shows counts but App Lock is on — does count update leak info? | Counts (e.g., "43 Notes") are low-sensitivity metadata; only text previews leak content. Record-Only mode is the safe default. |

---

# Feature 5: Auto-Title Generation Improvements

## 5.1 Problem

In Phase 1 without AI, note titles are either user-provided or derived from the first few words of the transcription. This results in unhelpful titles like "So I was thinking about..." or "Okay remind me to..." that make the notes feed hard to scan. Better local heuristics can significantly improve the browsing experience without any AI dependency.

## 5.2 Feature Summary

Implement a local (no AI, no cloud) title generation algorithm that extracts a meaningful, scannable title from the transcription text using keyword extraction and pattern matching.

## 5.3 Algorithm

```
Input: Raw transcription text
Output: Title string (max 60 characters)

Step 1: Strip filler phrases
    Remove: "so", "okay", "um", "uh", "like", "you know",
            "I was thinking", "remind me to", "I need to",
            "let me", "basically", "actually", "well"

Step 2: Extract first meaningful sentence
    Split by sentence boundaries (. ! ?)
    Take the first sentence that is > 3 words after filler removal

Step 3: Apply fallback patterns
    If no good sentence found:
    - If note has todos → "Tasks: [first todo text]"
    - If note has reminders → "Reminder: [first reminder text]"
    - If note has action items → "Action: [first action text]"
    - Else → "[Date] [Time] Voice Note"

Step 4: Truncate and clean
    Trim to 60 characters at word boundary
    Capitalize first letter
    Remove trailing conjunctions ("and", "but", "or")
    Add "..." if truncated
```

## 5.4 Implementation

- Create `TitleGeneratorService` — pure Dart utility class, no dependencies
- Call after transcription is finalized (both live STT and Whisper modes)
- Store generated title in `Note.title` (user can still edit manually)
- If user has manually edited the title, do not overwrite on subsequent transcription edits

## 5.5 Existing Title Behavior

| Current | Proposed |
|---|---|
| First ~30 chars of raw transcription | Smart extraction after filler removal |
| No awareness of note content type | Falls back to task/reminder-based titles |
| No truncation logic | Clean truncation at word boundary with "..." |

## 5.6 Estimated Effort

**Small** — Pure Dart string processing, no model changes, no UI changes, integrates into existing save flow.

---

# Feature 6: AMOLED Dark Theme

## 6.1 Problem

The current dark theme uses standard dark gray backgrounds (Material Design defaults). Many Android users specifically search for and prefer AMOLED/true black themes because they save battery on OLED screens and are easier on the eyes in dark environments. This is a frequently mentioned preference in Play Store reviews for note-taking apps.

## 6.2 Feature Summary

Add a third theme option: "AMOLED Dark" (pure black backgrounds) alongside the existing Light, Dark, and System options.

## 6.3 Theme Values

| Element | Current Dark Theme | AMOLED Dark Theme |
|---|---|---|
| Scaffold background | `#121212` (Material dark) | `#000000` (pure black) |
| Card background | `#1E1E1E` | `#0A0A0A` |
| Surface color | `#1E1E1E` | `#000000` |
| AppBar background | `#1E1E1E` | `#000000` |
| Bottom navigation | `#1E1E1E` | `#000000` |
| Dividers | `#2C2C2C` | `#1A1A1A` |
| Primary text | `#FFFFFF` | `#FFFFFF` |
| Secondary text | `#B3B3B3` | `#999999` |
| Accent color | Same as current theme | Same as current theme |

## 6.4 UI Location

**Settings → Appearance → Theme**

Current options:
- Light
- Dark
- System

New options:
- Light
- Dark
- AMOLED Dark
- System (follows OS; uses Dark or AMOLED Dark based on sub-selection)

## 6.5 Implementation

- Create `amoledDarkTheme` in theme configuration (copy `darkTheme`, override background/surface colors)
- Add `ThemeMode.amoledDark` option to `UserSettings` model (or use a string enum since Flutter's built-in `ThemeMode` only has light/dark/system)
- Update `settingsProvider` to expose the new theme
- Update `MaterialApp` to select between three theme data objects
- Migration: existing "dark" users remain on standard dark

## 6.6 Estimated Effort

**Small** — Theme data copy with color overrides, settings picker update, one new enum value.

---

# Feature 7: Note Templates

## 7.1 Problem

New users opening VoiceNotes AI for the first time face a blank canvas. They know they can record, but they may not know what kinds of notes the app is best at organizing. Templates provide guided starting points that showcase the app's structuring capabilities (actions, todos, reminders) and help users develop note-taking habits.

## 7.2 Feature Summary

Offer a set of built-in note templates that pre-populate a new text note with structured placeholders. Users select a template when creating a new text note, and the template content appears in the editor ready to be filled in or spoken over.

## 7.3 Built-in Templates

| Template Name | Icon | Pre-filled Content |
|---|---|---|
| **Meeting Notes** | 🤝 | `## Meeting: [Topic]\n### Date: [Today]\n### Attendees:\n- \n\n### Discussion Points:\n1. \n\n### Action Items:\n- [ ] \n\n### Next Steps:\n- ` |
| **Daily Journal** | 📔 | `## [Today's Date]\n\n### How am I feeling today?\n\n\n### What happened today?\n\n\n### What am I grateful for?\n1. \n2. \n3. \n\n### Tomorrow's priorities:\n- [ ] ` |
| **Idea Capture** | 💡 | `## Idea: [Title]\n\n### The idea:\n\n\n### Why it matters:\n\n\n### Next steps to explore:\n- [ ] \n\n### Related to:\n- ` |
| **Grocery List** | 🛒 | `## Grocery List — [Date]\n\n### Produce:\n- [ ] \n\n### Dairy & Eggs:\n- [ ] \n\n### Meat & Protein:\n- [ ] \n\n### Pantry:\n- [ ] \n\n### Other:\n- [ ] ` |
| **Project Planning** | 📋 | `## Project: [Name]\n\n### Goal:\n\n\n### Key milestones:\n- [ ] \n- [ ] \n- [ ] \n\n### Resources needed:\n- \n\n### Risks:\n- \n\n### Deadline: ` |
| **Quick Checklist** | ✅ | `## [Checklist Title]\n\n- [ ] \n- [ ] \n- [ ] \n- [ ] \n- [ ] ` |

## 7.4 User Flow

```
[Home Page → SpeedDialFab → "New Text Note"]
    ↓
[Template Picker Bottom Sheet]
    ├── "Blank Note" (default — no template, current behavior)
    ├── "Meeting Notes" 🤝
    ├── "Daily Journal" 📔
    ├── "Idea Capture" 💡
    ├── "Grocery List" 🛒
    ├── "Project Planning" 📋
    └── "Quick Checklist" ✅
    ↓
[Note Detail opens with template content pre-filled in editor]
    ↓
[User edits/fills in the template]
```

## 7.5 Template Storage

- Built-in templates are **hardcoded** in a Dart constants file (`lib/constants/note_templates.dart`)
- No Hive storage needed for built-in templates
- Each template is a simple data class:

```dart
class NoteTemplate {
  final String id;
  final String name;
  final String icon;       // Emoji or icon name
  final String content;    // Markdown-formatted template text
  final String category;   // "productivity", "personal", "planning"
}
```

## 7.6 Future Extension (Phase 2+)

- **Custom templates**: Users create and save their own templates from existing notes
- **Template suggestions**: After a user records a meeting note, suggest "Save as template?"
- **Template gallery**: Community-shared templates (requires cloud)

## 7.7 Estimated Effort

**Small** — Template data class, constants file with 6 templates, bottom sheet picker UI, pre-fill logic in note creation flow.

---

# Feature 8: App Lock (PIN / Biometric)

## 8.1 Problem

VoiceNotes AI stores deeply personal content — private thoughts, meeting notes with confidential information, medical observations, personal journal entries, financial details. The app currently opens directly to the Home screen with all notes visible to anyone who picks up the unlocked phone. While the phone itself may have a lock screen, users often hand their phone to others (children, colleagues, friends) or leave it unlocked on a desk. A dedicated app lock is the expected standard for any app that stores sensitive personal data — competitors like Standard Notes, Day One, and even banking apps all offer this. For a privacy-first app, the absence of app-level protection undermines the core brand promise.

## 8.2 Feature Summary

Allow users to protect VoiceNotes AI with a PIN code, fingerprint, or face recognition. When enabled, the app requires authentication every time it is opened or brought back from background after a configurable timeout. The lock screen appears before any content is shown.

## 8.3 User Stories

1. **As a user**, I want to lock VoiceNotes AI with my fingerprint so nobody else can read my notes if they pick up my phone.
2. **As a user**, I want to set a PIN as a fallback if biometric authentication fails or isn't available on my device.
3. **As a user**, I want to control how quickly the app locks after I leave it — immediately, after 1 minute, or after 5 minutes.
4. **As a user**, I want the lock screen to show no preview of my notes — just the app logo and authentication prompt.
5. **As a user with the Home Screen Widget**, I want to control what the widget shows when App Lock is enabled so my notes stay private.
6. **As a user**, I want to still be able to record a voice note from the widget without unlocking the app every time, because recording adds data rather than exposing it.

## 8.4 Authentication Methods

| Method | Platform | Package | Priority |
|---|---|---|---|
| Fingerprint | Android, iOS | `local_auth` | Primary |
| Face ID | iOS | `local_auth` | Primary |
| Face Unlock | Android (device-dependent) | `local_auth` | Primary |
| PIN (4-6 digits) | Android, iOS | Custom implementation | Fallback (always available) |

- **Biometric is the primary method** — fastest, most convenient
- **PIN is always required as fallback** — set during initial App Lock setup
- If biometric auth fails 3 times, automatically falls back to PIN
- If device has no biometric hardware, only PIN is available

## 8.5 User Flow — Enable App Lock

```
[Settings → Security → App Lock]
    ↓
[Toggle "Enable App Lock" ON]
    ↓
[Set PIN screen]
    ├── "Create a 4-6 digit PIN"
    ├── PIN entry keypad (obscured dots)
    ├── "Confirm PIN" (enter again)
    └── Warning: "If you forget your PIN, you'll need to reinstall the app.
         Make sure you have a backup first."
    ↓
[Biometric prompt (if available)]
    ├── "Enable fingerprint/Face ID unlock?"
    ├── [Enable] → tests biometric → success → enabled
    └── [Skip] → PIN only
    ↓
[Auto-lock timeout picker]
    ├── Immediately (default)
    ├── After 1 minute
    ├── After 5 minutes
    └── After 15 minutes
    ↓
[Widget Privacy prompt — shown ONLY if Home Screen Widget is active]
    ├── "Your home screen widget may display note information."
    ├── "How much should it show when your app is locked?"
    ├── ○ Full — counts + note preview
    ├── ● Record-Only — counts only (default)
    ├── ○ Minimal — icon + record button only
    └── "You can change this later in Settings."
    ↓
[App Lock enabled — confirmation]
```

## 8.6 User Flow — Unlock App

```
[User opens app or returns from background (after timeout)]
    ↓
[Lock Screen]
    ├── App logo (centered, matches splash screen style)
    ├── "VoiceNotes AI" title
    ├── Biometric prompt (auto-triggered if enabled)
    │   ├── Success → unlock → show last screen
    │   └── Failure → show "Try again" or fall back to PIN after 3 failures
    ├── "Use PIN" button (always visible)
    │   ├── PIN keypad
    │   ├── Success → unlock
    │   └── Wrong PIN → shake animation, "Incorrect PIN"
    │       └── After 5 wrong attempts → 30-second cooldown → 1 minute → 5 minutes (progressive lockout)
    └── No "cancel" — user must authenticate or close the app
```

## 8.7 Auto-Lock Behavior

| Event | Behavior |
|---|---|
| App moved to background | Start auto-lock timer (based on timeout setting) |
| App returns to foreground within timeout | No lock — resume normally |
| App returns to foreground after timeout | Show lock screen |
| App killed and re-launched | Always show lock screen |
| Phone locked and unlocked | If app was in background, apply timeout rule |
| Incoming phone call during recording | Do NOT lock — recording continues, timer pauses |
| Notification tap (reminder deep-link) | Show lock screen first → authenticate → navigate to note |
| Widget record tap (Full/Record-Only mode) | Skip lock → go to Recording Screen → lock when viewing notes |
| Widget record tap (Minimal mode) | Show lock screen → authenticate → go to Recording Screen |
| Widget content tap (counts/preview) | Show lock screen → authenticate → navigate to content |

## 8.8 Settings UI

```
Settings
├── ...existing sections...
├── Security                              ← New section
│   ├── App Lock                    [toggle]
│   │   ├── Change PIN              [→]
│   │   ├── Biometric Unlock        [toggle]  (hidden if no biometric hardware)
│   │   ├── Auto-Lock Timeout       [picker: Immediately / 1 min / 5 min / 15 min]
│   │   └── Widget Privacy          [picker: Full / Record-Only / Minimal]
│   │       (visible ONLY when App Lock is ON and widget is active)
│   └── (Future: Change Passphrase for backup encryption)
├── ...existing sections...
```

## 8.9 Lock Screen UI Design

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│          [App Logo]             │  ← Same logo as splash screen
│       VoiceNotes AI             │
│                                 │
│     ┌─────────────────┐        │
│     │  🔐 Use PIN      │        │  ← Or biometric auto-prompt
│     └─────────────────┘        │
│                                 │
│     ┌───┬───┬───┐             │
│     │ 1 │ 2 │ 3 │             │  ← PIN keypad (shown after "Use PIN" tap)
│     ├───┼───┼───┤             │
│     │ 4 │ 5 │ 6 │             │
│     ├───┼───┼───┤             │
│     │ 7 │ 8 │ 9 │             │
│     ├───┼───┼───┤             │
│     │   │ 0 │ ⌫ │             │
│     └───┴───┴───┘             │
│                                 │
│     ● ● ● ○ ○ ○               │  ← PIN dots (filled as entered)
│                                 │
└─────────────────────────────────┘
```

- Background matches current theme (light/dark/AMOLED)
- No note content, previews, or data visible behind the lock
- Smooth transition animation on unlock (fade or slide up)

## 8.10 Data Model Changes

```dart
// Add to UserSettings Hive model
bool appLockEnabled = false;
String? appLockPinHash;              // SHA-256 hash of PIN (never store raw PIN)
bool biometricEnabled = false;
int autoLockTimeoutSeconds = 0;      // 0 = immediately, 60, 300, 900
String widgetPrivacyLevel = 'record_only';  // 'full', 'record_only', 'minimal'
```

- PIN is stored as a **salted SHA-256 hash**, never in plain text
- Salt is generated per-device and stored in `flutter_secure_storage` (not in Hive)
- Biometric credentials are handled entirely by the OS — only the enabled/disabled flag is stored

## 8.11 Technical Implementation

### Core Lock Logic

- Create `AppLockService` — manages lock state, timeout tracking, authentication
- Use `WidgetsBindingObserver` to detect app lifecycle changes (`didChangeAppLifecycleState`)
- Track `lastBackgroundedAt` timestamp; compare with timeout on resume
- Lock screen is a full-screen overlay pushed via `Navigator` above all routes (not a route itself — prevents back-button bypass)

### Biometric Authentication

- Use `local_auth` package — supports fingerprint, Face ID, and Android face unlock
- Check `canCheckBiometrics` and `getAvailableBiometrics` before showing biometric option
- Handle platform-specific biometric prompts (Android dialog vs iOS native Face ID)

### PIN Authentication

- Custom PIN entry widget with keypad
- SHA-256 hash comparison (input → hash → compare with stored hash)
- Progressive lockout: track failed attempts in memory (resets on app restart — deliberate choice to avoid permanent lockout)

### App Recents / Task Switcher Protection

- On Android: set `FLAG_SECURE` on the window when App Lock is enabled — this hides app content in the task switcher (shows blank/blurred preview)
- On iOS: overlay a blur or the lock screen when app enters background (captured in `didChangeAppLifecycleState`)

### Packages

| Package | Purpose |
|---|---|
| `local_auth` | Biometric authentication (fingerprint, Face ID) |
| `crypto` (dart) | SHA-256 hashing for PIN storage |

## 8.12 Security Considerations

| Concern | Mitigation |
|---|---|
| PIN brute-force | Progressive lockout (30s → 1min → 5min after repeated failures) |
| PIN stored insecurely | Salted SHA-256 hash only; salt in flutter_secure_storage |
| Task switcher leaks content | FLAG_SECURE (Android) / background blur (iOS) |
| Screenshot while app is open | Optional: FLAG_SECURE blocks screenshots when lock is enabled (user-configurable — some users want screenshots) |
| Forgot PIN | No recovery without reinstall — show warning during setup; encourage backup first |
| Biometric spoofing | Handled by OS-level biometric security; app trusts OS verdict |
| Background recording bypasses lock | By design — recording is a write operation, not a read operation |
| Notification content visible on lock screen | Reminder notifications should use `setVisibility(VISIBILITY_SECRET)` when App Lock is enabled — shows "VoiceNotes AI reminder" without note content |

## 8.13 Interaction with Other Features

| Feature | Impact |
|---|---|
| **Home Screen Widget** | Widget Privacy setting controls display. See Feature 4, section 4.7 for full interaction model. |
| **Local Backup & Restore** | App Lock PIN/biometric settings are included in backup. On restore, App Lock is restored with the same PIN hash. User must remember their PIN. |
| **Trash** | Trash screen requires authentication (behind App Lock like all other screens). |
| **Notifications (Reminders)** | When App Lock is enabled, notification content is hidden on the device lock screen. Tapping a notification opens the app → lock screen → authenticate → navigate to note. |
| **Share / Export** | Sharing and exporting work normally after authentication — no additional prompt. |
| **Onboarding** | First-time setup (onboarding flow) is never blocked by App Lock — it's only enabled after initial setup via Settings. |

## 8.14 Edge Cases

| Scenario | Handling |
|---|---|
| User forgets PIN, no biometric | Must reinstall app. Data is lost unless they have a backup. Show this warning during setup. |
| Device has no biometric hardware | PIN-only mode; biometric toggle hidden in settings |
| Biometric enrolled/removed at OS level after App Lock setup | On next unlock, `local_auth` returns error → fall back to PIN; show "Biometric changed — please re-enable in settings" |
| User disables App Lock | Prompt for current PIN/biometric to confirm → disable → widget reverts to full display |
| App update resets lock state? | No — lock settings stored in encrypted Hive, persist across updates |
| Multiple failed biometric attempts | After 3 failures, auto-switch to PIN keypad |
| Phone restarts | App Lock triggers on first open (cold start always requires auth) |

## 8.15 Estimated Effort

**Medium** — Lock screen UI, PIN setup/verification flow, biometric integration via `local_auth`, lifecycle observer for auto-lock timing, FLAG_SECURE for task switcher, Widget Privacy setting and cross-feature logic.

---

# Implementation Priority & Dependency Map

```
                    No Dependencies
                    ┌─────────────┐
                    │   Pinned    │ ← Small effort, immediate value
                    │   Notes     │
                    └─────────────┘
                    ┌─────────────┐
                    │  AMOLED     │ ← Small effort, Play Store appeal
                    │  Dark Theme │
                    └─────────────┘
                    ┌─────────────┐
                    │  Auto-Title │ ← Small effort, UX improvement
                    │  Generation │
                    └─────────────┘
                    ┌─────────────┐
                    │    Note     │ ← Small effort, adoption boost
                    │  Templates  │
                    └─────────────┘

                    Model Changes Required
                    ┌─────────────┐
                    │   Trash /   │ ← Medium effort, touches all queries
                    │ Soft Delete │
                    └─────────────┘

                    Mutual Dependency (build together or App Lock first)
                    ┌─────────────┐       ┌─────────────┐
                    │  App Lock   │◄─────►│ Home Screen │
                    │ PIN/Biomet. │       │   Widget    │
                    └─────────────┘       └─────────────┘
                      Medium effort         Medium effort
                           │                     │
                           └──────┬──────────────┘
                                  ▼
                    Widget Privacy setting bridges both features.
                    Build App Lock first (or in parallel) so the
                    Widget can read lock state on first release.

                    Highest Effort
                    ┌─────────────┐
                    │   Local     │ ← Medium-Large effort, most critical
                    │   Backup    │   (App Lock settings included in backup)
                    └─────────────┘
```

**Recommended implementation order:**
1. Pinned Notes + AMOLED Dark Theme + Auto-Title (can be done in parallel, small)
2. Note Templates (small, improves onboarding)
3. Trash / Soft Delete (medium, requires model changes and query updates)
4. App Lock (medium, builds security foundation — do before Widget)
5. Home Screen Widget (medium, platform-specific work — reads App Lock state for Widget Privacy)
6. Local Backup & Restore (medium-large, most critical but also most complex — includes App Lock settings in backup)

---

# Impact on Existing Code

## New Files

| File | Feature |
|---|---|
| `lib/services/backup_service.dart` | Backup & Restore |
| `lib/services/title_generator_service.dart` | Auto-Title |
| `lib/services/app_lock_service.dart` | App Lock — lock state, timeout tracking, auth orchestration |
| `lib/pages/trash_page.dart` | Trash |
| `lib/pages/backup_restore_page.dart` | Backup & Restore |
| `lib/pages/lock_screen_page.dart` | App Lock — PIN keypad + biometric prompt overlay |
| `lib/pages/pin_setup_page.dart` | App Lock — PIN creation and change flow |
| `lib/constants/note_templates.dart` | Templates |
| `lib/widgets/pinned_section_widget.dart` | Pinned Notes |
| `lib/widgets/template_picker_sheet.dart` | Templates |
| `lib/widgets/widget_privacy_picker.dart` | App Lock × Widget — privacy level selector |
| `lib/theme/amoled_dark_theme.dart` | AMOLED Theme |
| `android/app/src/main/res/layout/widget_*.xml` | Home Screen Widget |
| `ios/VoiceNotesWidget/` | Home Screen Widget (iOS extension) |

## Modified Files

| File | Changes |
|---|---|
| Note Hive model | Add `isPinned`, `pinnedAt`, `isDeleted`, `deletedAt`, `previousFolderId`, `previousProjectIds` |
| Folder Hive model | Add `isDeleted`, `deletedAt` |
| ProjectDocument Hive model | Add `isDeleted`, `deletedAt` |
| UserSettings model | Add AMOLED theme option, `appLockEnabled`, `appLockPinHash`, `biometricEnabled`, `autoLockTimeoutSeconds`, `widgetPrivacyLevel` |
| NotesProvider | Pinned/unpinned split, soft delete filtering |
| FoldersProvider | Soft delete filtering |
| ProjectDocumentsProvider | Soft delete filtering |
| Home Page | Pinned section, template picker integration |
| Note Detail Page | Pin/unpin action, auto-title on save |
| Settings Page | Backup & Restore section, AMOLED theme option, Trash link, new Security section (App Lock, Widget Privacy) |
| go_router config | Add routes for Trash, Backup & Restore, PIN setup |
| Theme configuration | Add AMOLED dark theme data |
| App menu | Add Trash entry |
| Search | Filter out trashed items |
| Tasks view | Filter out tasks from trashed notes |
| main.dart | Add `WidgetsBindingObserver` for app lifecycle → App Lock auto-lock |
| AndroidManifest.xml | Add `FLAG_SECURE` support for task switcher protection |
| Notification service | Hide notification content when App Lock enabled (`VISIBILITY_SECRET`) |
| Home Screen Widget (both platforms) | Read App Lock + Widget Privacy settings to determine display mode |

## New Dependencies

| Package | Purpose | Feature |
|---|---|---|
| `archive` | ZIP archive creation/extraction | Backup & Restore |
| `encrypt` | AES-256 encryption for backup files | Backup & Restore |
| `home_widget` | Home screen widget support | Widget |
| `local_auth` | Biometric authentication (fingerprint, Face ID) | App Lock |
| `crypto` (dart) | SHA-256 hashing for PIN storage | App Lock |

---

*End of Feature Specification*
