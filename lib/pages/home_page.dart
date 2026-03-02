import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../providers/tasks_provider.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/tasks_tab.dart';
import '../widgets/note_card.dart';
import '../widgets/template_picker_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTab = 0; // 0 = Notes, 1 = Tasks
  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = {};

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
    final openTaskCount = allTasks.where((t) => !t.isCompleted).length;

    return Scaffold(
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
                    'VoiceNotes AI',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
              actions: [
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
                  // Statistics cards (always visible)
                  Row(
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
                      const SizedBox(width: 10),
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CategoryCard(
                          icon: Icons.article_rounded,
                          title: "Projects",
                          subtitle: "${projects.length}",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor:
                              Theme.of(context).colorScheme.onSurface,
                          iconColor: const Color(0xFF8E24AA),
                          hasBorder: true,
                          onTap: () =>
                              context.push(AppRoutes.projectDocuments),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes / Tasks tab bar (below stats)
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
                  const SizedBox(height: 16),

                  // Tab content
                  if (_selectedTab == 0) ...[
                    // Notes List or Empty State
                    if (notes.isEmpty)
                      _buildEmptyState(context)
                    else ...[
                      // Split into pinned and unpinned
                      ..._buildPinnedSection(
                        context, ref, notes, folders, projects),
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
                                label: 'Add to Folder',
                                onTap: () {
                                  _showBulkFolderPicker(
                                      context, ref, notes);
                                },
                              ),
                              _ActionBarButton(
                                icon: Icons.article_rounded,
                                label: 'Add to Project',
                                onTap: () {
                                  _showBulkProjectPicker(
                                      context, ref, notes);
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

            // Speed Dial FAB (hide during selection)
            if (!_selectionMode)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SpeedDialFab(
                  items: [
                    SpeedDialItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        context.push(AppRoutes.search);
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
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Folder',
                      onTap: () {
                        setState(() => _selectedTab = 0);
                        _showNewFolderDialog(context, ref);
                      },
                    ),
                    SpeedDialItem(
                      icon: Icons.edit_note_rounded,
                      label: 'Text Note',
                      onTap: () async {
                        setState(() => _selectedTab = 0);
                        final template = await showModalBottomSheet<dynamic>(
                          context: context,
                          builder: (_) => const TemplatePickerSheet(),
                        );
                        // null from "Blank Note", NoteTemplate from a template,
                        // or nothing if sheet dismissed
                        if (!mounted) return;
                        if (template == false) return; // dismissed
                        final extras = <String, dynamic>{
                          'isNewTextNote': true,
                        };
                        if (template != null) {
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No notes yet",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the record button to create\nyour first voice note",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  List<Widget> _buildPinnedSection(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
    List<dynamic> folders,
    List<dynamic> projects,
  ) {
    final pinned = notes.where((n) => n.isPinned).toList()
      ..sort((a, b) =>
          (b.pinnedAt ?? DateTime.now()).compareTo(a.pinnedAt ?? DateTime.now()));
    final unpinned = notes.where((n) => !n.isPinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
        widgets.add(_buildNoteItem(context, ref, note, folders, projects));
      }
      // Recent section header
      if (unpinned.isNotEmpty) {
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

    // Unpinned notes
    for (final note in unpinned) {
      widgets.add(_buildNoteItem(context, ref, note, folders, projects));
    }

    return widgets;
  }

  Widget _buildNoteItem(
    BuildContext context,
    WidgetRef ref,
    Note note,
    List<dynamic> folders,
    List<dynamic> projects,
  ) {
    final noteFolderNames = folders
        .where((f) => f.noteIds.contains(note.id))
        .map((f) => f.name as String)
        .toList();

    final noteProjectNames = note.projectDocumentIds
        .map((id) {
          try {
            return projects.firstWhere((d) => d.id == id).title as String;
          } catch (_) {
            return null;
          }
        })
        .whereType<String>()
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
    );

    if (_selectionMode) return card;

    return Dismissible(
      key: ValueKey(note.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.open_in_new_rounded,
            color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.push(
            AppRoutes.noteDetail,
            extra: {'noteId': note.id},
          );
          return false;
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

  void _showProjectChangePicker(
      BuildContext context, WidgetRef ref, Note note) {
    var projects = ref.read(projectDocumentsProvider);
    final currentProjectIds = note.projectDocumentIds.toSet();
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
                      onPressed: () {
                        // Add to new projects
                        for (final pid in selected) {
                          if (!currentProjectIds.contains(pid)) {
                            ref
                                .read(projectDocumentsProvider.notifier)
                                .addNoteBlock(pid, note.id);
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
                leading: const Icon(Icons.note_add_rounded,
                    color: Color(0xFF7B1FA2)),
                title: const Text('New Project'),
                onTap: () async {
                  final name = await _showNewNameDialog(
                      context, 'New Project', 'Project title');
                  if (name != null && name.trim().isNotEmpty) {
                    final project = await ref
                        .read(projectDocumentsProvider.notifier)
                        .create(title: name.trim());
                    setSheetState(() {
                      projects = ref.read(projectDocumentsProvider);
                      selected.add(project.id);
                    });
                  }
                },
              ),
              const Divider(height: 1),
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
                            ? const Color(0xFF7B1FA2)
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

  // --- Bulk folder/project pickers (multi-select) ---

  void _showBulkFolderPicker(
      BuildContext context, WidgetRef ref, List<Note> allNotes) {
    var folders = ref.read(foldersProvider);
    final selected = <String>{};

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

  void _showBulkProjectPicker(
      BuildContext context, WidgetRef ref, List<Note> allNotes) {
    var projects = ref.read(projectDocumentsProvider);
    final selected = <String>{};

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
                        'Add ${_selectedNoteIds.length} note${_selectedNoteIds.length > 1 ? 's' : ''} to project',
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
                        for (final pid in selected) {
                          for (final nid in _selectedNoteIds) {
                            ref
                                .read(
                                    projectDocumentsProvider.notifier)
                                .addNoteBlock(pid, nid);
                          }
                        }
                        Navigator.of(ctx).pop();
                        _exitSelectionMode();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Added to ${selected.length} project${selected.length > 1 ? 's' : ''}')),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.note_add_rounded,
                    color: Color(0xFF7B1FA2)),
                title: const Text('New Project'),
                onTap: () async {
                  final name = await _showNewNameDialog(
                      context, 'New Project', 'Project title');
                  if (name != null && name.trim().isNotEmpty) {
                    final project = await ref
                        .read(projectDocumentsProvider.notifier)
                        .create(title: name.trim());
                    setSheetState(() {
                      projects = ref.read(projectDocumentsProvider);
                      selected.add(project.id);
                    });
                  }
                },
              ),
              const Divider(height: 1),
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
                            ? const Color(0xFF7B1FA2)
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

  void _showNewProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Project title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final desc = descController.text.trim();
                ref.read(projectDocumentsProvider.notifier).create(
                      title: title,
                      description: desc.isEmpty ? null : desc,
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
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

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.hasBorder = false,
    this.onTap,
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
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
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
