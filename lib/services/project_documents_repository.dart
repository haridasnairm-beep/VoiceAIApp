import 'package:uuid/uuid.dart';
import '../models/project_document.dart';
import '../models/project_block.dart';
import '../models/note.dart';
import 'hive_service.dart';

/// Repository for ProjectDocument CRUD operations against Hive.
class ProjectDocumentsRepository {
  static const _uuid = Uuid();

  /// Get all project documents, sorted by updatedAt desc.
  List<ProjectDocument> getAllProjectDocuments() {
    final docs = HiveService.projectDocumentsBox.values.toList();
    docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return docs;
  }

  /// Get a single project document by ID.
  ProjectDocument? getProjectDocument(String id) {
    try {
      return HiveService.projectDocumentsBox.values
          .firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new empty project document.
  Future<ProjectDocument> createProjectDocument({
    required String title,
    String? description,
  }) async {
    final doc = ProjectDocument(
      id: _uuid.v4(),
      title: title,
      description: description,
    );
    await HiveService.projectDocumentsBox.put(doc.id, doc);
    return doc;
  }

  /// Update an existing project document.
  Future<void> updateProjectDocument(ProjectDocument document) async {
    document.updatedAt = DateTime.now();
    await HiveService.projectDocumentsBox.put(document.id, document);
  }

  /// Delete a project document and remove its ID from all linked notes.
  Future<void> deleteProjectDocument(String id) async {
    final doc = getProjectDocument(id);
    if (doc != null) {
      // Remove documentId from all linked notes
      for (final block in doc.blocks) {
        if (block.type == BlockType.noteReference && block.noteId != null) {
          _removeDocIdFromNote(block.noteId!, id);
        }
      }
    }
    await HiveService.projectDocumentsBox.delete(id);
  }

  /// Add a note_reference block to a document.
  Future<ProjectBlock> addNoteBlock(String documentId, String noteId) async {
    final doc = getProjectDocument(documentId);
    if (doc == null) throw Exception('Document not found');

    final block = ProjectBlock(
      id: _uuid.v4(),
      type: BlockType.noteReference,
      sortOrder: doc.blocks.length,
      noteId: noteId,
    );
    doc.blocks.add(block);
    await updateProjectDocument(doc);

    // Add documentId to note's projectDocumentIds
    _addDocIdToNote(noteId, documentId);

    return block;
  }

  /// Add a free_text block to a document.
  Future<ProjectBlock> addFreeTextBlock(
      String documentId, String content) async {
    final doc = getProjectDocument(documentId);
    if (doc == null) throw Exception('Document not found');

    final block = ProjectBlock(
      id: _uuid.v4(),
      type: BlockType.freeText,
      sortOrder: doc.blocks.length,
      content: content,
    );
    doc.blocks.add(block);
    await updateProjectDocument(doc);
    return block;
  }

  /// Add a section_header block to a document.
  Future<ProjectBlock> addSectionHeaderBlock(
      String documentId, String content) async {
    final doc = getProjectDocument(documentId);
    if (doc == null) throw Exception('Document not found');

    final block = ProjectBlock(
      id: _uuid.v4(),
      type: BlockType.sectionHeader,
      sortOrder: doc.blocks.length,
      content: content,
    );
    doc.blocks.add(block);
    await updateProjectDocument(doc);
    return block;
  }

  /// Remove a block from a document.
  Future<void> removeBlock(String documentId, String blockId) async {
    final doc = getProjectDocument(documentId);
    if (doc == null) return;

    final block = doc.blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    // If note_reference, remove documentId from the note
    if (block.type == BlockType.noteReference && block.noteId != null) {
      _removeDocIdFromNote(block.noteId!, documentId);
    }

    doc.blocks.removeWhere((b) => b.id == blockId);

    // Re-index sortOrder
    for (var i = 0; i < doc.blocks.length; i++) {
      doc.blocks[i].sortOrder = i;
    }

    await updateProjectDocument(doc);
  }

  /// Reorder blocks within a document.
  Future<void> reorderBlocks(
      String documentId, List<String> newBlockOrder) async {
    final doc = getProjectDocument(documentId);
    if (doc == null) return;

    final blockMap = {for (final b in doc.blocks) b.id: b};
    final reordered = <ProjectBlock>[];
    for (var i = 0; i < newBlockOrder.length; i++) {
      final block = blockMap[newBlockOrder[i]];
      if (block != null) {
        block.sortOrder = i;
        reordered.add(block);
      }
    }
    doc.blocks = reordered;
    await updateProjectDocument(doc);
  }

  /// Update content of a free_text or section_header block.
  Future<void> updateBlockContent(
      String documentId, String blockId, String newContent) async {
    final doc = getProjectDocument(documentId);
    if (doc == null) return;

    final block = doc.blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return;

    block.content = newContent;
    block.updatedAt = DateTime.now();
    await updateProjectDocument(doc);
  }

  /// Search project documents by title/description.
  List<ProjectDocument> searchProjectDocuments(String query) {
    if (query.isEmpty) return getAllProjectDocuments();
    final lower = query.toLowerCase();
    return getAllProjectDocuments().where((d) {
      return d.title.toLowerCase().contains(lower) ||
          (d.description?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  /// Get total count of project documents.
  int get count => HiveService.projectDocumentsBox.length;

  // --- Helper methods for note ↔ document linking ---

  void _addDocIdToNote(String noteId, String documentId) {
    final note = _getNoteById(noteId);
    if (note != null && !note.projectDocumentIds.contains(documentId)) {
      note.projectDocumentIds.add(documentId);
      note.updatedAt = DateTime.now();
      HiveService.notesBox.put(note.id, note);
    }
  }

  void _removeDocIdFromNote(String noteId, String documentId) {
    final note = _getNoteById(noteId);
    if (note != null) {
      note.projectDocumentIds.remove(documentId);
      note.updatedAt = DateTime.now();
      HiveService.notesBox.put(note.id, note);
    }
  }

  Note? _getNoteById(String id) {
    try {
      return HiveService.notesBox.values.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}
