import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import 'notes_provider.dart';

/// Derived provider that aggregates all todos, actions, and reminders
/// from all notes into a flat, sorted list of TaskItem view models.
final tasksProvider = Provider<List<TaskItem>>((ref) {
  final notes = ref.watch(notesProvider);

  final List<TaskItem> allTasks = [];

  for (final note in notes) {
    for (final todo in note.todos) {
      allTasks.add(TaskItem(
        type: TaskType.todo,
        id: todo.id,
        text: todo.text,
        isCompleted: todo.isCompleted,
        dueDate: todo.dueDate,
        createdAt: todo.createdAt,
        sourceNoteId: note.id,
        sourceNoteTitle: note.title,
        sourceNoteDate: note.createdAt,
      ));
    }

    for (final action in note.actions) {
      allTasks.add(TaskItem(
        type: TaskType.action,
        id: action.id,
        text: action.text,
        isCompleted: action.isCompleted,
        createdAt: action.createdAt,
        sourceNoteId: note.id,
        sourceNoteTitle: note.title,
        sourceNoteDate: note.createdAt,
      ));
    }

    for (final reminder in note.reminders) {
      allTasks.add(TaskItem(
        type: TaskType.reminder,
        id: reminder.id,
        text: reminder.text,
        isCompleted: reminder.isCompleted,
        reminderTime: reminder.reminderTime,
        createdAt: reminder.createdAt,
        sourceNoteId: note.id,
        sourceNoteTitle: note.title,
        sourceNoteDate: note.createdAt,
      ));
    }
  }

  // Sort: overdue first, then by effective date (soonest first),
  // then by creation date (newest first)
  allTasks.sort((a, b) {
    // Overdue items first
    if (a.isOverdue && !b.isOverdue) return -1;
    if (!a.isOverdue && b.isOverdue) return 1;

    // Then by effective date (soonest first)
    final aDate = a.dueDate ?? a.reminderTime;
    final bDate = b.dueDate ?? b.reminderTime;
    if (aDate != null && bDate != null) {
      final cmp = aDate.compareTo(bDate);
      if (cmp != 0) return cmp;
    }
    if (aDate != null && bDate == null) return -1;
    if (aDate == null && bDate != null) return 1;

    // Then by creation date (newest first)
    return b.createdAt.compareTo(a.createdAt);
  });

  return allTasks;
});
