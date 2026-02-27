import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../providers/project_documents_provider.dart';
import '../models/project_block.dart';

class NotePickerPage extends ConsumerStatefulWidget {
  final String? documentId;

  const NotePickerPage({super.key, this.documentId});

  @override
  ConsumerState<NotePickerPage> createState() => _NotePickerPageState();
}

class _NotePickerPageState extends ConsumerState<NotePickerPage> {
  final Set<String> _selectedNoteIds = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final documents = ref.watch(projectDocumentsProvider);
    final doc =
        documents.where((d) => d.id == widget.documentId).firstOrNull;

    // Get already-linked note IDs for this document
    final linkedNoteIds = <String>{};
    if (doc != null) {
      for (final block in doc.blocks) {
        if (block.type == BlockType.noteReference && block.noteId != null) {
          linkedNoteIds.add(block.noteId!);
        }
      }
    }

    // Filter notes by search
    final filteredNotes = _searchQuery.isEmpty
        ? allNotes
        : allNotes.where((n) {
            final lower = _searchQuery.toLowerCase();
            return n.title.toLowerCase().contains(lower) ||
                n.rawTranscription.toLowerCase().contains(lower);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: const Text('Add Voice Notes'),
        actions: [
          TextButton(
            onPressed: _selectedNoteIds.isEmpty
                ? null
                : () async {
                    for (final noteId in _selectedNoteIds) {
                      await ref
                          .read(projectDocumentsProvider.notifier)
                          .addNoteBlock(widget.documentId!, noteId);
                    }
                    if (context.mounted && context.canPop()) context.pop();
                  },
            child: Text('Add (${_selectedNoteIds.length})'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Notes list
          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Text(
                      'No notes found',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final isLinked = linkedNoteIds.contains(note.id);
                      final isSelected = _selectedNoteIds.contains(note.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedNoteIds.add(note.id);
                            } else {
                              _selectedNoteIds.remove(note.id);
                            }
                          });
                        },
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              _formatDate(note.createdAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                            ),
                            if (isLinked) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Linked',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        secondary: const Icon(Icons.mic_rounded),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}
