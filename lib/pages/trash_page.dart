import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  String _timeAgo(DateTime? deletedAt) {
    if (deletedAt == null) return '';
    final diff = DateTime.now().difference(deletedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  int _daysRemaining(DateTime? deletedAt) {
    if (deletedAt == null) return 30;
    final diff = DateTime.now().difference(deletedAt);
    return (30 - diff.inDays).clamp(0, 30);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers to trigger rebuild when items are restored/deleted
    ref.watch(notesProvider);
    ref.watch(foldersProvider);
    ref.watch(projectDocumentsProvider);

    final trashedNotes = ref.read(notesProvider.notifier).getTrashedNotes();
    final trashedFolders = ref.read(foldersProvider.notifier).getTrashedFolders();
    final trashedProjects =
        ref.read(projectDocumentsProvider.notifier).getTrashedProjects();
    final totalCount =
        trashedNotes.length + trashedFolders.length + trashedProjects.length;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text('Trash ($totalCount)'),
        actions: [
          if (totalCount > 0)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'empty') _confirmEmptyTrash(context, ref);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'empty',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Empty Trash', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: totalCount == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 64, color: theme.hintColor),
                  const SizedBox(height: 16),
                  Text('Trash is empty',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Deleted items will appear here',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Items are permanently deleted after 30 days',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Notes section
                if (trashedNotes.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.description_rounded,
                    label: 'Notes',
                    count: trashedNotes.length,
                  ),
                  ...trashedNotes.map((note) => _TrashItem(
                        title: note.title,
                        subtitle: _timeAgo(note.deletedAt),
                        daysRemaining: _daysRemaining(note.deletedAt),
                        icon: Icons.description_outlined,
                        onRestore: () {
                          ref.read(notesProvider.notifier).restoreNote(note.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${note.title} restored')),
                          );
                        },
                        onDeletePermanently: () =>
                            _confirmPermanentDelete(context, ref, 'note', note.title, () {
                              ref.read(notesProvider.notifier).permanentlyDeleteNote(note.id);
                              ref.read(notesProvider.notifier).refresh();
                            }),
                      )),
                  const SizedBox(height: 12),
                ],

                // Folders section
                if (trashedFolders.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.folder_rounded,
                    label: 'Folders',
                    count: trashedFolders.length,
                  ),
                  ...trashedFolders.map((folder) => _TrashItem(
                        title: folder.name,
                        subtitle: _timeAgo(folder.deletedAt),
                        daysRemaining: _daysRemaining(folder.deletedAt),
                        icon: Icons.folder_outlined,
                        onRestore: () {
                          ref.read(foldersProvider.notifier).restoreFolder(folder.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${folder.name} restored')),
                          );
                        },
                        onDeletePermanently: () =>
                            _confirmPermanentDelete(context, ref, 'folder', folder.name, () {
                              ref.read(foldersProvider.notifier).permanentlyDeleteFolder(folder.id);
                              ref.read(foldersProvider.notifier).refresh();
                            }),
                      )),
                  const SizedBox(height: 12),
                ],

                // Projects section
                if (trashedProjects.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.article_rounded,
                    label: 'Projects',
                    count: trashedProjects.length,
                  ),
                  ...trashedProjects.map((project) => _TrashItem(
                        title: project.title,
                        subtitle: _timeAgo(project.deletedAt),
                        daysRemaining: _daysRemaining(project.deletedAt),
                        icon: Icons.article_outlined,
                        onRestore: () {
                          ref.read(projectDocumentsProvider.notifier).restoreProject(project.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${project.title} restored')),
                          );
                        },
                        onDeletePermanently: () =>
                            _confirmPermanentDelete(context, ref, 'project', project.title, () {
                              ref.read(projectDocumentsProvider.notifier).permanentlyDeleteProject(project.id);
                              ref.read(projectDocumentsProvider.notifier).refresh();
                            }),
                      )),
                ],
              ],
            ),
    );
  }

  void _confirmPermanentDelete(
      BuildContext context, WidgetRef ref, String type, String name, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('This will permanently delete "$name". This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
        title: const Text('Empty Trash?'),
        content: const Text(
            'This will permanently delete all items in Trash. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Permanently delete all trashed items
              final notes = ref.read(notesProvider.notifier).getTrashedNotes();
              for (final n in notes) {
                await ref.read(notesProvider.notifier).permanentlyDeleteNote(n.id);
              }
              final folders = ref.read(foldersProvider.notifier).getTrashedFolders();
              for (final f in folders) {
                await ref.read(foldersProvider.notifier).permanentlyDeleteFolder(f.id);
              }
              final projects = ref.read(projectDocumentsProvider.notifier).getTrashedProjects();
              for (final p in projects) {
                await ref.read(projectDocumentsProvider.notifier).permanentlyDeleteProject(p.id);
              }
              ref.read(notesProvider.notifier).refresh();
              ref.read(foldersProvider.notifier).refresh();
              ref.read(projectDocumentsProvider.notifier).refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trash emptied')),
                );
              }
            },
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.hintColor),
          const SizedBox(width: 6),
          Text('$label ($count)',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _TrashItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final int daysRemaining;
  final IconData icon;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  const _TrashItem({
    required this.title,
    required this.subtitle,
    required this.daysRemaining,
    required this.icon,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: theme.hintColor),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: daysRemaining <= 7
                    ? Colors.red.withValues(alpha: 0.1)
                    : theme.hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${daysRemaining}d left',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: daysRemaining <= 7 ? Colors.red : theme.hintColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'restore') onRestore();
            if (value == 'delete') onDeletePermanently();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Forever', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
