# VoiceNotes AI — Feature Spec: Project Documents

**Version:** 1.1
**Date:** 2026-02-27
**Status:** COMPLETE (Step 4.5 + Step 4.7 Addendum A)
**Phase:** Phase 1 Addition (Step 4.5 — after Wire UI to Data Layer)
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md) | [Project Status](PROJECT_STATUS.md)

---

## 1. Feature Overview

**Project Documents** is a new feature that allows users to create rich, composite note documents assembled from individual voice notes. A project document acts as a living workspace — a single, scrollable page where users aggregate, arrange, and edit transcripts from multiple voice notes alongside free-text content and section headers.

**Core Concept:** Voice notes are atomic units. Project documents are compositions built from those atoms. The voice note remains the source of truth; the project document is a curated view that references and arranges them.

**Why this matters:** Users frequently capture many voice notes around a single topic (a project, a trip, a client). Today, these notes live as separate items in a flat list or folder. Project Documents let users build a structured narrative from those fragments — turning scattered voice captures into a single, coherent, editable document.

---

## 2. Implementation Status

### Core Project Documents — ✅ COMPLETE (Step 4.5)

| Sub-step | Description | Status |
|---|---|---|
| A | Data Model & Storage (3 new Hive models, Note model changes, migration) | ✅ Done |
| B | Repository & Provider Layer (ProjectDocumentsRepository, versioning) | ✅ Done |
| C | UI — Project Documents List Screen | ✅ Done |
| D | UI — Project Document Detail Screen (block rendering, editing) | ✅ Done |
| E | UI — Note Picker & Supporting Screens (version history) | ✅ Done |
| F | Integration & Polish (home page entry, migration, build verified) | ✅ Done |

**Created:** 13 files (3 models + 3 generated, 1 repository, 1 provider, 4 pages)
**Modified:** 8 files (Note model, HiveService, NotesRepository, NotesProvider, nav, Home, main)

### Addendum A Features — ✅ COMPLETE (Step 4.7)

| Feature | Status | Description |
|---|---|---|
| A1. Sharing & Export | ✅ Done | Share notes/projects via OS share sheet, export as Markdown/plain text/PDF |
| A2. Rich Text Formatting | ✅ Done | Bold, italic, bullets, headings, links in free-text blocks via flutter_quill |
| A3. Image Blocks (Photos) | ✅ Done | Photo blocks in projects + note attachments, gallery/camera/crop/full-screen viewer |

---

## 3. User Stories

1. **As a user**, I want to create a Project Document so I can group related voice notes into a single, organized page.
2. **As a user**, I want to add any existing voice note's transcript to a Project Document so I can build a comprehensive view of a topic.
3. **As a user**, I want to add the same voice note to multiple Project Documents so I don't have to choose where it belongs.
4. **As a user**, I want to reorder blocks within a Project Document (drag and drop) so I can arrange content in the sequence that makes sense.
5. **As a user**, I want to add section headers and dividers between note blocks so I can organize the document visually.
6. **As a user**, I want to add free-text blocks (typed content) so I can write context, summaries, or commentary alongside voice note transcripts.
7. **As a user**, I want to edit a voice note's transcript directly within the Project Document, and have that edit saved as a new version on the original note.
8. **As a user**, I want to see the full version history of a note's transcript so I can review or revert changes.
9. **As a user**, I want to export the entire Project Document as a single file so I can share it outside the app.
10. **As a user**, I want an AI-generated summary of the entire Project Document so I can get a quick overview.

---

## 4. Phasing

This feature spans Phase 1 and Phase 2. The split is clean — Phase 1 covers everything that works locally without AI or cloud services.

### Phase 1 Scope (On-Device, No AI)

| Capability | Status |
|---|---|
| Create / rename / delete Project Documents | ✅ Complete |
| Add voice note references to a Project Document | ✅ Complete |
| One note can appear in multiple Project Documents | ✅ Complete |
| Reorder blocks via drag and drop | ✅ Complete |
| Add section header / divider blocks | ✅ Complete |
| Add free-text blocks | ✅ Complete |
| Edit transcript within Project Document (bi-directional) | ✅ Complete |
| Full version history on note transcripts | ✅ Complete |
| View Project Document as a single scrollable page | ✅ Complete |
| Remove a block from Project Document (does not delete the original note) | ✅ Complete |
| Timestamp display per note block (original recording time) | ✅ Complete |
| Project Document list screen | ✅ Complete |
| Voice command to add note to project ("Project \<name\> Start \<content\>") | ✅ Complete (v1.3.0) |
| Share single note / project document via OS share sheet | ⏳ Addendum A1 |
| Export as Markdown / plain text file | ⏳ Addendum A1 |
| Rich text formatting in free-text blocks | ⏳ Addendum A2 |
| Image blocks (photos) in projects + note attachments | ⏳ Addendum A3 |

### Phase 2 Scope (AI-Powered)

| Capability | Phase |
|---|---|
| AI-generated summary of entire Project Document | Phase 2 |
| PDF export (formatted, professional) | Phase 2 |
| AI-suggested note additions ("You have 3 other notes about this topic") | Phase 2 |
| Share with embedded images / audio | Phase 2 |

