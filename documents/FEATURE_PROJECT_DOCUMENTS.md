# VoiceNotes AI — Feature Spec: Project Documents

**Version:** 1.0
**Date:** 2026-02-26
**Status:** Approved for Development
**Phase:** Phase 1 Addition (Step 4.5 — after Wire UI to Data Layer)
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Implementation Plan](IMPLEMENTATION_PLAN.md)

---

## 1. Feature Overview

**Project Documents** is a new feature that allows users to create rich, composite note documents assembled from individual voice notes. A project document acts as a living workspace — a single, scrollable page where users aggregate, arrange, and edit transcripts from multiple voice notes alongside free-text content and section headers.

**Core Concept:** Voice notes are atomic units. Project documents are compositions built from those atoms. The voice note remains the source of truth; the project document is a curated view that references and arranges them.

**Why this matters:** Users frequently capture many voice notes around a single topic (a project, a trip, a client). Today, these notes live as separate items in a flat list or folder. Project Documents let users build a structured narrative from those fragments — turning scattered voice captures into a single, coherent, editable document.

---

## 2. User Stories

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

## 3. Phasing

This feature spans Phase 1 and Phase 2. The split is clean — Phase 1 covers everything that works locally without AI or cloud services.

### Phase 1 Scope (On-Device, No AI)

| Capability | Included |
|---|---|
| Create / rename / delete Project Documents | ✅ |
| Add voice note references to a Project Document | ✅ |
| One note can appear in multiple Project Documents | ✅ |
| Reorder blocks via drag and drop | ✅ |
| Add section header / divider blocks | ✅ |
| Add free-text blocks | ✅ |
| Edit transcript within Project Document (bi-directional) | ✅ |
| Full version history on note transcripts | ✅ |
| View Project Document as a single scrollable page | ✅ |
| Remove a block from Project Document (does not delete the original note) | ✅ |
| Timestamp display per note block (original recording time) | ✅ |
| Project Document list screen | ✅ |

### Phase 2 Scope (AI-Powered)

| Capability | Phase |
|---|---|
| AI-generated summary of entire Project Document | Phase 2 |
| Export as single file (Markdown / PDF / plain text) | Phase 2 |
| AI-suggested note additions ("You have 3 other notes about this topic") | Phase 2 |
| Voice command to add current note to a project ("Add this to Kitchen Renovation") | Phase 2 |

---

## 4. Data Models

### 4.1 New Models

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

### 4.2 Modified Existing Models

The existing **Note** model requires the following changes:

```
Note (MODIFIED)
├── ... (all existing fields remain unchanged)
│
├── rawTranscription: String          ← KEEP for backward compatibility
│                                        (always reflects the latest version text)
│
├── transcriptVersions: List<TranscriptVersion>  ← NEW
│                                        (full version history; first entry = original STT output)
│
└── projectDocumentIds: List<String>  ← NEW
                                        (list of ProjectDocument IDs this note belongs to;
                                         used for reverse lookup / UI indicators)
```

**Migration note:** When this feature is implemented, existing notes should be migrated by creating a single `TranscriptVersion` entry (versionNumber: 1, isOriginal: true) from their current `rawTranscription` value. The `rawTranscription` field continues to hold the latest text for backward compatibility with search, display, and other features that read it directly.

### 4.3 Hive Storage

| Box | Contents |
|---|---|
| `projectDocumentsBox` (NEW) | All ProjectDocument objects, AES-256 encrypted |
| `notesBox` (EXISTING) | Updated Note objects with new fields |

### 4.4 Relationship Diagram

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

## 5. Screens & UI

### 5.1 Project Documents List Screen

**Route:** `/project-documents`
**Access:** From Home page (new tab or navigation item alongside Folders) and from bottom navigation or drawer.

