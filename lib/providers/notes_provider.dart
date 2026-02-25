import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../services/notes_repository.dart';

/// Provider for the NotesRepository singleton.
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository();
});

/// Notifier that manages the list of all notes, backed by Hive.
class NotesNotifier extends Notifier<List<Note>> {
  @override
  List<Note> build() {
    return ref.read(notesRepositoryProvider).getAllNotes();
  }

  void refresh() {
    state = ref.read(notesRepositoryProvider).getAllNotes();
  }

  Future<Note> addNote({
    required String audioFilePath,
    int audioDurationSeconds = 0,
    String title = 'Untitled Note',
  }) async {
    final repo = ref.read(notesRepositoryProvider);
    final note = await repo.createNote(
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
      title: title,
    );
    state = [note, ...state];
    return note;
  }

  Future<void> updateNote(Note note) async {
    await ref.read(notesRepositoryProvider).updateNote(note);
    state = [
      for (final n in state)
        if (n.id == note.id) note else n,
    ];
  }

  Future<void> deleteNote(String id) async {
    await ref.read(notesRepositoryProvider).deleteNote(id);
    state = state.where((n) => n.id != id).toList();
  }

  Note? getNoteById(String id) {
    try {
      return state.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state.where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.rawTranscription.toLowerCase().contains(lower) ||
          n.topics.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }

  List<Note> getUnprocessedNotes() {
    return state.where((n) => !n.isProcessed).toList();
  }
}

/// Provider for the notes list.
final notesProvider =
    NotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);
