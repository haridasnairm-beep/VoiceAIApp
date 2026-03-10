import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../nav.dart';
import '../theme.dart';
import '../models/project_block.dart';
import '../models/note.dart';
import '../providers/project_documents_provider.dart';
import '../providers/notes_provider.dart';
import '../services/sharing_service.dart';
import '../services/image_attachment_repository.dart';
import '../widgets/image_block_widget.dart';
import '../widgets/share_preview_sheet.dart';
import '../widgets/find_replace_bar.dart';
import '../widgets/gesture_fab.dart';
import '../widgets/speed_dial_fab.dart';
import '../widgets/template_picker_sheet.dart';
import '../constants/note_templates.dart';
import '../providers/settings_provider.dart';

import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

// Preset font colors for the color picker
const _fontColors = <Color>[
  Color(0xFFFFFFFF), // White
  Color(0xFFE53E3E), // Red
  Color(0xFFF6AD55), // Orange
  Color(0xFFECC94B), // Yellow
  Color(0xFF38A169), // Green
  Color(0xFF4A90E2), // Blue
  Color(0xFF9F7AEA), // Purple
  Color(0xFFED64A6), // Pink
];

// Font size presets: small, normal, large
const _fontSizes = <(String label, double? size)>[
  ('S', 12),
  ('M', null), // null = default/normal
  ('L', 20),
];

