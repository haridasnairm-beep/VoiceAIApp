import 'package:uuid/uuid.dart';
import '../models/note.dart';
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
  }) async {
    final note = Note(
      id: _uuid.v4(),
      title: title,
      rawTranscription: rawTranscription,
      detectedLanguage: detectedLanguage,
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
      folderId: folderId,
      isProcessed: true,
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
}