---

## 5. Data Models

### 5.1 Implemented Models (Current State)

These models are live in the codebase as of v1.4.0:

```
ProjectDocument
├── id: String (UUID)
├── title: String
├── description: String? (optional subtitle/description)
├── blocks: List<ProjectBlock> (ordered list — order = display order)
├── createdAt: DateTime
└── updatedAt: DateTime

ProjectBlock
├── id: String (UUID)
├── type: BlockType (note_reference | free_text | section_header)
├── sortOrder: int (determines position in the document)
├── noteId: String? (required when type = note_reference; references Note.id)
├── content: String? (required when type = free_text or section_header; holds the typed text or header title)
├── createdAt: DateTime
└── updatedAt: DateTime

TranscriptVersion
├── id: String (UUID)
├── text: String (the transcript text at this version)
├── versionNumber: int (1, 2, 3...)
├── editSource: String (describes where the edit was made — e.g., "Note Detail", "Project: Kitchen Renovation")
├── createdAt: DateTime
└── isOriginal: bool (true only for the first version from STT)
```

### 5.2 Note Model (Current State — with Project Document fields)

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
```

### 5.3 Hive Storage (Current State)

| Box | Contents | Status |
|---|---|---|
| `projectDocumentsBox` | All ProjectDocument objects, AES-256 encrypted | ✅ Active |
| `notesBox` | Note objects with transcriptVersions and projectDocumentIds | ✅ Active |
| `foldersBox` | Folder objects | ✅ Active |
| `settingsBox` | UserSettings | ✅ Active |

### 5.4 Relationship Diagram (Current State)

```
ProjectDocument ──has many──▶ ProjectBlock
                                  │
                    ┌─────────────┼─────────────┐
                    │             │              │
              note_reference   free_text   section_header
                    │
                    ▼
                  Note ──has many──▶ TranscriptVersion
                    │
                    ├── can belong to many ProjectDocuments
                    └── projectDocumentIds[] tracks reverse references
