import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/reminder_item.dart';
import '../services/notes_repository.dart';
import '../services/notification_service.dart';

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
    String rawTranscription = '',
    String detectedLanguage = 'en',
    String? folderId,
  }) async {
    final repo = ref.read(notesRepositoryProvider);
    final note = await repo.createNote(
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
      title: title,
      rawTranscription: rawTranscription,
      detectedLanguage: detectedLanguage,
      folderId: folderId,
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

  static const _uuid = Uuid();

  /// Add a manual reminder to a note and schedule a notification.
  Future<void> addReminder({
    required String noteId,
    required String text,
    required DateTime reminderTime,
    required bool notificationsEnabled,
  }) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final reminderId = _uuid.v4();
    final notificationId = reminderId.hashCode & 0x7FFFFFFF;

    final reminder = ReminderItem(
      id: reminderId,
      text: text,
      reminderTime: reminderTime,
      notificationId: notificationId,
    );

    note.reminders = [...note.reminders, reminder];
    note.updatedAt = DateTime.now();
    await updateNote(note);

    if (notificationsEnabled && reminderTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleReminder(
        notificationId: notificationId,
        title: 'Reminder: ${note.title}',
        body: text,
        scheduledTime: reminderTime,
        noteId: noteId,
      );
    }
  }

  /// Toggle a reminder's completed state and cancel its notification.
  Future<void> toggleReminderCompleted({
    required String noteId,
    required String reminderId,
  }) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final idx = note.reminders.indexWhere((r) => r.id == reminderId);
    if (idx == -1) return;

    note.reminders[idx].isCompleted = !note.reminders[idx].isCompleted;
    note.updatedAt = DateTime.now();

    if (note.reminders[idx].isCompleted &&
        note.reminders[idx].notificationId != null) {
      await NotificationService.instance
          .cancelNotification(note.reminders[idx].notificationId!);
    }

    await updateNote(note);
  }

  /// Delete a reminder from a note and cancel its notification.
  Future<void> deleteReminder({
    required String noteId,
    required String reminderId,
  }) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final reminder = note.reminders.where((r) => r.id == reminderId).firstOrNull;
    if (reminder?.notificationId != null) {
      await NotificationService.instance
          .cancelNotification(reminder!.notificationId!);
    }

    note.reminders = note.reminders.where((r) => r.id != reminderId).toList();
    note.updatedAt = DateTime.now();
    await updateNote(note);
  }
}

/// Provider for the notes list.
final notesProvider =
    NotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);
