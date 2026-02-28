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

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTab = 0; // 0 = Notes, 1 = Tasks

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final projects = ref.watch(projectDocumentsProvider);
    final allTasks = ref.watch(tasksProvider);
    final openTaskCount = allTasks.where((t) => !t.isCompleted).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
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
                  // Notes / Tasks tab bar
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
                  const SizedBox(height: 20),

                  // Tab content
                  if (_selectedTab == 0) ...[
                    // Categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryCard(
                            icon: Icons.description,
                            title: "All Notes",
                            subtitle: "${notes.length} items",
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            textColor:
                                Theme.of(context).colorScheme.onPrimary,
                            iconColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 16),
                          _CategoryCard(
                            icon: Icons.folder_rounded,
                            title: "Folders",
                            subtitle: "${folders.length} items",
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            iconColor:
                                Theme.of(context).colorScheme.secondary,
                            hasBorder: true,
                            onTap: () => context.push(AppRoutes.folders),
                          ),
                          const SizedBox(width: 16),
                          _CategoryCard(
                            icon: Icons.article_rounded,
                            title: "Projects",
                            subtitle: "${projects.length} items",
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            textColor:
                                Theme.of(context).colorScheme.onSurface,
                            iconColor: const Color(0xFF8E24AA),
                            hasBorder: true,
                            onTap: () => context.push(AppRoutes.folders),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recent Notes Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Notes",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.search),
                          child: Text(
                            "See All",
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes List or Empty State
                    if (notes.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...notes.map((note) {
                        // Resolve folder names (reverse lookup)
                        final noteFolderNames = folders
                            .where((f) => f.noteIds.contains(note.id))
                            .map((f) => f.name)
                            .toList();

                        // Resolve project names
                        final noteProjectNames = note.projectDocumentIds
                            .map((id) {
                              try {
                                return projects
                                    .firstWhere((d) => d.id == id)
                                    .title;
                              } catch (_) {
                                return null;
                              }
                            })
                            .whereType<String>()
                            .toList();

                        return Dismissible(
                          key: ValueKey(note.id),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 24),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction ==
                                DismissDirection.startToEnd) {
                              // Right swipe → open note
                              context.push(
                                AppRoutes.noteDetail,
                                extra: {'noteId': note.id},
                              );
                              return false;
                            } else {
                              // Left swipe → confirm delete
                              return await _confirmDelete(
                                  context, note);
                            }
                          },
                          onDismissed: (direction) {
                            if (direction ==
                                DismissDirection.endToStart) {
                              ref
                                  .read(notesProvider.notifier)
                                  .deleteNote(note.id);
                            }
                          },
                          child: NoteCard(
                            note: note,
                            timestamp: _formatDate(note.createdAt),
                            folderNames: noteFolderNames,
                            projectNames: noteProjectNames,
                            onTap: () => context.push(
                              AppRoutes.noteDetail,
                              extra: {'noteId': note.id},
                            ),
                            onDelete: () =>
                                _confirmAndDelete(context, ref, note),
                            onLongPress: () => _showNoteContextMenu(
                                context, ref, note,
                                noteFolderNames, noteProjectNames),
                          ),
                        );
                      }),
                  ] else ...[
                    // Tasks tab
                    const TasksTab(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Speed Dial FAB
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SpeedDialFab(
                  items: [
                    SpeedDialItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () => context.push(AppRoutes.search),
                    ),
                    SpeedDialItem(
                      icon: Icons.article_rounded,
                      label: 'New Project',
                      onTap: () => _showNewProjectDialog(context, ref),
                    ),
                    SpeedDialItem(
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Folder',
                      onTap: () => _showNewFolderDialog(context, ref),
                    ),
                    SpeedDialItem(
                      icon: Icons.edit_note_rounded,
                      label: 'Text Note',
                      onTap: () => context.push(
                        AppRoutes.noteDetail,
                        extra: {'isNewTextNote': true},
                      ),
                    ),
                    SpeedDialItem(
                      icon: Icons.mic_rounded,
                      label: 'Record Note',
                      onTap: () => context.push(AppRoutes.recording),
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

  Future<bool> _confirmDelete(BuildContext context, Note note) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
            'Delete "${note.title}"? This will remove the note and its audio recording.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
    }
  }

  void _showNoteContextMenu(
    BuildContext context,
    WidgetRef ref,
    Note note,
    List<String> currentFolderNames,
    List<String> currentProjectNames,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(
                  AppRoutes.noteDetail,
                  extra: {'noteId': note.id},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Title'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditTitleDialog(context, ref, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: const Text('Add to Folder'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showFolderPicker(context, ref, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.article_rounded),
              title: const Text('Add to Project'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showProjectPicker(context, ref, note);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmAndDelete(context, ref, note);
              },
            ),
          ],
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

  void _showFolderPicker(
      BuildContext context, WidgetRef ref, Note note) {
    final folders = ref.read(foldersProvider);
    final currentFolderIds =
        folders.where((f) => f.noteIds.contains(note.id)).map((f) => f.id).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
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
                  Text('Add to Folder',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showNewFolderAndAssign(context, ref, note);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
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
                  final isInFolder = currentFolderIds.contains(folder.id);
                  return ListTile(
                    leading: Icon(
                      isInFolder
                          ? Icons.folder_rounded
                          : Icons.folder_open_rounded,
                      color: isInFolder
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(folder.name),
                    trailing: isInFolder
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20)
                        : null,
                    onTap: () {
                      if (isInFolder) {
                        ref.read(foldersProvider.notifier).removeNoteFromFolder(
                            folder.id, note.id);
                      } else {
                        ref.read(foldersProvider.notifier).addNoteToFolder(
                            folder.id, note.id);
                      }
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderAndAssign(
      BuildContext context, WidgetRef ref, Note note) {
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final folder = await ref
                    .read(foldersProvider.notifier)
                    .addFolder(name: name);
                ref.read(foldersProvider.notifier).addNoteToFolder(
                    folder.id, note.id);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  void _showProjectPicker(
      BuildContext context, WidgetRef ref, Note note) {
    final projects = ref.read(projectDocumentsProvider);
    final currentProjectIds = note.projectDocumentIds.toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
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
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showNewProjectAndAssign(context, ref, note);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
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
                  final project = projects[index];
                  final isLinked = currentProjectIds.contains(project.id);
                  return ListTile(
                    leading: Icon(
                      Icons.article_rounded,
                      color: isLinked
                          ? const Color(0xFF7B1FA2)
                          : null,
                    ),
                    title: Text(project.title),
                    subtitle: project.description != null
                        ? Text(project.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)
                        : null,
                    trailing: isLinked
                        ? const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20)
                        : null,
                    onTap: () {
                      if (!isLinked) {
                        ref
                            .read(projectDocumentsProvider.notifier)
                            .addNoteBlock(project.id, note.id);
                      }
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewProjectAndAssign(
      BuildContext context, WidgetRef ref, Note note) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final doc = await ref
                    .read(projectDocumentsProvider.notifier)
                    .create(title: title);
                ref
                    .read(projectDocumentsProvider.notifier)
                    .addNoteBlock(doc.id, note.id);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create & Add'),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        constraints: const BoxConstraints(minWidth: 140),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: hasBorder
              ? Border.all(color: Theme.of(context).dividerColor)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
