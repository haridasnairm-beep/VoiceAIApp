import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../models/project_block.dart';
import '../models/note.dart';
import '../providers/project_documents_provider.dart';
import '../providers/notes_provider.dart';

class ProjectDocumentDetailPage extends ConsumerStatefulWidget {
  final String? documentId;

  const ProjectDocumentDetailPage({super.key, this.documentId});

  @override
  ConsumerState<ProjectDocumentDetailPage> createState() =>
      _ProjectDocumentDetailPageState();
}

class _ProjectDocumentDetailPageState
    extends ConsumerState<ProjectDocumentDetailPage> {
  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(projectDocumentsProvider);
    final doc = documents.where((d) => d.id == widget.documentId).firstOrNull;
    final allNotes = ref.watch(notesProvider);

    if (doc == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) context.pop();
              else context.go(AppRoutes.projectDocuments);
            },
          ),
          title: const Text('Project'),
        ),
        body: const Center(child: Text('Project not found')),
      );
    }

    final sortedBlocks = List.of(doc.blocks)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go(AppRoutes.projectDocuments);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (doc.description != null && doc.description!.isNotEmpty)
              Text(
                doc.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') _showRenameDialog(context, doc);
              if (value == 'delete') _showDeleteDialog(context, doc);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: sortedBlocks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.widgets_outlined,
                      size: 64, color: Theme.of(context).hintColor),
                  const SizedBox(height: 16),
                  Text(
                    'No blocks yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first block',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
              itemCount: sortedBlocks.length,
              itemBuilder: (context, index) {
                final block = sortedBlocks[index];
                return _buildBlockCard(
                  context,
                  doc,
                  block,
                  allNotes,
                  index: index,
                  total: sortedBlocks.length,
                  sortedBlocks: sortedBlocks,
                );
              },
            ),
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddBlockSheet(context, doc.id),
              icon: Icon(Icons.add_rounded,
                  color: Theme.of(context).colorScheme.onPrimary),
              label: Text('Add Block',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    dynamic doc,
    ProjectBlock block,
    List<Note> allNotes, {
    required int index,
    required int total,
    required List<ProjectBlock> sortedBlocks,
  }) {
    final isFirst = index == 0;
    final isLast = index == total - 1;

    void onMoveUp() {
      if (isFirst) return;
      final blockIds = sortedBlocks.map((b) => b.id).toList();
      final id = blockIds.removeAt(index);
      blockIds.insert(index - 1, id);
      ref
          .read(projectDocumentsProvider.notifier)
          .reorderBlocks(doc.id, blockIds);
    }

    void onMoveDown() {
      if (isLast) return;
      final blockIds = sortedBlocks.map((b) => b.id).toList();
      final id = blockIds.removeAt(index);
      blockIds.insert(index + 1, id);
      ref
          .read(projectDocumentsProvider.notifier)
          .reorderBlocks(doc.id, blockIds);
    }

    switch (block.type) {
      case BlockType.noteReference:
        return _NoteReferenceCard(
          block: block,
          allNotes: allNotes,
          isFirst: isFirst,
          isLast: isLast,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () => ref
              .read(projectDocumentsProvider.notifier)
              .removeBlock(doc.id, block.id),
          onViewOriginal: () {
            if (block.noteId != null) {
              context.push(AppRoutes.noteDetail,
                  extra: {'noteId': block.noteId});
            }
          },
          onViewHistory: () {
            if (block.noteId != null) {
              context.push(AppRoutes.versionHistory,
                  extra: {'noteId': block.noteId});
            }
          },
          onSaveEdit: (newText) {
            if (block.noteId != null) {
              ref.read(projectDocumentsProvider.notifier).editNoteTranscript(
                    documentId: doc.id,
                    noteId: block.noteId!,
                    newText: newText,
                    documentTitle: doc.title,
                  );
            }
          },
        );
      case BlockType.freeText:
        return _FreeTextCard(
          block: block,
          isFirst: isFirst,
          isLast: isLast,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () => ref
              .read(projectDocumentsProvider.notifier)
              .removeBlock(doc.id, block.id),
          onSave: (newContent) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContent(doc.id, block.id, newContent),
        );
      case BlockType.sectionHeader:
        return _SectionHeaderCard(
          block: block,
          isFirst: isFirst,
          isLast: isLast,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () => ref
              .read(projectDocumentsProvider.notifier)
              .removeBlock(doc.id, block.id),
          onSave: (newContent) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContent(doc.id, block.id, newContent),
        );
    }
  }

  void _showAddBlockSheet(BuildContext context, String documentId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: const Text('Add Voice Note'),
              subtitle: const Text('Select from existing notes'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(AppRoutes.notePickerRoute,
                    extra: {'documentId': documentId});
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Add Free Text'),
              subtitle: const Text('Type your own content'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(projectDocumentsProvider.notifier)
                    .addFreeTextBlock(documentId, '');
              },
            ),
            ListTile(
              leading: const Icon(Icons.title_rounded),
              title: const Text('Add Section Header'),
              subtitle: const Text('Organize with headings'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(projectDocumentsProvider.notifier)
                    .addSectionHeaderBlock(documentId, 'New Section');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, dynamic doc) {
    final controller = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Project'),
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
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                doc.title = name;
                ref
                    .read(projectDocumentsProvider.notifier)
                    .updateDocument(doc);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
            'Delete "${doc.title}"? This will not delete any linked notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectDocumentsProvider.notifier).delete(doc.id);
              Navigator.of(ctx).pop();
              if (context.canPop()) context.pop();
              else context.go(AppRoutes.projectDocuments);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// --- Shared helpers ---

String _formatTimestamp(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final min = dt.minute.toString().padLeft(2, '0');
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$min $ampm';
}

// --- Block Card Widgets ---

class _NoteReferenceCard extends StatefulWidget {
  final ProjectBlock block;
  final List<Note> allNotes;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final VoidCallback onViewOriginal;
  final VoidCallback onViewHistory;
  final void Function(String) onSaveEdit;

  const _NoteReferenceCard({
    required this.block,
    required this.allNotes,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onViewOriginal,
    required this.onViewHistory,
    required this.onSaveEdit,
  });

  @override
  State<_NoteReferenceCard> createState() => _NoteReferenceCardState();
}

class _NoteReferenceCardState extends State<_NoteReferenceCard> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDetailsDialog(BuildContext context, Note note) {
    final duration = note.audioDurationSeconds > 0
        ? '${note.audioDurationSeconds ~/ 60}:${(note.audioDurationSeconds % 60).toString().padLeft(2, '0')}'
        : 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Title', value: note.title),
            const SizedBox(height: 8),
            _DetailRow(
                label: 'Recorded',
                value: _formatTimestamp(note.createdAt)),
            const SizedBox(height: 8),
            _DetailRow(
                label: 'Language',
                value: note.detectedLanguage.toUpperCase()),
            const SizedBox(height: 8),
            _DetailRow(label: 'Duration', value: duration),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note =
        widget.allNotes.where((n) => n.id == widget.block.noteId).firstOrNull;

    if (note == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded,
                size: 16, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('This note has been deleted',
                    style: TextStyle(fontSize: 13))),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content area
          Expanded(
            child: _editing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: null,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _editing = false),
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () {
                              widget.onSaveEdit(_controller.text);
                              setState(() => _editing = false);
                            },
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      _controller.text = note.rawTranscription;
                      setState(() => _editing = true);
                    },
                    child: Text(
                      note.rawTranscription.isEmpty
                          ? 'No transcript — tap to add'
                          : note.rawTranscription,
                      style: TextStyle(
                        fontSize: 14,
                        color: note.rawTranscription.isEmpty
                            ? Theme.of(context).hintColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
          ),

          // 3-dot menu (top-right)
          SizedBox(
            width: 28,
            height: 28,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) {
                if (value == 'move_up') widget.onMoveUp();
                if (value == 'move_down') widget.onMoveDown();
                if (value == 'details') _showDetailsDialog(context, note);
                if (value == 'original') widget.onViewOriginal();
                if (value == 'history') widget.onViewHistory();
                if (value == 'remove') widget.onRemove();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'move_up',
                  enabled: !widget.isFirst,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move up'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'move_down',
                  enabled: !widget.isLast,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move down'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'original',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_new, size: 18),
                      SizedBox(width: 8),
                      Text('View original note'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Version history'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert,
                  size: 18, color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeTextCard extends StatefulWidget {
  final ProjectBlock block;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String) onSave;

  const _FreeTextCard({
    required this.block,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onSave,
  });

  @override
  State<_FreeTextCard> createState() => _FreeTextCardState();
}

class _FreeTextCardState extends State<_FreeTextCard> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content ?? '');
  }

  @override
  void didUpdateWidget(covariant _FreeTextCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _controller.text = widget.block.content ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: 'Free Text'),
            const SizedBox(height: 8),
            _DetailRow(
                label: 'Created',
                value: _formatTimestamp(widget.block.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content area
          Expanded(
            child: _editing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: null,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          isDense: true,
                          hintText: 'Type your text here...',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _editing = false),
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () {
                              widget.onSave(_controller.text);
                              setState(() => _editing = false);
                            },
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: Text(
                      (widget.block.content ?? '').isEmpty
                          ? 'Tap to add text...'
                          : widget.block.content!,
                      style: TextStyle(
                        fontSize: 14,
                        color: (widget.block.content ?? '').isEmpty
                            ? Theme.of(context).hintColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
          ),

          // 3-dot menu (top-right)
          SizedBox(
            width: 28,
            height: 28,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) {
                if (value == 'move_up') widget.onMoveUp();
                if (value == 'move_down') widget.onMoveDown();
                if (value == 'details') _showDetailsDialog(context);
                if (value == 'remove') widget.onRemove();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'move_up',
                  enabled: !widget.isFirst,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move up'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'move_down',
                  enabled: !widget.isLast,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move down'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Details'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert,
                  size: 18, color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderCard extends StatefulWidget {
  final ProjectBlock block;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String) onSave;

  const _SectionHeaderCard({
    required this.block,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onSave,
  });

  @override
  State<_SectionHeaderCard> createState() => _SectionHeaderCardState();
}

class _SectionHeaderCardState extends State<_SectionHeaderCard> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content ?? '');
  }

  @override
  void didUpdateWidget(covariant _SectionHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _controller.text = widget.block.content ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DetailRow(label: 'Type', value: 'Section Header'),
            const SizedBox(height: 8),
            _DetailRow(
                label: 'Created',
                value: _formatTimestamp(widget.block.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content area
          Expanded(
            child: _editing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          hintText: 'Section title',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _editing = false),
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () {
                              widget.onSave(_controller.text);
                              setState(() => _editing = false);
                            },
                            style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: Text(
                      widget.block.content ?? 'Section Header',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
          ),

          // 3-dot menu (top-right)
          SizedBox(
            width: 28,
            height: 28,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) {
                if (value == 'move_up') widget.onMoveUp();
                if (value == 'move_down') widget.onMoveDown();
                if (value == 'details') _showDetailsDialog(context);
                if (value == 'remove') widget.onRemove();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'move_up',
                  enabled: !widget.isFirst,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move up'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'move_down',
                  enabled: !widget.isLast,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Move down'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Details'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Remove'),
                    ],
                  ),
                ),
              ],
              icon: Icon(Icons.more_vert,
                  size: 18, color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Detail Row helper for Details dialog ---

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
