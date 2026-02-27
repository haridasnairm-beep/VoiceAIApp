# VoiceNotes AI — Feature Spec: Interactive Tasks & Reminder Enhancement

**Version:** 1.0
**Date:** 2026-02-27
**Status:** Approved for Development
**Phase:** Phase 1 Addition
**Reference:** [Concept Document](voicenotes-ai-concept.md) | [Specification](PROJECT_SPECIFICATION.md) | [Project Status](PROJECT_STATUS.md) | [Project Documents Feature Spec](FEATURE_PROJECT_DOCUMENTS.md)

---

## 1. Feature Overview

This spec covers three interconnected features that make tasks and reminders genuinely useful within VoiceNotes AI:

1. **Interactive Checkboxes** — Todos and action items become tappable, checkable items on Note Detail and inside Project Document blocks. Users can mark tasks complete and see progress visually.

2. **Aggregated Tasks View** — A new dedicated surface on the Home page that pulls all unchecked todos and action items from every note into a single, filterable list. One place to see everything that needs doing.

3. **Reminder Enhancement (Hybrid Model)** — Keep the existing in-app reminder system (local notifications with deep-link back to the note) AND add a one-tap "Add to OS Reminder" option that pushes the reminder to iOS Reminders or Google Tasks with pre-filled text and time. User chooses where the reminder lives.

**Why these matter together:** VoiceNotes AI captures tasks through voice. But capture without follow-through is just noise. These features close the loop — users can see all their tasks in one place, check them off as they go, and choose whether reminders stay in-app (with context) or go to the OS (for system-level reliability).

---

## 2. Current State (What Already Exists)

Before defining what to build, here's what's already in place:

| Component | Status | Details |
|---|---|---|
| `TodoItem` model | ✅ Exists | Has `id`, `text`, `isCompleted`, `dueDate?`, `createdAt` |
| `ActionItem` model | ✅ Exists | Has `id`, `text`, `isCompleted`, `createdAt` |
| `ReminderItem` model | ✅ Exists | Has `id`, `text`, `reminderTime`, `isCompleted`, `notificationId?`, `createdAt` |
| `Note.todos` | ✅ Exists | `List<TodoItem>` on every note |
| `Note.actions` | ✅ Exists | `List<ActionItem>` on every note |
| `Note.reminders` | ✅ Exists | `List<ReminderItem>` on every note |
| Reminder notifications | ✅ Exists | `flutter_local_notifications` with scheduling, deep-link, cancellation |
| Reminder CRUD on Note Detail | ✅ Exists | Add, toggle complete, delete with notification cancellation |
| Note Detail page | ✅ Exists | Shows structured sections (actions, todos, reminders, general notes) |
| Project Document blocks | ✅ Exists | note_reference blocks display linked note's transcript |
| NotesRepository | ✅ Exists | CRUD operations for notes |
| NotesProvider | ✅ Exists | Riverpod Notifier backed by repository |

**Key insight:** The data layer is largely in place. `isCompleted` already exists on todos, actions, and reminders. The work is primarily UI (making checkboxes interactive, creating the tasks view) and the OS reminder bridge.

---

## 3. User Stories

### Interactive Checkboxes
1. **As a user**, I want to tap a checkbox on a todo item in Note Detail to mark it complete, so I can track what I've done.
2. **As a user**, I want to tap a checkbox on an action item in Note Detail to mark it complete.
3. **As a user**, I want completed items to show with a strikethrough and muted styling so I can visually distinguish done from not-done.
4. **As a user**, I want to uncheck a completed item if I marked it by mistake.
5. **As a user**, I want to check off tasks directly inside a Project Document's note_reference block, without navigating to the original note.
6. **As a user**, I want checkbox state changes in a Project Document to update the original note (and vice versa).

### Aggregated Tasks View
7. **As a user**, I want to see all my unchecked todos and action items from all notes in one place, so I don't have to open each note individually.
8. **As a user**, I want each task in the aggregated view to show which note it came from, so I have context.
9. **As a user**, I want to tap a task's source note to navigate directly to that note.
10. **As a user**, I want to check off tasks from the aggregated view without opening the source note.
11. **As a user**, I want to toggle showing/hiding completed tasks in the aggregated view.
12. **As a user**, I want to see a count of open tasks (e.g., "12 open tasks") at a glance.
13. **As a user**, I want to filter tasks by type (todos only, actions only, or both).

