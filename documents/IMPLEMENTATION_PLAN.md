# VoiceNotes AI - Implementation Plan

**Version:** 4.0
**Last Updated:** 2026-03-03
**Repository:** https://github.com/haridasnairm-beep/VoiceAIApp
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Project Documents Feature Spec](FEATURE_PROJECT_DOCUMENTS.md) | [Tasks & Reminders Feature Spec](FEATURE_TASKS_AND_REMINDERS.md) | [Phase 1 Value Gaps](FEATURE_PHASE1_VALUE_GAPS.md) | [UX Audit](UX_PRODUCT_AUDIT.md)

---

## Overview

This plan covers three phases:

- **Phase 1 (On-Device):** A fully functional voice note-taking app — completed (v1.0.0). Steps 1–10.7 all done.
- **Phase 1.5 (UX & Launch Readiness):** Seven implementation waves addressing launch blockers, UX polish, structural redesign, quality foundations, discoverability, power-user features, and differentiation. Based on comprehensive UX/product audit.
- **Phase 2 (AI-Powered):** AI categorization, Whisper API, n8n integration, cloud sync.

**Current state:** Phase 1 core + value gap features complete (v1.0.0). All 7 original steps + Steps 4.5/4.6/4.7 + bonus features + post-release enhancements + 8 value gap features (Steps 8–10.7) done.

**Next:** Phase 1.5 — UX & Launch Readiness (7 waves, 38 items). Ship to Play Store after Wave 4.

---

# PHASE 1 — On-Device Features ✅ COMPLETE

Steps 1–7 + Steps 4.5/4.6/4.7 + Steps 8–10.7 are all complete. See [PROJECT_STATUS.md](PROJECT_STATUS.md) for full details.

```
PHASE 1 — On-Device (No AI) — ALL COMPLETE
├── Step 1: Project Alignment & Branding ────── [Small]  ✅
├── Step 2: State Management (Riverpod) ─────── [Medium] ✅
├── Step 3: Data Models & Hive Database ─────── [Medium] ✅
├── Step 4: Wire UI to Data Layer ───────────── [Large]  ✅
├── Step 4.5: Project Documents ─────────────── [Large]  ✅
├── Step 4.6: Interactive Tasks & Reminders ──── [Med-Lg] ✅
├── Step 4.7: Sharing, Rich Text & Images ────── [Large]  ✅
├── Step 5: On-Device Speech-to-Text ────────── [Medium] ✅
├── Step 6: Waveform, Playback & Notifications ─ [Medium] ✅
├── Step 7: Testing, Polish & Release ────────── [Large]  ✅
├── Step 8: Pinned Notes + AMOLED + Auto-Title ─ [Small]  ✅
├── Step 9: Note Templates ───────────────────── [Small]  ✅
├── Step 10: Trash / Soft Delete ─────────────── [Medium] ✅
├── Step 10.5: App Lock (PIN/Biometric) ──────── [Medium] ✅
├── Step 10.6: Home Screen Widget ────────────── [Medium] ✅
└── Step 10.7: Local Backup & Restore ────────── [Med-Lg] ✅
```

---

# PHASE 1.5 — UX & Launch Readiness

Based on comprehensive UX/product audit. Organized into 7 waves, each building on the previous. Play Store submission target: after Wave 4.

**Approach rationale:** Waves are ordered so each builds on the previous. Wave 1 unblocks publishing. Wave 2 makes the first impression great. Wave 3 simplifies the mental model. Wave 4 ensures stability. Wave 5 helps users discover features. Wave 6 rewards power users. Wave 7 differentiates from competitors.

---

## Wave 1: Launch Blockers (Week 1) — Step 11 ✅ COMPLETE

**Goal:** Remove hard blockers that prevent Play Store submission and manage user expectations.

### 11.1 Privacy Policy & Terms of Service ✅

**Priority:** BLOCKER — Cannot submit to Play Store without this.

#### Tasks:
1. ✅ Privacy Policy page (`/privacy_policy`) — already exists in-app
2. ✅ Terms & Conditions page (`/terms_conditions`) — already exists in-app
3. ⬜ Host web versions at a public URL for Play Store listing *(outside code scope)*
4. ✅ Linked from About page (Legal section)
5. ⬜ Add consent acknowledgment to onboarding (informational, not blocking) *(Wave 2+)*

### 11.2 AI Expectation Management ✅

**Priority:** Critical — prevents 1-star reviews from "where's the AI?" confusion.

