import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../providers/project_documents_provider.dart';
import '../models/project_block.dart';

class NotePickerPage extends ConsumerStatefulWidget {
  final String? documentId;
  /// Filter: 'voice' = only voice notes (V prefix), 'text' = only text notes (T prefix), null = all
  final String? filterType;

  const NotePickerPage({super.key, this.documentId, this.filterType});

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

    // Helper: a note is a voice note if it has an audio file OR its title
    // starts with the voice-note prefix pattern (V1, V2, ...).
    // Live STT mode produces voice notes without audio files, so we must
    // also check the title prefix to correctly classify them.
    bool isVoiceNote(n) =>
        n.audioFilePath.isNotEmpty ||
        RegExp(r'^V\d+').hasMatch(n.title);

    // Filter by type first
    final typeFiltered = widget.filterType == 'voice'
        ? allNotes.where((n) => isVoiceNote(n)).toList()
        : widget.filterType == 'text'
            ? allNotes.where((n) => !isVoiceNote(n)).toList()
            : allNotes;

    // Then filter by search
    final filteredNotes = _searchQuery.isEmpty
        ? typeFiltered
        : typeFiltered.where((n) {
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
        title: Text(widget.filterType == 'text'
            ? 'Add Text Notes'
            : widget.filterType == 'voice'
                ? 'Add Voice Notes'
                : 'Add Notes'),
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
                        secondary: Icon(isVoiceNote(note)
                            ? Icons.mic_rounded
                            : Icons.edit_note_rounded),
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
