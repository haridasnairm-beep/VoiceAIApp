import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/action_item.dart';
import '../models/note.dart';
import '../models/todo_item.dart';
import '../models/transcript_version.dart';
import 'hive_service.dart';

/// Repository for Note CRUD operations against Hive.
class NotesRepository {
  static const _uuid = Uuid();

  /// Get all active (non-deleted) notes, sorted by creation date (newest first).
  List<Note> getAllNotes() {
    final notes = HiveService.notesBox.values
        .where((n) => !n.isDeleted)
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  /// Get all trashed notes, sorted by deletion date (newest first).
  List<Note> getTrashedNotes() {
    final notes = HiveService.notesBox.values
        .where((n) => n.isDeleted)
        .toList();
    notes.sort((a, b) =>
        (b.deletedAt ?? DateTime.now()).compareTo(a.deletedAt ?? DateTime.now()));
    return notes;
  }

  /// Get a single note by ID.
  Note? getNoteById(String id) {
    try {
      return HiveService.notesBox.values.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new note from a recording.
  /// Returns the created note.
  Future<Note> createNote({
    required String audioFilePath,
    int audioDurationSeconds = 0,
    String title = 'Untitled Note',
    String rawTranscription = '',
    String detectedLanguage = 'en',
    String? folderId,
    bool isProcessed = true,
  }) async {
    final note = Note(
      id: _uuid.v4(),
      title: title,
      rawTranscription: rawTranscription,
      detectedLanguage: detectedLanguage,
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
      folderId: folderId,
      isProcessed: isProcessed,
    );
    await HiveService.notesBox.put(note.id, note);
    return note;
  }

  /// Update an existing note.
  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Soft-delete a note (move to trash).
  Future<void> deleteNote(String id) async {
    final note = getNoteById(id);
    if (note == null) return;
    note.isDeleted = true;
    note.deletedAt = DateTime.now();
    note.previousFolderId = note.folderId;
    note.isPinned = false;
    note.pinnedAt = null;
    await HiveService.notesBox.put(id, note);
  }

  /// Restore a note from trash.
  Future<void> restoreNote(String id) async {
    final note = getNoteById(id);
    if (note == null) return;
    note.isDeleted = false;
    note.deletedAt = null;
    note.folderId = note.previousFolderId;
    note.previousFolderId = null;
    await HiveService.notesBox.put(id, note);
  }

  /// Permanently delete a note and its files.
  Future<void> permanentlyDeleteNote(String id) async {
    final note = getNoteById(id);
    if (note != null && note.audioFilePath.isNotEmpty) {
      try {
        final file = File(note.audioFilePath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await HiveService.notesBox.delete(id);
  }

  /// Purge notes that have been in trash for more than 30 days.
  Future<int> purgeExpiredTrash() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final expired = HiveService.notesBox.values
        .where((n) => n.isDeleted && n.deletedAt != null && n.deletedAt!.isBefore(cutoff))
        .toList();
    for (final note in expired) {
      await permanentlyDeleteNote(note.id);
    }
    return expired.length;
  }

  /// Search notes by query string.
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();
    final lower = query.toLowerCase();
    return getAllNotes().where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.rawTranscription.toLowerCase().contains(lower) ||
          n.topics.any((t) => t.toLowerCase().contains(lower)) ||
          n.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }

  /// Get all unprocessed notes (offline queue).
  List<Note> getUnprocessedNotes() {
    return getAllNotes().where((n) => !n.isProcessed).toList();
  }

  /// Get notes by folder ID.
  List<Note> getNotesByFolder(String folderId) {
    return getAllNotes().where((n) => n.folderId == folderId).toList();
  }

  /// Get total count of notes.
  int get count => HiveService.notesBox.length;

  // --- Transcript Versioning ---

  /// Add a new transcript version to a note and update rawTranscription.
  Future<void> addTranscriptVersion(
      String noteId, String newText, String editSource,
      {String? richContentJson}) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final nextVersion = note.transcriptVersions.isEmpty
        ? 1
        : note.transcriptVersions
                .map((v) => v.versionNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;

    final version = TranscriptVersion(
      id: _uuid.v4(),
      text: newText,
      versionNumber: nextVersion,
      editSource: editSource,
      richContentJson: richContentJson,
    );

    note.transcriptVersions = [...note.transcriptVersions, version];
    // Only overwrite rawTranscription for plain-text notes.
    // Rich-text (quill_delta) notes store delta JSON in rawTranscription,
    // which must not be clobbered with plain text.
    if (note.contentFormat != 'quill_delta') {
      note.rawTranscription = newText;
    }
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Update a note's rich-text content (delta JSON) and add a version entry.
  Future<void> updateNoteRichContent(
      String noteId, String newContent, String contentFormat,
      String editSource, {String? plainText}) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final nextVersion = note.transcriptVersions.isEmpty
        ? 1
        : note.transcriptVersions
                .map((v) => v.versionNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;

    final version = TranscriptVersion(
      id: _uuid.v4(),
      text: plainText ?? newContent,
      versionNumber: nextVersion,
      editSource: editSource,
      richContentJson: contentFormat == 'quill_delta' ? newContent : null,
    );

    note.transcriptVersions = [...note.transcriptVersions, version];
    note.rawTranscription = newContent;
    note.contentFormat = contentFormat;
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Get all transcript versions for a note, sorted by versionNumber asc.
  List<TranscriptVersion> getTranscriptVersions(String noteId) {
    final note = getNoteById(noteId);
    if (note == null) return [];
    final versions = List<TranscriptVersion>.from(note.transcriptVersions);
    versions.sort((a, b) => a.versionNumber.compareTo(b.versionNumber));
    return versions;
  }

  /// Restore a transcript version — creates a new version with the restored text.
  Future<void> restoreTranscriptVersion(
      String noteId, String versionId) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final version = note.transcriptVersions
        .where((v) => v.id == versionId)
        .firstOrNull;
    if (version == null) return;

    final editSource = 'Restored from v${version.versionNumber}';

    if (version.richContentJson != null) {
      // Restore rich content — update rawTranscription + contentFormat
      await updateNoteRichContent(
        noteId,
        version.richContentJson!,
        'quill_delta',
        editSource,
        plainText: version.text,
      );
    } else {
      // Restore plain text
      await addTranscriptVersion(noteId, version.text, editSource);
      // If note was previously rich text, revert to plain
      if (note.contentFormat == 'quill_delta') {
        note.rawTranscription = version.text;
        note.contentFormat = null;
        await HiveService.notesBox.put(note.id, note);
      }
    }
  }

  /// Ensure a note has at least one transcript version (migration helper).
  Future<void> ensureTranscriptVersion(Note note) async {
    if (note.transcriptVersions.isEmpty && note.rawTranscription.isNotEmpty) {
      final version = TranscriptVersion(
        id: _uuid.v4(),
        text: note.rawTranscription,
        versionNumber: 1,
        editSource: 'Original transcription',
        createdAt: note.createdAt,
        isOriginal: true,
        richContentJson:
            note.contentFormat == 'quill_delta' ? note.rawTranscription : null,
      );
      note.transcriptVersions = [version];
      await HiveService.notesBox.put(note.id, note);
    }
  }

  // --- Project Document ID management ---

  /// Add a project document ID to a note's projectDocumentIds.
  Future<void> addProjectDocumentId(String noteId, String documentId) async {
    final note = getNoteById(noteId);
    if (note != null && !note.projectDocumentIds.contains(documentId)) {
      note.projectDocumentIds.add(documentId);
      note.updatedAt = DateTime.now();
      await HiveService.notesBox.put(note.id, note);
    }
  }

  /// Remove a project document ID from a note's projectDocumentIds.
  Future<void> removeProjectDocumentId(
      String noteId, String documentId) async {
    final note = getNoteById(noteId);
    if (note != null) {
      note.projectDocumentIds.remove(documentId);
      note.updatedAt = DateTime.now();
      await HiveService.notesBox.put(note.id, note);
    }
  }

  // --- Todo Item CRUD ---

  /// Toggle a todo item's completed state.
  Future<void> toggleTodoCompleted(String noteId, String todoId) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final idx = note.todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    note.todos[idx].isCompleted = !note.todos[idx].isCompleted;
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Add a new todo item to a note.
  Future<void> addTodoItem(String noteId, String text,
      {DateTime? dueDate}) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final todo = TodoItem(
      id: _uuid.v4(),
      text: text,
      dueDate: dueDate,
    );
    note.todos = [...note.todos, todo];
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Update a todo item's text and/or due date.
  Future<void> updateTodoItem(String noteId, String todoId,
      {String? text, DateTime? dueDate, bool clearDueDate = false}) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final idx = note.todos.indexWhere((t) => t.id == todoId);
    if (idx == -1) return;
    if (text != null) note.todos[idx].text = text;
    if (dueDate != null) note.todos[idx].dueDate = dueDate;
    if (clearDueDate) note.todos[idx].dueDate = null;
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Delete a todo item from a note.
  Future<void> deleteTodoItem(String noteId, String todoId) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    note.todos = note.todos.where((t) => t.id != todoId).toList();
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  // --- Action Item CRUD ---

  /// Toggle an action item's completed state.
  Future<void> toggleActionCompleted(String noteId, String actionId) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final idx = note.actions.indexWhere((a) => a.id == actionId);
    if (idx == -1) return;
    note.actions[idx].isCompleted = !note.actions[idx].isCompleted;
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Add a new action item to a note.
  Future<void> addActionItem(String noteId, String text) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final action = ActionItem(
      id: _uuid.v4(),
      text: text,
    );
    note.actions = [...note.actions, action];
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Update an action item's text.
  Future<void> updateActionItem(
      String noteId, String actionId, String text) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final idx = note.actions.indexWhere((a) => a.id == actionId);
    if (idx == -1) return;
    note.actions[idx].text = text;
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Delete an action item from a note.
  Future<void> deleteActionItem(String noteId, String actionId) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    note.actions = note.actions.where((a) => a.id != actionId).toList();
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  // --- Reminder Enhancement ---

  /// Reschedule a reminder to a new time.
  Future<void> rescheduleReminder(
      String noteId, String reminderId, DateTime newTime) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final idx = note.reminders.indexWhere((r) => r.id == reminderId);
    if (idx == -1) return;
    note.reminders[idx].reminderTime = newTime;
    note.reminders[idx].isCompleted = false;
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Add an image attachment ID to a note.
  Future<void> addImageAttachment(String noteId, String attachmentId) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    if (!note.imageAttachmentIds.contains(attachmentId)) {
      note.imageAttachmentIds.add(attachmentId);
      note.updatedAt = DateTime.now();
      await HiveService.notesBox.put(note.id, note);
    }
  }

  /// Remove an image attachment ID from a note.
  Future<void> removeImageAttachment(String noteId, String attachmentId) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    note.imageAttachmentIds.remove(attachmentId);
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  // --- Tag Management ---

  /// Add a tag to a note (no-op if already present).
  Future<void> addTag(String noteId, String tag) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty || note.tags.contains(normalized)) return;
    note.tags = [...note.tags, normalized];
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Remove a tag from a note.
  Future<void> removeTag(String noteId, String tag) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    note.tags = note.tags.where((t) => t != tag).toList();
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Set all tags on a note at once (replaces existing tags).
  Future<void> setTags(String noteId, List<String> tags) async {
    final note = getNoteById(noteId);
    if (note == null) return;
    note.tags = tags.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty).toList();
    note.updatedAt = DateTime.now();
    await HiveService.notesBox.put(note.id, note);
  }

  /// Rename a tag across all notes.
  Future<void> renameTag(String oldTag, String newTag) async {
    final normalized = newTag.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final affected = HiveService.notesBox.values
        .where((n) => !n.isDeleted && n.tags.contains(oldTag))
        .toList();
    for (final note in affected) {
      note.tags = note.tags.map((t) => t == oldTag ? normalized : t).toList();
      note.updatedAt = DateTime.now();
      await HiveService.notesBox.put(note.id, note);
    }
  }

  /// Delete a tag from all notes.
  Future<void> deleteTag(String tag) async {
    final affected = HiveService.notesBox.values
        .where((n) => !n.isDeleted && n.tags.contains(tag))
        .toList();
    for (final note in affected) {
      note.tags = note.tags.where((t) => t != tag).toList();
      note.updatedAt = DateTime.now();
      await HiveService.notesBox.put(note.id, note);
    }
  }

  /// Get all unique tags across all active notes with note counts.
  Map<String, int> getAllTagsWithCounts() {
    final counts = <String, int>{};
    for (final note in getAllNotes()) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Get all notes that have a specific tag.
  List<Note> getNotesByTag(String tag) {
    return getAllNotes().where((n) => n.tags.contains(tag)).toList();
  }
}