#### Tasks:
1. ✅ Added "About Transcription & AI" section to About page — explains on-device Whisper + announces AI features as future update
2. ⬜ Draft Play Store description *(outside code scope)*
3. ⬜ Store listing AI qualifier *(outside code scope)*

### 11.3 Recording Mode Clarity ✅

**Priority:** High — prevents user confusion about the Android mic limitation.

#### Tasks:
1. ✅ Add one-line description below mode selector on Recording screen:
   - Live: "Instant text as you speak — no audio replay"
   - Whisper: "Audio saved, transcribed after recording"
2. ✅ Add info tooltip (ⓘ) on Audio Settings transcription mode picker explaining the tradeoff in detail
3. ✅ If user is in Live mode and taps the playback area on Note Detail, show explanatory message instead of empty player

### Estimated effort: Small (3-5 days)
### Status: ✅ COMPLETE (2026-03-03)

---

## Wave 2: Core Feel (Weeks 2-3) — Step 12 ✅ COMPLETE

**Goal:** Transform how the app *feels* during the first 60 seconds of use. Make the core recording → save → view cycle warm, responsive, and delightful.

### 12.1 Haptic Feedback System

#### Tasks:
1. Create `HapticService` utility class with methods: `light()`, `medium()`, `heavy()`, `selection()`
2. Add haptic feedback to:
   - Record start / stop / pause / resume
   - Checkbox completion (tasks, actions, reminders)
   - Pin / Unpin actions
   - Drag-and-drop reorder (on grab and on drop)
   - Save confirmation
   - Delete confirmation
3. Respect device haptic settings (check `HapticFeedback` availability)

### 12.2 Recording Sound Cues

#### Tasks:
1. Add subtle audio tone assets (record_start.mp3, record_stop.mp3) — short, non-intrusive
2. Play on recording start and stop
3. Respect device silent mode — no sound if muted
4. Add setting toggle if users prefer silence (Audio & Recording settings)

### 12.3 Recording Experience Animations

#### Tasks:
1. Subtle pulse animation on mic icon when speech is detected vs silence
2. Animated "Saving…" transition when user taps Save — note visually "lands" in the feed (scale + fade)
3. Smooth transition from recording screen back to home with saved note appearing at top

### 12.4 Empty State Improvements

#### Tasks:
1. Design contextual empty state illustrations for:
   - Home feed (Notes tab) — "Tap the mic to capture your first thought"
   - Tasks tab — "Tasks you create in your notes appear here" with link to voice commands help
   - Library — "Create folders to organize your notes"
   - Projects (inside folder) — brief visual of what a project document looks like
   - Search — "Search across all your notes, tasks, and reminders"
2. Each empty state includes one actionable CTA (button or tappable text)

### 12.5 Home Screen Progressive Disclosure

#### Tasks:
1. Hide stats cards until user has 5+ notes and 2+ folders
2. New users see a clean, uncluttered home with just the notes feed and FAB
3. Stats cards fade in with a subtle animation when thresholds are met
4. Store threshold state in UserSettings to avoid recalculating on every load

### 12.6 Task Completion Micro-Interactions

#### Tasks:
1. Soft check animation on checkbox completion (scale bounce)
2. Light haptic feedback (via HapticService)
3. Temporary green highlight (300ms) on the completed row
4. Smooth collapse animation when hiding completed tasks in Tasks tab
5. Apply consistently across all surfaces: Note Detail, Project Documents, Tasks View

### 12.7 Guided First Recording Experience

#### Tasks:
1. After onboarding completes (first launch only), navigate to Home with a coached overlay
2. Overlay highlights the record FAB with animated pointer: "Let's try it! Tap the mic and say something."
3. When user taps record, overlay updates: "Great! Speak naturally, then tap Save when done."
4. After save, overlay highlights the new note: "Here's your note! Tap to see the full transcription."
5. Store `guidedRecordingCompleted: true` in UserSettings after completion
6. Dismissible at any point — user can skip with an X button

### New Files:
| File | Purpose |
|---|---|
| `lib/services/haptic_service.dart` | Centralized haptic feedback utility |
| `lib/widgets/guided_recording_overlay.dart` | First-recording coached experience |
| `lib/widgets/empty_state_illustrated.dart` | Reusable empty state with illustration and CTA |

### Estimated effort: Medium (8-12 days)

---

## Wave 3: Structural Redesign (Weeks 4-6) — Step 13 ✅ COMPLETE

**Goal:** Simplify the app's information architecture. Move projects inside folders, implement tags, and redesign for progressive disclosure.

### 13.1 Move Projects Inside Folders

**Impact:** Largest structural change — affects navigation, data models, providers, and multiple screens.