```

**Key relationship rules:**
- A ProjectDocument contains an ordered list of ProjectBlocks.
- A ProjectBlock of type `note_reference` points to exactly one Note via `noteId`.
- A Note can be referenced by blocks in multiple ProjectDocuments (many-to-many).
- When a Note is deleted, all ProjectBlocks referencing it should be removed or converted to a placeholder ("Note deleted") — see Edge Cases section.
- Deleting a ProjectBlock of type `note_reference` does NOT delete the original Note.
- Deleting a ProjectDocument does NOT delete any referenced Notes.

---

## 6. Screens & UI (Implemented)

### 6.1 Library Page (Folders & Projects — Unified View)

**Route:** Part of main navigation
**Access:** From Home page navigation

**Layout:**
- Unified view with collapsible section headers for Folders and Projects (arrow toggle + count badge)
- **Folders section** — user-created folders with note count, last updated timestamp
- **Projects section** — project documents with note count, block count, last updated, description preview
- **SpeedDialFab** — Record Note, New Folder, New Project actions
- **Topics chips** — horizontally scrollable topic tags extracted from folders

> **Note:** The original spec proposed a separate Project Documents List Screen (`/project-documents`). The actual implementation merges this into the Library page alongside Folders, which is a better UX — one place for all organization.

### 6.2 Project Document Detail Screen

**Route:** `/project-documents/:id`
**Access:** Tapping a project document card from the Library page.

**Layout:**
This is the core screen — a single scrollable canvas displaying all blocks in order.

**Header area:**
- Document title (editable via tap)
- Description (editable via tap)
- Metadata line: created date, last updated, block count
- Action buttons: Add Block, Reorder Mode, More (rename, delete document)

**Block rendering:**
Each block is a distinct card/section within the scrollable page:

**Note Reference Block:**
- Visual indicator: small mic icon + "Voice Note" label
- Original recording timestamp (e.g., "Feb 24, 2026 · 3:42 PM")
- Detected language badge
- Note title (linked — tapping navigates to original Note Detail)
- Full transcript text (editable in-place)
- Audio duration indicator
- Block actions (overflow menu): Remove from document, View original note, View version history
- Visual border or accent color to distinguish from other block types

**Free-Text Block:**
- Visual indicator: small text/pen icon
- Editable text area — user types directly
- Block actions: Remove from document
- Subtle different styling from note blocks (e.g., lighter background, no mic icon)

**Section Header Block:**
- Large/bold text rendering
- Optional horizontal divider line below
- Editable in-place
- Block actions: Remove from document

**Reorder Mode:**
- Activated via toolbar button
- Drag handles appear on each block
- User drags blocks to reorder
- "Done" button to exit reorder mode
- sortOrder values updated on save

### 6.3 Add Block Flow

When the user taps "Add Block" on a Project Document, present options:

1. **Add Voice Note** — opens a picker/search screen showing all existing notes. User selects one (or multiple). Selected notes are appended as `note_reference` blocks at the end of the document.
2. **Add Free Text** — inserts a new empty `free_text` block at the end. Cursor focuses for immediate typing.
3. **Add Section Header** — inserts a new `section_header` block at the end. Cursor focuses for immediate typing.

### 6.4 Note Picker Screen

**Route:** `/project-documents/:id/add-notes`

- Shows all notes (reverse chronological)
- Search bar to filter
- Checkboxes for multi-select
- Already-linked notes shown with a "linked" indicator (but can still be added again if user wants — no restriction)
- "Add Selected" button confirms

### 6.5 Bi-Directional Editing Flow

When a user edits a voice note transcript inside a Project Document:

1. User taps on the transcript text within a `note_reference` block → text becomes editable
2. User makes changes → taps "Save" or taps outside the field
3. App creates a new `TranscriptVersion` on the original Note:
   - `versionNumber` = previous latest + 1
   - `editSource` = "Project: [Document Title]"
   - `text` = new edited text
4. App updates `Note.rawTranscription` to the new text (keeps backward compatibility)
5. App updates `Note.updatedAt` timestamp
6. The change is immediately reflected everywhere this note appears (other project documents, note detail, search results, home feed)

### 6.6 Version History Screen

**Route:** `/project-documents/:id/version-history/:noteId`

- Version list showing: version number, date, edit source
- Full text per version
- "Restore this version" action — creates a NEW version with the restored text (non-destructive)

### 6.7 Voice Command Integration (Implemented in v1.3.0)

In Whisper recording mode, users can say "Project \<name\> Start \<content\>" to automatically assign the recording to a project. The `VoiceCommandParser` extracts the project name, `VoiceCommandProcessor` looks up or auto-creates the project by name (case-insensitive match), and only the content after "Start" is saved as the note's transcription. Manual dropdown selections take priority over voice command results. Controlled by `voiceCommandsEnabled` setting.

### 6.8 Integration with Existing Screens

**Home Page:**
- Recent notes feed remains the primary view
- "See All" on folders/projects navigates to Library

**Note Detail Page:**
- "Linked Projects" section shows which Project Documents reference this note
- Each linked project is tappable → navigates to that Project Document
- "Add to Project" action available

**Recording Flow (Whisper mode):**
- Folder & Project dropdowns allow assignment before saving
- Voice commands auto-assign to folder/project
- Manual dropdown selections override voice command results
- Default folder pre-selected from Settings

**Folders vs. Projects — Distinction:**
- **Folders** = simple organizational containers. A note lives in one folder. Flat grouping.
- **Project Documents** = rich composite documents. A note can be referenced in many projects. Structured, ordered, editable canvas.
- Both coexist in the Library page. They serve different purposes. Folders organize; Projects compose.

---

## 7. Repository & Provider Layer (Implemented)

### 7.1 ProjectDocumentsRepository

CRUD operations for the `projectDocumentsBox` Hive box:

| Method | Description | Status |
|---|---|---|
| `getAllProjectDocuments()` | Returns all project documents, sorted by updatedAt desc | ✅ |
| `getProjectDocument(id)` | Returns a single project document by ID | ✅ |
| `createProjectDocument(title, description?)` | Creates a new empty project document | ✅ |
| `updateProjectDocument(document)` | Saves changes (title, description, blocks) | ✅ |
| `deleteProjectDocument(id)` | Deletes document and removes its ID from all linked notes' `projectDocumentIds` | ✅ |
| `addBlockToDocument(documentId, block)` | Appends a new block, updates sortOrder | ✅ |
| `removeBlockFromDocument(documentId, blockId)` | Removes block, updates sortOrder; cleans up note's `projectDocumentIds` | ✅ |
| `reorderBlocks(documentId, newBlockOrder)` | Updates sortOrder for all blocks based on new ordering | ✅ |

### 7.2 NotesRepository — Project Document Additions

| Method | Description | Status |
|---|---|---|
| `addTranscriptVersion(noteId, newText, editSource)` | Creates new TranscriptVersion, updates rawTranscription | ✅ |
| `getTranscriptVersions(noteId)` | Returns all versions, sorted by versionNumber asc | ✅ |
| `restoreTranscriptVersion(noteId, versionId)` | Creates new version with restored text, updates rawTranscription | ✅ |
| `addProjectDocumentId(noteId, documentId)` | Adds documentId to note's projectDocumentIds list | ✅ |
| `removeProjectDocumentId(noteId, documentId)` | Removes documentId from note's projectDocumentIds list | ✅ |

### 7.3 projectDocumentsProvider

Riverpod Notifier backed by ProjectDocumentsRepository (one of 6 active providers):

| State/Method | Description | Status |
|---|---|---|
| `state` | List of all ProjectDocuments | ✅ |
| `create(title, description?)` | Creates new document, refreshes state | ✅ |
| `delete(id)` | Deletes document, cleans up note references, refreshes state | ✅ |
| `addNoteBlock(documentId, noteId)` | Adds note_reference block, updates note's projectDocumentIds | ✅ |
| `addFreeTextBlock(documentId, content)` | Adds free_text block | ✅ |
| `addSectionHeaderBlock(documentId, content)` | Adds section_header block | ✅ |
| `removeBlock(documentId, blockId)` | Removes block, cleans up references | ✅ |
| `reorderBlocks(documentId, newOrder)` | Updates block ordering | ✅ |
| `updateBlockContent(documentId, blockId, newContent)` | For free_text and section_header edits | ✅ |
| `editNoteTranscript(documentId, blockId, noteId, newText)` | Bi-directional edit — creates new version on note | ✅ |

---

## 8. Edge Cases & Error Handling

| Scenario | Behavior |
|---|---|
| **Note deleted that is referenced in a project** | Replace the note_reference block with a placeholder card showing "This note has been deleted" with an option to remove the block. Do NOT delete the block automatically — let the user decide. |
| **Same note added twice to one project** | Allow it. User may want the same transcript in two different sections of the document. Each is a separate ProjectBlock with the same noteId. |
| **Project document deleted** | Remove the document. Remove the documentId from all linked notes' `projectDocumentIds`. Do NOT delete any notes. |
| **Edit conflict — same note edited from two different project documents** | Not possible in single-device MVP (no concurrent editing). Edits are sequential. Each creates a new version. No conflict resolution needed until cloud sync (Phase 2). |
| **Very long project document (50+ blocks)** | Implement lazy rendering — only render blocks visible in the viewport. Use a scrollable list builder, not a column. |
| **Empty project document** | Show an empty state with prompt: "Add your first block" with quick-add buttons. |
| **Note with no transcript (empty recording)** | Allow adding to project. Show block with "No transcript available" text and option to edit/add text manually. |
| **Reorder with many blocks** | Limit visible drag area. Consider "move up / move down" buttons as alternative to drag-and-drop for accessibility. |
| **Version history grows very large** | Display versions with pagination or lazy loading. Show last 10 by default with "Load more" option. |
| **Data migration for existing notes** | On first launch after update: iterate all existing notes, create a single TranscriptVersion (v1, isOriginal: true) from rawTranscription. Set projectDocumentIds to empty list. |

---

## 9. Future Considerations (Phase 2+)

These are explicitly out of scope for Phase 1 but inform the data model design:

- **AI Summary:** "Summarize this project" button sends all block content to AI, returns a summary displayed at the top of the document.
- **PDF Export:** Render the full document as a formatted PDF with professional layout.
- **AI-suggested note additions:** AI detects related notes and suggests adding them to the project.
- **Collaborative project documents:** Shared via E2E encrypted cloud sync. Requires Phase 2 accounts.
- **Templates:** "Meeting Notes" template pre-creates a project document with section headers (Attendees, Discussion Points, Action Items, Next Steps).
- **Cross-project note search:** "Show me all notes that appear in more than one project."

---

*End of Core Feature Specification*

---

# ADDENDUM A: Sharing, Rich Text Formatting & Image Blocks

**Version:** 1.1
**Date:** 2026-02-27
**Status:** Approved for Development
**Phase:** Phase 1 Addition
**Scope:** Extends the Project Documents feature with three new capabilities

---

## A1. Feature: Sharing & Export

### A1.1 Overview

Users can share individual voice notes or entire Project Documents via the native OS share sheet, and export Project Documents as Markdown or plain text files. No AI required. No account required.

### A1.2 User Stories

11. **As a user**, I want to share a single voice note's transcript via WhatsApp, email, or any app so I can send my notes to others.
12. **As a user**, I want to share an entire Project Document as a single block of text so I can send a complete summary to someone.
13. **As a user**, I want to export a Project Document as a Markdown file so I can save it outside the app.
14. **As a user**, I want to export a Project Document as a plain text file for maximum compatibility.

### A1.3 Share: Single Note

**Trigger:** Share icon/button on the Note Detail page (and in the note card overflow menu on Home).

**Shared content format (plain text):**
```
[Note Title]
Recorded: [Date] · [Time] · [Language]