### Reminder Enhancement
14. **As a user**, I want to keep using in-app reminders with notifications that deep-link back to my note (existing behavior).
15. **As a user**, I want a one-tap option to send a reminder to my phone's native Reminders/Tasks app instead.
16. **As a user**, I want the OS reminder to be pre-filled with the reminder text and time so I just confirm.
17. **As a user**, I want to choose per-reminder whether it stays in-app or goes to OS — not a global setting.
18. **As a user**, I want to snooze or reschedule a reminder from the notification or Note Detail page.

---

## 4. Feature A: Interactive Checkboxes

### 4.1 Note Detail Page — Todos & Actions

**Current behavior:** Todos and actions display as text items with `isCompleted` stored in Hive but the UI interaction may be limited.

**Enhanced behavior:**

Each todo and action item renders as a row with:
- **Checkbox** (leading) — tappable, toggles `isCompleted`
- **Text** — the task description
- **Due date badge** (todos only, if `dueDate` is set) — small pill showing date, colored red if overdue
- **Strikethrough + muted opacity** when `isCompleted == true`
- **Overflow menu** (⋮) — Edit text, Delete item, (for todos) Set/change due date

**On checkbox tap:**
1. Toggle `isCompleted` on the item
2. Persist to Hive via `NotesRepository`
3. Update `Note.updatedAt` timestamp
4. If the note is referenced in any Project Documents, the change reflects immediately (since Project Documents read from the Note object)

**Visual treatment:**
- Unchecked: full opacity, normal text weight, empty checkbox outline
- Checked: reduced opacity (~60%), strikethrough text, filled checkbox with checkmark
- Overdue todos: due date badge in red/warning color
- Completed items sink to the bottom of their section (optional — discuss with user)

### 4.2 Project Document — Note Reference Blocks

**Current behavior:** Note reference blocks display the full transcript of the linked note. Todos and actions from the note are not individually surfaced in the block.

**Enhanced behavior:**

Below the transcript text in a note_reference block, add a collapsible "Tasks" sub-section that shows:
- All `TodoItem` entries from the linked note — with interactive checkboxes
- All `ActionItem` entries from the linked note — with interactive checkboxes
- Count indicator in the collapsed state: "3 tasks (1 completed)"

**On checkbox tap in Project Document:**
1. Same as Note Detail — toggle `isCompleted` on the original Note's item
2. Persist to Hive
3. Change reflects everywhere (Note Detail, other Project Documents, Aggregated Tasks View)

**Collapsed by default** if no tasks exist on the note. Expanded by default if tasks exist.

### 4.3 Manual Task Creation

Users should be able to manually add todos and actions to a note (not just from AI extraction in Phase 2):

**On Note Detail page:**
- "Add Task" button at the bottom of the Todos section
- Tapping opens an inline text field + optional due date picker
- New `TodoItem` created, persisted, appears in the list immediately
- Same for Actions section — "Add Action" button

**This enables Phase 1 utility** — users can manually create tasks on their notes even before AI auto-extraction is available in Phase 2.

### 4.4 Data Layer Changes

**No model changes needed** — `TodoItem.isCompleted` and `ActionItem.isCompleted` already exist.

**Repository additions:**

| Method | Description |
|---|---|
| `NotesRepository.toggleTodoCompleted(noteId, todoId)` | Flips `isCompleted`, updates `updatedAt` |
| `NotesRepository.toggleActionCompleted(noteId, actionId)` | Flips `isCompleted`, updates `updatedAt` |
| `NotesRepository.addTodoItem(noteId, text, dueDate?)` | Creates new TodoItem, appends to note |
| `NotesRepository.addActionItem(noteId, text)` | Creates new ActionItem, appends to note |
| `NotesRepository.updateTodoItem(noteId, todoId, text?, dueDate?)` | Edits todo text or due date |
| `NotesRepository.updateActionItem(noteId, actionId, text?)` | Edits action text |
| `NotesRepository.deleteTodoItem(noteId, todoId)` | Removes todo from note |
| `NotesRepository.deleteActionItem(noteId, actionId)` | Removes action from note |

