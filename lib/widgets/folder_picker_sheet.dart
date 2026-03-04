import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/folders_provider.dart';
import '../theme.dart';
import 'folder_color_picker.dart';

/// Reusable bottom sheet for picking a folder.
///
/// Returns the selected folder ID, or null if cancelled.
/// [excludeFolderId] hides the current folder from the list.
class FolderPickerSheet extends ConsumerStatefulWidget {
  final String? excludeFolderId;

  const FolderPickerSheet({this.excludeFolderId, super.key});

  @override
  ConsumerState<FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends ConsumerState<FolderPickerSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final allFolders = ref.watch(foldersProvider);
    final folders = allFolders
        .where((f) => !f.isArchived && f.id != widget.excludeFolderId)
        .toList();
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
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
              color: theme.hintColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text('Move to Folder',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _selectedId == null
                      ? null
                      : () => Navigator.of(context).pop(_selectedId),
                  child: const Text('Move'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.create_new_folder_rounded,
                color: theme.colorScheme.primary),
            title: const Text('New Folder'),
            onTap: () async {
              final name = await _showNewFolderDialog(context);
              if (name != null && name.trim().isNotEmpty) {
                final folder = await ref
                    .read(foldersProvider.notifier)
                    .addFolder(name: name.trim());
                setState(() => _selectedId = folder.id);
              }
            },
          ),
          const Divider(height: 1),
          if (folders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No other folders available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: folders.length,
                itemBuilder: (_, index) {
                  final folder = folders[index];
                  final isSelected = _selectedId == folder.id;
                  final fc = folderColor(folder.colorValue);
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: fc.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.folder_rounded,
                          color: fc, size: 20),
                    ),
                    title: Text(folder.name),
                    subtitle: Text(
                      '${folder.noteIds.length} notes · ${folder.projectDocumentIds.length} projects',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () => setState(() => _selectedId = folder.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<String?> _showNewFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
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
              if (name.isNotEmpty) Navigator.of(ctx).pop(name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
