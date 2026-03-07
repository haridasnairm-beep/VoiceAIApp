import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../models/note.dart';
import '../models/project_block.dart';
import '../models/project_document.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/gesture_fab.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/tasks_tab.dart';
import '../widgets/note_card.dart';
import '../widgets/template_picker_sheet.dart';
import '../constants/note_templates.dart';
import '../widgets/empty_state_illustrated.dart';
import '../widgets/backup_reminder_banner.dart';
import '../providers/settings_provider.dart';
import '../services/haptic_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTab = 0; // 0 = Notes, 1 = Tasks
  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = {};
  bool _backupReminderDismissed = false;
  bool _isDialOpen = false;
  final GlobalKey<GestureFabState> _gestureFabKey = GlobalKey<GestureFabState>();

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

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final projects = ref.watch(projectDocumentsProvider);
    final allTasks = ref.watch(tasksProvider);
    final settings = ref.watch(settingsProvider);
    final openTaskCount = allTasks.where((t) => !t.isCompleted).length;

    final showStats = notes.isNotEmpty || folders.isNotEmpty;

    // Guided first-recording banner: show when not completed and no notes yet
    final showGuidedBanner =
        !settings.guidedRecordingCompleted && notes.isEmpty;

    // Backup reminder: show when 10+ notes and never backed up, or backup > 30 days old
    // Hidden when auto-backup is enabled (auto-backup handles it)
    final showBackupReminder = !_backupReminderDismissed &&
        !settings.autoBackupEnabled &&
        notes.length >= 10 &&
        (settings.lastBackupDate == null ||
            DateTime.now().difference(settings.lastBackupDate!).inDays > 30);

    // Auto-dismiss guided banner once the user has recorded their first note
    if (settings.guidedRecordingCompleted == false && notes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(settingsProvider.notifier).setGuidedRecordingCompleted(true);
      });
    }

    return PopScope(
      canPop: !_selectionMode && !_isDialOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isDialOpen) {
          _gestureFabKey.currentState?.closeDial();
          return;
        }
        if (_selectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      if (_selectedNoteIds.length == notes.length) {
                        _selectedNoteIds.clear();
                        _selectionMode = false;
                      } else {
                        _selectedNoteIds.addAll(notes.map((n) => n.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedNoteIds.length == notes.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                ),
              ],
            )
          : AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    'Vaanix',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.calendar_month_rounded,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => context.push(AppRoutes.calendar),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                  onSelected: (value) => context.push(value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: AppRoutes.preferences,
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Preferences'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.security,
                      child: Row(
                        children: [
                          Icon(Icons.lock_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Security'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.audioSettings,
                      child: Row(
                        children: [
                          Icon(Icons.mic_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Audio & Recording'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.storage,
                      child: Row(
                        children: [
                          Icon(Icons.storage_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Storage'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.backupRestore,
                      child: Row(
                        children: [
                          Icon(Icons.backup_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Backup & Restore'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.support,
                      child: Row(
                        children: [
                          Icon(Icons.help_outline_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Help & Support'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.about,
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('About'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.trash,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          const Text('Trash'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: AppRoutes.dangerZone,
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 20, color: Theme.of(context).colorScheme.error),
                          const SizedBox(width: 12),
                          Text('Danger Zone', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistics cards
                  if (showStats) Row(
                    children: [
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.description,
                          title: "Notes",
                          subtitle: "${notes.length}",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor:
                              Theme.of(context).colorScheme.onSurface,
                          iconColor:
                              Theme.of(context).colorScheme.primary,
                          hasBorder: true,
                        ),
                      ),
                      if (projects.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CategoryCard(
                            icon: Icons.article_rounded,
                            title: "Projects",
                            subtitle: "${projects.length}",
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            iconColor: const Color(0xFF7B1FA2),
                            hasBorder: true,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.folder_rounded,
                          title: "Folders",
                          subtitle: "${folders.length}",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor:
                              Theme.of(context).colorScheme.onSurface,
                          iconColor:
                              Theme.of(context).colorScheme.secondary,
                          hasBorder: true,
                          onTap: () => context.push(AppRoutes.folders),
                          showNavigationHint: true,
                        ),
                      ),
                    ],
                  ),
                  if (showStats) const SizedBox(height: 16),

                  // Notes / Tasks tab bar — only show if user has tasks
                  if (allTasks.isNotEmpty) ...[
                    SegmentedButton<int>(
                      segments: [
                        const ButtonSegment(
                          value: 0,
                          label: Text('Notes'),
                          icon: Icon(Icons.description_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Tasks'),
                          icon: Badge(
                            isLabelVisible: openTaskCount > 0 && _selectedTab != 1,
                            label: Text(
                              openTaskCount > 99
                                  ? '99+'
                                  : openTaskCount.toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            child: const Icon(Icons.task_alt_rounded, size: 18),
                          ),
                        ),
                      ],
                      selected: {_selectedTab},
                      onSelectionChanged: (selected) =>
                          setState(() => _selectedTab = selected.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        selectedForegroundColor:
                            Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Tab content
                  if (_selectedTab == 0) ...[
                    // Guided first-recording banner
                    if (showGuidedBanner)
                      _buildGuidedBanner(context, ref),

                    // Backup reminder banner
                    if (showBackupReminder && !showGuidedBanner)
                      BackupReminderBanner(
                        neverBackedUp: settings.lastBackupDate == null,
                        onDismiss: () => setState(() =>
                            _backupReminderDismissed = true),
                      ),

                    // Notes + Projects List or Empty State
                    if (notes.isEmpty && projects.isEmpty && !showGuidedBanner)
                      _buildEmptyState(context)
                    else if (notes.isNotEmpty || projects.isNotEmpty) ...[
                      // Sort selector
                      _buildSortRow(context, ref, settings.noteSortOrder),
                      // Split into pinned and unpinned (mixed with projects)
                      ..._buildPinnedSection(
                        context, ref, notes, folders, projects, settings.noteSortOrder),
                    ],
                  ] else ...[
                    // Tasks tab
                    const TasksTab(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Selection action bar
            if (_selectionMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                              _ActionBarButton(
                                icon: Icons.open_in_new_rounded,
                                label: 'Open',
                                onTap: () {
                                  final noteId =
                                      _selectedNoteIds.first;
                                  _exitSelectionMode();
                                  context.push(
                                    AppRoutes.noteDetail,
                                    extra: {'noteId': noteId},
                                  );
                                },
                              ),
                              _ActionBarButton(
                                icon: Icons.edit_rounded,
                                label: 'Edit Title',
                                onTap: () {
                                  final noteId =
                                      _selectedNoteIds.first;
                                  final note = notes.firstWhere(
                                      (n) => n.id == noteId);
                                  _exitSelectionMode();
                                  _showEditTitleDialog(
                                      context, ref, note);
                                },
                              ),
                              Builder(builder: (_) {
                                final noteId = _selectedNoteIds.first;
                                final note = notes.firstWhere(
                                    (n) => n.id == noteId,
                                    orElse: () => notes.first);
                                return _ActionBarButton(
                                  icon: note.isPinned
                                      ? Icons.push_pin_outlined
                                      : Icons.push_pin_rounded,
                                  label: note.isPinned ? 'Unpin' : 'Pin',
                                  onTap: () async {
                                    final ok = await ref
                                        .read(notesProvider.notifier)
                                        .togglePin(noteId);
                                    if (!ok && mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Max 10 pinned notes. Unpin one first.'),
                                      ));
                                    }
                                    _exitSelectionMode();
                                  },
                                );
                              }),
                              _ActionBarButton(
                                icon: Icons.folder_rounded,
                                label: 'Folder',
                                onTap: () {
                                  _showBulkFolderPicker(
                                      context, ref, notes);
                                },
                              ),
                              _ActionBarButton(
                                icon: Icons.article_rounded,
                                label: 'Project',
                                onTap: () {
                                  _showBulkProjectPicker(
                                      context, ref);
                                },
                              ),
                              _ActionBarButton(
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                                color: Colors.red,
                                onTap: () => _confirmBulkDelete(
                                    context, ref, notes),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionBarButton(
                                icon: Icons.folder_rounded,
                                label: 'Folder',
                                onTap: () {
                                  _showBulkFolderPicker(
                                      context, ref, notes);
                                },
                              ),
                              _ActionBarButton(
                                icon: Icons.article_rounded,
                                label: 'Project',
                                onTap: () {
                                  _showBulkProjectPicker(
                                      context, ref);
                                },
                              ),
                              _ActionBarButton(
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                                color: Colors.red,
                                onTap: () => _confirmBulkDelete(
                                    context, ref, notes),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

            // Gesture FAB (hide during selection)
            if (!_selectionMode)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureFab(
                  key: _gestureFabKey,
                  sessionCount: settings.sessionCount,
                  showSubtitleHint: settings.sessionCount <= 10,
                  onDialToggled: (open) => setState(() => _isDialOpen = open),
                  onRecord: () {
                    setState(() => _selectedTab = 0);
                    context.push(AppRoutes.recording);
                  },
                  speedDialItems: [
                    SpeedDialItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        context.push(AppRoutes.search);
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Folder',
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        _showNewFolderDialog(context, ref);
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.article_rounded,
                      label: 'New Project',
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        _showNewProjectDialog(context, ref);
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.edit_note_rounded,
                      label: 'Text Note',
                      onTap: () async {
                        setState(() => _selectedTab = 0);
                        final template = await showModalBottomSheet<dynamic>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => const TemplatePickerSheet(),
                        );
                        if (!mounted) return;
                        if (template == null) return;
                        final extras = <String, dynamic>{
                          'isNewTextNote': true,
                        };
                        if (template is NoteTemplate) {
                          extras['templateContent'] = template.content;
                          extras['templateTitle'] =
                              '${template.name} — ${_formatDate(DateTime.now())}';
                        }
                        context.push(AppRoutes.noteDetail, extra: extras);
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.mic_rounded,
                      label: 'Record Note',
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        context.push(AppRoutes.recording);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateIllustrated(
      icon: Icons.mic_none_rounded,
      title: 'No notes yet',
      subtitle: 'Tap the mic button to capture\nyour first voice note',
      ctaLabel: 'Record a Note',
      onCta: () => context.push(AppRoutes.recording),
    );
  }

  Widget _buildGuidedBanner(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mic_none_rounded,
              color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to capture your first thought?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap the mic button below and start speaking.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.recording),
                  child: Text(
                    'Start recording →',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 18, color: theme.colorScheme.secondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => ref
                .read(settingsProvider.notifier)
                .setGuidedRecordingCompleted(true),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---

  Widget _buildSortRow(BuildContext context, WidgetRef ref, String currentSort) {
    const labels = {
      'newest': 'Newest',
      'oldest': 'Oldest',
      'titleAZ': 'A — Z',
      'titleZA': 'Z — A',
      'longest': 'Longest',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<String>(
            onSelected: (v) =>
                ref.read(settingsProvider.notifier).setNoteSortOrder(v),
            itemBuilder: (_) => labels.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          if (e.key == currentSort)
                            Icon(Icons.check_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary)
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
                Icon(Icons.sort_rounded,
                    size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  labels[currentSort] ?? 'Newest',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Note> _applySortOrder(List<Note> notes, String sortOrder) {
    final sorted = List<Note>.from(notes);
    switch (sortOrder) {
      case 'oldest':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'titleAZ':
        sorted.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case 'titleZA':
        sorted.sort(
            (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case 'longest':
        sorted.sort(
            (a, b) => b.audioDurationSeconds.compareTo(a.audioDurationSeconds));
      default: // newest
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  List<Widget> _buildPinnedSection(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
    List<dynamic> folders,
    List<ProjectDocument> projects,
    String sortOrder,
  ) {
    final pinned = notes.where((n) => n.isPinned).toList()
      ..sort((a, b) =>
          (b.pinnedAt ?? DateTime.now()).compareTo(a.pinnedAt ?? DateTime.now()));
    final unpinned = _applySortOrder(
        notes.where((n) => !n.isPinned).toList(), sortOrder);

    // Build mixed list of unpinned notes + projects sorted together
    final List<_FeedItem> feedItems = [
      ...unpinned.map((n) => _FeedItem(note: n, createdAt: n.createdAt, title: n.title)),
      ...projects.map((p) => _FeedItem(project: p, createdAt: p.createdAt, title: p.title)),
    ];
    // Apply same sort order to mixed list
    switch (sortOrder) {
      case 'oldest':
        feedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'titleAZ':
        feedItems.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case 'titleZA':
        feedItems.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      default: // newest, longest
        feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final widgets = <Widget>[];

    // Pinned section header + items
    if (pinned.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.push_pin_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Pinned (${pinned.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ));
      for (final note in pinned) {
        widgets.add(_buildNoteItem(context, ref, note, folders));
      }
      // Recent section header
      if (feedItems.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Recent',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
          ),
        ));
      }
    }

    // Mixed unpinned notes + projects
    for (final item in feedItems) {
      if (item.note != null) {
        widgets.add(_buildNoteItem(context, ref, item.note!, folders));
      } else if (item.project != null) {
        widgets.add(_buildProjectItem(context, ref, item.project!, folders));
      }
    }

    return widgets;
  }

  Widget _buildProjectItem(
    BuildContext context,
    WidgetRef ref,
    ProjectDocument project,
    List<dynamic> folders,
  ) {
    final blockCount = project.blocks.length;
    final folderName = folders
        .where((f) => (f.projectDocumentIds as List).contains(project.id))
        .map((f) => f.name as String)
        .toList();
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.projectDocumentDetail,
        extra: {'documentId': project.id},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Metadata
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 12, color: theme.hintColor),
                const SizedBox(width: 3),
                Text(
                  _formatDate(project.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(' · ',
                    style: TextStyle(color: theme.hintColor, fontSize: 12)),
                Text(
                  '$blockCount ${blockCount == 1 ? 'block' : 'blocks'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            // Row 2: Description
            if (project.description != null && project.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                project.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Row 3: Labels
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _ProjectLabelChip(
                  icon: Icons.article_rounded,
                  label: project.title,
                  bgColor: const Color(0xFFF3E5F5),
                  textColor: const Color(0xFF7B1FA2),
                ),
                ...folderName.map((name) => _ProjectLabelChip(
                      icon: Icons.folder_rounded,
                      label: name,
                      bgColor: const Color(0xFFE3F2FD),
                      textColor: const Color(0xFF1565C0),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(
    BuildContext context,
    WidgetRef ref,
    Note note,
    List<dynamic> folders,
  ) {
    final noteFolderNames = folders
        .where((f) => f.noteIds.contains(note.id))
        .map((f) => f.name as String)
        .toList();

    final projects = ref.read(projectDocumentsProvider);
    final noteProjectNames = projects
        .where((p) => note.projectDocumentIds.contains(p.id))
        .map((p) => p.title)
        .toList();

    final card = NoteCard(
      note: note,
      timestamp: _formatDate(note.createdAt),
      folderNames: noteFolderNames,
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

    if (_selectionMode) return card;

    return Dismissible(
      key: ValueKey(note.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              note.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              note.isPinned ? 'Unpin' : 'Pin',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(width: 6),
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Toggle pin
          HapticService.light();
          ref.read(notesProvider.notifier).togglePin(note.id);
          return false; // Don't actually dismiss
        } else {
          return await _confirmDelete(context, note);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref.read(notesProvider.notifier).deleteNote(note.id);
        }
      },
      child: card,
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Note note) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 24),
            const SizedBox(width: 8),
            const Text('Delete Note'),
          ],
        ),
        content: Text('Move "${note.title}" to Trash? You can restore it within 30 days.'),
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
    return result ?? false;
  }

  void _confirmAndDelete(
      BuildContext context, WidgetRef ref, Note note) async {
    final confirmed = await _confirmDelete(context, note);
    if (confirmed) {
      ref.read(notesProvider.notifier).deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${note.title}" moved to Trash'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(notesProvider.notifier).restoreNote(note.id);
            },
          ),
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  void _confirmBulkDelete(
      BuildContext context, WidgetRef ref, List<Note> allNotes) async {
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

  // --- Folder/Project change pickers (single note, from capsule tap) ---

  void _showFolderChangePicker(
      BuildContext context, WidgetRef ref, Note note) {
    var folders = ref.read(foldersProvider);
    final currentFolderIds = folders
        .where((f) => f.noteIds.contains(note.id))
        .map((f) => f.id)
        .toSet();
    final selected = Set<String>.from(currentFolderIds);

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
                  color:
                      Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text('Change Folder',
                        style:
                            Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: () {
                        // Remove from old folders
                        for (final fid in currentFolderIds) {
                          if (!selected.contains(fid)) {
                            ref
                                .read(foldersProvider.notifier)
                                .removeNoteFromFolder(fid, note.id);
                          }
                        }
                        // Add to new folders
                        for (final fid in selected) {
                          if (!currentFolderIds.contains(fid)) {
                            ref
                                .read(foldersProvider.notifier)
                                .addNoteToFolder(fid, note.id);
                          }
                        }
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.create_new_folder_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('New Folder'),
                onTap: () async {
                  final name = await _showNewNameDialog(
                      context, 'New Folder', 'Folder name');
                  if (name != null && name.trim().isNotEmpty) {
                    final folder = await ref
                        .read(foldersProvider.notifier)
                        .addFolder(name: name.trim());
                    setSheetState(() {
                      folders = ref.read(foldersProvider);
                      selected.add(folder.id);
                    });
                  }
                },
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

  // --- Single-note project change picker ---

  void _showProjectChangePicker(
      BuildContext context, WidgetRef ref, Note note) {
    var projects = ref.read(projectDocumentsProvider);
    final currentProjectIds = Set<String>.from(note.projectDocumentIds);
    final selected = Set<String>.from(currentProjectIds);

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
                  color:
                      Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text('Change Project',
                        style:
                            Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: () async {
                        // Remove from old projects
                        for (final pid in currentProjectIds) {
                          if (!selected.contains(pid)) {
                            await ref
                                .read(projectDocumentsProvider.notifier)
                                .removeNoteFromProject(pid, note.id);
                          }
                        }
                        // Add to new projects
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
              ListTile(
                leading: Icon(Icons.add_circle_outline_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('New Project'),
                onTap: () async {
                  final name = await _showNewNameDialog(
                      context, 'New Project', 'Project name');
                  if (name != null && name.trim().isNotEmpty) {
                    final allFolders = ref.read(foldersProvider);
                    final general =
                        allFolders.where((f) => f.name == 'General').toList();
                    final folderId =
                        general.isNotEmpty ? general.first.id : null;
                    final doc = await ref
                        .read(projectDocumentsProvider.notifier)
                        .create(title: name.trim(), folderId: folderId);
                    setSheetState(() {
                      projects = ref.read(projectDocumentsProvider);
                      selected.add(doc.id);
                    });
                  }
                },
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
                      final isChecked = selected.contains(project.id);
                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: (val) {
                          setSheetState(() {
                            if (val == true) {
                              selected.add(project.id);
                            } else {
                              selected.remove(project.id);
                            }
                          });
                        },
                        secondary: Icon(
                          Icons.article_rounded,
                          color: isChecked
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(project.title),
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

  // --- Single-note label/tag manager ---

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
            // Gather all existing tags from other notes for suggestions
            final allTagCounts = ref.read(notesRepositoryProvider).getAllTagsWithCounts();
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
                // Add new label input
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
                            if (tag.isNotEmpty && !currentTags.contains(tag)) {
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
                // Current labels
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
                                      style: const TextStyle(fontSize: 12)),
                                  deleteIcon:
                                      const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    ref
                                        .read(notesProvider.notifier)
                                        .removeTag(
                                            noteId: note.id, tag: tag);
                                    setSheetState(() {
                                      currentTags.remove(tag);
                                    });
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
                // Suggestions from existing labels
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
                            '$count note${count == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context).hintColor),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                size: 20),
                            onPressed: () {
                              ref.read(notesProvider.notifier).addTag(
                                  noteId: note.id, tag: tag);
                              setSheetState(() {
                                currentTags.add(tag);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Text(
                        'Type a label name above to create one.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Bulk folder picker (multi-select) ---

  void _showBulkFolderPicker(
      BuildContext context, WidgetRef ref, List<Note> allNotes) {
    var folders = ref.read(foldersProvider);
    // Pre-select folders that already contain the selected notes
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
                  color:
                      Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                        'Add ${_selectedNoteIds.length} note${_selectedNoteIds.length > 1 ? 's' : ''} to folder',
                        style:
                            Theme.of(context).textTheme.titleMedium),
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
              ListTile(
                leading: Icon(Icons.create_new_folder_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('New Folder'),
                onTap: () async {
                  final name = await _showNewNameDialog(
                      context, 'New Folder', 'Folder name');
                  if (name != null && name.trim().isNotEmpty) {
                    final folder = await ref
                        .read(foldersProvider.notifier)
                        .addFolder(name: name.trim());
                    setSheetState(() {
                      folders = ref.read(foldersProvider);
                      selected.add(folder.id);
                    });
                  }
                },
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

  void _showNewFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(foldersProvider.notifier).addFolder(name: name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context, WidgetRef ref) async {
    final name = await _showNewNameDialog(
        context, 'New Project', 'Project name');
    if (name != null && name.trim().isNotEmpty && mounted) {
      // Assign to General folder by default
      final folders = ref.read(foldersProvider);
      final generalFolder = folders.where((f) => f.name == 'General').toList();
      final folderId = generalFolder.isNotEmpty ? generalFolder.first.id : null;
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
  }

  void _showBulkProjectPicker(BuildContext context, WidgetRef ref) {
    var projects = ref.read(projectDocumentsProvider);
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
                    Text(
                      'Add to Project',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                              // Add notes as noteReference blocks in the project
                              final project = projects.firstWhere(
                                  (p) => p.id == selectedProjectId);
                              for (final nid in _selectedNoteIds) {
                                // Skip if already linked
                                final alreadyLinked = project.blocks.any(
                                    (b) => b.type == BlockType.noteReference &&
                                        b.noteId == nid);
                                if (!alreadyLinked) {
                                  await ref
                                      .read(projectDocumentsProvider.notifier)
                                      .addNoteBlock(project.id, nid);
                                }
                              }
                              // Also move notes to project's folder
                              if (project.folderId != null) {
                                for (final nid in _selectedNoteIds) {
                                  ref
                                      .read(notesProvider.notifier)
                                      .moveNoteToFolder(nid, project.folderId!);
                                }
                              }
                              Navigator.of(ctx).pop();
                              _exitSelectionMode();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Added to "${project.title}"')),
                              );
                            },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.add_circle_outline_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('New Project'),
                onTap: () async {
                  final name = await _showNewNameDialog(
                      context, 'New Project', 'Project name');
                  if (name != null && name.trim().isNotEmpty) {
                    // Assign to General folder
                    final allFolders = ref.read(foldersProvider);
                    final general = allFolders.where((f) => f.name == 'General').toList();
                    final folderId = general.isNotEmpty ? general.first.id : null;
                    final doc = await ref
                        .read(projectDocumentsProvider.notifier)
                        .create(title: name.trim(), folderId: folderId);
                    setSheetState(() {
                      projects = ref.read(projectDocumentsProvider);
                      selectedProjectId = doc.id;
                    });
                  }
                },
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
                      final isSelected = selectedProjectId == project.id;
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(Icons.article_rounded,
                              color: Color(0xFF7B1FA2), size: 20),
                        ),
                        title: Text(project.title),
                        subtitle: Text(
                          '${project.blocks.length} blocks',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded,
                                color: Theme.of(context).colorScheme.primary)
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

  Future<String?> _showNewNameDialog(
      BuildContext context, String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
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
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDay = DateTime(date.year, date.month, date.day);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (noteDay == today) {
      return 'Today, $time';
    } else if (noteDay == yesterday) {
      return 'Yesterday, $time';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      return '$month $day';
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final bool hasBorder;
  final VoidCallback? onTap;
  final bool showNavigationHint;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.hasBorder = false,
    this.onTap,
    this.showNavigationHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: hasBorder
              ? Border.all(color: Theme.of(context).dividerColor)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const Spacer(),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.8),
                      ),
                ),
                if (showNavigationHint) ...[
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded,
                      size: 14,
                      color: textColor.withValues(alpha: 0.5)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItem {
  final Note? note;
  final ProjectDocument? project;
  final DateTime createdAt;
  final String title;

  _FeedItem({this.note, this.project, required this.createdAt, required this.title});
}

class _ProjectLabelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _ProjectLabelChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBarButton({
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
