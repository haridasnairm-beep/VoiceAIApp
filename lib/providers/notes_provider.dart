import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a single note's structured data.
/// Will be replaced with Hive model in Step 3.
class NoteState {
  final String id;
  final String title;
  final String rawTranscription;
  final String detectedLanguage;
  final String audioFilePath;
  final int audioDurationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final List<String> topics;
  final bool isProcessed;

  const NoteState({
    required this.id,
    required this.title,
    required this.rawTranscription,
    required this.detectedLanguage,
    required this.audioFilePath,
    this.audioDurationSeconds = 0,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.topics = const [],
    this.isProcessed = false,
  });

  NoteState copyWith({
    String? title,
    String? rawTranscription,
    String? detectedLanguage,
    String? folderId,
    List<String>? topics,
    bool? isProcessed,
    DateTime? updatedAt,
  }) {
    return NoteState(
      id: id,
      title: title ?? this.title,
      rawTranscription: rawTranscription ?? this.rawTranscription,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      folderId: folderId ?? this.folderId,
      topics: topics ?? this.topics,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
}

/// Notifier that manages the list of all notes.
/// In Step 3, this will read/write from Hive.
class NotesNotifier extends Notifier<List<NoteState>> {
  @override
  List<NoteState> build() => [];

  void addNote(NoteState note) {
    state = [note, ...state];
  }

  void updateNote(NoteState updated) {
    state = [
      for (final note in state)
        if (note.id == updated.id) updated else note,
    ];
  }

  void deleteNote(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  NoteState? getNoteById(String id) {
    try {
      return state.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  List<NoteState> searchNotes(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state.where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.rawTranscription.toLowerCase().contains(lower) ||
          n.topics.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }

  List<NoteState> getUnprocessedNotes() {
    return state.where((n) => !n.isProcessed).toList();
  }
}

/// Provider for the notes list.
final notesProvider =
    NotifierProvider<NotesNotifier, List<NoteState>>(NotesNotifier.new);
