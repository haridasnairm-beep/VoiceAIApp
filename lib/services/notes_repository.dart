import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/transcript_version.dart';
import 'hive_service.dart';

/// Repository for Note CRUD operations against Hive.
class NotesRepository {
  static const _uuid = Uuid();

  /// Get all notes, sorted by creation date (newest first).
  List<Note> getAllNotes() {
    final notes = HiveService.notesBox.values.toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  /// Delete a note by ID.
  Future<void> deleteNote(String id) async {
    await HiveService.notesBox.delete(id);
  }

  /// Search notes by query string.
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return getAllNotes();
    final lower = query.toLowerCase();
    return getAllNotes().where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.rawTranscription.toLowerCase().contains(lower) ||
          n.topics.any((t) => t.toLowerCase().contains(lower));
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
      String noteId, String newText, String editSource) async {
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
    );

    note.transcriptVersions = [...note.transcriptVersions, version];
    note.rawTranscription = newText;
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

    await addTranscriptVersion(
        noteId, version.text, 'Restored from v${version.versionNumber}');
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
}