**Provider additions:**
Expose the above methods through `NotesProvider` so UI can call them.

---

## 5. Feature B: Aggregated Tasks View

### 5.1 Overview

A new section/tab on the Home page that aggregates all unchecked todos and action items from every note into a single, scrollable, filterable list. This is the "everything I need to do" view.

### 5.2 Placement on Home Page

**Recommended approach:** Add a segmented control or tab bar at the top of the Home page:

```
[ Notes ]  [ Tasks ]
```

- **Notes tab** (default) — the existing recent notes feed
- **Tasks tab** — the new aggregated tasks view

Alternatively, a horizontal section on Home with a "See All" link that navigates to a full-screen Tasks page. Either works — the tab approach keeps it one tap away.

### 5.3 Tasks Tab UI

**Header area:**
- Open task count: "12 open tasks" (prominent, large number)
- Filter chips: `All` | `Todos` | `Actions`
- Toggle: "Show completed" (off by default)

**Task list:**
Each row displays:

```
┌─────────────────────────────────────────────┐
│ ☐  Call the dentist about appointment       │
│    📝 Meeting Notes — Feb 26, 2026          │
│    Due: Mar 1, 2026                         │
└─────────────────────────────────────────────┘
```

- **Checkbox** (leading) — interactive, same behavior as Note Detail
- **Task text** — the todo or action description
- **Source note** — note title + date, styled as a tappable link (navigates to Note Detail)
- **Due date** (if present) — with overdue highlighting
- **Type indicator** — subtle icon or label distinguishing todo vs. action

**Sorting:**
- Default: overdue items first, then by due date (soonest first), then by creation date (newest first)
- Items without due dates sorted after dated items

**Empty state:**
- When no tasks exist: "No open tasks — you're all caught up! 🎉"
- When filter has no results: "No [todos/actions] found"

**Completed tasks toggle:**
- When "Show completed" is on, completed items appear at the bottom with strikethrough styling
- Completed items grouped under a "Completed" sub-header with count

### 5.4 Data Layer

**New Riverpod provider — `tasksProvider`:**

This is a computed/derived provider that reads from `notesProvider` and assembles a flat task list:

```dart
// Pseudo-code
final tasksProvider = Provider<TasksState>((ref) {
  final notes = ref.watch(notesProvider);
  
  List<TaskItem> allTasks = [];
  for (final note in notes) {
    for (final todo in note.todos) {
      allTasks.add(TaskItem(
        type: TaskType.todo,
        item: todo,
        sourceNoteId: note.id,
        sourceNoteTitle: note.title,
        sourceNoteDate: note.createdAt,
      ));
    }
    for (final action in note.actions) {
      allTasks.add(TaskItem(
        type: TaskType.action,
        item: action,
        sourceNoteId: note.id,
        sourceNoteTitle: note.title,
        sourceNoteDate: note.createdAt,
      ));
    }
  }
  // Sort: overdue first, then by dueDate, then by createdAt
  return TasksState(tasks: sorted(allTasks));
});
```

**`TaskItem` — view model (not a Hive model):**

```
TaskItem (UI view model — NOT stored in Hive)
├── type: TaskType (todo | action)
├── id: String (the TodoItem or ActionItem id)
├── text: String
├── isCompleted: bool
├── dueDate: DateTime? (only for todos)
├── createdAt: DateTime
├── sourceNoteId: String
├── sourceNoteTitle: String
└── sourceNoteDate: DateTime
```

This is a read-only projection. All mutations (toggle, edit, delete) go through `NotesProvider` using the `sourceNoteId` and item `id`.

### 5.5 Navigation

| Route | Screen | Notes |
|---|---|---|
| No new route needed | Tasks tab on Home page | Implemented as a tab within the existing Home screen |

If a full-screen tasks page is preferred instead:

| Route | Screen | Notes |
|---|---|---|
| `/tasks` | Aggregated Tasks Page | Standalone screen accessible from Home |

