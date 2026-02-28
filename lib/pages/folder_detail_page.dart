import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../models/folder.dart';
import '../models/note.dart';

enum _SortOption { newest, oldest, titleAZ, titleZA }

class FolderDetailPage extends ConsumerStatefulWidget {
  final String? folderId;

  const FolderDetailPage({super.key, this.folderId});

  @override
  ConsumerState<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends ConsumerState<FolderDetailPage> {
  _SortOption _sortOption = _SortOption.newest;

  String get folderId => widget.folderId ?? '';

  String _plainTextPreview(Note note) {
    if (note.contentFormat == 'quill_delta' && note.rawTranscription.isNotEmpty) {
      try {
        final json = jsonDecode(note.rawTranscription) as List;
        return Document.fromJson(json).toPlainText().trim();
      } catch (_) {
        return note.rawTranscription;
      }
    }
    return note.rawTranscription;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day';
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

    // Get notes that belong to this folder
    final allNotes = ref.watch(notesProvider);
    final folderNotes = _sortNotes(
        allNotes.where((n) => n.folderId == widget.folderId).toList());

    // Calculate total audio duration
    int totalSeconds = 0;
    for (final note in folderNotes) {
      totalSeconds += note.audioDurationSeconds;
    }
    final totalAudio = '${totalSeconds ~/ 60}m';

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
              '${folder.noteIds.length} voice notes',
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
                if (value == 'rename') {
                  _showRenameDialog(context, folder!);
                } else if (value == 'delete') {
                  _showDeleteDialog(context);
                }
              },
              itemBuilder: (ctx) => [
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.recording, extra: {'folderId': widget.folderId}),
        icon: Icon(Icons.mic_rounded,
            color: Theme.of(context).colorScheme.onPrimary),
        label: Text('Record Note',
            style:
                TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
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
                ],
              ),
            ),

            // Recent Notes Header
              Padding(
                padding:
                    const EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Notes',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurface,
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
                              color:
                                  Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel(_sortOption),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes List
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
                        children: [
                          ...folderNotes.map((note) => _FolderNoteCard(
                                title: note.title,
                                lang: note.detectedLanguage,
                                preview: _plainTextPreview(note),
                                hasTasks: note.todos.isNotEmpty,
                                taskCount: '${note.todos.length}',
                                hasReminders: note.reminders.isNotEmpty,
                                reminderCount:
                                    '${note.reminders.length}',
                                date: _formatDate(note.createdAt),
                                onTap: () => context.push(
                                  AppRoutes.noteDetail,
                                  extra: {'noteId': note.id},
                                ),
                              )),
                          const SizedBox(height: 80),
                        ],
                      ),
              ),
            ],
          ),
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

class _FolderNoteCard extends StatelessWidget {
  final String title;
  final String lang;
  final String preview;
  final bool hasTasks;
  final String taskCount;
  final bool hasReminders;
  final String reminderCount;
  final String date;
  final VoidCallback? onTap;

  const _FolderNoteCard({
    required this.title,
    required this.lang,
    required this.preview,
    required this.hasTasks,
    required this.taskCount,
    required this.hasReminders,
    required this.reminderCount,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border:
                        Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language,
                          size: 12,
                          color:
                              Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        lang,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (hasTasks)
                      Row(
                        children: [
                          const Icon(Icons.task_alt_rounded,
                              size: 16, color: AppColors.lightSuccess),
                          const SizedBox(width: 4),
                          Text(
                            taskCount,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    if (hasReminders)
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              size: 16, color: AppColors.lightAccent),
                          const SizedBox(width: 4),
                          Text(
                            reminderCount,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
