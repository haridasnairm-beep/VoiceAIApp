import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/tags_provider.dart';
import '../models/note.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/gesture_fab.dart';
import '../providers/settings_provider.dart';
import '../widgets/empty_state_illustrated.dart';
import '../widgets/folder_color_picker.dart';

class FoldersPage extends ConsumerWidget {
  const FoldersPage({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allFolders = ref.watch(foldersProvider);
    final folders = allFolders.where((f) => !f.isArchived).toList();
    final archivedFolders = allFolders.where((f) => f.isArchived).toList();
    final tags = ref.watch(tagsProvider);
    final notes = ref.watch(notesProvider);

    // Smart filters
    final now = DateTime.now();
    final thisWeekCount = notes.where((n) =>
        now.difference(n.createdAt).inDays < 7).length;
    final openTaskCount = notes.where((n) =>
        n.todos.any((t) => !t.isCompleted) ||
        n.actions.any((a) => !a.isCompleted)).length;
    final unorganizedCount = notes.where((n) =>
        n.folderId == null && n.tags.isEmpty).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'Your folders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.search),
            icon: Icon(Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            folders.isEmpty
                ? _EmptyLibraryState(
                    onCreateFolder: () => _showNewFolderDialog(context, ref),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Smart Filters
                        if (notes.length >= 3) ...[
                          Text('Smart Filters',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    fontWeight: FontWeight.bold,
                                  )),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (thisWeekCount > 0)
                                _SmartFilterChip(
                                  icon: Icons.date_range_rounded,
                                  label: 'This Week',
                                  count: thisWeekCount,
                                  onTap: () => _showFilteredNotes(
                                    context,
                                    ref,
                                    title: 'This Week',
                                    icon: Icons.date_range_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                    filteredNotes: notes.where((n) =>
                                        now.difference(n.createdAt).inDays < 7).toList()
                                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                                  ),
                                ),
                              if (openTaskCount > 0)
                                _SmartFilterChip(
                                  icon: Icons.task_alt_rounded,
                                  label: 'Open Tasks',
                                  count: openTaskCount,
                                  color: Colors.orange,
                                  onTap: () => _showFilteredNotes(
                                    context,
                                    ref,
                                    title: 'Open Tasks',
                                    icon: Icons.task_alt_rounded,
                                    color: Colors.orange,
                                    filteredNotes: notes.where((n) =>
                                        n.todos.any((t) => !t.isCompleted) ||
                                        n.actions.any((a) => !a.isCompleted)).toList()
                                      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
                                  ),
                                ),
                              if (unorganizedCount > 0)
                                _SmartFilterChip(
                                  icon: Icons.folder_off_outlined,
                                  label: 'Unorganized',
                                  count: unorganizedCount,
                                  color: Theme.of(context).hintColor,
                                  onTap: () => _showFilteredNotes(
                                    context,
                                    ref,
                                    title: 'Unorganized Notes',
                                    icon: Icons.folder_off_outlined,
                                    color: Theme.of(context).hintColor,
                                    filteredNotes: notes.where((n) =>
                                        n.folderId == null && n.tags.isEmpty).toList()
                                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Tags quick-access row
                        if (tags.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () => context.push(AppRoutes.tags),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.label_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${tags.length} ${tags.length == 1 ? 'tag' : 'tags'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Manage',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Theme.of(context).hintColor,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Folders list
                        ...folders.map((folder) {
                          final fc = folderColor(folder.colorValue);
                          return _FolderCard(
                            title: folder.name,
                            noteCount: folder.noteIds.length,
                            projectCount: folder.projectDocumentIds.length,
                            lastActive: _formatDate(folder.updatedAt),
                            icon: Icons.folder_rounded,
                            iconBg: fc.withValues(alpha: 0.15),
                            iconColor: fc,
                            onTap: () => context.push(
                              AppRoutes.folderDetail,
                              extra: {'folderId': folder.id},
                            ),
                          );
                        }),

                        // Archived folders section
                        if (archivedFolders.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _showArchivedSheet(
                                context, ref, archivedFolders),
                            child: Row(
                              children: [
                                Icon(Icons.archive_outlined,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                                const SizedBox(width: 8),
                                Text(
                                  '${archivedFolders.length} archived',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                ),
                                const Spacer(),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18,
                                    color: Theme.of(context).hintColor),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),

            // Gesture FAB with swipe-up to record
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: GestureFab(
                  sessionCount: ref.watch(settingsProvider).sessionCount,
                  showSubtitleHint: ref.watch(settingsProvider).sessionCount <= 10,
                  onRecord: () => context.push(AppRoutes.recording),
                  speedDialItems: [
                    SpeedDialItem(
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Folder',
                      onTap: () => _showNewFolderDialog(context, ref),
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

  void _showNewFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int? selectedColor;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Folder name',
                ),
              ),
              const SizedBox(height: 16),
              Text('Color',
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.secondary)),
              const SizedBox(height: 8),
              FolderColorPicker(
                selectedColorValue: selectedColor,
                onColorSelected: (v) =>
                    setDialogState(() => selectedColor = v),
              ),
            ],
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
                  if (selectedColor != null) {
                    folder.colorValue = selectedColor;
                    await ref
                        .read(foldersProvider.notifier)
                        .updateFolder(folder);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilteredNotes(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Note> filteredNotes,
  }) {
    final folders = ref.read(foldersProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 10),
                    Text(
                      '$title (${filteredNotes.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filteredNotes.isEmpty
                    ? Center(
                        child: Text('No notes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                )),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredNotes.length,
                        itemBuilder: (_, index) {
                          final note = filteredNotes[index];
                          final folderName = folders
                              .where((f) => f.noteIds.contains(note.id))
                              .map((f) => f.name)
                              .toList();
                          String preview = note.rawTranscription;
                          if (note.contentFormat == 'quill_delta' && preview.isNotEmpty) {
                            try {
                              final json = jsonDecode(preview) as List;
                              preview = Document.fromJson(json).toPlainText().trim();
                            } catch (_) {}
                          }
                          final openTasks = note.todos.where((t) => !t.isCompleted).length +
                              note.actions.where((a) => !a.isCompleted).length;
                          return ListTile(
                            leading: Icon(
                              note.audioFilePath.isNotEmpty
                                  ? Icons.mic_rounded
                                  : Icons.edit_note_rounded,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    preview.isEmpty
                                        ? (folderName.isNotEmpty
                                            ? folderName.first
                                            : 'No folder')
                                        : preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                  ),
                                ),
                                if (openTasks > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$openTasks task${openTasks > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              context.push(
                                AppRoutes.noteDetail,
                                extra: {'noteId': note.id},
                              );
                            },
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

  void _showArchivedSheet(
      BuildContext context, WidgetRef ref, List<dynamic> archived) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('Archived Folders',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ...archived.map((folder) => ListTile(
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(folder.name as String),
                  subtitle: Text(
                      '${folder.noteIds.length} notes'),
                  trailing: TextButton(
                    onPressed: () {
                      folder.isArchived = false;
                      ref
                          .read(foldersProvider.notifier)
                          .updateFolder(folder);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Unarchive'),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SmartFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color? color;
  final VoidCallback? onTap;

  const _SmartFilterChip({
    required this.icon,
    required this.label,
    required this.count,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 6),
            Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: c,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(width: 4),
            Text('$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: c,
                    )),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String title;
  final int noteCount;
  final int projectCount;
  final String lastActive;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  const _FolderCard({
    required this.title,
    required this.noteCount,
    required this.projectCount,
    required this.lastActive,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = projectCount > 0
        ? '$noteCount notes · $projectCount projects'
        : '$noteCount notes';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      if (lastActive.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastActive,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary,
                              ),
                        ),
                      ],
                    ],
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

class _EmptyLibraryState extends StatelessWidget {
  final VoidCallback onCreateFolder;

  const _EmptyLibraryState({required this.onCreateFolder});

  @override
  Widget build(BuildContext context) {
    return EmptyStateIllustrated(
      icon: Icons.folder_open_rounded,
      title: 'No folders yet',
      subtitle:
          'Create folders to organize your notes\nand keep ideas grouped together',
      ctaLabel: 'Create a Folder',
      onCta: onCreateFolder,
      iconColor: Theme.of(context).colorScheme.secondary,
    );
  }
}