### 5.6 Badge on Home Tab

When the Tasks tab is not selected, show a small badge with the open task count on the tab label — similar to an unread notification badge. This gives at-a-glance awareness without switching tabs.

---

## 6. Feature C: Reminder Enhancement (Hybrid Model)

### 6.1 Current Reminder Flow

Today:
1. User opens Note Detail → taps "Add Reminder"
2. Picks date/time via dialog
3. `ReminderItem` created, local notification scheduled via `flutter_local_notifications`
4. Notification fires at the scheduled time → tapping it deep-links to the note
5. User can toggle complete or delete the reminder

This works well for in-app context. The enhancement adds an OS bridge without removing anything.

### 6.2 Enhanced Reminder Flow

After the user creates a reminder (step 2 above), show a bottom sheet with two options:

```
┌─────────────────────────────────────────────┐
│  Reminder set: "Call the dentist"            │
│  🕐 Mar 1, 2026 at 3:00 PM                  │
│                                              │
│  Where should this reminder live?            │
│                                              │
│  ┌─────────────────────────────────────────┐ │
│  │ 📱  Keep in VoiceNotes AI               │ │
│  │     Notification with link to this note  │ │
│  └─────────────────────────────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │ 📤  Also add to [iOS Reminders /        │ │
│  │     Google Tasks]                        │ │
│  │     Syncs across your devices            │ │
│  └─────────────────────────────────────────┘ │
│                                              │
└─────────────────────────────────────────────┘
```

**"Keep in VoiceNotes AI"** — existing behavior, nothing changes. The in-app reminder + notification is created.

**"Also add to OS Reminders"** — creates the in-app reminder AND opens the OS reminder creation (pre-filled). The user gets both: in-app deep-link context + OS-level reliability and cross-device sync.

**Key decision: "Also" not "Instead"** — the in-app reminder is always created (for deep-link value). The OS push is additive. This avoids a scenario where the user pushes to OS, the OS reminder fires, and they have no way to get back to the original note.

### 6.3 OS Reminder Integration

**iOS:**
- Use platform channel or `url_launcher` with `x-apple-reminder://` URL scheme
- Or use `add_2_calendar` package for calendar events (not quite reminders, but similar)
- Best option: use the `EventKit` framework via a platform channel to create a reminder in Apple Reminders with title, date, and a note containing "From VoiceNotes AI: [note title]"

**Android:**
- Use an intent to open Google Tasks or the default reminders app
- `Intent.ACTION_INSERT` with `Events.CONTENT_URI` for calendar-based reminders
- Or use Google Tasks API (requires auth — Phase 2)
- Simplest Phase 1 approach: launch an intent to create a calendar event with the reminder text and time, which triggers a notification at the scheduled time

**Practical Phase 1 recommendation:**
Use the **calendar event approach** for both platforms — it's the most universal and doesn't require authentication or platform-specific APIs. The `add_2_calendar` package handles this cross-platform:

```dart
Add2Calendar.addEvent2Cal(Event(
  title: reminderText,
  description: 'From VoiceNotes AI: $noteTitle',
  startDate: reminderTime,
  endDate: reminderTime.add(Duration(minutes: 15)),
  allDay: false,
));
```

This opens the native calendar app with pre-filled details. The user confirms, and the OS handles the notification. Simple, no auth needed, works offline.

### 6.4 Snooze / Reschedule

**From Note Detail page:**
- On each reminder item, add a "Reschedule" action (clock icon or in overflow menu)
- Opens the same date/time picker, pre-filled with current time
- Updates `ReminderItem.reminderTime`, cancels old notification, schedules new one

**From notification (stretch goal):**
- Add notification action buttons: "Done" (marks complete) and "Snooze 1hr" (reschedules +1 hour)
- `flutter_local_notifications` supports action buttons on Android — iOS support is more limited
- If complexity is too high, defer notification actions to Phase 2 and keep snooze only in-app

### 6.5 Reminder in Aggregated Tasks View

Reminders should also appear in the Aggregated Tasks View alongside todos and actions:

- Show as a distinct type with a 🔔 icon
- Display scheduled time prominently
- Overdue reminders highlighted
- Checkbox to mark complete
- Tapping navigates to source note

Update the `TaskItem` view model:

```
TaskItem (UPDATED)
├── type: TaskType (todo | action | reminder)    ← reminder added
├── id: String
├── text: String
├── isCompleted: bool
├── dueDate: DateTime? (for todos)
├── reminderTime: DateTime? (for reminders)      ← NEW
├── createdAt: DateTime
├── sourceNoteId: String
├── sourceNoteTitle: String
└── sourceNoteDate: DateTime
```

### 6.6 Data Layer Changes

**No model changes needed** for the core reminder — `ReminderItem` already has everything.

**Repository additions:**

| Method | Description |
|---|---|
| `NotesRepository.rescheduleReminder(noteId, reminderId, newTime)` | Updates `reminderTime`, reschedules notification |
| `NotesRepository.addReminderToOS(reminderItem, noteTitle)` | Launches OS calendar intent with pre-filled data |

### 6.7 Tech Stack for Reminders

| Component | Package | Purpose |
|---|---|---|
| OS calendar integration | `add_2_calendar` | Cross-platform calendar event creation |
| Existing notifications | `flutter_local_notifications` | In-app reminder notifications (already in project) |

---

## 7. Implementation Tasks

### Step 4.6: Interactive Tasks & Reminder Enhancement

**Goal:** Make todos, actions, and reminders interactive across all surfaces, add aggregated tasks view, and enhance reminders with OS bridge.

**Estimated effort:** Medium-Large

### Sub-step A: Interactive Checkboxes on Note Detail

1. Update todo item rendering — add interactive checkbox widget
2. Update action item rendering — add interactive checkbox widget
3. Implement strikethrough + muted styling for completed items
4. Add overdue date highlighting for todos with past due dates
5. Wire checkbox taps to `NotesProvider` toggle methods
6. Add "Add Task" button to Todos section (inline creation)
7. Add "Add Action" button to Actions section (inline creation)
8. Add edit and delete actions to todo/action item overflow menus
9. Add due date picker for manual todo creation

### Sub-step B: Checkboxes in Project Document Blocks

1. Add collapsible "Tasks" sub-section to note_reference block widget
2. Render todos and actions from the linked note with interactive checkboxes
3. Show task count indicator in collapsed state
4. Wire checkbox taps to `NotesProvider` (same as Note Detail — bi-directional)
5. Auto-expand when tasks exist, collapse when none

### Sub-step C: Aggregated Tasks View

1. Create `TaskItem` view model class
2. Create `tasksProvider` — derived Riverpod provider that aggregates from all notes
3. Add Tasks tab to Home page (segmented control or tab bar)
4. Implement task list UI with checkbox, text, source note link, due date
5. Implement filter chips (All / Todos / Actions)
6. Include reminders in the aggregated view with 🔔 indicator
7. Implement "Show completed" toggle
8. Implement sorting (overdue first → due date → creation date)
9. Implement open task count badge
10. Implement empty states
11. Wire source note tap to navigate to Note Detail
12. Wire checkbox taps to `NotesProvider`

### Sub-step D: Reminder Enhancement

1. Add `add_2_calendar` package
2. Create reminder destination bottom sheet (Keep in-app / Also add to OS)
3. Implement OS calendar event creation with pre-filled data
4. Add "Reschedule" action to reminder items on Note Detail
5. Implement reschedule date/time picker with notification update
6. (Stretch) Add notification action buttons for "Done" and "Snooze 1hr"

### Sub-step E: Polish & Integration

1. Ensure checkbox state syncs across all surfaces (Note Detail ↔ Project Document ↔ Tasks View)
2. Test with notes that have many tasks (20+ items)
3. Verify reminder notification deep-links still work
4. Update "Delete All Data" to handle any new state
5. Accessibility: checkbox labels, screen reader support for task counts
6. Empty states for Tasks tab

---

## 8. Impact on Existing Code

### Files to Modify

