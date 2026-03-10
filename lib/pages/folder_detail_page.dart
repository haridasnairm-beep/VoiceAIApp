import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/project_documents_provider.dart';
import '../models/folder.dart';
import '../models/note.dart';
import '../models/project_document.dart';
import '../providers/settings_provider.dart';
import '../widgets/folder_picker_sheet.dart';
import '../widgets/gesture_fab.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/note_card.dart';
import '../widgets/template_picker_sheet.dart';
import '../constants/note_templates.dart';

enum _SortOption { newest, oldest, titleAZ, titleZA }
enum _FilterOption { all, notes, projects }

class FolderDetailPage extends ConsumerStatefulWidget {
  final String? folderId;

  const FolderDetailPage({super.key, this.folderId});

  @override
  ConsumerState<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends ConsumerState<FolderDetailPage> {
  _SortOption _sortOption = _SortOption.newest;
  _FilterOption _filterOption = _FilterOption.all;

  String get folderId => widget.folderId ?? '';


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';
    if (dateOnly == today) return 'Today, $time';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday, $time';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day, $time';
  }

  String _sortLabel(_SortOption option) {
    switch (option) {
      case _SortOption.newest:
        return 'Newest';
      case _SortOption.oldest:
        return 'Oldest';
      case _SortOption.titleAZ:
        return 'A — Z';
      case _SortOption.titleZA:
        return 'Z — A';
    }
  }

