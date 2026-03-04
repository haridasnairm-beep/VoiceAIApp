import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_document.dart';
import '../services/project_documents_repository.dart';
import 'notes_provider.dart';
import 'folders_provider.dart';

/// Provider for the ProjectDocumentsRepository singleton.
final projectDocumentsRepositoryProvider =
    Provider<ProjectDocumentsRepository>((ref) {
  return ProjectDocumentsRepository();
});

/// Notifier that manages the list of all project documents, backed by Hive.
class ProjectDocumentsNotifier extends Notifier<List<ProjectDocument>> {
  @override
  List<ProjectDocument> build() {
    return ref.read(projectDocumentsRepositoryProvider).getAllProjectDocuments();
  }

  void refresh() {
    state =
        ref.read(projectDocumentsRepositoryProvider).getAllProjectDocuments();
  }

  Future<ProjectDocument> create({
    required String title,
    String? description,
    String? folderId,
  }) async {
    final repo = ref.read(projectDocumentsRepositoryProvider);
    final doc = await repo.createProjectDocument(
      title: title,
      description: description,
      folderId: folderId,
    );
    // Also register in the folder's projectDocumentIds list
    if (folderId != null) {
      final foldersRepo = ref.read(foldersRepositoryProvider);
      await foldersRepo.addProjectToFolder(folderId, doc.id);
      ref.read(foldersProvider.notifier).refresh();
    }
    state = [doc, ...state];
    return doc;
  }

  Future<void> delete(String id) async {
    await ref.read(projectDocumentsRepositoryProvider).deleteProjectDocument(id);
    state = state.where((d) => d.id != id).toList();
  }

  Future<void> restoreProject(String id) async {
    await ref.read(projectDocumentsRepositoryProvider).restoreProjectDocument(id);
    refresh();
  }

  Future<void> permanentlyDeleteProject(String id) async {
    await ref.read(projectDocumentsRepositoryProvider).permanentlyDeleteProjectDocument(id);
  }

  List<ProjectDocument> getTrashedProjects() {
    return ref.read(projectDocumentsRepositoryProvider).getTrashedProjects();
  }

  Future<int> purgeExpiredTrash() async {
    return ref.read(projectDocumentsRepositoryProvider).purgeExpiredTrash();
  }

  Future<void> updateDocument(ProjectDocument document) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .updateProjectDocument(document);
    state = [
      for (final d in state)
        if (d.id == document.id) document else d,
    ];
  }

  /// Move a project to a different folder (atomic).
  Future<void> moveProjectToFolder(String projectId, String newFolderId) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .moveProjectToFolder(projectId, newFolderId);
    refresh();
    ref.read(foldersProvider.notifier).refresh();
  }

  Future<void> addNoteBlock(String documentId, String noteId) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .addNoteBlock(documentId, noteId);
    refresh();
    ref.read(notesProvider.notifier).refresh();
  }

  Future<void> addFreeTextBlock(String documentId, String content) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .addFreeTextBlock(documentId, content);
    refresh();
  }

  Future<void> addSectionHeaderBlock(String documentId, String content) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .addSectionHeaderBlock(documentId, content);
    refresh();
  }

  Future<void> addImageBlock(
      String documentId, String attachmentId, String? caption) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .addImageBlock(documentId, attachmentId, caption);
    refresh();
  }

  Future<void> updateBlockContentFormat(
      String documentId, String blockId, String content, String format) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .updateBlockContentFormat(documentId, blockId, content, format);
    refresh();
  }

  Future<void> removeBlock(String documentId, String blockId) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .removeBlock(documentId, blockId);
    refresh();
    ref.read(notesProvider.notifier).refresh();
  }

  Future<void> reorderBlocks(
      String documentId, List<String> newOrder) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .reorderBlocks(documentId, newOrder);
    refresh();
  }

  Future<void> updateBlockContent(
      String documentId, String blockId, String newContent) async {
    await ref
        .read(projectDocumentsRepositoryProvider)
        .updateBlockContent(documentId, blockId, newContent);
    refresh();
  }

  /// Edit a note's transcript from within a project document (bi-directional).
  Future<void> editNoteTranscript({
    required String documentId,
    required String noteId,
    required String newText,
    required String documentTitle,
  }) async {
    final notesRepo = ref.read(notesRepositoryProvider);
    await notesRepo.addTranscriptVersion(
      noteId,
      newText,
      'Project: $documentTitle',
    );
    ref.read(notesProvider.notifier).refresh();
    refresh();
  }

  /// Edit a note's rich-text transcript from within a project document.
  Future<void> editNoteTranscriptRich({
    required String documentId,
    required String noteId,
    required String newContent,
    required String contentFormat,
    required String documentTitle,
  }) async {
    final notesRepo = ref.read(notesRepositoryProvider);
    await notesRepo.updateNoteRichContent(
      noteId,
      newContent,
      contentFormat,
      'Project: $documentTitle',
    );
    ref.read(notesProvider.notifier).refresh();
    refresh();
  }

  ProjectDocument? getById(String id) {
    try {
      return state.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProjectDocument> search(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state.where((doc) {
      return doc.title.toLowerCase().contains(lower) ||
          (doc.description?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }
}

/// Provider for the project documents list.
final projectDocumentsProvider =
    NotifierProvider<ProjectDocumentsNotifier, List<ProjectDocument>>(
        ProjectDocumentsNotifier.new);
