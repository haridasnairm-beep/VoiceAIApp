/// Task type enum for the aggregated tasks view.
enum TaskType { todo, action, reminder }

/// View model for the aggregated tasks view.
/// NOT a Hive model — derived from NotesProvider at runtime.
class TaskItem {
  final TaskType type;
  final String id;
  final String text;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? reminderTime;
  final DateTime createdAt;
  final String sourceNoteId;
  final String sourceNoteTitle;
  final DateTime sourceNoteDate;

  const TaskItem({
    required this.type,
    required this.id,
    required this.text,
    required this.isCompleted,
    this.dueDate,
    this.reminderTime,
    required this.createdAt,
    required this.sourceNoteId,
    required this.sourceNoteTitle,
    required this.sourceNoteDate,
  });

  /// The effective date used for sorting (due date, reminder time, or creation date).
  DateTime get effectiveDate => dueDate ?? reminderTime ?? createdAt;

  /// Whether this task is overdue.
  bool get isOverdue {
    if (isCompleted) return false;
    final date = dueDate ?? reminderTime;
    return date != null && date.isBefore(DateTime.now());
  }
}
