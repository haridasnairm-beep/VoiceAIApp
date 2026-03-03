import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/empty_state_illustrated.dart';
import '../theme.dart';

/// Tags management page — list all tags with counts, rename, delete.
class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        centerTitle: false,
      ),
      body: tags.isEmpty
          ? const EmptyStateIllustrated(
              icon: Icons.label_outline_rounded,
              title: 'No tags yet',
              subtitle:
                  'Add tags to your notes to quickly\nfilter and group related content',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final entry = tags[index];
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        '#',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  title: Text('#${entry.tag}'),
                  subtitle: Text(
                    '${entry.count} ${entry.count == 1 ? 'note' : 'notes'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  trailing: PopupMenuButton<_TagAction>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) => _handleAction(
                        context, ref, action, entry.tag),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _TagAction.rename,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _TagAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded,
                              color: Colors.red),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, _TagAction action, String tag) async {
    if (action == _TagAction.rename) {
      await _showRenameDialog(context, ref, tag);
    } else {
      await _showDeleteConfirm(context, ref, tag);
    }
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, String oldTag) async {
    final controller = TextEditingController(text: oldTag);
    final newTag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New tag name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newTag != null && newTag.isNotEmpty && newTag != oldTag) {
      await ref.read(notesProvider.notifier).renameTag(oldTag, newTag);
    }
  }

  Future<void> _showDeleteConfirm(
      BuildContext context, WidgetRef ref, String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
            'Remove "#$tag" from all notes? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notesProvider.notifier).deleteTag(tag);
    }
  }
}

enum _TagAction { rename, delete }