[Full transcription text]

— Shared from VoiceNotes AI
```

**Behavior:**
- Uses Flutter's `share_plus` package to invoke the native OS share sheet
- Shares text only (no audio file in Phase 1 — audio sharing is Phase 2)
- If the note has photos attached (see A3), photos are NOT included in text share — only transcript text
- Works offline (share sheet is an OS feature)

### A1.4 Share: Project Document

**Trigger:** Share button in the Project Document Detail screen header/toolbar.

**Shared content format (plain text):**
```
[Project Document Title]
[Description if present]
Last updated: [Date]

---

[For each block, in order:]

## [Section Header text]          ← for section_header blocks

[Free text content]               ← for free_text blocks (formatting stripped to plain text)

📝 [Note Title] · [Date] · [Language]
[Full transcript text]            ← for note_reference blocks

🖼️ [Photo caption or "Photo"]    ← for image_block blocks (placeholder text, image not shared)

---

— Shared from VoiceNotes AI
```

**Behavior:**
- Assembles all blocks in display order into a single text string
- Rich text formatting (bold, italic, etc.) is stripped for plain text share — only raw text
- Images are represented as placeholder text (e.g., "[Photo]" or caption if set)
- Uses `share_plus` for OS share sheet

### A1.5 Export: Project Document as File

**Trigger:** "Export" option in the Project Document Detail screen overflow menu (⋮).

**Export formats available:**
1. **Markdown (.md)** — preserves structure with Markdown syntax
2. **Plain text (.txt)** — flat text, no formatting

**Markdown export format:**
```markdown
# [Project Document Title]

