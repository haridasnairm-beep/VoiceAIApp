import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../providers/settings_provider.dart';
import '../models/note.dart';
import '../models/project_block.dart';
import '../constants/note_templates.dart';
import '../widgets/note_card.dart';
import '../widgets/gesture_fab.dart';
import '../widgets/speed_dial_fab.dart';
import '../utils/responsive.dart';
import '../widgets/template_picker_sheet.dart';

enum _CalendarFilter { all, tasks, projects }

/// Calendar page — full month grid that collapses to week strip on scroll.
/// Multi-dot vertical indicators + NoteCard tiles matching home page.
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDay;
  late DateTime _focusedMonth;
  bool _collapsed = false;
  _CalendarFilter _activeFilter = _CalendarFilter.all;
  String _sortOrder = 'newest';
  late AnimationController _collapseController;
  late Animation<double> _collapseAnim;

  // Multi-select
  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = {};
  bool _isDialOpen = false;
  final GlobalKey<GestureFabState> _gestureFabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month);
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _collapseAnim = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  void _setCollapsed(bool collapsed) {
    if (_collapsed == collapsed) return;
    _collapsed = collapsed;
    if (collapsed) {
      _collapseController.forward();
    } else {
      _collapseController.reverse();
    }
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _focusedMonth = DateTime(day.year, day.month);
    });
  }

  void _goToDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDay = d;
      _focusedMonth = DateTime(d.year, d.month);
    });
    // Expand calendar when jumping to today
    _setCollapsed(false);
  }

  // --- Multi-select helpers ---
  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        if (_selectedNoteIds.isEmpty) _selectionMode = false;
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _enterSelectionMode(String noteId) {
    setState(() {
      _selectionMode = true;
      _selectedNoteIds.add(noteId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  Future<void> _showMonthYearPicker(BuildContext context) async {
    final now = DateTime.now();
    final firstYear = now.year - 3;
    final lastYear = now.year + 3;
    var pickedYear = _focusedMonth.year;
    var pickedMonth = _focusedMonth.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select Month & Year'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Year row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: pickedYear > firstYear
                          ? () => setDialogState(() => pickedYear--)
                          : null,
                    ),
                    Text(
                      '$pickedYear',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: pickedYear < lastYear
                          ? () => setDialogState(() => pickedYear++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Month grid
                GridView.count(
                  crossAxisCount: Responsive.monthPickerColumns(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final isCurrent =
                        m == now.month && pickedYear == now.year;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => pickedMonth = m),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: m == pickedMonth
                              ? Theme.of(ctx).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: isCurrent
                              ? Border.all(
                                  color: Theme.of(ctx).colorScheme.primary,
                                  width: 1.5)
                              : null,
                        ),
                        child: Text(
                          _shortMonthName(m),
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                fontWeight: m == pickedMonth
                                    ? FontWeight.bold
                                    : null,
                                color: m == pickedMonth
                                    ? Theme.of(ctx)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : null,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                  ctx, DateTime(pickedYear, pickedMonth)),
              child: const Text('Go'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      // Select the 1st of that month (or today if same month)
      final now2 = DateTime.now();
      final targetDay = result.year == now2.year && result.month == now2.month
          ? DateTime(now2.year, now2.month, now2.day)
          : DateTime(result.year, result.month, 1);
      _goToDate(targetDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotes =
        ref.watch(notesProvider).where((n) => !n.isDeleted).toList();
    final folders = ref.watch(foldersProvider);
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Build date → notes map
    final dateNotesMap = <DateTime, List<Note>>{};
    for (final note in allNotes) {
      final d = DateTime(
          note.createdAt.year, note.createdAt.month, note.createdAt.day);
      dateNotesMap.putIfAbsent(d, () => []).add(note);
    }

    // Notes for selected day
    final selectedDayNotes = (dateNotesMap[_selectedDay] ?? <Note>[]);

    // Compute counts for filter chips
    final noteCount = selectedDayNotes.length;
    final taskCount = selectedDayNotes
        .where((n) => n.todos.isNotEmpty || n.actions.isNotEmpty)
        .length;
    final projectCount = selectedDayNotes
        .where((n) => n.projectDocumentIds.isNotEmpty)
        .length;

    // Apply filter — "All" = everything, "Notes" = all notes,
    // "Tasks" = notes with tasks, "Projects" = notes linked to projects
    List<Note> filteredNotes;
    switch (_activeFilter) {
      case _CalendarFilter.tasks:
        filteredNotes = selectedDayNotes
            .where((n) => n.todos.isNotEmpty || n.actions.isNotEmpty)
            .toList();
      case _CalendarFilter.projects:
        filteredNotes = selectedDayNotes
            .where((n) => n.projectDocumentIds.isNotEmpty)
            .toList();
      default: // all + notes both show all notes for the day
        filteredNotes = selectedDayNotes.toList();
    }

    // Apply sort
    switch (_sortOrder) {
      case 'oldest':
        filteredNotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'titleAZ':
        filteredNotes.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case 'titleZA':
        filteredNotes.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      default:
        filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return PopScope(
      canPop: !_selectionMode && !_isDialOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isDialOpen) {
          _gestureFabKey.currentState?.closeDial();
          return;
        }
        if (_selectionMode) _exitSelectionMode();
      },
      child: Scaffold(
        appBar: _selectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _exitSelectionMode,
                ),
                title: Text(
                  '${_selectedNoteIds.length} selected',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedNoteIds.length == filteredNotes.length) {
                          _selectedNoteIds.clear();
                          _selectionMode = false;
                        } else {
                          _selectedNoteIds
                              .addAll(filteredNotes.map((n) => n.id));
                        }
                      });
                    },
                    child: Text(
                      _selectedNoteIds.length == filteredNotes.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              )
            : AppBar(
                title: const Text('Calendar'),
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.home),
                ),
                actions: [
                  TextButton(
                    onPressed: () => _goToDate(todayDate),
                    child: const Text('Today'),
                  ),
                ],
              ),
        body: Stack(
          children: [
            // Main content column
            ResponsiveCenter(
            child: Column(
              children: [
                // Month/Year header (tappable for picker)
                if (!_selectionMode) _buildMonthHeader(context),

                // Calendar: full month or collapsed week strip
                if (!_selectionMode)
                  AnimatedBuilder(
                    animation: _collapseAnim,
                    builder: (context, child) {
                      return _collapseAnim.value < 0.5
                          ? _buildFullMonthGrid(
                              context, todayDate, dateNotesMap, scheme)
                          : _buildCollapsedWeekStrip(
                              context, todayDate, dateNotesMap, scheme);
                    },
                  ),

                // Dot legend
                if (!_selectionMode) _buildDotLegend(context, scheme),

                // Always-visible collapse/expand grab handle
                if (!_selectionMode) _buildGrabHandle(context, scheme),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // Day header + filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        _formatDayHeader(_selectedDay, todayDate),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (!_selectionMode) _buildSortButton(context, scheme),
                    ],
                  ),
                ),

                // Filter chips row
                if (noteCount > 0 && !_selectionMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(context, scheme, 'All Notes', noteCount,
                              _CalendarFilter.all),
                          if (taskCount > 0) ...[
                            const SizedBox(width: 6),
                            _filterChip(context, scheme, 'With Tasks',
                                taskCount, _CalendarFilter.tasks),
                          ],
                          if (projectCount > 0) ...[
                            const SizedBox(width: 6),
                            _filterChip(context, scheme, 'With Projects',
                                projectCount, _CalendarFilter.projects),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Note cards list
                Expanded(
                  child: filteredNotes.isNotEmpty
                      ? NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification) {
                              final delta = notification.scrollDelta ?? 0;
                              if (delta > 3 && !_collapsed) {
                                _setCollapsed(true);
                              }
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              return _buildNoteItem(context, ref,
                                  filteredNotes[index], folders);
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_note_rounded,
                                  size: 48,
                                  color: scheme.secondary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                noteCount == 0
                                    ? 'No notes on this day'
                                    : 'No matching notes',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: scheme.secondary),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            ),

            // Selection action bar (overlays bottom of screen)
            if (_selectionMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: _selectedNoteIds.length == 1
                        ? Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionBarBtn(
                                icon: Icons.open_in_new_rounded,
                                label: 'Open',
                                onTap: () {
                                  final noteId =
                                      _selectedNoteIds.first;
                                  _exitSelectionMode();
                                  context.push(AppRoutes.noteDetail,
                                      extra: {'noteId': noteId});
                                },
                              ),
                              _ActionBarBtn(
                                icon: Icons.edit_rounded,
                                label: 'Edit Title',
                                onTap: () {
                                  final noteId =
                                      _selectedNoteIds.first;
                                  final note =
                                      filteredNotes.firstWhere(
                                          (n) => n.id == noteId);
                                  _exitSelectionMode();
                                  _showEditTitleDialog(
                                      context, ref, note);
                                },
                              ),
                              Builder(builder: (_) {
                                final noteId =
                                    _selectedNoteIds.first;
                                final note =
                                    filteredNotes.firstWhere(
                                        (n) => n.id == noteId,
                                        orElse: () =>
                                            filteredNotes.first);
                                return _ActionBarBtn(
                                  icon: note.isPinned
                                      ? Icons.push_pin_outlined
                                      : Icons.push_pin_rounded,
                                  label: note.isPinned
                                      ? 'Unpin'
                                      : 'Pin',
                                  onTap: () async {
                                    final ok = await ref
                                        .read(
                                            notesProvider.notifier)
                                        .togglePin(noteId);
                                    if (!ok && mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                              const SnackBar(
                                        content: Text(
                                            'Max 10 pinned notes. Unpin one first.'),
                                      ));
                                    }
                                    _exitSelectionMode();
                                  },
                                );
                              }),
                              _ActionBarBtn(
                                icon: Icons.folder_rounded,
                                label: 'Folder',
                                onTap: () => _showBulkFolderPicker(
                                    context, ref),
                              ),
                              _ActionBarBtn(
                                icon: Icons.article_rounded,
                                label: 'Project',
                                onTap: () =>
                                    _showBulkProjectPicker(
                                        context, ref),
                              ),
                              _ActionBarBtn(
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                                color: Colors.red,
                                onTap: () => _confirmBulkDelete(
                                    context, ref),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionBarBtn(
                                icon: Icons.folder_rounded,
                                label: 'Folder',
                                onTap: () => _showBulkFolderPicker(
                                    context, ref),
                              ),
                              _ActionBarBtn(
                                icon: Icons.article_rounded,
                                label: 'Project',
                                onTap: () =>
                                    _showBulkProjectPicker(
                                        context, ref),
                              ),
                              _ActionBarBtn(
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                                color: Colors.red,
                                onTap: () => _confirmBulkDelete(
                                    context, ref),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

            // Gesture FAB (hide during selection)
            if (!_selectionMode)
              Positioned(
                right: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
                child: GestureFab(
                  key: _gestureFabKey,
                  sessionCount:
                      ref.watch(settingsProvider).sessionCount,
                  showSubtitleHint: ref
                          .watch(settingsProvider)
                          .sessionCount <=
                      10,
                  onRecord: () =>
                      context.push(AppRoutes.recording),
                  onDialToggled: (open) =>
                      setState(() => _isDialOpen = open),
                  speedDialItems: [
                    SpeedDialItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () =>
                          context.push(AppRoutes.search),
                    ),
                    SpeedDialItem(
                      icon: Icons.article_outlined,
                      label: 'New Project',
                      onTap: () async {
                        final controller = TextEditingController();
                        final name = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('New Project'),
                            content: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText: 'Project name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(controller.text),
                                child: const Text('Create'),
                              ),
                            ],
                          ),
                        );
                        if (name != null && name.trim().isNotEmpty && mounted) {
                          final folders = ref.read(foldersProvider);
                          final general = folders.where((f) => f.name == 'General').toList();
                          final folderId = general.isNotEmpty ? general.first.id : null;
                          final doc = await ref
                              .read(projectDocumentsProvider.notifier)
                              .create(title: name.trim(), folderId: folderId);
                          if (mounted) {
                            context.push(
                              AppRoutes.projectDocumentDetail,
                              extra: {'documentId': doc.id},
                            );
                          }
                        }
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.edit_note_rounded,
                      label: 'Text Note',
                      onTap: () async {
                        final template =
                            await showModalBottomSheet<dynamic>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) =>
                              const TemplatePickerSheet(),
                        );
                        if (!mounted) return;
                        if (template == null) return;
                        final extras = <String, dynamic>{
                          'isNewTextNote': true,
                        };
                        if (template is NoteTemplate) {
                          extras['templateContent'] =
                              template.content;
                          extras['templateTitle'] =
                              template.name;
                        }
                        context.push(AppRoutes.noteDetail,
                            extra: extras);
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.mic_rounded,
                      label: 'Record Note',
                      onTap: () =>
                          context.push(AppRoutes.recording),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 20,
            onPressed: () {
              final prev = DateTime(
                  _focusedMonth.year, _focusedMonth.month - 1);
              final daysInMonth =
                  DateTime(prev.year, prev.month + 1, 0).day;
              final day = _selectedDay.day.clamp(1, daysInMonth);
              _selectDay(DateTime(prev.year, prev.month, day));
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showMonthYearPicker(context),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _monthYearLabel(_focusedMonth),
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 20,
            onPressed: () {
              final next = DateTime(
                  _focusedMonth.year, _focusedMonth.month + 1);
              final daysInMonth =
                  DateTime(next.year, next.month + 1, 0).day;
              final day = _selectedDay.day.clamp(1, daysInMonth);
              _selectDay(DateTime(next.year, next.month, day));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullMonthGrid(
    BuildContext context,
    DateTime todayDate,
    Map<DateTime, List<Note>> dateNotesMap,
    ColorScheme scheme,
  ) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday - 1; // Mon=0..Sun=6
    const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: dayLabels
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
          const SizedBox(height: 4),
          // Month grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: Responsive.isWide(context) ? 1.1 : 0.75,
            children: [
              // Empty cells before first day
              for (var i = 0; i < startOffset; i++) const SizedBox(),
              // Day cells
              for (var day = 1; day <= daysInMonth; day++)
                _buildDayCell(
                  context,
                  DateTime(_focusedMonth.year, _focusedMonth.month, day),
                  todayDate,
                  dateNotesMap,
                  scheme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedWeekStrip(
    BuildContext context,
    DateTime todayDate,
    Map<DateTime, List<Note>> dateNotesMap,
    ColorScheme scheme,
  ) {
    // Find the Monday of the selected day's week
    final weekday = _selectedDay.weekday; // 1=Mon..7=Sun
    final monday = _selectedDay.subtract(Duration(days: weekday - 1));
    const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: dayLabels
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
          const SizedBox(height: 4),
          SizedBox(
            height: 60,
            child: Row(
              children: List.generate(7, (i) {
                final day = monday.add(Duration(days: i));
                return Expanded(
                  child: _buildDayCell(
                      context, day, todayDate, dateNotesMap, scheme),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime todayDate,
    Map<DateTime, List<Note>> dateNotesMap,
    ColorScheme scheme,
  ) {
    final isSelected = day == _selectedDay;
    final isToday = day == todayDate;
    final isCurrentMonth = day.month == _focusedMonth.month;
    final notesOnDay = dateNotesMap[day];
    final dots = _computeDots(notesOnDay, scheme);

    return GestureDetector(
      onTap: () => _selectDay(day),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer
              : isToday
                  ? scheme.surfaceContainerHighest
                  : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: isToday && !isSelected
              ? Border.all(color: scheme.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight:
                        isSelected || isToday ? FontWeight.bold : null,
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : !isCurrentMonth
                            ? scheme.secondary.withValues(alpha: 0.4)
                            : scheme.onSurface,
                  ),
            ),
            if (dots.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: dots
                    .map((color) => Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDotLegend(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(context, Colors.teal, 'Notes'),
          const SizedBox(width: 12),
          _legendItem(context, Colors.orange, 'Tasks'),
          const SizedBox(width: 12),
          _legendItem(context, Colors.purple, 'Projects'),
        ],
      ),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.secondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildGrabHandle(BuildContext context, ColorScheme scheme) {
    return GestureDetector(
      onTap: () => _setCollapsed(!_collapsed),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedBuilder(
              animation: _collapseAnim,
              builder: (context, _) => Icon(
                _collapseAnim.value > 0.5
                    ? Icons.expand_more_rounded
                    : Icons.expand_less_rounded,
                size: 20,
                color: scheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compute colored dots for a day (horizontal, max 3):
  /// - Blue: notes  - Orange: tasks/todos  - Purple: linked to projects
  List<Color> _computeDots(List<Note>? notes, ColorScheme scheme) {
    if (notes == null || notes.isEmpty) return [];
    final dots = <Color>[];
    dots.add(Colors.teal); // Notes dot (always present if notes exist)
    if (notes.any((n) => n.todos.isNotEmpty || n.actions.isNotEmpty)) {
      dots.add(Colors.orange);
    }
    if (notes.any((n) => n.projectDocumentIds.isNotEmpty)) {
      dots.add(Colors.purple);
    }
    return dots;
  }

  Widget _filterChip(BuildContext context, ColorScheme scheme, String label,
      int count, _CalendarFilter filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: scheme.primary, width: 1)
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isActive ? FontWeight.bold : null,
                color: isActive ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
        ),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, ColorScheme scheme) {
    const labels = {
      'newest': 'Newest',
      'oldest': 'Oldest',
      'titleAZ': 'A — Z',
      'titleZA': 'Z — A',
    };
    return PopupMenuButton<String>(
      onSelected: (v) => setState(() => _sortOrder = v),
      itemBuilder: (_) => labels.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    if (e.key == _sortOrder)
                      Icon(Icons.check_rounded,
                          size: 16, color: scheme.primary)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(e.value),
                  ],
                ),
              ))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sort_rounded, size: 18, color: scheme.secondary),
          const SizedBox(width: 4),
          Text(
            labels[_sortOrder] ?? 'Newest',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.secondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    WidgetRef ref,
    Note note,
    List<dynamic> folders,
  ) {
    final noteFolders = folders
        .where((f) => f.noteIds.contains(note.id))
        .toList();
    final noteFolderNames = noteFolders.map((f) => f.name as String).toList();
    final noteFolderColors = {
      for (final f in noteFolders) f.name as String: f.colorValue as int?,
    };

    final projects = ref.read(projectDocumentsProvider);
    final noteProjectNames = projects
        .where((p) => note.projectDocumentIds.contains(p.id))
        .map((p) => p.title)
        .toList();

    return NoteCard(
      note: note,
      timestamp: _formatTime(note.createdAt),
      folderNames: noteFolderNames,
      folderColors: noteFolderColors,
      projectNames: noteProjectNames,
      isSelected: _selectedNoteIds.contains(note.id),
      selectionMode: _selectionMode,
      onTap: _selectionMode
          ? () => _toggleSelection(note.id)
          : () => context.push(
                AppRoutes.noteDetail,
                extra: {'noteId': note.id},
              ),
      onDelete: () => _confirmAndDelete(context, ref, note),
      onLongPress: _selectionMode
          ? () => _toggleSelection(note.id)
          : () => _enterSelectionMode(note.id),
      onFolderTap: _selectionMode
          ? null
          : (_) => _showFolderChangePicker(context, ref, note),
      onProjectTap: _selectionMode
          ? null
          : (_) => _showProjectChangePicker(context, ref, note),
      onTagTap: _selectionMode
          ? null
          : (_) => _showTagManager(context, ref, note),
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext context, WidgetRef ref, Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text('Move "${note.title}" to trash?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Move to Trash')),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(notesProvider.notifier).deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${note.title}" moved to Trash'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                ref.read(notesProvider.notifier).restoreNote(note.id),
          ),
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  Future<void> _showFolderChangePicker(
      BuildContext context, WidgetRef ref, Note note) async {
    final folders =
        ref.read(foldersProvider).where((f) => !f.isDeleted).toList();
    final currentFolderIds = folders
        .where((f) => f.noteIds.contains(note.id))
        .map((f) => f.id)
        .toSet();
    final selected = Set<String>.from(currentFolderIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assign Folders',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...folders.map((f) => CheckboxListTile(
                    title: Text(f.name),
                    value: selected.contains(f.id),
                    onChanged: (v) => setSheetState(() => v == true
                        ? selected.add(f.id)
                        : selected.remove(f.id)),
                  )),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      for (final fid in currentFolderIds) {
                        if (!selected.contains(fid)) {
                          await ref
                              .read(foldersProvider.notifier)
                              .removeNoteFromFolder(fid, note.id);
                        }
                      }
                      for (final fid in selected) {
                        if (!currentFolderIds.contains(fid)) {
                          await ref
                              .read(foldersProvider.notifier)
                              .addNoteToFolder(fid, note.id);
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProjectChangePicker(
      BuildContext context, WidgetRef ref, Note note) async {
    final projects = ref.read(projectDocumentsProvider);
    final currentProjectIds = Set<String>.from(note.projectDocumentIds);
    final selected = Set<String>.from(currentProjectIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text('Change Project',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: () async {
                        for (final pid in currentProjectIds) {
                          if (!selected.contains(pid)) {
                            await ref
                                .read(projectDocumentsProvider.notifier)
                                .removeNoteFromProject(pid, note.id);
                          }
                        }
                        for (final pid in selected) {
                          if (!currentProjectIds.contains(pid)) {
                            await ref
                                .read(projectDocumentsProvider.notifier)
                                .addNoteBlock(pid, note.id);
                          }
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: projects.length,
                  itemBuilder: (_, index) {
                    final p = projects[index];
                    if (p.isDeleted) return const SizedBox.shrink();
                    return CheckboxListTile(
                      title: Text(p.title),
                      value: selected.contains(p.id),
                      onChanged: (v) => setSheetState(() => v == true
                          ? selected.add(p.id)
                          : selected.remove(p.id)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTagManager(BuildContext context, WidgetRef ref, Note note) {
    final controller = TextEditingController();
    final currentTags = List<String>.from(note.tags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, scrollController) {
            final allTagCounts =
                ref.read(notesRepositoryProvider).getAllTagsWithCounts();
            final suggestions = allTagCounts.keys
                .where((t) => !currentTags.contains(t))
                .toList()
              ..sort();

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text('Manage Labels',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Add label...',
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onSubmitted: (val) {
                            final tag = val.trim().toLowerCase();
                            if (tag.isNotEmpty &&
                                !currentTags.contains(tag)) {
                              ref.read(notesProvider.notifier).addTag(
                                  noteId: note.id, tag: tag);
                              setSheetState(() {
                                currentTags.add(tag);
                                controller.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          final tag =
                              controller.text.trim().toLowerCase();
                          if (tag.isNotEmpty &&
                              !currentTags.contains(tag)) {
                            ref.read(notesProvider.notifier).addTag(
                                noteId: note.id, tag: tag);
                            setSheetState(() {
                              currentTags.add(tag);
                              controller.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (currentTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: currentTags
                            .map((tag) => Chip(
                                  label: Text('#$tag',
                                      style:
                                          const TextStyle(fontSize: 12)),
                                  deleteIcon: const Icon(Icons.close,
                                      size: 16),
                                  onDeleted: () {
                                    ref
                                        .read(notesProvider.notifier)
                                        .removeTag(
                                            noteId: note.id, tag: tag);
                                    setSheetState(
                                        () => currentTags.remove(tag));
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                const Divider(height: 16),
                if (suggestions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Existing labels',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context).hintColor)),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: suggestions.length,
                      itemBuilder: (_, index) {
                        final tag = suggestions[index];
                        final count = allTagCounts[tag] ?? 0;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.label_rounded,
                              size: 20),
                          title: Text('#$tag'),
                          subtitle: Text(
                              '$count note${count == 1 ? '' : 's'}'),
                          onTap: () {
                            ref.read(notesProvider.notifier).addTag(
                                noteId: note.id, tag: tag);
                            setSheetState(
                                () => currentTags.add(tag));
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _monthYearLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _shortMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  String _formatDayHeader(DateTime date, DateTime today) {
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (date == today.add(const Duration(days: 1))) return 'Tomorrow';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${_shortMonthName(date.month)}';
  }

  String _formatTime(DateTime dt) {
    final hour =
        dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  // --- Bulk action methods ---

  void _confirmBulkDelete(BuildContext context, WidgetRef ref) async {
    final count = _selectedNoteIds.length;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            Text('Delete $count Note${count > 1 ? 's' : ''}'),
          ],
        ),
        content: Text(
            'Move $count note${count > 1 ? 's' : ''} to Trash? You can restore within 30 days.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
    if (result == true) {
      final idsToDelete = Set<String>.from(_selectedNoteIds);
      _exitSelectionMode();
      for (final id in idsToDelete) {
        ref.read(notesProvider.notifier).deleteNote(id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('$count note${count > 1 ? 's' : ''} deleted')),
        );
      }
    }
  }

  void _showBulkFolderPicker(BuildContext context, WidgetRef ref) {
    var folders = ref.read(foldersProvider).where((f) => !f.isDeleted).toList();
    final selected = <String>{};
    for (final folder in folders) {
      if (_selectedNoteIds.every((nid) => folder.noteIds.contains(nid))) {
        selected.add(folder.id);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                        'Add ${_selectedNoteIds.length} note${_selectedNoteIds.length > 1 ? 's' : ''} to folder',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: () {
                        for (final fid in selected) {
                          for (final nid in _selectedNoteIds) {
                            ref
                                .read(foldersProvider.notifier)
                                .addNoteToFolder(fid, nid);
                          }
                        }
                        Navigator.of(ctx).pop();
                        _exitSelectionMode();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Added to ${selected.length} folder${selected.length > 1 ? 's' : ''}')),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: folders.length,
                  itemBuilder: (_, index) {
                    final folder = folders[index];
                    final isChecked = selected.contains(folder.id);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            selected.add(folder.id);
                          } else {
                            selected.remove(folder.id);
                          }
                        });
                      },
                      secondary: Icon(
                        Icons.folder_rounded,
                        color: isChecked
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(folder.name),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBulkProjectPicker(BuildContext context, WidgetRef ref) {
    final projects = ref.read(projectDocumentsProvider);
    String? selectedProjectId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text('Add to Project',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: selectedProjectId == null
                          ? null
                          : () async {
                              final project = projects.firstWhere(
                                  (p) => p.id == selectedProjectId);
                              for (final nid in _selectedNoteIds) {
                                final alreadyLinked = project.blocks.any(
                                    (b) =>
                                        b.type == BlockType.noteReference &&
                                        b.noteId == nid);
                                if (!alreadyLinked) {
                                  await ref
                                      .read(
                                          projectDocumentsProvider.notifier)
                                      .addNoteBlock(project.id, nid);
                                }
                              }
                              Navigator.of(ctx).pop();
                              _exitSelectionMode();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Added to "${project.title}"')),
                                );
                              }
                            },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No projects yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: projects.length,
                    itemBuilder: (_, index) {
                      final project = projects[index];
                      if (project.isDeleted) return const SizedBox.shrink();
                      final isSelected = selectedProjectId == project.id;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.article_rounded,
                              color: Color(0xFF7B1FA2), size: 20),
                        ),
                        title: Text(project.title),
                        subtitle: Text(
                          '${project.blocks.length} blocks',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color:
                                    Theme.of(context).colorScheme.primary)
                            : null,
                        selected: isSelected,
                        onTap: () => setSheetState(
                            () => selectedProjectId = project.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTitleDialog(
      BuildContext context, WidgetRef ref, Note note) {
    final controller = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Note title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != note.title) {
                note.title = newTitle;
                note.updatedAt = DateTime.now();
                ref.read(notesProvider.notifier).updateNote(note);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ActionBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
