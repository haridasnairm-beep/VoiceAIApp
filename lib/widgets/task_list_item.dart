import 'dart:async';

import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../services/haptic_service.dart';
import '../theme.dart';

/// Reusable task row widget for the aggregated Tasks view.
///
/// Plays a scale-bounce animation and a brief green highlight when a task
/// transitions from incomplete → complete. Haptic feedback fires on every tap.
class TaskListItem extends StatefulWidget {
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
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  Color? _highlightColor;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(TaskListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Completion transition: false → true
    if (!oldWidget.task.isCompleted && widget.task.isCompleted) {
      _bounceController.forward(from: 0);
      _highlightTimer?.cancel();
      setState(() => _highlightColor = Colors.green.withValues(alpha: 0.1));
      _highlightTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _highlightColor = null);
      });
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _highlightColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            GestureDetector(
              onTap: () {
                HapticService.selection();
                widget.onToggle();
              },
              child: Icon(
                widget.task.isCompleted
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: widget.task.isCompleted
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
                    widget.task.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.task.isCompleted
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: widget.task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Source note + type
                  GestureDetector(
                    onTap: widget.onTapSource,
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
                            widget.task.sourceNoteTitle,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
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
                          widget.task.type == TaskType.reminder
                              ? Icons.alarm_rounded
                              : Icons.event_rounded,
                          size: 13,
                          color: widget.task.isOverdue
                              ? Colors.red
                              : Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _dateText!,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: widget.task.isOverdue
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.secondary,
                                fontWeight: widget.task.isOverdue
                                    ? FontWeight.bold
                                    : null,
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
      ),
    );
  }

  IconData get _typeIcon {
    switch (widget.task.type) {
      case TaskType.todo:
        return Icons.task_alt_rounded;
      case TaskType.action:
        return Icons.checklist_rounded;
      case TaskType.reminder:
        return Icons.alarm_rounded;
    }
  }

  String? get _dateText {
    final date = widget.task.dueDate ?? widget.task.reminderTime;
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

    if (widget.task.type == TaskType.reminder) {
      final hour = date.hour > 12
          ? date.hour - 12
          : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final min = date.minute.toString().padLeft(2, '0');
      return '$label, $hour:$min $amPm';
    }
    return label;
  }
}