*[Description if present]*
*Last updated: [Date]*

---

## [Section Header text]

[Free text with Markdown formatting preserved — bold, italic, bullets, links]

---

### 📝 [Note Title]
*Recorded: [Date] · [Time] · [Language]*

> [Full transcript text as blockquote]

---

![Photo](photo_filename.jpg)     ← for image blocks (embedded if possible, filename reference if not)

---
```

**Plain text export:** Same as the share format in A1.4.

**File handling:**
- File is generated in a temp directory
- User is presented with the OS share sheet (which allows saving to Files, sending via email, etc.)
- Alternatively, use `open_file` or `path_provider` to save to Downloads and show a confirmation
- File name: `[document_title]_[date].md` or `.txt`

### A1.6 Phase 2 Export Additions

| Capability | Phase |
|---|---|
| PDF export (formatted, professional) | Phase 2 |
| Share audio file alongside transcript | Phase 2 |
| Share with embedded images | Phase 2 |
| Email directly from app (pre-filled) | Phase 2 |

### A1.7 Tech Stack for Sharing/Export

| Component | Package | Purpose |
|---|---|---|
| OS share sheet | `share_plus` | Native sharing to any app |
| File generation | `dart:io` + `path_provider` | Create temp .md / .txt files |
| File sharing | `share_plus` (with file path) | Share generated files via OS sheet |

---

## A2. Feature: Rich Text Formatting (Free-Text Blocks)

### A2.1 Overview

Free-text blocks within Project Documents support medium-level rich text formatting: bold, italic, bullet lists, heading sizes, and links. This transforms free-text blocks from plain text inputs into lightly structured content areas — enough to write context, summaries, and commentary with visual hierarchy, without becoming a full document editor.

### A2.2 User Stories

15. **As a user**, I want to bold and italicize text in my free-text blocks so I can add emphasis.
16. **As a user**, I want to create bullet lists in free-text blocks so I can organize points clearly.
17. **As a user**, I want to set heading sizes in free-text blocks so I can create sub-sections within the document.
18. **As a user**, I want to add links in free-text blocks so I can reference external resources.

### A2.3 Supported Formatting

| Format | Toolbar Icon | Markdown Equivalent | Behavior |
|---|---|---|---|
| **Bold** | **B** | `**text**` | Toggles bold on selected text or at cursor |
| *Italic* | *I* | `*text*` | Toggles italic on selected text or at cursor |
| Bullet list | • list icon | `- item` | Creates/extends an unordered list |
| Heading 1 | H1 | `# text` | Large heading — for major sub-sections |
| Heading 2 | H2 | `## text` | Medium heading — for minor sub-sections |
| Link | 🔗 link icon | `[text](url)` | Opens dialog to enter URL for selected text |

### A2.4 UI: Formatting Toolbar

**Placement:** A compact toolbar appears above the keyboard (or below the block header) when a free-text block is in edit mode.

**Toolbar layout:** `[ B ] [ I ] [ • ] [ H1 ] [ H2 ] [ 🔗 ]`

**Behavior:**
- Toolbar appears only when editing a free-text block — does NOT appear for section headers or note reference blocks
- Toolbar scrolls horizontally if needed on small screens
- Active formatting states are highlighted (e.g., B is highlighted when cursor is inside bold text)
- Link insertion: select text → tap link icon → enter URL in dialog → text becomes tappable link
- Tapping a link in view mode opens it in the system browser

### A2.5 Storage Format

**Recommendation: Store as Quill Delta JSON internally.**

The rich text content of a free-text block is stored in the `content` field of `ProjectBlock` as a serialized Delta JSON string (used by `flutter_quill`). This preserves all formatting in a structured, diff-friendly format.

**ProjectBlock model changes required:**
```
ProjectBlock (EXTENDED for rich text)
├── ... (all existing fields)
├── contentFormat: String? (NEW)
│   ├── "plain" — for section_header and legacy blocks
│   └── "quill_delta" — for rich free_text blocks
```

**Why Delta JSON over Markdown storage:**
- Exact formatting fidelity (no parsing ambiguity)
- Native to `flutter_quill` — no conversion layer needed for editing
- Easily convertible TO Markdown for export (one-way conversion)
- Supports future formatting additions without storage migration

**Migration:** Existing free-text blocks with plain text content should be converted to a simple Delta with a single text insert on first load.

### A2.6 Export Behavior with Formatting

When exporting or sharing:
- **Markdown export:** Delta JSON → converted to Markdown syntax (bold → `**`, italic → `*`, bullets → `- `, headings → `#`/`##`, links → `[text](url)`)
- **Plain text export/share:** All formatting stripped, raw text only
- **In-app display:** Rendered natively by `flutter_quill` viewer

### A2.7 Scope Boundaries

| In Scope (Phase 1) | Out of Scope |
|---|---|
| Bold, italic | Underline, strikethrough |
| Bullet lists | Numbered lists, checklists |
| H1, H2 headings | H3-H6 headings |
| Links (URL) | Inline images within text |
| Basic toolbar | Slash commands (e.g., `/heading`) |
| Quill Delta storage | Markdown source editing mode |