/// Builds a custom rich-text toolbar with visible icons in all themes.
Widget buildQuillToolbar(QuillController controller, ThemeData theme,
    {bool showHeaders = true, bool showBullets = true, bool showColor = true, bool showSize = true}) {
  return ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final style = controller.getSelectionStyle();
      final isBold = style.attributes.containsKey(Attribute.bold.key);
      final isItalic = style.attributes.containsKey(Attribute.italic.key);
      final isBulletList = style.attributes[Attribute.list.key]?.value == 'bullet';
      final headerLevel = style.attributes[Attribute.header.key]?.value;

      // Current font color
      final colorAttr = style.attributes[Attribute.color.key];
      final currentColorHex = colorAttr?.value as String?;

      // Current font size
      final sizeAttr = style.attributes[Attribute.size.key];
      final currentSize = sizeAttr?.value;

      Widget btn(IconData icon, bool active, VoidCallback onTap) {
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(Icons.format_bold, isBold, () {
                controller.formatSelection(
                  isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold,
                );
              }),
              btn(Icons.format_italic, isItalic, () {
                controller.formatSelection(
                  isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic,
                );
              }),
              if (showBullets)
                btn(Icons.format_list_bulleted, isBulletList, () {
                  controller.formatSelection(
                    isBulletList ? Attribute.clone(Attribute.list, null) : Attribute.ul,
                  );
                }),
              if (showHeaders) ...[
                btn(Icons.title, headerLevel == 1, () {
                  controller.formatSelection(
                    headerLevel == 1 ? Attribute.clone(Attribute.header, null) : Attribute.h1,
                  );
                }),
                btn(Icons.format_size, headerLevel == 2, () {
                  controller.formatSelection(
                    headerLevel == 2 ? Attribute.clone(Attribute.header, null) : Attribute.h2,
                  );
                }),
              ],
              if (showSize) ...[
                // Divider
                Container(
                  width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.dividerColor,
                ),
                // Font size buttons: S / M / L
                for (final entry in _fontSizes)
                  _FontSizeButton(
                    label: entry.$1,
                    active: entry.$2 == null
                        ? (currentSize == null || currentSize == 'null')
                        : currentSize?.toString() == entry.$2.toString(),
                    theme: theme,
                    onTap: () {
                      if (entry.$2 == null) {
                        controller.formatSelection(Attribute.clone(Attribute.size, null));
                      } else {
                        controller.formatSelection(Attribute.fromKeyValue('size', entry.$2));
                      }
                    },
                  ),
              ],
              if (showColor) ...[
                // Divider
                Container(
                  width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.dividerColor,
                ),
                // Color picker button
                _ColorPickerButton(
                  controller: controller,
                  currentColorHex: currentColorHex,
                  theme: theme,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _FontSizeButton extends StatelessWidget {
  final String label;
  final bool active;
  final ThemeData theme;
  final VoidCallback onTap;

  const _FontSizeButton({
    required this.label,
    required this.active,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final QuillController controller;
  final String? currentColorHex;
  final ThemeData theme;

  const _ColorPickerButton({
    required this.controller,
    required this.currentColorHex,
    required this.theme,
  });

  Color? _parseColor(String? hex) {
    if (hex == null || hex == 'null') return null;
    final clean = hex.replaceFirst('#', '').replaceFirst('ff', '');
    try {
      return Color(int.parse('ff$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _parseColor(currentColorHex);
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _showColorMenu(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: activeColor != null ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          Icons.format_color_text_rounded,
          size: 20,
          color: activeColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // Sentinel color to represent "reset to default"
  static const _resetSentinel = Color(0x00000001);

  void _showColorMenu(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);

    showMenu<Color?>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 60,
        offset.dx + box.size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem<Color?>(
          value: _resetSentinel,
          height: 48,
          child: Row(
            children: [
              Icon(Icons.format_color_reset_rounded, size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 8),
              Text('Default', style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
        PopupMenuItem<Color?>(
          enabled: false,
          height: 48,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _fontColors.map((c) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(c);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 1.5),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).then((color) {
      if (color == null) return; // menu dismissed
      if (color == _resetSentinel) {
        controller.formatSelection(Attribute.clone(Attribute.color, null));
      } else {
        final hexStr = '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';
        controller.formatSelection(Attribute.fromKeyValue('color', hexStr));
      }
    });
  }
}

class ProjectDocumentDetailPage extends ConsumerStatefulWidget {
  final String? documentId;

  const ProjectDocumentDetailPage({super.key, this.documentId});

  @override
  ConsumerState<ProjectDocumentDetailPage> createState() =>
      _ProjectDocumentDetailPageState();
}

class _ProjectDocumentDetailPageState
    extends ConsumerState<ProjectDocumentDetailPage> {
  // Inline title editing
  bool _isEditingTitle = false;
  final TextEditingController _titleController = TextEditingController();

  // Find & Replace state
  bool _showFindBar = false;
  String _searchQuery = '';
  List<({String blockId, String? noteId, BlockType blockType, int start, int end})> _findMatches = [];
  int _currentMatchIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startEditTitle(dynamic doc) {
    _titleController.text = doc.title;
    setState(() => _isEditingTitle = true);
  }

  void _saveTitle(dynamic doc) {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != doc.title) {
      doc.title = newTitle;
      ref.read(projectDocumentsProvider.notifier).updateDocument(doc);
    }
    setState(() => _isEditingTitle = false);
  }

  String _blockPlainText(ProjectBlock block) {
    final content = block.content ?? '';
    if (block.contentFormat == 'quill_delta' && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as List;
        return Document.fromJson(json).toPlainText().trim();
      } catch (_) {}
    }
    return content;
  }

  String _notePlainText(Note note) {
    if (note.contentFormat == 'quill_delta' && note.rawTranscription.isNotEmpty) {
      try {
        final json = jsonDecode(note.rawTranscription) as List;
        return Document.fromJson(json).toPlainText().trim();
      } catch (_) {}
    }
    return note.rawTranscription;
  }

  void _performSearch(String query) {
    final doc = ref.read(projectDocumentsProvider)
        .where((d) => d.id == widget.documentId).firstOrNull;
    if (doc == null) {
      setState(() { _searchQuery = query; _findMatches = []; });
      return;
    }
    final allNotes = ref.read(notesProvider);
    final sortedBlocks = List.of(doc.blocks)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final matches = <({String blockId, String? noteId, BlockType blockType, int start, int end})>[];

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      for (final block in sortedBlocks) {
        String plainText = '';
        String? noteId;
        if (block.type == BlockType.noteReference) {
          noteId = block.noteId;
          final note = allNotes.where((n) => n.id == block.noteId).firstOrNull;
          if (note != null) plainText = _notePlainText(note);
        } else if (block.type == BlockType.sectionHeader || block.type == BlockType.freeText) {
          plainText = _blockPlainText(block);
        } else {
          continue;
        }
        final lowerText = plainText.toLowerCase();
        int searchFrom = 0;
        while (true) {
          final idx = lowerText.indexOf(lowerQuery, searchFrom);
          if (idx == -1) break;
          matches.add((
            blockId: block.id, noteId: noteId,
            blockType: block.type, start: idx, end: idx + query.length,
          ));
          searchFrom = idx + 1;
        }
      }
    }
    setState(() {
      _searchQuery = query;
      _findMatches = matches;
      _currentMatchIndex = 0;
    });
  }

  void _navigateMatch(int delta) {
    if (_findMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + delta) % _findMatches.length;
      if (_currentMatchIndex < 0) _currentMatchIndex = _findMatches.length - 1;
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_findMatches.isEmpty || !_scrollController.hasClients) return;
    final match = _findMatches[_currentMatchIndex];
    final doc = ref.read(projectDocumentsProvider)
        .where((d) => d.id == widget.documentId).firstOrNull;
    if (doc == null) return;
    final sortedBlocks = List.of(doc.blocks)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final blockIndex = sortedBlocks.indexWhere((b) => b.id == match.blockId);
    if (blockIndex >= 0) {
      final targetOffset = (blockIndex * 80.0)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(targetOffset,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _replaceCurrentMatch(String replacement) {
    if (_findMatches.isEmpty) return;
    final match = _findMatches[_currentMatchIndex];
    _replaceMatch(match, replacement);
    Future.microtask(() => _performSearch(_searchQuery));
  }

  void _replaceAllMatches(String replacement) {
    if (_findMatches.isEmpty) return;
    // Group by block, replace in reverse order to preserve positions
    final grouped = <String, List<({String blockId, String? noteId, BlockType blockType, int start, int end})>>{};
    for (final m in _findMatches) {
      grouped.putIfAbsent(m.blockId, () => []).add(m);
    }
    for (final blockMatches in grouped.values) {
      final sorted = List.of(blockMatches)
        ..sort((a, b) => b.start.compareTo(a.start));
      for (final match in sorted) {
        _replaceMatch(match, replacement);
      }
    }
    Future.microtask(() => _performSearch(_searchQuery));
  }

  void _replaceMatch(
    ({String blockId, String? noteId, BlockType blockType, int start, int end}) match,
    String replacement,
  ) {
    final doc = ref.read(projectDocumentsProvider)
        .where((d) => d.id == widget.documentId).firstOrNull;
    if (doc == null) return;

    if (match.blockType == BlockType.noteReference && match.noteId != null) {
      final allNotes = ref.read(notesProvider);
      final note = allNotes.where((n) => n.id == match.noteId).firstOrNull;
      if (note == null) return;
      if (note.contentFormat == 'quill_delta') {
        try {
          final json = jsonDecode(note.rawTranscription) as List;
          final quillDoc = Document.fromJson(json);
          quillDoc.delete(match.start, match.end - match.start);
          quillDoc.insert(match.start, replacement);
          ref.read(projectDocumentsProvider.notifier).editNoteTranscriptRich(
            documentId: doc.id, noteId: match.noteId!,
            newContent: jsonEncode(quillDoc.toDelta().toJson()),
            contentFormat: 'quill_delta', documentTitle: doc.title,
          );
          return;
        } catch (_) {}
      }
      final text = note.rawTranscription;
      final newText = text.substring(0, match.start) + replacement + text.substring(match.end);
      ref.read(projectDocumentsProvider.notifier).editNoteTranscript(
        documentId: doc.id, noteId: match.noteId!,
        newText: newText, documentTitle: doc.title,
      );
    } else {
      final block = doc.blocks.where((b) => b.id == match.blockId).firstOrNull;
      if (block == null) return;
      if (block.contentFormat == 'quill_delta') {
        try {
          final json = jsonDecode(block.content!) as List;
          final quillDoc = Document.fromJson(json);
          quillDoc.delete(match.start, match.end - match.start);
          quillDoc.insert(match.start, replacement);
          ref.read(projectDocumentsProvider.notifier).updateBlockContentFormat(
            doc.id, block.id,
            jsonEncode(quillDoc.toDelta().toJson()), 'quill_delta',
          );
          return;
        } catch (_) {}
      }
      final text = block.content ?? '';
      final newText = text.substring(0, match.start) + replacement + text.substring(match.end);
      ref.read(projectDocumentsProvider.notifier).updateBlockContent(doc.id, block.id, newText);
    }
  }

  /// Get the active match range for a block, or null.
  ({int start, int end})? _activeMatchForBlock(String blockId) {
    if (_findMatches.isEmpty) return null;
    final current = _findMatches[_currentMatchIndex];
    if (current.blockId != blockId) return null;
    return (start: current.start, end: current.end);
  }

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
        title: _isEditingTitle
            ? TextField(
                controller: _titleController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _saveTitle(doc),
              )
            : GestureDetector(
                onTap: () => _startEditTitle(doc),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            doc.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.edit_rounded,
                            size: 16, color: Theme.of(context).hintColor),
                      ],
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
              ),
        actions: [
          if (_isEditingTitle)
            IconButton(
              icon: Icon(Icons.check_rounded,
                  color: Theme.of(context).colorScheme.primary),
              onPressed: () => _saveTitle(doc),
            )
          else ...[
            IconButton(
              icon: Icon(_showFindBar ? Icons.search_off_rounded : Icons.find_replace_rounded),
              tooltip: 'Find & Replace',
              onPressed: () => setState(() {
                _showFindBar = !_showFindBar;
                if (!_showFindBar) {
                  _searchQuery = '';
                  _findMatches = [];
                }
              }),
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share',
              onPressed: () => _shareDocument(doc, allNotes),
            ),
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
        ],
      ),
      body: Column(
        children: [
          if (_showFindBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: FindReplaceBar(
                onSearch: _performSearch,
                onReplace: _replaceCurrentMatch,
                onReplaceAll: _replaceAllMatches,
                onNext: () => _navigateMatch(1),
                onPrevious: () => _navigateMatch(-1),
                onClose: () => setState(() {
                  _showFindBar = false;
                  _searchQuery = '';
                  _findMatches = [];
                }),
                currentMatch: _currentMatchIndex,
                totalMatches: _findMatches.length,
              ),
            ),
          Expanded(
            child: Stack(
        children: [
          sortedBlocks.isEmpty
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
                  controller: _scrollController,
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
          if (MediaQuery.of(context).viewInsets.bottom == 0)
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
                      extra: {'projectId': doc.id}),
                  speedDialItems: [
                    SpeedDialItem(
                      icon: Icons.image_rounded,
                      label: 'Add Image',
                      onTap: () => _pickAndAddImage(doc.id),
                    ),
                    SpeedDialItem(
                      icon: Icons.checklist_rounded,
                      label: 'Tasks',
                      onTap: () => _showAddTaskSheet(context, doc.id),
                    ),
                    SpeedDialItem(
                      icon: Icons.title_rounded,
                      label: 'Section Header',
                      onTap: () => ref
                          .read(projectDocumentsProvider.notifier)
                          .addSectionHeaderBlock(doc.id, 'New Section'),
                    ),
                    SpeedDialItem(
                      icon: Icons.edit_note_rounded,
                      label: 'Add Text Note',
                      onTap: () => _showAddTextNoteSheet(context, doc.id),
                    ),
                    SpeedDialItem(
                      icon: Icons.mic_rounded,
                      label: 'Add Voice Note',
                      onTap: () => _showAddVoiceNoteSheet(context, doc.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
          ), // Expanded
        ], // Column
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
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          activeMatchRange: _activeMatchForBlock(block.id),
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
          onSaveRichEdit: (content, format) {
            if (block.noteId != null) {
              ref
                  .read(projectDocumentsProvider.notifier)
                  .editNoteTranscriptRich(
                    documentId: doc.id,
                    noteId: block.noteId!,
                    newContent: content,
                    contentFormat: format,
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
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          activeMatchRange: _activeMatchForBlock(block.id),
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () => ref
              .read(projectDocumentsProvider.notifier)
              .removeBlock(doc.id, block.id),
          onSave: (newContent) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContent(doc.id, block.id, newContent),
          onSaveRichText: (content, format) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContentFormat(
                  doc.id, block.id, content, format),
        );
      case BlockType.sectionHeader:
        return _SectionHeaderCard(
          block: block,
          isFirst: isFirst,
          isLast: isLast,
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          activeMatchRange: _activeMatchForBlock(block.id),
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () => ref
              .read(projectDocumentsProvider.notifier)
              .removeBlock(doc.id, block.id),
          onSave: (newContent) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContent(doc.id, block.id, newContent),
          onSaveRichText: (content, format) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContentFormat(doc.id, block.id, content, format),
        );
      case BlockType.imageBlock:
        final repo = ImageAttachmentRepository();
        final attachment = block.imageAttachmentId != null
            ? repo.getImageAttachment(block.imageAttachmentId!)
            : null;
        final imageFile = block.imageAttachmentId != null
            ? repo.getImageFile(block.imageAttachmentId!)
            : null;
        return ImageBlockWidget(
          attachment: attachment,
          imageFile: imageFile,
          caption: block.content,
          isFirst: isFirst,
          isLast: isLast,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () async {
            // Cascade delete: remove image attachment + file
            if (block.imageAttachmentId != null) {
              await repo.deleteImageAttachment(block.imageAttachmentId!);
            }
            ref
                .read(projectDocumentsProvider.notifier)
                .removeBlock(doc.id, block.id);
          },
          onEditCaption: (newCaption) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContent(doc.id, block.id, newCaption),
        );
      case BlockType.taskBlock:
        return _TaskBlockCard(
          block: block,
          allNotes: allNotes,
          isFirst: isFirst,
          isLast: isLast,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
          onRemove: () => ref
              .read(projectDocumentsProvider.notifier)
              .removeBlock(doc.id, block.id),
          onUpdate: (newContent) => ref
              .read(projectDocumentsProvider.notifier)
              .updateBlockContent(doc.id, block.id, newContent),
          onViewNote: (noteId) => context.push(
              AppRoutes.noteDetail, extra: {'noteId': noteId}),
        );
    }
  }

  void _shareDocument(dynamic doc, List<Note> allNotes) {
    final service = SharingService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SharePreviewSheet(
          title: doc.title,
          isProject: true,
          assembleText: (options) =>
              service.assembleDocumentText(doc, allNotes, options: options),
          onExportPdf: (options) =>
              service.exportDocumentAsPdf(doc, allNotes, options: options),
          onExportMarkdown: () =>
              service.exportDocumentAsMarkdown(doc, allNotes),
        ),
      ),
    );
  }

  /// Bottom sheet: Record new voice note or pick existing ones for the project.
  void _showAddVoiceNoteSheet(BuildContext context, String documentId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fiber_manual_record_rounded,
                  color: Colors.red),
              title: const Text('Record New Voice Note'),
              subtitle: const Text('Record and auto-add to this project'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(AppRoutes.recording,
                    extra: {'projectId': documentId});
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add Existing Voice Notes'),
              subtitle: const Text('Select from your voice notes'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(AppRoutes.notePickerRoute,
                    extra: {'documentId': documentId, 'filterType': 'voice'});
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet: Create new text note or pick existing text notes for the project.
  void _showAddTextNoteSheet(BuildContext context, String documentId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline_rounded,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Create New Text Note'),
              subtitle: const Text('Create and auto-add to this project'),
              onTap: () async {
                Navigator.of(ctx).pop();
                // Show template picker, then navigate to note detail
                final template = await showModalBottomSheet<dynamic>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const TemplatePickerSheet(),
                );
                if (!mounted) return;
                if (template == null) return;
                final extras = <String, dynamic>{
                  'isNewTextNote': true,
                  'projectId': documentId,
                };
                if (template is NoteTemplate) {
                  extras['templateContent'] = template.content;
                  extras['templateTitle'] = template.name;
                }
                // Find folder for this project to auto-assign
                final projects = ref.read(projectDocumentsProvider);
                final project =
                    projects.where((p) => p.id == documentId).firstOrNull;
                if (project?.folderId != null) {
                  extras['folderId'] = project!.folderId;
                }
                context.push(AppRoutes.noteDetail, extra: extras);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add Existing Text Notes'),
              subtitle: const Text('Select from your text notes'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(AppRoutes.notePickerRoute,
                    extra: {'documentId': documentId, 'filterType': 'text'});
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet: Create new task or select existing tasks for a Task Block.
  void _showAddTaskSheet(BuildContext context, String documentId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.checklist_rounded,
                      color: Colors.orange, size: 22),
                  const SizedBox(width: 8),
                  Text('Add Tasks',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.add_task_rounded,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Create New Task'),
              subtitle:
                  const Text('A new text note will be created for this task'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showNewTaskDialog(context, documentId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_check_rounded),
              title: const Text('Select Existing Tasks'),
              subtitle: const Text('Pick tasks from your notes'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showExistingTaskPicker(context, documentId);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog to create a new task (creates a text note + adds task to it + adds task block).
  void _showNewTaskDialog(BuildContext context, String documentId) {
    final textCtrl = TextEditingController();
    String taskType = 'todo'; // default

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new text note will be created and linked to this task.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task description',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Type: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('To-Do'),
                    selected: taskType == 'todo',
                    onSelected: (_) =>
                        setDialogState(() => taskType = 'todo'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Action'),
                    selected: taskType == 'action',
                    onSelected: (_) =>
                        setDialogState(() => taskType = 'action'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final taskText = textCtrl.text.trim();
                if (taskText.isEmpty) return;
                Navigator.of(ctx).pop();

                // 1. Create a text note
                final note = await ref.read(notesProvider.notifier).addNote(
                      audioFilePath: '',
                      rawTranscription: taskText,
                      isProcessed: true,
                    );

                // 2. Add the task to the note
                String? taskId;
                if (taskType == 'todo') {
                  await ref.read(notesProvider.notifier).addTodoItem(
                        noteId: note.id,
                        text: taskText,
                      );
                  // Get the newly created todo's id
                  final updated = ref.read(notesProvider)
                      .where((n) => n.id == note.id)
                      .firstOrNull;
                  taskId = updated?.todos.lastOrNull?.id;
                } else {
                  await ref.read(notesProvider.notifier).addActionItem(
                        noteId: note.id,
                        text: taskText,
                      );
                  final updated = ref.read(notesProvider)
                      .where((n) => n.id == note.id)
                      .firstOrNull;
                  taskId = updated?.actions.lastOrNull?.id;
                }

                if (taskId == null) return;

                // 3. Create task block with this reference
                final taskRef = jsonEncode([
                  {
                    'noteId': note.id,
                    'taskId': taskId,
                    'taskType': taskType,
                  }
                ]);
                ref
                    .read(projectDocumentsProvider.notifier)
                    .addTaskBlock(documentId, taskRef);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  /// Picker sheet showing all existing tasks from all notes.
  void _showExistingTaskPicker(BuildContext context, String documentId) {
    final allNotes = ref.read(notesProvider);

    // Collect all tasks across all notes
    final taskEntries = <_TaskEntry>[];
    for (final note in allNotes) {
      if (note.isDeleted) continue;
      for (final action in note.actions) {
        taskEntries.add(_TaskEntry(
          noteId: note.id,
          taskId: action.id,
          taskType: 'action',
          text: action.text,
          isCompleted: action.isCompleted,
          noteTitle: note.title,
        ));
      }
      for (final todo in note.todos) {
        taskEntries.add(_TaskEntry(
          noteId: note.id,
          taskId: todo.id,
          taskType: 'todo',
          text: todo.text,
          isCompleted: todo.isCompleted,
          noteTitle: note.title,
          dueDate: todo.dueDate,
        ));
      }
    }

    if (taskEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks found in any notes')),
      );
      return;
    }

    final selected = <_TaskEntry>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Select Tasks (${selected.length})',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              final refs = selected
                                  .map((e) => {
                                        'noteId': e.noteId,
                                        'taskId': e.taskId,
                                        'taskType': e.taskType,
                                      })
                                  .toList();
                              ref
                                  .read(projectDocumentsProvider.notifier)
                                  .addTaskBlock(
                                      documentId, jsonEncode(refs));
                            },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: taskEntries.length,
                  itemBuilder: (ctx, i) {
                    final entry = taskEntries[i];
                    final isSelected = selected.contains(entry);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setSheetState(() {
                          if (val == true) {
                            selected.add(entry);
                          } else {
                            selected.remove(entry);
                          }
                        });
                      },
                      title: Text(
                        entry.text,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: entry.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        '${entry.taskType == 'action' ? 'Action' : 'To-Do'} · ${entry.noteTitle}${entry.dueDate != null ? ' · ${entry.dueDate!.month}/${entry.dueDate!.day}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(
                        entry.taskType == 'action'
                            ? Icons.flash_on_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 20,
                        color: entry.taskType == 'action'
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                      ),
                      dense: true,
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

  Future<void> _pickAndAddImage(String documentId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;

      // Offer crop before saving
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).colorScheme.surface,
            toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
            lockAspectRatio: false,
          ),
        ],
      );
      if (cropped == null || !mounted) return;

      final repo = ImageAttachmentRepository();
      final attachment = await repo.saveImage(
        sourceFile: File(cropped.path),
        sourceType: source == ImageSource.gallery ? 'gallery' : 'camera',
      );

      ref
          .read(projectDocumentsProvider.notifier)
          .addImageBlock(documentId, attachment.id, null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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

class _NoteReferenceCard extends ConsumerStatefulWidget {
  final ProjectBlock block;
  final List<Note> allNotes;
  final bool isFirst;
  final bool isLast;
  final String? searchQuery;
  final ({int start, int end})? activeMatchRange;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final VoidCallback onViewOriginal;
  final VoidCallback onViewHistory;
  final void Function(String) onSaveEdit;
  final void Function(String content, String format)? onSaveRichEdit;

  const _NoteReferenceCard({
    required this.block,
    required this.allNotes,
    required this.isFirst,
    required this.isLast,
    this.searchQuery,
    this.activeMatchRange,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onViewOriginal,
    required this.onViewHistory,
    required this.onSaveEdit,
    this.onSaveRichEdit,
  });

  @override
  ConsumerState<_NoteReferenceCard> createState() => _NoteReferenceCardState();
}

class _NoteReferenceCardState extends ConsumerState<_NoteReferenceCard> {
  bool _editing = false;
  late TextEditingController _controller;
  QuillController? _quillController;

  bool _isRichText(Note note) => note.contentFormat == 'quill_delta';

  /// Build a read-only QuillEditor for notes with quill_delta format.
  Widget _buildReadOnlyQuill(Note note) {
    try {
      final json = jsonDecode(note.rawTranscription) as List;
      final controller = QuillController(
        document: Document.fromJson(json),
        selection: const TextSelection.collapsed(offset: 0),
      );
      final onSurface = Theme.of(context).colorScheme.onSurface;
      return QuillEditor.basic(
        controller: controller,
        config: QuillEditorConfig(
          showCursor: false,
          enableInteractiveSelection: false,
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              TextStyle(fontSize: 14, color: onSurface),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      );
    } catch (_) {
      return Text(
        note.rawTranscription,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
  }

  /// Create a QuillController from a note's rich text content.
  QuillController _createQuillController(Note note) {
    try {
      final json = jsonDecode(note.rawTranscription) as List;
      return QuillController(
        document: Document.fromJson(json),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      final doc = Document()..insert(0, note.rawTranscription);
      return QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  /// Extract plain text from a note, handling quill_delta format.
  String _plainText(Note note) {
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _quillController?.dispose();
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
                      if (_isRichText(note) && _quillController != null) ...[
                        Container(
                          constraints: const BoxConstraints(
                              minHeight: 80, maxHeight: 300),
                          child: QuillEditor.basic(
                            controller: _quillController!,
                            config: const QuillEditorConfig(
                              autoFocus: true,
                              minHeight: 60,
                              placeholder: 'Edit transcription...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        buildQuillToolbar(
                            _quillController!, Theme.of(context)),
                      ] else
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
                            onPressed: () {
                              _quillController?.dispose();
                              _quillController = null;
                              setState(() => _editing = false);
                            },
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: () {
                              if (_isRichText(note) &&
                                  _quillController != null) {
                                final deltaJson = jsonEncode(
                                    _quillController!.document
                                        .toDelta()
                                        .toJson());
                                if (widget.onSaveRichEdit != null) {
                                  widget.onSaveRichEdit!(
                                      deltaJson, 'quill_delta');
                                } else {
                                  widget.onSaveEdit(
                                      _quillController!.document
                                          .toPlainText()
                                          .trim());
                                }
                                _quillController?.dispose();
                                _quillController = null;
                              } else {
                                widget.onSaveEdit(_controller.text);
                              }
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
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_isRichText(note)) {
                            _quillController =
                                _createQuillController(note);
                          } else {
                            _controller.text = _plainText(note);
                          }
                          setState(() => _editing = true);
                        },
                        child: note.rawTranscription.isEmpty
                            ? Text(
                                'No transcript — tap to add',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              )
                            : widget.searchQuery != null
                                ? _HighlightedText(
                                    text: _plainText(note),
                                    query: widget.searchQuery!,
                                    activeRange: widget.activeMatchRange,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  )
                                : note.contentFormat == 'quill_delta'
                                    ? _buildReadOnlyQuill(note)
                                    : Text(
                                        note.rawTranscription,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                      ),
                      // Tasks are shown via dedicated Task Blocks — not inline here
                    ],
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
                if (value == 'rich_edit') widget.onViewOriginal();
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
                  value: 'rich_edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Rich text edit'),
                    ],
                  ),
                ),
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
  final String? searchQuery;
  final ({int start, int end})? activeMatchRange;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String) onSave;
  final void Function(String content, String format)? onSaveRichText;

  const _FreeTextCard({
    required this.block,
    required this.isFirst,
    required this.isLast,
    this.searchQuery,
    this.activeMatchRange,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onSave,
    this.onSaveRichText,
  });

  @override
  State<_FreeTextCard> createState() => _FreeTextCardState();
}

class _FreeTextCardState extends State<_FreeTextCard> {
  bool _editing = false;
  late QuillController _quillController;

  bool get _isRichText => widget.block.contentFormat == 'quill_delta';

  @override
  void initState() {
    super.initState();
    _quillController = _createController();
  }

  QuillController _createController() {
    final content = widget.block.content ?? '';
    if (_isRichText && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as List;
        return QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fallback to plain text
      }
    }
    // Plain text — wrap in simple Document
    final doc = Document()..insert(0, content);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void didUpdateWidget(covariant _FreeTextCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _quillController.dispose();
      _quillController = _createController();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  void _saveContent() {
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    if (widget.onSaveRichText != null) {
      widget.onSaveRichText!(deltaJson, 'quill_delta');
    } else {
      widget.onSave(_quillController.document.toPlainText().trim());
    }
    setState(() => _editing = false);
  }

  String _getPlainText() {
    final content = widget.block.content ?? '';
    if (_isRichText && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as List;
        return Document.fromJson(json).toPlainText().trim();
      } catch (_) {
        return content;
      }
    }
    return content;
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
                label: 'Format',
                value: _isRichText ? 'Rich Text' : 'Plain Text'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content area
              Expanded(
                child: _editing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                                minHeight: 80, maxHeight: 300),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).dividerColor),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: QuillEditor.basic(
                              controller: _quillController,
                              config: const QuillEditorConfig(
                                autoFocus: true,
                                minHeight: 60,
                                placeholder: 'Type your text here...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Formatting toolbar
                          buildQuillToolbar(_quillController, Theme.of(context)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _quillController.dispose();
                                  _quillController = _createController();
                                  setState(() => _editing = false);
                                },
                                style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    minimumSize: const Size(0, 32)),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 6),
                              FilledButton(
                                onPressed: _saveContent,
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
                        child: _getPlainText().isEmpty
                            ? Text(
                                'Tap to add text...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              )
                            : widget.searchQuery != null
                                ? _HighlightedText(
                                    text: _getPlainText(),
                                    query: widget.searchQuery!,
                                    activeRange: widget.activeMatchRange,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  )
                                : _isRichText
                                    ? QuillEditor.basic(
                                        controller: _quillController,
                                        config: const QuillEditorConfig(
                                          showCursor: false,
                                          enableInteractiveSelection: false,
                                        ),
                                      )
                                    : Text(
                                        _getPlainText(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
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
        ],
      ),
    );
  }
}

class _SectionHeaderCard extends StatefulWidget {
  final ProjectBlock block;
  final bool isFirst;
  final bool isLast;
  final String? searchQuery;
  final ({int start, int end})? activeMatchRange;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String) onSave;
  final void Function(String content, String format)? onSaveRichText;

  const _SectionHeaderCard({
    required this.block,
    required this.isFirst,
    required this.isLast,
    this.searchQuery,
    this.activeMatchRange,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onSave,
    this.onSaveRichText,
  });

  @override
  State<_SectionHeaderCard> createState() => _SectionHeaderCardState();
}

class _SectionHeaderCardState extends State<_SectionHeaderCard> {
  bool _editing = false;
  late QuillController _quillController;

  bool get _isRichText => widget.block.contentFormat == 'quill_delta';

  @override
  void initState() {
    super.initState();
    _quillController = _createController();
  }

  QuillController _createController() {
    final content = widget.block.content ?? '';
    if (_isRichText && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as List;
        return QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {}
    }
    final doc = Document()..insert(0, content);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void didUpdateWidget(covariant _SectionHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing) {
      _quillController.dispose();
      _quillController = _createController();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  void _saveContent() {
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());
    if (widget.onSaveRichText != null) {
      widget.onSaveRichText!(deltaJson, 'quill_delta');
    } else {
      widget.onSave(_quillController.document.toPlainText().trim());
    }
    setState(() => _editing = false);
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
                      QuillEditor.basic(
                        controller: _quillController,
                        config: const QuillEditorConfig(
                          autoFocus: true,
                          minHeight: 36,
                          placeholder: 'Section title',
                        ),
                      ),
                      const SizedBox(height: 4),
                      buildQuillToolbar(_quillController, Theme.of(context), showHeaders: false, showBullets: false),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _quillController.dispose();
                              _quillController = _createController();
                              setState(() => _editing = false);
                            },
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                minimumSize: const Size(0, 32)),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: _saveContent,
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
                    child: widget.searchQuery != null
                        ? _HighlightedText(
                            text: _quillController.document.toPlainText().trim(),
                            query: widget.searchQuery!,
                            activeRange: widget.activeMatchRange,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          )
                        : _isRichText
                            ? QuillEditor.basic(
                                controller: _quillController,
                                config: const QuillEditorConfig(
                                  showCursor: false,
                                  enableInteractiveSelection: false,
                                ),
                              )
                            : Text(
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

/// Renders text with search query matches highlighted.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final ({int start, int end})? activeRange;
  final TextStyle? style;

  const _HighlightedText({
    required this.text,
    required this.query,
    this.activeRange,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int lastEnd = 0;

    int searchFrom = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, searchFrom);
      if (idx == -1) break;
      if (idx > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, idx)));
      }
      final isActive = activeRange != null && activeRange!.start == idx;
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: isActive
              ? Colors.orange.withAlpha(180)
              : Colors.yellow.withAlpha(120),
        ),
      ));
      lastEnd = idx + query.length;
      searchFrom = idx + 1;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    if (spans.isEmpty) return Text(text, style: style);
    return RichText(text: TextSpan(style: style, children: spans));
  }
}

// ---------------------------------------------------------------------------
// Task Block helpers
// ---------------------------------------------------------------------------

/// Lightweight value object for the existing-task picker.
class _TaskEntry {
  final String noteId;
  final String taskId;
  final String taskType; // 'action' | 'todo'
  final String text;
  final bool isCompleted;
  final String noteTitle;
  final DateTime? dueDate;

  const _TaskEntry({
    required this.noteId,
    required this.taskId,
    required this.taskType,
    required this.text,
    required this.isCompleted,
    required this.noteTitle,
    this.dueDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TaskEntry &&
          noteId == other.noteId &&
          taskId == other.taskId;

  @override
  int get hashCode => Object.hash(noteId, taskId);
}

// ---------------------------------------------------------------------------
// _TaskBlockCard — renders a Task Block in a project document
// ---------------------------------------------------------------------------

class _TaskBlockCard extends ConsumerStatefulWidget {
  final ProjectBlock block;
  final List<Note> allNotes;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String newContent) onUpdate;
  final void Function(String noteId) onViewNote;

  const _TaskBlockCard({
    required this.block,
    required this.allNotes,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onUpdate,
    required this.onViewNote,
  });

  @override
  ConsumerState<_TaskBlockCard> createState() => _TaskBlockCardState();
}

class _TaskBlockCardState extends ConsumerState<_TaskBlockCard> {
  /// Parse the JSON task references stored in block.content.
  List<Map<String, dynamic>> _parseRefs() {
    final raw = widget.block.content;
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Look up live task data from the referenced note.
  ({String text, bool isCompleted, DateTime? dueDate, bool found, String noteTitle})?
      _resolveTask(Map<String, dynamic> ref) {
    final noteId = ref['noteId'] as String?;
    final taskId = ref['taskId'] as String?;
    final taskType = ref['taskType'] as String?;
    if (noteId == null || taskId == null || taskType == null) return null;

    final note =
        widget.allNotes.where((n) => n.id == noteId).firstOrNull;
    if (note == null) {
      return (
        text: '(Note deleted)',
        isCompleted: false,
        dueDate: null,
        found: false,
        noteTitle: '',
      );
    }

    if (taskType == 'action') {
      final action =
          note.actions.where((a) => a.id == taskId).firstOrNull;
      if (action != null) {
        return (
          text: action.text,
          isCompleted: action.isCompleted,
          dueDate: null,
          found: true,
          noteTitle: note.title,
        );
      }
    } else {
      final todo =
          note.todos.where((t) => t.id == taskId).firstOrNull;
      if (todo != null) {
        return (
          text: todo.text,
          isCompleted: todo.isCompleted,
          dueDate: todo.dueDate,
          found: true,
          noteTitle: note.title,
        );
      }
    }
    return (
      text: '(Task removed)',
      isCompleted: false,
      dueDate: null,
      found: false,
      noteTitle: note.title,
    );
  }

  void _removeTaskRef(int index) {
    final refs = _parseRefs();
    if (index < refs.length) {
      refs.removeAt(index);
      widget.onUpdate(jsonEncode(refs));
    }
  }

  @override
  Widget build(BuildContext context) {
    final refs = _parseRefs();
    final theme = Theme.of(context);
    final completedCount = refs.where((r) {
      final resolved = _resolveTask(r);
      return resolved != null && resolved.isCompleted;
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    const Icon(Icons.checklist_rounded,
                        size: 16, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      '${refs.length} tasks ($completedCount completed)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Task rows
                ...List.generate(refs.length, (i) {
                  final taskRef = refs[i];
                  final resolved = _resolveTask(taskRef);
                  if (resolved == null) return const SizedBox.shrink();

                  final taskType = taskRef['taskType'] as String? ?? 'todo';
                  final noteId = taskRef['noteId'] as String? ?? '';
                  final taskId = taskRef['taskId'] as String? ?? '';
                  final isOverdue = resolved.dueDate != null &&
                      !resolved.isCompleted &&
                      resolved.dueDate!.isBefore(DateTime.now());

                  return GestureDetector(
                    onTap: resolved.found
                        ? () {
                            if (taskType == 'action') {
                              ref
                                  .read(notesProvider.notifier)
                                  .toggleActionCompleted(
                                    noteId: noteId,
                                    actionId: taskId,
                                  );
                            } else {
                              ref
                                  .read(notesProvider.notifier)
                                  .toggleTodoCompleted(
                                    noteId: noteId,
                                    todoId: taskId,
                                  );
                            }
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(
                            resolved.isCompleted
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: resolved.isCompleted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            taskType == 'action'
                                ? Icons.flash_on_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 14,
                            color: taskType == 'action'
                                ? Colors.orange
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              resolved.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: !resolved.found
                                    ? theme.hintColor
                                    : resolved.isCompleted
                                        ? theme.colorScheme.secondary
                                            .withValues(alpha: 0.7)
                                        : theme.colorScheme.onSurface,
                                decoration: resolved.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                fontStyle: !resolved.found
                                    ? FontStyle.italic
                                    : null,
                              ),
                            ),
                          ),
                          if (resolved.dueDate != null)
                            Text(
                              '${resolved.dueDate!.month}/${resolved.dueDate!.day}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue
                                    ? Colors.red
                                    : theme.colorScheme.secondary,
                                fontWeight:
                                    isOverdue ? FontWeight.bold : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // 3-dot menu
          SizedBox(
            width: 28,
            height: 28,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              onSelected: (value) {
                if (value == 'move_up') widget.onMoveUp();
                if (value == 'move_down') widget.onMoveDown();
                if (value == 'remove') widget.onRemove();
                if (value.startsWith('view_')) {
                  final noteId = value.substring(5);
                  widget.onViewNote(noteId);
                }
                if (value.startsWith('delete_')) {
                  final idx = int.tryParse(value.substring(7));
                  if (idx != null) _removeTaskRef(idx);
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[
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
                ];

                // Add "View note" entries for each unique noteId
                final noteIds = refs
                    .map((r) => r['noteId'] as String?)
                    .whereType<String>()
                    .toSet();
                for (final nid in noteIds) {
                  final note = widget.allNotes
                      .where((n) => n.id == nid)
                      .firstOrNull;
                  items.add(PopupMenuItem(
                    value: 'view_$nid',
                    child: Row(
                      children: [
                        const Icon(Icons.open_in_new, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note?.title ?? 'View note',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ));
                }

                items.addAll([
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Remove block'),
                      ],
                    ),
                  ),
                ]);

                return items;
              },
              icon: Icon(Icons.more_vert,
                  size: 18, color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}