**Layout:**
- Screen title: "Projects"
- **"New Project" button** — prominent, top or floating action button
- **Project Document cards** in a list, each showing:
  - Title
  - Description (if present, first line)
  - Number of blocks / linked notes count
  - Last updated timestamp
  - Brief preview (first block's content, truncated)
- **Empty state** when no project documents exist — illustration + "Create your first project document" prompt
- **Search** — filter project documents by title/description keyword

### 5.2 Project Document Detail Screen

**Route:** `/project-documents/:id`
**Access:** Tapping a project document card from the list.

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

### 5.3 Add Block Flow

When the user taps "Add Block" on a Project Document, present options:

1. **Add Voice Note** — opens a picker/search screen showing all existing notes. User selects one (or multiple). Selected notes are appended as `note_reference` blocks at the end of the document.
2. **Add Free Text** — inserts a new empty `free_text` block at the end. Cursor focuses for immediate typing.
3. **Add Section Header** — inserts a new `section_header` block at the end. Cursor focuses for immediate typing.

**Note Picker screen:**
- Shows all notes (reverse chronological)
- Search bar to filter
- Checkboxes for multi-select
- Already-linked notes shown with a "linked" indicator (but can still be added again if user wants — no restriction)
- "Add Selected" button confirms

### 5.4 Bi-Directional Editing Flow

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

**Version History access:**
- From the block's overflow menu: "View version history"
- Opens a bottom sheet or sub-screen showing all versions:
  - Version number, date, edit source
  - Diff indicator or full text per version
  - "Restore this version" action — creates a NEW version with the restored text (does not delete intermediate versions)

### 5.5 Integration Points with Existing Screens

**Home Page:**
- Add a "Projects" section or tab alongside recent notes and folders
- Or add "Projects" as a navigation item in bottom nav / drawer

**Note Detail Page:**
- Add a "Linked Projects" section showing which Project Documents reference this note
- Each linked project is tappable → navigates to that Project Document
- Add "Add to Project" action button — opens project picker to link this note to a project document

**Recording Flow (post-save):**
- After saving a new voice note, show an optional prompt: "Add to a Project?" with quick project selection
- This is non-blocking — user can dismiss and add later

**Folders vs. Projects — Distinction:**
- **Folders** = simple organizational containers. A note lives in one folder. Flat grouping.
- **Project Documents** = rich composite documents. A note can be referenced in many projects. Structured, ordered, editable canvas.
- Both coexist. They serve different purposes. Folders organize; Projects compose.

---

## 6. Repository & Provider Layer

### 6.1 New Repository

**ProjectDocumentsRepository** — CRUD operations for the `projectDocumentsBox` Hive box:

| Method | Description |
|---|---|
| `getAllProjectDocuments()` | Returns all project documents, sorted by updatedAt desc |
| `getProjectDocument(id)` | Returns a single project document by ID |
| `createProjectDocument(title, description?)` | Creates a new empty project document |
| `updateProjectDocument(document)` | Saves changes (title, description, blocks) |
| `deleteProjectDocument(id)` | Deletes document and removes its ID from all linked notes' `projectDocumentIds` |
| `addBlockToDocument(documentId, block)` | Appends a new block, updates sortOrder |
| `removeBlockFromDocument(documentId, blockId)` | Removes block, updates sortOrder of remaining blocks; if note_reference, removes documentId from the note's `projectDocumentIds` |
| `reorderBlocks(documentId, newBlockOrder)` | Updates sortOrder for all blocks based on new ordering |

### 6.2 Modified Repository

**NotesRepository** — additions:

| Method | Description |
|---|---|
| `addTranscriptVersion(noteId, newText, editSource)` | Creates new TranscriptVersion, updates rawTranscription to latest text |
| `getTranscriptVersions(noteId)` | Returns all versions for a note, sorted by versionNumber asc |
| `restoreTranscriptVersion(noteId, versionId)` | Creates a new version with the restored text, updates rawTranscription |
| `addProjectDocumentId(noteId, documentId)` | Adds documentId to note's projectDocumentIds list |
| `removeProjectDocumentId(noteId, documentId)` | Removes documentId from note's projectDocumentIds list |

### 6.3 New Riverpod Provider

**projectDocumentsProvider** — Notifier backed by ProjectDocumentsRepository:

| State/Method | Description |
|---|---|
| `state` | List of all ProjectDocuments |
| `create(title, description?)` | Creates new document, refreshes state |
| `delete(id)` | Deletes document, cleans up note references, refreshes state |
| `addNoteBlock(documentId, noteId)` | Adds note_reference block, updates note's projectDocumentIds |
| `addFreeTextBlock(documentId, content)` | Adds free_text block |
| `addSectionHeaderBlock(documentId, content)` | Adds section_header block |
| `removeBlock(documentId, blockId)` | Removes block, cleans up references |
| `reorderBlocks(documentId, newOrder)` | Updates block ordering |
| `updateBlockContent(documentId, blockId, newContent)` | For free_text and section_header edits |
| `editNoteTranscript(documentId, blockId, noteId, newText)` | Bi-directional edit — creates new version on note |

---

## 7. Navigation / Routes

Add these routes to the existing go_router configuration:

| Route | Screen | Extras |
|---|---|---|
| `/project-documents` | Project Documents List | — |
| `/project-documents/:id` | Project Document Detail | documentId |
| `/project-documents/:id/add-notes` | Note Picker (for adding notes to a project) | documentId |
| `/project-documents/:id/version-history/:noteId` | Transcript Version History | documentId, noteId |

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

## 9. Implementation Tasks

### Step 4.5: Project Documents (Phase 1 Addition)

**Goal:** Implement the Project Documents feature with local Hive storage, bi-directional editing, version history, and all Phase 1 UI.

**Estimated effort:** Large

### Sub-step A: Data Model & Storage

1. Create `ProjectDocument` Hive model with type adapter
2. Create `ProjectBlock` Hive model with type adapter
3. Create `TranscriptVersion` Hive model with type adapter
4. Create `BlockType` enum (note_reference, free_text, section_header)
5. Add `projectDocumentsBox` to HiveService initialization (AES-256 encrypted)
6. Modify existing `Note` model:
   - Add `transcriptVersions: List<TranscriptVersion>` field
   - Add `projectDocumentIds: List<String>` field
7. Write data migration: on app start, if a Note has no transcriptVersions, create v1 from rawTranscription
8. Run `build_runner` to regenerate type adapters

### Sub-step B: Repository & Provider Layer

1. Create `ProjectDocumentsRepository` with all CRUD methods
2. Add transcript versioning methods to `NotesRepository`
3. Add projectDocumentIds management methods to `NotesRepository`
4. Create `projectDocumentsProvider` (Notifier/NotifierProvider)
5. Wire provider to repository with proper state management

### Sub-step C: UI — Project Documents List Screen

1. Create `/project-documents` route and screen
2. Implement project document card widget
3. Implement "New Project" creation dialog (title + optional description)
4. Implement rename and delete actions with confirmation
5. Implement search/filter within project documents
6. Implement empty state
7. Add navigation entry point from Home page

### Sub-step D: UI — Project Document Detail Screen

1. Create `/project-documents/:id` route and screen
2. Implement block rendering engine (switch on block type → render appropriate card)
3. Implement Note Reference Block widget:
   - Display transcript, timestamp, language badge, note title
   - In-place editing with save
   - Overflow menu (remove, view original, version history)
4. Implement Free-Text Block widget:
   - Editable text area
   - Overflow menu (remove)
5. Implement Section Header Block widget:
   - Large/bold editable text with optional divider
   - Overflow menu (remove)
6. Implement "Add Block" action sheet (Add Voice Note / Add Free Text / Add Section Header)
7. Implement reorder mode with drag handles
8. Wire all edit/save/delete actions to provider

### Sub-step E: UI — Note Picker & Supporting Screens

1. Create note picker screen with search and multi-select
2. Show "already linked" indicator on notes
3. Implement "Add to Project" action on Note Detail page
4. Implement "Linked Projects" section on Note Detail page
5. Implement optional "Add to Project?" prompt after saving a new recording
6. Create Version History screen/bottom sheet:
   - List all versions with number, date, source
   - "Restore this version" action

### Sub-step F: Integration & Polish

1. Handle note deletion — update project document blocks to show placeholder
2. Handle project document deletion — clean up note references
3. Ensure search indexes include project document titles
4. Test with large documents (50+ blocks)
5. Implement lazy rendering for block list
6. Accessibility: screen reader labels, drag-and-drop alternatives
7. Empty states for all new screens

---

## 10. Impact on Existing Code

### Files to Modify

| File / Area | Change |
|---|---|
| **Note Hive model** | Add `transcriptVersions` and `projectDocumentIds` fields |
| **Note type adapter** | Regenerate with build_runner |
| **HiveService** | Add `projectDocumentsBox` initialization |
| **NotesRepository** | Add versioning and project reference methods |
| **Notes Provider** | Expose new repository methods |
| **go_router config** | Add 4 new routes |
| **Home Page** | Add Projects navigation entry |
| **Note Detail Page** | Add "Linked Projects" section and "Add to Project" button |
| **Recording Page (post-save flow)** | Add optional "Add to Project" prompt |
| **Bottom navigation / drawer** | Add Projects entry if applicable |

### New Files to Create

| File | Purpose |
|---|---|
| `lib/models/project_document.dart` | ProjectDocument Hive model |
| `lib/models/project_block.dart` | ProjectBlock Hive model |
| `lib/models/transcript_version.dart` | TranscriptVersion Hive model |
| `lib/repositories/project_documents_repository.dart` | CRUD for project documents |
| `lib/providers/project_documents_provider.dart` | Riverpod provider |
| `lib/pages/project_documents_page.dart` | List screen |
| `lib/pages/project_document_detail_page.dart` | Detail / canvas screen |
| `lib/pages/note_picker_page.dart` | Multi-select note picker |
| `lib/pages/version_history_page.dart` | Transcript version history |
| `lib/widgets/note_reference_block.dart` | Block widget |
| `lib/widgets/free_text_block.dart` | Block widget |
| `lib/widgets/section_header_block.dart` | Block widget |
| `lib/widgets/project_document_card.dart` | Card for list screen |

---

## 11. Relationship to Existing Features

### Folders vs. Project Documents

These are complementary, not competing features:

| Aspect | Folders | Project Documents |
|---|---|---|
| **Purpose** | Organize / group notes | Compose / build a document from notes |
| **Note relationship** | A note belongs to one folder | A note can appear in many project documents |
| **Content** | Just a container of note references | Rich canvas: note transcripts + free text + headers |
| **Editing** | No editing within folder view | Full inline editing with version history |
| **Structure** | Flat list of notes | Ordered, user-arranged blocks |
| **Analogy** | File folder | Google Docs page built from voice clips |

### Auto-Folder vs. Project Documents (Phase 2)

In Phase 2, when AI auto-categorization is added, the AI could suggest creating a Project Document from a cluster of related notes, or suggest adding a new note to an existing Project Document based on topic matching. This is listed as Phase 2 scope.

---

## 12. Future Considerations (Phase 2+)

These are explicitly out of scope for the initial implementation but inform the data model design:

- **AI Summary:** "Summarize this project" button sends all block content to AI, returns a summary displayed at the top of the document.
- **Export:** Render the full document as Markdown, PDF, or plain text. Markdown is simplest — section headers become `##`, note blocks become quoted text with timestamps, free text becomes paragraphs.
- **Voice command integration:** "Add this to Kitchen Renovation" after recording a note. Requires Phase 2 AI pipeline.
- **Collaborative project documents:** Shared via E2E encrypted cloud sync. Requires Phase 2 accounts.
- **Templates:** "Meeting Notes" template pre-creates a project document with section headers (Attendees, Discussion Points, Action Items, Next Steps).
- **Cross-project note search:** "Show me all notes that appear in more than one project."

---

*End of Feature Specification*
