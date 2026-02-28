import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../theme.dart';

/// Reusable task row widget for the aggregated Tasks view.
class TaskListItem extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onTapSource;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTapSource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              task.isCompleted
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: task.isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task text
                Text(
                  task.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: task.isCompleted
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
                const SizedBox(height: 4),
                // Source note + type
                GestureDetector(
                  onTap: onTapSource,
                  child: Row(
                    children: [
                      Icon(
                        _typeIcon,
                        size: 13,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.sourceNoteTitle,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    decoration: TextDecoration.underline,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Due date / reminder time
                if (_dateText != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        task.type == TaskType.reminder
                            ? Icons.alarm_rounded
                            : Icons.event_rounded,
                        size: 13,
                        color: task.isOverdue
                            ? Colors.red
                            : Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dateText!,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: task.isOverdue
                                      ? Colors.red
                                      : Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                  fontWeight:
                                      task.isOverdue ? FontWeight.bold : null,
                                ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _typeIcon {
    switch (task.type) {
      case TaskType.todo:
        return Icons.task_alt_rounded;
      case TaskType.action:
        return Icons.checklist_rounded;
      case TaskType.reminder:
        return Icons.alarm_rounded;
    }
  }

  String? get _dateText {
    final date = task.dueDate ?? task.reminderTime;
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'Today';
    } else if (dateOnly == tomorrow) {
      label = 'Tomorrow';
    } else {
      label = '${date.month}/${date.day}/${date.year}';
    }

    if (task.type == TaskType.reminder) {
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final min = date.minute.toString().padLeft(2, '0');
      return '$label, $hour:$min $amPm';
    }
    return label;
  }
}
