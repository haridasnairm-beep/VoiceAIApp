import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/task_item.dart';
import '../nav.dart';
import '../providers/notes_provider.dart';
import '../providers/tasks_provider.dart';
import 'task_list_item.dart';

/// Tasks tab content widget for the Home page.
class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  TaskType? _filterType; // null = All
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(tasksProvider);

    // Apply type filter
    final filteredTasks = _filterType == null
        ? allTasks
        : allTasks.where((t) => t.type == _filterType).toList();

    // Split into open and completed
    final openTasks = filteredTasks.where((t) => !t.isCompleted).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();

    final openCount =
        allTasks.where((t) => !t.isCompleted).length; // unfiltered count

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Open task count
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
          child: Row(
            children: [
              Text(
                '$openCount',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                openCount == 1 ? 'open task' : 'open tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(context, 'All', null),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Todos', TaskType.todo),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Actions', TaskType.action),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Reminders', TaskType.reminder),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Task list
        if (openTasks.isEmpty && completedTasks.isEmpty)
          _buildEmptyState(context)
        else ...[
          if (openTasks.isEmpty && !_showCompleted)
            _buildAllDoneState(context)
          else
            ...openTasks.map((task) => TaskListItem(
                  task: task,
                  onToggle: () => _toggleTask(task),
                  onTapSource: () => _navigateToNote(task.sourceNoteId),
                )),

          // Show completed toggle
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showCompleted = !_showCompleted),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _showCompleted
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showCompleted
                          ? 'Hide completed (${completedTasks.length})'
                          : 'Show completed (${completedTasks.length})',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showCompleted)
              ...completedTasks.map((task) => TaskListItem(
                    task: task,
                    onToggle: () => _toggleTask(task),
                    onTapSource: () => _navigateToNote(task.sourceNoteId),
                  )),
          ],
        ],
      ],
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, TaskType? type) {
    final selected = _filterType == type;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterType = type),
      selectedColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.task_alt_rounded,
                size: 48, color: Theme.of(context).hintColor),
            const SizedBox(height: 12),
            Text(
              _filterType != null
                  ? 'No ${_filterType == TaskType.todo ? 'todos' : _filterType == TaskType.action ? 'actions' : 'reminders'} found'
                  : 'No tasks yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tasks from your notes will appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDoneState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.celebration_rounded,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              "You're all caught up!",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTask(TaskItem task) {
    final notifier = ref.read(notesProvider.notifier);
    switch (task.type) {
      case TaskType.todo:
        notifier.toggleTodoCompleted(
            noteId: task.sourceNoteId, todoId: task.id);
        break;
      case TaskType.action:
        notifier.toggleActionCompleted(
            noteId: task.sourceNoteId, actionId: task.id);
        break;
      case TaskType.reminder:
        notifier.toggleReminderCompleted(
            noteId: task.sourceNoteId, reminderId: task.id);
        break;
    }
  }

  void _navigateToNote(String noteId) {
    context.push(AppRoutes.noteDetail, extra: {'noteId': noteId});
  }
}