  List<Note> _sortNotes(List<Note> notes) {
    final sorted = List<Note>.from(notes);
    switch (_sortOption) {
      case _SortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortOption.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _SortOption.titleAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case _SortOption.titleZA:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    // Find the folder by id
    final folders = ref.watch(foldersProvider);
    final Folder? folder;
    if (widget.folderId == null) {
      folder = null;
    } else {
      final matches = folders.where((f) => f.id == widget.folderId);
      folder = matches.isNotEmpty ? matches.first : null;
    }

    if (folder == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_off_rounded,
                    size: 64, color: Theme.of(context).hintColor),
                const SizedBox(height: 16),
                Text(
                  'Folder not found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Get notes that belong to this folder (check both note.folderId and folder.noteIds)
    final allNotes = ref.watch(notesProvider);
    final folderNotes = _sortNotes(allNotes
        .where((n) =>
            n.folderId == widget.folderId ||
            folder!.noteIds.contains(n.id))
        .toList());

    // Get project documents that belong to this folder
    final allProjects = ref.watch(projectDocumentsProvider);
    final folderProjects = allProjects
        .where((p) => p.folderId == widget.folderId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Calculate total audio duration
    int totalSeconds = 0;
    for (final note in folderNotes) {
      totalSeconds += note.audioDurationSeconds;
    }
    final totalAudio = totalSeconds >= 60
        ? '${totalSeconds ~/ 60}m'
        : '${totalSeconds}s';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folder.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              '${folderNotes.length} notes${folderProjects.isNotEmpty ? ' · ${folderProjects.length} projects' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(AppRoutes.search,
                extra: {'folderId': widget.folderId}),
          ),
          if (!folder.isAutoGenerated && folder.name != 'General')
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: Theme.of(context).colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'new_project') {
                  _showNewProjectDialog(context, ref);
                } else if (value == 'rename') {
                  _showRenameDialog(context, folder!);
                } else if (value == 'archive') {
                  folder!.isArchived = true;
                  ref.read(foldersProvider.notifier).updateFolder(folder);
                  context.pop();
                } else if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'new_project',
                  child: Text('New Project'),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive'),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stat chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: Icons.mic_rounded,
                      color: AppColors.lightPrimary,
                      value: totalAudio,
                      label: 'Total Audio',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.note_rounded,
                      color: AppColors.lightSuccess,
                      value: '${folder.noteIds.length}',
                      label: 'Notes',
                    ),
                  ),
                  if (folderProjects.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.article_rounded,
                        color: const Color(0xFF7B1FA2),
                        value: '${folderProjects.length}',
                        label: 'Projects',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Toggle/filter: All | Notes | Projects — only show if folder has projects
            if (folderProjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SegmentedButton<_FilterOption>(
                  segments: [
                    ButtonSegment(
                      value: _FilterOption.all,
                      label: const SizedBox(width: 32, child: Center(child: Text('All'))),
                    ),
                    const ButtonSegment(value: _FilterOption.notes, label: Text('Notes')),
                    const ButtonSegment(value: _FilterOption.projects, label: Text('Projects')),
                  ],
                  selected: {_filterOption},
                  onSelectionChanged: (selected) =>
                      setState(() => _filterOption = selected.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    selectedForegroundColor:
                        Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

            // Sort header
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterOption == _FilterOption.projects ? 'Projects' :
                    _filterOption == _FilterOption.notes ? 'Notes' : 'All Items',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  PopupMenuButton<_SortOption>(
                    onSelected: (option) {
                      setState(() => _sortOption = option);
                    },
                    itemBuilder: (ctx) => _SortOption.values.map((option) {
                      return PopupMenuItem(
                        value: option,
                        child: Row(
                          children: [
                            if (option == _sortOption)
                              Icon(Icons.check_rounded,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(_sortLabel(option)),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          _sortLabel(_sortOption),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // === Unified timeline (All) or filtered view ===
            if (_filterOption == _FilterOption.all) ...[
              // Merge notes and projects into single timeline sorted by date
              Builder(builder: (context) {
                final items = <_TimelineItem>[
                  ...folderNotes.map((n) => _TimelineItem(
                        date: n.updatedAt,
                        note: n,
                      )),
                  ...folderProjects.map((p) => _TimelineItem(
                        date: p.updatedAt,
                        project: p,
                      )),
                ];
                items.sort((a, b) {
                  switch (_sortOption) {
                    case _SortOption.newest:
                      return b.date.compareTo(a.date);
                    case _SortOption.oldest:
                      return a.date.compareTo(b.date);
                    case _SortOption.titleAZ:
                      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
                    case _SortOption.titleZA:
                      return b.title.toLowerCase().compareTo(a.title.toLowerCase());
                  }
                });
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              size: 48, color: Theme.of(context).hintColor),
                          const SizedBox(height: 12),
                          Text(
                            'This folder is empty',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: items.map((item) {
                      if (item.note != null) {
                        final note = item.note!;
                        final noteFolders = folders
                            .where((f) => f.noteIds.contains(note.id))
                            .toList();
                        final noteFolderNames = noteFolders.map((f) => f.name).toList();
                        final noteFolderColors = {
                          for (final f in noteFolders) f.name: f.colorValue,
                        };
                        final noteProjectNames = allProjects
                            .where((p) => note.projectDocumentIds.contains(p.id))
                            .map((p) => p.title)
                            .toList();
                        return NoteCard(
                          note: note,
                          timestamp: _formatDate(note.createdAt),
                          folderNames: noteFolderNames,
                          folderColors: noteFolderColors,
                          projectNames: noteProjectNames,
                          onTap: () => context.push(
                            AppRoutes.noteDetail,
                            extra: {'noteId': note.id},
                          ),
                          onDelete: () {},
                          onLongPress: () {},
                          onProjectTap: (_) => _showProjectChangePicker(context, ref, note, allProjects),
                          onTagTap: (_) => _showTagManager(context, ref, note),
                        );
                      } else {
                        final project = item.project!;
                        return _FolderProjectCard(
                          project: project,
                          onTap: () => context.push(
                            AppRoutes.projectDocumentDetail,
                            extra: {'documentId': project.id},
                          ),
                          onLongPress: () => _showProjectMoveMenu(context, project),
                        );
                      }
                    }).toList(),
                  ),
                );
              }),
            ],

            // === Notes only ===
            if (_filterOption == _FilterOption.notes) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: folderNotes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.note_rounded,
                                  size: 48,
                                  color: Theme.of(context).hintColor),
                              const SizedBox(height: 12),
                              Text(
                                'No notes in this folder',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: folderNotes.map((note) {
                          final noteFolders = folders
                              .where((f) => f.noteIds.contains(note.id))
                              .toList();
                          final noteFolderNames = noteFolders.map((f) => f.name).toList();
                          final noteFolderColors = {
                            for (final f in noteFolders) f.name: f.colorValue,
                          };
                          final noteProjectNames = allProjects
                              .where((p) => note.projectDocumentIds.contains(p.id))
                              .map((p) => p.title)
                              .toList();
                          return NoteCard(
                            note: note,
                            timestamp: _formatDate(note.createdAt),
                            folderNames: noteFolderNames,
                            folderColors: noteFolderColors,
                            projectNames: noteProjectNames,
                            onTap: () => context.push(
                              AppRoutes.noteDetail,
                              extra: {'noteId': note.id},
                            ),
                            onDelete: () {},
                            onLongPress: () {},
                            onProjectTap: (_) => _showProjectChangePicker(context, ref, note, allProjects),
                            onTagTap: (_) => _showTagManager(context, ref, note),
                          );
                        }).toList(),
                      ),
              ),
            ],

            // === Projects only ===
            if (_filterOption == _FilterOption.projects) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: folderProjects.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.article_rounded,
                                  size: 48,
                                  color: Theme.of(context).hintColor),
                              const SizedBox(height: 12),
                              Text(
                                'No projects in this folder',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: folderProjects
                            .map((project) => _FolderProjectCard(
                                  project: project,
                                  onTap: () => context.push(
                                    AppRoutes.projectDocumentDetail,
                                    extra: {'documentId': project.id},
                                  ),
                                  onLongPress: () => _showProjectMoveMenu(context, project),
                                ))
                            .toList(),
                      ),
              ),
            ],

              const SizedBox(height: 100),
            ],
          ),
        ),
          // Gesture FAB
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: GestureFab(
                sessionCount: ref.watch(settingsProvider).sessionCount,
                showSubtitleHint: ref.watch(settingsProvider).sessionCount <= 10,
                onRecord: () => context.push(AppRoutes.recording,
                    extra: {'folderId': widget.folderId}),
                speedDialItems: [
                  SpeedDialItem(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onTap: () => context.push(AppRoutes.search,
                        extra: {'folderId': widget.folderId}),
                  ),
                  SpeedDialItem(
                    icon: Icons.article_outlined,
                    label: 'New Project',
                    onTap: () => _showNewProjectDialog(context, ref),
                  ),
                  SpeedDialItem(
                    icon: Icons.edit_note_rounded,
                    label: 'Text Note',
                    onTap: () async {
                      final template = await showModalBottomSheet<dynamic>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const TemplatePickerSheet(),
                      );
                      if (!mounted) return;
                      if (template == null) return;
                      final extras = <String, dynamic>{
                        'isNewTextNote': true,
                        'folderId': widget.folderId,
                      };
                      if (template is NoteTemplate) {
                        extras['templateContent'] = template.content;
                        extras['templateTitle'] = template.name;
                      }
                      context.push(AppRoutes.noteDetail, extra: extras);
                    },
                  ),
                  SpeedDialItem(
                    icon: Icons.mic_rounded,
                    label: 'Record Note',
                    onTap: () => context.push(AppRoutes.recording,
                        extra: {'folderId': widget.folderId}),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                folder.name = newName;
                ref
                    .read(foldersProvider.notifier)
                    .updateFolder(folder);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                await ref.read(projectDocumentsProvider.notifier).create(
                      title: title,
                      folderId: widget.folderId,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showProjectMoveMenu(BuildContext context, ProjectDocument project) async {
    final folderId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FolderPickerSheet(excludeFolderId: widget.folderId),
    );
    if (folderId != null && mounted) {
      await ref
          .read(projectDocumentsProvider.notifier)
          .moveProjectToFolder(project.id, folderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project moved to folder')),
        );
      }
    }
  }

  void _showProjectChangePicker(
      BuildContext context, WidgetRef ref, Note note, List<ProjectDocument> allProjects) {
    var projects = List<ProjectDocument>.from(allProjects);
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
              ListTile(
                leading: Icon(Icons.add_circle_outline_rounded,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('New Project'),
                onTap: () async {
                  final name = await _showNewNameDialog(context, 'New Project', 'Project name');
                  if (name != null && name.trim().isNotEmpty) {
                    final allFolders = ref.read(foldersProvider);
                    final general = allFolders.where((f) => f.name == 'General').toList();
                    final folderId = general.isNotEmpty ? general.first.id : null;
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
                  child: Text('No projects yet.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).hintColor)),
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
                        secondary: Icon(Icons.article_rounded,
                            color: isChecked
                                ? Theme.of(context).colorScheme.primary
                                : null),
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
                    color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Text('Manage Labels',
                          style: Theme.of(context).textTheme.titleMedium),
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
                          final tag = controller.text.trim().toLowerCase();
                          if (tag.isNotEmpty && !currentTags.contains(tag)) {
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
                                      style: const TextStyle(fontSize: 12)),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    ref.read(notesProvider.notifier).removeTag(
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
                              ?.copyWith(color: Theme.of(context).hintColor)),
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
                          leading: const Icon(Icons.label_rounded, size: 20),
                          title: Text('#$tag'),
                          subtitle: Text(
                            '$count note${count == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () {
                              ref.read(notesProvider.notifier).addTag(
                                  noteId: note.id, tag: tag);
                              setSheetState(() => currentTags.add(tag));
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  Expanded(
                    child: Center(
                      child: Text('Type a label name above to create one.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor)),
                    ),
                  ),
              ],
            );
          },
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder'),
        content: const Text(
            'Are you sure you want to delete this folder? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(foldersProvider.notifier)
                  .deleteFolder(widget.folderId!);
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  final DateTime date;
  final Note? note;
  final ProjectDocument? project;

  _TimelineItem({required this.date, this.note, this.project});

  String get title => note?.title ?? project?.title ?? '';
}

class _FolderProjectCard extends StatelessWidget {
  final ProjectDocument project;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _FolderProjectCard({required this.project, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final blockCount = project.blocks.length;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.article_rounded,
                  color: Color(0xFF7B1FA2), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$blockCount ${blockCount == 1 ? 'block' : 'blocks'}${project.description != null && project.description!.isNotEmpty ? ' · ${project.description}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20),
          ],
        ),
      ),
    );
  }
}