#### Data Model Changes:
1. Add `projectDocumentIds: List<String>` field to `Folder` model
2. Add `folderId: String` field to `ProjectDocument` model (required — every project lives in a folder)
3. Migration: existing project documents auto-assigned to "General" folder (or user's default folder)
4. Run `build_runner` to regenerate type adapters

#### Repository & Provider Changes:
1. Update `ProjectDocumentsRepository` — CRUD now requires folderId
2. Update `FoldersRepository` — add methods to manage projectDocumentIds list
3. Update `projectDocumentsProvider` — filter by folderId
4. Remove separate projects count from home stats

#### UI Changes:
1. **Home page:** Stats cards show Notes + Folders only (2 cards, not 3)
2. **Library page:** Shows only folders (no separate Projects section). Remove collapsible section headers.
3. **Folder Detail page:** Show notes AND project documents together with visual distinction. Add toggle/filter for Notes only / Projects only / All. Add "New Project" button.
4. **SpeedDialFab (Home):** Remove "New Project" — project creation happens inside folders
5. **SpeedDialFab (Library):** Record Note, New Folder only
6. **Note card chips:** Remove project capsule chips from home feed (projects are accessed via folders)
7. **Recording page:** Remove Project dropdown — only folder assignment before save
8. **Multi-select:** Remove "Add to Project" from bulk operations on home page

#### Migration:
1. On first app launch after update, auto-migrate all existing ProjectDocuments:
   - If a ProjectDocument has linked notes that all share the same folder → assign that folder
   - If linked notes span multiple folders → assign to default folder
   - If no linked notes → assign to "General" folder
2. Show one-time migration notice: "Projects are now organized inside folders for simpler navigation"

### 13.2 Tags System

#### Data Model Changes:
1. Add `tags: List<String>` field to `Note` model (HiveField)
2. Add `allTags: List<String>` to track all known tags (stored in a lightweight Hive box or derived from notes)
3. Run `build_runner` to regenerate type adapters

#### Repository & Provider Changes:
1. Add tag methods to `NotesRepository`: `addTag(noteId, tag)`, `removeTag(noteId, tag)`, `getAllTags()`
2. Create `tagsProvider` — derived provider that collects all unique tags across all notes with counts
3. Wire to search — tags as a filter criterion

#### UI — Note Detail:
1. Tag pills section below metadata (above structured output)
2. "+" button to add tag — shows text input with autocomplete from existing tags
3. Tap existing tag pill → remove option
4. Tags saved immediately on add/remove

#### UI — Home Feed:
1. Tag pills displayed on note cards (inline, after folder chip)
2. Tapping a tag pill on a card filters the feed to show only notes with that tag

#### UI — Search:
1. Add tag filter to search screen — multi-select from existing tags
2. Tag matches included in search results

#### UI — Tags Management:
1. Tags page accessible from Library (or Settings)
2. List all tags with note count per tag
3. Rename tag (updates across all notes)
4. Merge two tags into one
5. Delete tag (removes from all notes)

#### Voice Commands:
1. Extend parser to support "Tag \<name\>" keyword (alongside existing "Folder")
2. Multiple tags supported: "Folder Kitchen Tag Budget Tag Urgent Start..."
3. Tags auto-created if they don't exist

#### Multi-Select:
1. Add "Add Tags" option to multi-select bottom bar
2. Shows tag picker with autocomplete and create-new option

### 13.3 Progressive Disclosure Audit

#### Tasks:
1. Audit every screen for information density
2. Define three feature visibility tiers:
   - **Tier 1** (everyone sees immediately): Recording, notes feed, basic search, folders
   - **Tier 2** (discover in first week): Tasks tab, reminders, pinning, tags, templates
   - **Tier 3** (power users when invested): Project documents, rich text, voice commands, PDF export, backup/restore, app lock, find & replace
3. Ensure Tier 3 features are not visible on the default home screen
4. Verify that each tier's features have corresponding contextual tips (Wave 5)
5. Document the progressive disclosure map for future feature additions

### New Files:
| File | Purpose |
|---|---|
| `lib/providers/tags_provider.dart` | Derived provider for tag management |
| `lib/pages/tags_page.dart` | Tags management screen |
| `lib/widgets/tag_pills.dart` | Reusable tag pill display + editing widget |
| `lib/widgets/tag_picker.dart` | Tag selection with autocomplete |

### Modified Files:
| File | Change |
|---|---|
| `lib/models/note.dart` | Add `tags` field |
| `lib/models/folder.dart` | Add `projectDocumentIds` field |
| `lib/models/project_document.dart` | Add `folderId` field |
| `lib/pages/home_page.dart` | 2 stats cards, remove project references |
| `lib/pages/library_page.dart` | Folders only, no separate projects section |
| `lib/pages/folder_detail_page.dart` | Mixed notes + projects view, new project button |
| `lib/pages/recording_page.dart` | Remove project dropdown, add tag support to voice commands |
| `lib/pages/note_detail_page.dart` | Add tags section |
| `lib/pages/search_page.dart` | Add tag filter |
| `lib/services/notes_repository.dart` | Tag CRUD methods |
| `lib/services/project_documents_repository.dart` | Folder-scoped CRUD |
| `lib/utils/voice_command_parser.dart` | Add Tag keyword support |
| `lib/utils/voice_command_processor.dart` | Tag creation/lookup |

### Estimated effort: Large (12-18 days)

---

## Wave 4: Quality Foundation (Weeks 6-8) — Step 14 ✅ COMPLETE

**Goal:** Establish stability infrastructure before Play Store submission. Tests, crash reporting, and data integrity.

### 14.1 Test Coverage Foundation

**Target:** 70% coverage on repositories and core services.

#### Unit Tests:
1. All Hive repository CRUD operations (notes, folders, settings, project_documents, image_attachments)
2. Data migration logic (especially projects-into-folders migration from Wave 3)
3. Tag operations (add, remove, rename, merge, delete)
4. Voice command parser (folder, tag, start, edge cases)
5. Title generation algorithm (filler removal, fallbacks, truncation)
6. Profanity filter
7. Sharing service (text assembly, Markdown conversion)

#### Widget Tests:
1. Core flow: record → save → view note → edit → delete
2. Search: keyword entry → results → filters → clear
3. Task completion: checkbox → strikethrough → sync across surfaces
4. Folder management: create → rename → archive → delete
5. Tag management: add → remove → rename → merge

#### Integration Tests:
1. End-to-end: record → transcribe (on-device) → save → search → find
2. Backup → restore → verify all data intact
3. Soft delete → trash → restore → verify
4. App lock → lock → unlock → verify navigation
5. Project inside folder: create → add notes → edit → share

### 14.2 Crash Reporting (Opt-In)

#### Tasks:
1. Add `sentry_flutter` (or `firebase_crashlytics`) dependency
2. Create `CrashReportingService` — initialize only when opted in
3. Add opt-in prompt during onboarding (final page): "Help improve VoiceNotes AI by sharing anonymous crash reports. No personal data is ever included."
4. Add toggle in Preferences page: "Anonymous Crash Reporting"
5. Store preference in `UserSettings.crashReportingEnabled`
6. Wrap app with error boundary — capture unhandled exceptions and Flutter errors
7. No personal data, no note content, no audio — only stack traces + device metadata

### 14.3 Hive Data Integrity Checks

#### Tasks:
1. On app startup, attempt to open each Hive box in a try-catch
2. If any box fails to open:
   - Log the error (to crash reporting if enabled)
   - Show recovery screen with options:
     a. "Try Again" — reattempt opening
     b. "Restore from Backup" — navigate to backup restore flow
     c. "Reset App" — clear all data and start fresh (last resort)
3. If a box opens but contains corrupt entries, skip those entries and log the count
4. Show a one-time notice: "X items could not be loaded and were skipped"
5. Validate referential integrity: notes reference existing folders, project blocks reference existing notes

### New Files:
| File | Purpose |
|---|---|
| `test/repositories/notes_repository_test.dart` | Unit tests |
| `test/repositories/folders_repository_test.dart` | Unit tests |
| `test/repositories/project_documents_repository_test.dart` | Unit tests |
| `test/services/voice_command_parser_test.dart` | Unit tests |
| `test/services/title_generator_test.dart` | Unit tests |
| `test/widgets/recording_flow_test.dart` | Widget test |
| `test/widgets/task_completion_test.dart` | Widget test |
| `test/integration/backup_restore_test.dart` | Integration test |
| `test/integration/full_flow_test.dart` | Integration test |
| `lib/services/crash_reporting_service.dart` | Opt-in crash reporting |
| `lib/pages/recovery_page.dart` | Data corruption recovery screen |

### Estimated effort: Large (12-16 days)

---

### 🚀 PLAY STORE SUBMISSION POINT

After Wave 4, the app is ready for Play Store submission:
- Privacy policy and ToS in place (Wave 1)
- Core experience polished and delightful (Wave 2)
- Information architecture simplified (Wave 3)
- Test coverage and crash reporting active (Wave 4)

Waves 5-7 ship as post-launch updates.

---

## Wave 5: Discoverability & Polish (Weeks 8-10) — Step 15 ✅ COMPLETE

**Goal:** Help users discover features they'd otherwise miss. Layer on polish details.

### 15.1 Contextual First-Time Tips System

#### Tasks:
1. Create `TipService` — manages which tips have been shown; checks against `UserSettings.dismissedTips`
2. Create `ContextualTip` widget — small tooltip overlay with message, dismiss button, and optional CTA
3. Implement tips for:
   - First note with tasks → "Tip: Create tasks by voice — say 'Todo' followed by your task"
   - First project document → "Tip: Drag blocks to reorder your document"
   - First search → "Tip: Filter by tag, folder, date, or category"
   - First swipe on note card → "Swipe right to pin, left for more actions"
   - First time in folder with 5+ notes → "Tip: You can create project documents to compose your notes"
   - First recording in Whisper mode → "Tip: Say 'Folder Kitchen Tag Budget Start...' to auto-organize"
4. Tips are one-time, dismissible, non-blocking

### 15.2 Overdue Task Badge on Note Cards

#### Tasks:
1. Check each note's todos for overdue items (dueDate < now && !isCompleted)
2. Show small red badge indicator on note card (top-right area, near pin icon)
3. Badge shows count of overdue items
4. Only shown on home feed note cards, not in search results or folder views (to avoid clutter)

### 15.3 Smart Backup Reminder

#### Tasks:
1. After user reaches 10 notes and has never created a backup → show non-intrusive banner at top of home screen: "Protect your notes — create your first backup" with Backup button
2. If backup exists but is older than 30 days → show subtle reminder on home screen
3. Banner dismissible; reappears on next condition match
4. Check `UserSettings.lastBackupDate` on app foreground

### 15.4 Auto-Title Edge Case Fixes

#### Tasks:
1. Test title generation with: notes under 5 words, notes that are entirely filler, non-English notes, notes with only tasks and no general content
2. Fix any edge cases where generated title is empty or unhelpful
3. Ensure fallback patterns always produce a meaningful title

### 15.5 Folder Colors

#### Tasks:
1. Add color picker to folder creation and edit dialogs (8-10 preset colors)
2. Store color in `Folder.color` (hex string)
3. Display as accent stripe on folder cards in Library
4. Display as colored dot on folder chips throughout the app (home feed, note detail, search)
5. Default color if none selected (neutral gray)

### 15.6 What's New Screen

#### Tasks:
1. Create `WhatsNewPage` — list of new features with icons, brief descriptions
2. On app launch, compare `UserSettings.lastSeenAppVersion` to current version
3. If different, show What's New before navigating to home
4. Dismissible, updates `lastSeenAppVersion` on close
5. Content stored as a simple list in a constants file (easy to update per release)

### 15.7 Undo/Redo for Text Editing

#### Tasks:
1. Flutter Quill has built-in undo/redo — expose undo/redo buttons in the rich text toolbar
2. Add undo/redo to note transcription editing (plain text mode — implement simple undo stack)
3. Wire keyboard shortcuts if applicable (Ctrl+Z / Ctrl+Y for external keyboards)

### 15.8 Loading Skeletons

#### Tasks:
1. Create `SkeletonLoader` widget — shimmer placeholder matching note card layout
2. Replace any loading spinners on home feed, search results, folder detail with skeleton placeholders
3. Skeleton layout matches the actual content layout (card shape, title line, preview lines)
4. Subtle shimmer animation (left-to-right sweep)

### New Files:
| File | Purpose |
|---|---|
| `lib/services/tip_service.dart` | Contextual tip management |
| `lib/widgets/contextual_tip.dart` | Tooltip overlay widget |
| `lib/widgets/backup_reminder_banner.dart` | Smart backup reminder |
| `lib/pages/whats_new_page.dart` | Post-update changelog |
| `lib/widgets/skeleton_loader.dart` | Loading skeleton placeholders |
| `lib/widgets/folder_color_picker.dart` | Color selection for folders |

### Estimated effort: Medium (10-14 days)

---

## Wave 6: Power User Features (Weeks 10-13) — Step 16

**Goal:** Reward users who are already invested. Improve efficiency and depth for daily use.

### 16.1 Android App Shortcuts

#### Tasks:
1. Add static shortcuts in `AndroidManifest.xml`: "Record Note", "New Text Note"
2. Long-press app icon → shortcuts appear
3. Each shortcut deep-links to the appropriate route

### 16.2 Note Sorting Options

#### Tasks:
1. Add sort selector on home feed (dropdown or icon button)
2. Sort options: Date (newest first), Date (oldest first), Title (A-Z), Title (Z-A), Duration (longest first)
3. Persist selection in `UserSettings.noteSortOrder`
4. Apply sort to notes list via provider

### 16.3 Task Batch Operations

#### Tasks:
1. Add multi-select mode to Tasks tab (matching home feed pattern — long-press to enter)
2. Multi-select bottom bar: Bulk Complete, Bulk Delete, Bulk Reschedule
3. Bulk Complete — marks all selected tasks as completed with animation
4. Bulk Delete — confirmation dialog, removes from source notes
5. Bulk Reschedule — date/time picker, applies new date to all selected reminders/todos

### 16.4 Search Keyword Highlighting

#### Tasks:
1. In search results, highlight matched keywords inline within note preview text
2. Use `TextSpan` with background highlight color matching section color
3. Show match count per note in results

### 16.5 Swipe Gestures on Note Cards

#### Tasks:
1. Implement `Dismissible` or custom swipe widget on note cards
2. Swipe right → Pin/Unpin (blue background with pin icon)
3. Swipe left → Reveal action buttons: Delete (red), Move to Folder (blue)
4. First-time contextual tip (Wave 5 tip system): "Swipe notes for quick actions"
5. Haptic feedback on swipe threshold

### 16.6 Archive Folders

#### Tasks:
1. Add `isArchived: bool` field to Folder model (default: false)
2. Archive action in folder overflow menu — sets flag, removes from main Library view
3. "Archived" collapsible section at bottom of Library page
4. Archived folders remain searchable
5. Unarchive action to restore to main view

### 16.7 Folder Drag-and-Drop Reordering

#### Tasks:
1. Add `sortOrder: int` field to Folder model
2. Implement `ReorderableListView` in Library page
3. Drag handle on each folder card (or long-press to grab)
4. Persist new order to Hive on drop
5. New folders default to end of list

### 16.8 Accessibility Pass

#### Tasks:
1. Add semantic labels to all interactive elements:
   - Waveform: "Recording waveform, currently recording" / "Recording paused"
   - Recording controls: "Start recording", "Pause recording", "Stop and save"
   - Checkboxes: "Mark [task text] as complete"
   - Drag handles: "Reorder [item name], currently position [N]"
   - Pin icon: "Pinned note" / "Unpin this note"
2. Test with TalkBack (Android) and VoiceOver (iOS) — ensure full app navigable
3. Verify contrast ratios on all 4 themes (Light, Dark, AMOLED, System) — WCAG AA minimum
4. Test dynamic text scaling — ensure layouts don't break at 150% and 200% text size
5. Add move up/down buttons as alternative to drag-and-drop in reorder modes

### Modified Files:
| File | Change |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | App shortcuts |
| `lib/pages/home_page.dart` | Sort selector, swipe gestures |
| `lib/widgets/tasks_tab.dart` | Multi-select, batch operations |
| `lib/pages/search_page.dart` | Keyword highlighting |
| `lib/pages/library_page.dart` | Folder reorder, archive section |
| `lib/models/folder.dart` | `isArchived`, `sortOrder` fields |
| Multiple files | Semantic labels, contrast fixes, text scaling |

### Estimated effort: Medium-Large (14-18 days)

---

## Wave 7: Differentiation (Weeks 13-17) — Step 17

**Goal:** Features that set VoiceNotes AI apart from competitors. Long-term competitive advantages.

### 17.1 Calendar / Timeline View

#### Tasks:
1. Create Calendar page accessible from home (calendar icon in AppBar or new tab)
2. Monthly calendar grid with dots on days that have recordings
3. Tap a day → shows that day's notes in a list below the calendar
4. Upcoming reminders section below calendar — timeline of scheduled reminders
5. Week view option (toggle between month and week)
6. Color-code dots: blue for notes, orange for notes with open tasks, red for overdue

#### New Files:
| File | Purpose |
|---|---|
| `lib/pages/calendar_page.dart` | Calendar / timeline view |
| `lib/widgets/calendar_grid.dart` | Monthly calendar widget |
| `lib/widgets/day_notes_list.dart` | Notes list for selected day |

### 17.2 Note Export Ecosystem Completion

#### Tasks:
1. **Markdown export for individual notes** — same as project document markdown export but for single notes; includes metadata header, transcription, tasks
2. **CSV export for tasks** — all open tasks exported as CSV with columns: Type, Text, Status, Due Date, Source Note, Created At. Filterable by folder/tag before export
3. **JSON full-data export** — entire app database as JSON for power users who want data portability. Includes notes, folders, tags, projects, tasks, settings (excludes audio files and images — too large). This is distinct from backup (which is encrypted and app-specific)
4. All exports via share sheet

### 17.3 Voice Command Confirmation & Error Recovery

#### Tasks:
1. When a voice command is detected and parsed, show a confirmation toast at bottom of screen:
   - "Created: Todo — buy groceries" or "Folder: Kitchen, Tag: Budget"
   - Toast includes "Undo" button (5-second window)
2. If Undo tapped — remove the auto-created task/folder/tag assignment and keep raw transcription
3. If voice command parsing fails (no "Start" keyword, ambiguous syntax), show warning: "Voice command not recognized — note saved as-is"
4. Log voice command success/failure rate (anonymous, if crash reporting enabled) to measure command reliability

### 17.4 Transcript-Audio Sync (Whisper Mode Only)

**Note:** This feature is feasible only with Whisper mode, which provides timestamps. Not available for Live STT mode.

#### Tasks:
1. When Whisper transcribes, capture word-level or segment-level timestamps from the model output
2. Store timestamps alongside transcription segments in the Note model (new field: `transcriptSegments: List<TranscriptSegment>`)
3. On Note Detail, make transcript text tappable — tapping a word/sentence seeks audio to that timestamp
4. During audio playback, auto-scroll and highlight the current segment in the transcript
5. Visual indicator: subtle background highlight on the currently playing segment
6. Graceful fallback: if timestamps unavailable (e.g., restored from backup, or Live STT note), disable sync features silently

#### New Data Model:
```
TranscriptSegment
├── text: String
├── startTimeMs: int
├── endTimeMs: int
└── confidence: double?
```

### 17.5 Smart Filters (Virtual Folders)

#### Tasks:
1. Create automatically generated filter views based on existing metadata:
   - "This Week" — notes created in the last 7 days
   - "With Open Tasks" — notes that have uncompleted todos/actions/reminders
   - "Reminders Due Soon" — notes with reminders in the next 48 hours
   - "Unorganized" — notes with no folder assignment and no tags
   - "Long Recordings" — notes with audio > 5 minutes
2. Show as a "Smart Filters" section in Library (above folders) — collapsible
3. Each filter shows count and opens a filtered notes list
4. No user setup required — derived entirely from existing data
5. Filters update automatically as data changes

### 17.6 Play Store Launch Optimization

#### Tasks:
1. **Store listing copy:**
   - Title: "VoiceNotes AI — Voice to Organized Notes"
   - Short description (80 chars): "Record your voice. Get organized notes. 100% private."
   - Long description: Lead with core value, mention key features (transcription, tasks, folders, privacy), note AI features coming soon
2. **Screenshots strategy:**
   - Screenshot 1: Recording screen with waveform — "Speak naturally"
   - Screenshot 2: Note detail with structured output — "Auto-organized"
   - Screenshot 3: Home feed with folders — "Everything in its place"
   - Screenshot 4: Tasks view — "Never miss a task"
   - Screenshot 5: Privacy/lock screen — "100% private, 100% yours"
3. **Feature graphic** — clean design with app icon + tagline
4. **Category:** Productivity
5. **Keywords/ASO:** voice notes, voice recorder, speech to text, note taking, task manager, privacy
6. **Content rating:** questionnaire completion
7. **App signing** — verify release keystore and signing config
8. **Test on physical devices** — minimum 3 Android devices (different screen sizes)

### Estimated effort: Large (16-20 days)

---

## Phase Summary (Updated)

```
PHASE 1 — On-Device (No AI) ─────────── ALL COMPLETE (v1.0.0)
│
PHASE 1.5 — UX & Launch Readiness
├── Wave 1: Launch Blockers ──────────── [Small]   Step 11
│   ├── 11.1 Privacy Policy & ToS
│   ├── 11.2 AI Expectation Management
│   └── 11.3 Recording Mode Clarity
├── Wave 2: Core Feel ────────────────── [Medium]  Step 12
│   ├── 12.1 Haptic Feedback System
│   ├── 12.2 Recording Sound Cues
│   ├── 12.3 Recording Experience Animations
│   ├── 12.4 Empty State Improvements
│   ├── 12.5 Home Screen Progressive Disclosure
│   ├── 12.6 Task Completion Micro-Interactions
│   └── 12.7 Guided First Recording Experience
├── Wave 3: Structural Redesign ──────── [Large]   Step 13
│   ├── 13.1 Move Projects Inside Folders
│   ├── 13.2 Tags System
│   └── 13.3 Progressive Disclosure Audit
├── Wave 4: Quality Foundation ───────── [Large]   Step 14
│   ├── 14.1 Test Coverage Foundation
│   ├── 14.2 Crash Reporting (Opt-In)
│   └── 14.3 Hive Data Integrity Checks
│                                            │
│                                     🚀 PLAY STORE SUBMISSION
│
├── Wave 5: Discoverability & Polish ──── [Medium]  Step 15
│   ├── 15.1 Contextual First-Time Tips
│   ├── 15.2 Overdue Task Badge
│   ├── 15.3 Smart Backup Reminder
│   ├── 15.4 Auto-Title Edge Cases
│   ├── 15.5 Folder Colors
│   ├── 15.6 What's New Screen
│   ├── 15.7 Undo/Redo for Text Editing
│   └── 15.8 Loading Skeletons
├── Wave 6: Power User Features ──────── [Med-Lg]  Step 16
│   ├── 16.1 Android App Shortcuts
│   ├── 16.2 Note Sorting Options
│   ├── 16.3 Task Batch Operations
│   ├── 16.4 Search Keyword Highlighting
│   ├── 16.5 Swipe Gestures on Note Cards
│   ├── 16.6 Archive Folders
│   ├── 16.7 Folder Reordering
│   └── 16.8 Accessibility Pass
└── Wave 7: Differentiation ──────────── [Large]   Step 17
    ├── 17.1 Calendar / Timeline View
    ├── 17.2 Export Ecosystem Completion
    ├── 17.3 Voice Command Confirmation
    ├── 17.4 Transcript-Audio Sync
    ├── 17.5 Smart Filters
    └── 17.6 Play Store Launch Optimization
                                             │
                                      PHASE 1.5 COMPLETE

PHASE 2 — AI-Powered
├── Step 18: Auth & Account System ────── [Large]
├── Step 19: AI Auto-Categorization ───── [Large]
├── Step 20: Cloud Transcription ──────── [Medium]
├── Step 21: Cloud Backup & Sync ──────── [Large]
└── Step 22: n8n Integration & Advanced ── [Large]
                                             │
                                      PHASE 2 RELEASE
```

---

## Decisions to Make

| # | Decision | Phase | Options | Impact |
|---|---|---|---|---|
| 1 | ~~State management~~ | 1 | ~~Riverpod~~ | ✅ Decided |
| 2 | On-device STT language scope | 1 | All supported vs top 10 | Affects recording UX |
| 3 | Crash reporting provider | 1.5 | Sentry vs Firebase Crashlytics | Affects privacy posture (Sentry more privacy-friendly) |
| 4 | Whisper API vs Google Cloud STT | 2 | Whisper (batch) vs Google (streaming) | Affects transcription quality |
| 5 | AI provider | 2 | OpenAI vs Anthropic | Affects structuring quality and cost |
| 6 | API key management | 2 | flutter_secure_storage vs dart_define env | Affects security approach |

---

## Risk Register

| Risk | Phase | Mitigation |
|---|---|---|
| On-device STT accuracy varies by language | 1 | Allow manual editing of transcription |
| speech_to_text session timeout on long recordings | 1 | Auto-restart listener, stitch results |
| Hive database corruption | 1.5 | Integrity checks on startup (Wave 4), backup mechanism |
| Large note lists slow down UI | 1 | Lazy loading, pagination, loading skeletons |
| Projects-in-folders migration data loss | 1.5 | Conservative auto-assignment to default folder; one-time notice |
| Tag proliferation (too many tags) | 1.5 | Tag management page with merge/delete; autocomplete to reuse existing |
| Contextual tips annoying users | 1.5 | One-time only, dismissible, non-blocking; respect dismissed state |
| APK size growth (currently 66.4MB) | 1.5 | Audit dependencies; monitor per-wave; crash reporting SDK adds ~2-3MB |
| Guided first recording feels forced | 1.5 | Dismissible at any point; skip button always visible |
| Play Store rejection (policy compliance) | 1.5 | Privacy policy, content rating, permissions justification all addressed in Wave 1 |
| Whisper API costs escalate with usage | 2 | Monitor per-note cost, keep on-device as default |
| AI categorization quality varies | 2 | Invest in prompt engineering, allow manual override |
| Large recordings fail API upload | 2 | Chunked uploads, max recording duration |
| Mixed-language detection unreliable | 2 | Default to user-preferred language for ambiguous segments |
| Backup passphrase loss = unrecoverable backup | 1 | Clear warning during backup creation; no recovery by design (privacy-first) |