### A2.8 Tech Stack for Rich Text

| Component | Package | Purpose |
|---|---|---|
| Rich text editor | `flutter_quill` | Editing with formatting toolbar |
| Rich text viewer | `flutter_quill` (read-only mode) | Display formatted content |
| Delta → Markdown | `quill_delta` + custom converter or `delta_to_markdown` | Export conversion |

---

## A3. Feature: Image Blocks (Photos)

### A3.1 Overview

Users can add photos to Project Documents as a new block type (`image_block`) and attach photos directly to individual voice notes on the Note Detail page. Photos can be picked from the device gallery or captured with the camera, with basic crop/resize before insertion. Images are stored locally on-device, consistent with the privacy-first architecture.

### A3.2 User Stories

19. **As a user**, I want to add a photo from my gallery to a Project Document so I can include visual context alongside my voice notes.
20. **As a user**, I want to take a new photo with my camera and add it directly to a Project Document.
21. **As a user**, I want to crop and resize a photo before adding it so I can focus on the relevant part.
22. **As a user**, I want to add a caption to a photo block so I can describe what the image shows.
23. **As a user**, I want to add photos to a voice note on the Note Detail page so I can associate images with a specific recording.
24. **As a user**, I want to view photos in full-screen by tapping them.
25. **As a user**, I want to remove a photo from a project or note without losing the original image on my phone.

### A3.3 Where Photos Can Be Added

| Location | Behavior |
|---|---|
| **Project Document** (as `image_block`) | New block type — sits alongside note references, free text, and section headers. Can be reordered like any other block. |
| **Note Detail Page** (as note attachments) | Photos attached directly to a Note. Displayed in an "Attachments" section on the Note Detail page. Travel with the note into any Project Document that references it. |

### A3.4 Data Models

**New model:**
```
ImageAttachment
├── id: String (UUID)
├── filePath: String (local path to stored image file)
├── fileName: String (original or generated filename)
├── caption: String? (optional user-entered caption)
├── width: int (pixels, after crop/resize)
├── height: int (pixels, after crop/resize)
├── fileSizeBytes: int
├── createdAt: DateTime
└── sourceType: String ("gallery" | "camera")
```

**Modified ProjectBlock model — new block type:**
```
ProjectBlock (EXTENDED)
├── type: BlockType
│   ├── note_reference      (existing)
│   ├── free_text           (existing)
│   ├── section_header      (existing)
│   └── image_block         ← NEW
├── imageAttachmentId: String?   ← NEW (required when type = image_block;
│                                    references ImageAttachment.id)
```

**Modified Note model:**
```
Note (EXTENDED)
├── ... (all existing fields)
├── imageAttachmentIds: List<String>  ← NEW (list of ImageAttachment IDs
│                                       attached directly to this note)
```

**Hive storage:**

| Box | Contents |
|---|---|
| `imageAttachmentsBox` (NEW) | All ImageAttachment metadata objects, AES-256 encrypted |
| `projectDocumentsBox` (EXISTING) | Updated with image_block support |
| `notesBox` (EXISTING) | Updated with imageAttachmentIds field |

**Image file storage:**
- Actual image files stored in app's local documents directory: `Documents/images/[uuid].jpg`
- Only metadata (path, dimensions, caption) stored in Hive
- Images are NOT stored inside Hive boxes (too large) — only file paths

### A3.5 Image Capture & Processing Flow

**Step 1: Source selection**
When user taps "Add Image" (from Project Document's "Add Block" menu or Note Detail's attachment area), present options:
- 📷 **Take Photo** — opens device camera
- 🖼️ **Choose from Gallery** — opens device photo picker

**Step 2: Crop & Resize**
After image is selected/captured:
- Opens crop/resize screen
- Crop: free-form aspect ratio (user drags corners)
- Resize: automatic — images larger than 2048px on longest edge are scaled down to 2048px to save storage
- Quality: JPEG at 85% quality for storage efficiency
- User can skip cropping if they want the full image

**Step 3: Save & Insert**
- Processed image saved to `Documents/images/[uuid].jpg`
- `ImageAttachment` metadata record created in Hive
- If adding to Project Document → new `image_block` ProjectBlock created, appended to document
- If adding to Note → `imageAttachmentId` added to note's `imageAttachmentIds` list
- Optional: caption input dialog shown after insertion (or user can add/edit caption later)

### A3.6 UI: Image Block in Project Document

**Rendering:**
- Image displayed at full block width with aspect ratio preserved
- Caption displayed below image in smaller, muted text (if present)
- Tap image → opens full-screen image viewer with pinch-to-zoom
- Overflow menu (⋮): Edit caption, Replace image, Remove from document, View full screen

**In reorder mode:** Image blocks show drag handles and can be reordered like any other block.

### A3.7 UI: Photos on Note Detail Page

**Placement:** "Attachments" section below the structured output sections (actions, todos, reminders, notes) and above the audio playback controls.

**Layout:**
- Horizontal scrollable thumbnail row (if multiple photos)
- Or grid view (2 columns) if more than 3 photos
- Tap thumbnail → full-screen viewer
- "Add Photo" button (camera icon) at the end of the row
- Long-press or overflow menu on thumbnail: Delete attachment, View full screen, Edit caption