| File / Area | Change |
|---|---|
| **Note Detail page** | Add interactive checkboxes, add task/action creation, add reschedule, add "Also add to OS" flow |
| **Home page** | Add Tasks tab/segmented control |
| **note_reference_block widget** | Add collapsible Tasks sub-section with checkboxes |
| **NotesRepository** | Add toggle, CRUD, and reschedule methods for todos/actions/reminders |
| **NotesProvider** | Expose new repository methods |
| **NotificationService** | Add reschedule method, (stretch) notification action buttons |

### New Files to Create

| File | Purpose |
|---|---|
| `lib/models/task_item.dart` | TaskItem view model for aggregated tasks |
| `lib/providers/tasks_provider.dart` | Derived provider aggregating todos + actions + reminders across all notes |
| `lib/widgets/task_list_item.dart` | Reusable task row widget (checkbox + text + source + date) |
| `lib/widgets/tasks_tab.dart` | Tasks tab content for Home page |
| `lib/widgets/interactive_todo_item.dart` | Todo item with checkbox, strikethrough, overflow menu |
| `lib/widgets/interactive_action_item.dart` | Action item with checkbox, strikethrough, overflow menu |
| `lib/widgets/reminder_destination_sheet.dart` | Bottom sheet for "Keep in-app / Also add to OS" choice |
| `lib/widgets/task_creation_inline.dart` | Inline text field for adding new tasks |
| `lib/services/os_reminder_service.dart` | Bridge to OS calendar/reminders via add_2_calendar |

---

## 9. Edge Cases & Error Handling

| Scenario | Behavior |
|---|---|
| **Note deleted that has tasks in Aggregated View** | Tasks from that note disappear from the aggregated view automatically (derived provider recomputes) |
| **Very many tasks across notes (100+)** | Lazy loading in the task list. Consider pagination or "Load more" after 50 items |
| **Overdue reminder with no notification** | If the app wasn't open when the reminder was due, show it as overdue in the Tasks view with red highlight |
| **OS calendar app not available** | Catch the intent failure, show a SnackBar: "No calendar app found. Reminder saved in VoiceNotes AI." |
| **User cancels OS calendar creation** | No problem — the in-app reminder was already created. The OS push is additive. |
| **Same task checked in two places simultaneously** | Not possible on single device. Changes are sequential — Hive write + provider refresh ensures consistency. |
| **Checkbox state out of sync** | Use `ref.watch()` to ensure all surfaces reactively update from the same Hive source of truth |
| **Adding a task to a note that's in a Project Document** | Task appears in the Project Document's note_reference block automatically (reads from Note) |
| **Reschedule to a past time** | Validate in the date/time picker — don't allow past times. Show error if attempted. |

---

## 10. New Package Dependencies

| Package | Purpose | Phase |
|---|---|---|
| `add_2_calendar` | Cross-platform OS calendar event creation | Phase 1 |

All other dependencies (flutter_local_notifications, hive, riverpod, etc.) are already in the project.

---

## 11. Phase 2 Enhancements (Out of Scope)

These are explicitly not part of this spec but are informed by the design:

| Feature | Phase | Notes |
|---|---|---|
| AI auto-extraction of todos/actions from transcription | Phase 2 | Populates the same `TodoItem`/`ActionItem` models automatically |
| Smart due date extraction ("by Friday") | Phase 2 | AI parses date references and sets `dueDate` |
| Recurring reminders | Phase 2 | Requires recurrence rules, more complex scheduling |
| Push to Todoist / Apple Reminders API / Google Tasks API | Phase 2 | Requires auth, deeper integration |
| Notification action buttons (Done / Snooze) | Phase 2 if too complex for Phase 1 | Platform-specific implementation |
| Task priority levels | Phase 2 | Low / Medium / High priority with sort options |
| Task assignment (multi-user) | Phase 3 | Requires accounts, speaker diarization |

---

## 12. Success Metrics

| Metric | Target |
|---|---|
| Tasks checked off per user per week | > 5 (indicates active use) |
| Aggregated Tasks View visits per session | > 0.3 (users check it regularly) |
| OS reminder push rate | > 20% of reminders (users find value in the bridge) |
| Manual task creation rate | > 2 per user per week (users add tasks directly, not just from voice) |

---

*End of Feature Specification*
