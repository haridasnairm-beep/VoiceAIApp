import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/notes_provider.dart';
import '../models/note.dart';

/// Calendar page — monthly grid with recording dots + day detail list.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final scheme = Theme.of(context).colorScheme;

    // Build a map of day → notes for the focused month
    final dayNotes = <int, List<Note>>{};
    for (final note in notes) {
      if (note.createdAt.year == _focusedMonth.year &&
          note.createdAt.month == _focusedMonth.month) {
        dayNotes.putIfAbsent(note.createdAt.day, () => []).add(note);
      }
    }

    // Notes for selected day
    final selectedDayNotes = _selectedDay != null
        ? (notes
            .where((n) =>
                n.createdAt.year == _selectedDay!.year &&
                n.createdAt.month == _selectedDay!.month &&
                n.createdAt.day == _selectedDay!.day)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        : <Note>[];

    // Upcoming reminders (next 7 days)
    final now = DateTime.now();
    final upcoming = <_UpcomingReminder>[];
    for (final note in notes) {
      for (final r in note.reminders) {
        if (!r.isCompleted &&
            r.reminderTime != null &&
            r.reminderTime!.isAfter(now) &&
            r.reminderTime!.isBefore(now.add(const Duration(days: 7)))) {
          upcoming.add(_UpcomingReminder(
            text: r.text,
            time: r.reminderTime!,
            noteTitle: note.title,
            noteId: note.id,
          ));
        }
      }
    }
    upcoming.sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: Column(
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                    _selectedDay = null;
                  }),
                ),
                Text(
                  _monthLabel(_focusedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                    _selectedDay = null;
                  }),
                ),
              ],
            ),
          ),

          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: scheme.secondary)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildCalendarGrid(context, dayNotes, scheme),
          ),

          const Divider(height: 24, indent: 16, endIndent: 16),

          // Day detail or upcoming reminders
          Expanded(
            child: selectedDayNotes.isNotEmpty
                ? _buildDayNotes(context, selectedDayNotes)
                : upcoming.isNotEmpty
                    ? _buildUpcoming(context, upcoming)
                    : Center(
                        child: Text(
                          _selectedDay != null
                              ? 'No notes on this day'
                              : 'Select a day to view notes',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.secondary),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context,
      Map<int, List<Note>> dayNotes, ColorScheme scheme) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // Monday=1, so offset = (weekday - 1)
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    final cells = <Widget>[];
    // Empty cells before first day
    for (var i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }
    // Day cells
    for (var day = 1; day <= daysInMonth; day++) {
      final notesOnDay = dayNotes[day];
      final hasNotes = notesOnDay != null && notesOnDay.isNotEmpty;
      final isToday = today.year == _focusedMonth.year &&
          today.month == _focusedMonth.month &&
          today.day == day;
      final isSelected = _selectedDay?.day == day &&
          _selectedDay?.month == _focusedMonth.month &&
          _selectedDay?.year == _focusedMonth.year;

      // Dot color: red if any overdue, orange if open tasks, blue otherwise
      Color? dotColor;
      if (hasNotes) {
        final hasOverdue = notesOnDay.any((n) =>
            n.todos.any((t) =>
                !t.isCompleted &&
                t.dueDate != null &&
                t.dueDate!.isBefore(today)) ||
            n.reminders.any((r) =>
                !r.isCompleted &&
                r.reminderTime != null &&
                r.reminderTime!.isBefore(today)));
        final hasOpenTasks = notesOnDay.any((n) =>
            n.todos.any((t) => !t.isCompleted) ||
            n.actions.any((a) => !a.isCompleted));
        dotColor = hasOverdue
            ? Colors.red
            : hasOpenTasks
                ? Colors.orange
                : scheme.primary;
      }

      cells.add(GestureDetector(
        onTap: () => setState(() {
          _selectedDay =
              DateTime(_focusedMonth.year, _focusedMonth.month, day);
        }),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer
                : isToday
                    ? scheme.surfaceContainerHighest
                    : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight:
                          isToday || isSelected ? FontWeight.bold : null,
                      color: isSelected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
              ),
              if (hasNotes)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: cells,
    );
  }

  Widget _buildDayNotes(BuildContext context, List<Note> notes) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = notes[index];
        String preview = note.rawTranscription;
        if (note.contentFormat == 'quill_delta' && preview.isNotEmpty) {
          try {
            preview = Document.fromJson(jsonDecode(preview) as List)
                .toPlainText()
                .trim();
          } catch (_) {}
        }
        if (preview.length > 80) preview = '${preview.substring(0, 80)}...';

        return ListTile(
          leading: Icon(
            note.audioFilePath.isEmpty
                ? Icons.edit_note_rounded
                : Icons.mic_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(note.title,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.secondary)),
          trailing: Text(
            '${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          onTap: () => context.push(AppRoutes.noteDetail,
              extra: {'noteId': note.id}),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          tileColor: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }

  Widget _buildUpcoming(
      BuildContext context, List<_UpcomingReminder> reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Upcoming Reminders',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final r = reminders[index];
              return ListTile(
                leading: const Icon(Icons.alarm_rounded,
                    color: Colors.orange, size: 20),
                title: Text(r.text,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(r.noteTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary)),
                trailing: Text(
                  _formatReminderTime(r.time),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
                onTap: () => context.push(AppRoutes.noteDetail,
                    extra: {'noteId': r.noteId}),
              );
            },
          ),
        ),
      ],
    );
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _formatReminderTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (date == today) return 'Today $time';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow $time';
    return '${dt.day}/${dt.month} $time';
  }
}

class _UpcomingReminder {
  final String text;
  final DateTime time;
  final String noteTitle;
  final String noteId;

  _UpcomingReminder({
    required this.text,
    required this.time,
    required this.noteTitle,
    required this.noteId,
  });
}