**In Project Documents:** When a note with attached photos is referenced in a Project Document, the note_reference block shows a small photo indicator (e.g., 📎 2 photos). Tapping "View original note" navigates to Note Detail where photos are visible. Photos are NOT displayed inline in the note_reference block itself — they stay on the Note Detail page to avoid clutter.

### A3.8 Relationship Rules

- An `ImageAttachment` can be referenced by one `image_block` in a Project Document OR attached to one Note — not both simultaneously. If the same photo is needed in both places, it's two separate copies/records.
- Deleting an `image_block` from a Project Document deletes the `ImageAttachment` record AND the image file (since it's only used there).
- Deleting a photo attachment from a Note deletes the `ImageAttachment` record AND the image file.
- Deleting a Note that has photo attachments also deletes all associated `ImageAttachment` records and image files.
- Deleting a Project Document deletes all `image_block` ImageAttachments and files within it. Note-attached photos (referenced via note_reference blocks) are NOT affected.

### A3.9 Edge Cases

| Scenario | Behavior |
|---|---|
| **Image file missing from disk** | Show placeholder with "Image unavailable" text. Log error. Do not crash. |
| **Very large image (>10MB)** | Resize aggressively before saving (max 2048px, 85% JPEG). Show size warning if original is >20MB. |
| **Many photos in one project (20+)** | Lazy load images. Load thumbnails first, full resolution on demand. |
| **Camera permission denied** | Show permission dialog explaining why camera access is needed. Fall back to gallery-only. |
| **Gallery permission denied** | Show permission dialog. Offer camera-only fallback. |
| **Storage space low** | Check available space before saving. Warn user if <100MB remaining. |
| **Duplicate photo added** | Allow it — each insertion creates a separate copy. No deduplication in Phase 1. |

### A3.10 Tech Stack for Images

| Component | Package | Purpose |
|---|---|---|
| Image picker (gallery + camera) | `image_picker` | Source selection |
| Image cropping | `image_cropper` | Crop and resize UI |
| Image display / full-screen viewer | `photo_view` | Pinch-to-zoom, pan |
| File storage | `path_provider` + `dart:io` | Save to app documents directory |
| Permissions | `permission_handler` | Camera and photo library permissions |
| Image compression | `flutter_image_compress` | Resize and quality reduction |

---

## A4. Updated Data Model Summary

This section summarizes all model changes required by the addendum, building on the current v1.4.0 codebase.

### A4.1 BlockType Enum (Updated)

```
BlockType
├── note_reference    (existing — implemented)
├── free_text         (existing — implemented)
├── section_header    (existing — implemented)
└── image_block       (NEW — Addendum A3)
```

### A4.2 ProjectBlock Model (Updated)

```
ProjectBlock (FINAL)
├── id: String (UUID)                          (existing)
├── type: BlockType                            (existing — add image_block)
├── sortOrder: int                             (existing)
├── noteId: String?                            (existing — for note_reference)
├── content: String?                           (existing — for free_text or section_header)
├── contentFormat: String?                     (NEW — "plain" or "quill_delta"; for free_text blocks)
├── imageAttachmentId: String?                 (NEW — for image_block)
├── createdAt: DateTime                        (existing)
└── updatedAt: DateTime                        (existing)
```

### A4.3 Note Model (Updated)

```
Note (FINAL — all additions)
├── ... (all existing fields from v1.4.0)
├── transcriptVersions: List<TranscriptVersion>   (existing — implemented)
├── projectDocumentIds: List<String>              (existing — implemented)
└── imageAttachmentIds: List<String>              (NEW — Addendum A3)
```

### A4.4 New Models Summary

| Model | Source | Hive Box | Status |
|---|---|---|---|
| ProjectDocument | Original spec | projectDocumentsBox | ✅ Implemented |
| ProjectBlock | Original spec (extended in addendum) | Nested in ProjectDocument | ✅ Implemented (needs extension) |
| TranscriptVersion | Original spec | Nested in Note | ✅ Implemented |
| ImageAttachment | Addendum A3 | imageAttachmentsBox (NEW) | ⏳ Pending |

### A4.5 Updated Relationship Diagram

```
ProjectDocument ──has many──▶ ProjectBlock
                                  │
                    ┌─────────────┼──────────────────┐
                    │             │                   │
              note_reference   free_text          image_block
              section_header   (rich text)             │
                    │                                  ▼
                    ▼                          ImageAttachment
                  Note                         (stored on disk)
                    │
                    ├── has many ──▶ TranscriptVersion
                    ├── has many ──▶ ImageAttachment (note-level photos)
                    ├── can belong to many ProjectDocuments
                    └── projectDocumentIds[] tracks reverse references
```

---

## A5. Implementation Tasks

These tasks build on the completed Step 4.5 codebase. All sub-steps reference extending existing files.

### Sub-step A: Data Model & Storage Extensions

1. Create `ImageAttachment` Hive model with type adapter
2. Add `image_block` to `BlockType` enum
3. Add `imageAttachmentId` field to `ProjectBlock` model
4. Add `contentFormat` field to `ProjectBlock` model
5. Add `imageAttachmentIds` field to `Note` model
6. Add `imageAttachmentsBox` to HiveService initialization (AES-256 encrypted)
7. Create `Documents/images/` directory on app initialization
8. Run `build_runner` to regenerate all type adapters
9. Write migration: existing free-text blocks get `contentFormat: "plain"`

### Sub-step B: Repository & Provider Extensions

1. Create `ImageAttachmentRepository` — CRUD for imageAttachmentsBox + file management
   - `saveImage(file, sourceType)` → processes, stores, returns ImageAttachment
   - `getImageAttachment(id)` → returns metadata
   - `deleteImageAttachment(id)` → deletes metadata AND file from disk
   - `getImageFile(id)` → returns File reference for display
2. Add image methods to `NotesRepository`:
   - `addImageAttachment(noteId, attachmentId)`
   - `removeImageAttachment(noteId, attachmentId)`
3. Add image block methods to `ProjectDocumentsRepository`:
   - `addImageBlock(documentId, attachmentId, caption?)`
4. Extend `projectDocumentsProvider` with image and sharing methods
5. Create `imageAttachmentProvider` if needed (or fold into existing providers)

### Sub-step C: UI — Project Document Detail Extensions

1. Implement Image Block widget:
   - Display image with aspect ratio preservation
   - Caption display and edit
   - Overflow menu (edit caption, replace, remove, full screen)
   - Full-screen viewer on tap (photo_view)
2. Add "Add Image" option to "Add Block" action sheet (alongside Voice Note / Free Text / Section Header)
3. Implement image source selection bottom sheet (Gallery / Camera)
4. Implement crop/resize flow (image_cropper)
5. Implement rich text editing for free-text blocks:
   - Integrate flutter_quill editor
   - Formatting toolbar (bold, italic, bullets, H1, H2, link)
   - Quill Delta serialization to/from Hive
6. Implement sharing:
   - Share button in toolbar → assemble document text → share_plus
   - Export menu → generate .md or .txt file → share_plus with file

### Sub-step D: Note Detail — Photos & Sharing

1. Add "Attachments" section to Note Detail page
2. Implement photo thumbnail row/grid
3. Implement "Add Photo" button (gallery + camera picker)
4. Implement crop/resize for note-level photos
5. Implement full-screen photo viewer
6. Implement photo deletion with confirmation
7. Add Share button to Note Detail page
8. Assemble note share text format → share_plus

### Sub-step E: Integration & Polish

1. Handle image cleanup on note deletion (delete associated ImageAttachments + files)
2. Handle image cleanup on project document deletion
3. Update "Delete All Data" to include imageAttachmentsBox and image files
4. Update storage display in Settings to include image file sizes
5. Test with large images, many photos, low storage scenarios
6. Accessibility: image alt-text from caption, screen reader labels

---

## A6. Files Impact

### Files to Modify (Existing)

| File / Area | Change |
|---|---|
| **ProjectBlock Hive model** | Add `imageAttachmentId`, `contentFormat` fields |
| **BlockType enum** | Add `image_block` |
| **Note Hive model** | Add `imageAttachmentIds` field |
| **HiveService** | Add `imageAttachmentsBox` initialization, image directory creation |
| **ProjectDocumentsRepository** | Add image block methods |
| **NotesRepository** | Add image attachment methods |
| **projectDocumentsProvider** | Add image, sharing, and export methods |
| **Project Document Detail screen** | Add image blocks, rich text editor, share/export buttons |
| **Note Detail screen** | Add attachments section, share button |
| **"Add Block" action sheet** | Add "Add Image" option |
| **Settings page** | Update storage display to include images |

### New Files to Create

| File | Purpose |
|---|---|
| `lib/models/image_attachment.dart` | ImageAttachment Hive model |
| `lib/repositories/image_attachment_repository.dart` | Image CRUD + file management |
| `lib/services/sharing_service.dart` | Assemble share text, generate export files |
| `lib/services/image_processing_service.dart` | Crop, resize, compress, save |
| `lib/widgets/image_block_widget.dart` | Image block for Project Document |
| `lib/widgets/note_attachments_section.dart` | Photo section on Note Detail |
| `lib/widgets/formatting_toolbar.dart` | Rich text toolbar for free-text blocks |
| `lib/pages/image_viewer_page.dart` | Full-screen image viewer |

---

## A7. Package Dependencies (Addendum)

| Package | Purpose | Phase | Status |
|---|---|---|---|
| `share_plus` | Native OS share sheet | Phase 1 | To add |
| `flutter_quill` | Rich text editing and viewing | Phase 1 | To add |
| `delta_to_markdown` or custom converter | Export Delta → Markdown | Phase 1 | To add |
| `image_picker` | Gallery and camera photo selection | Phase 1 | To add |
| `image_cropper` | Crop and resize UI | Phase 1 | To add |
| `photo_view` | Full-screen image viewer with zoom | Phase 1 | To add |
| `flutter_image_compress` | Image compression and resizing | Phase 1 | To add |
| `permission_handler` | Camera and photo library permissions | Phase 1 | Already in project |
| `path_provider` | File system access for image storage | Phase 1 | Already in project |

---

*End of Addendum A*
