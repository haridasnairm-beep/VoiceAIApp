import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/reminder_item.dart';
import '../models/transcript_version.dart';
import '../services/notes_repository.dart';
import '../services/notification_service.dart';
import '../services/voice_command_processor.dart';
import '../services/whisper_service.dart';
import '../services/title_generator_service.dart';
import '../utils/profanity_filter.dart';
import 'folders_provider.dart';
import 'project_documents_provider.dart';
import 'settings_provider.dart';

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

  /// Generate the next auto-incrementing title using the given prefix.
  /// e.g. prefix "VOICE" → VOICE001, VOICE002, ...
  String _generateTitleWithPrefix(String prefix) {
    int maxNum = 0;
    for (final note in state) {
      if (note.title.startsWith(prefix)) {
        final suffix = note.title.substring(prefix.length);
        final num = int.tryParse(suffix);
        if (num != null && num > maxNum) {
          maxNum = num;
        }
      }
    }
    final next = maxNum + 1;
    return '$prefix${next.toString().padLeft(3, '0')}';
  }

  /// Generate title for voice notes using notePrefix setting.
  String _generateTitle() {
    final prefix = ref.read(settingsProvider).notePrefix;
    return _generateTitleWithPrefix(prefix);
  }

  /// Generate title for text notes using textNotePrefix setting.
  String _generateTextNoteTitle() {
    final prefix = ref.read(settingsProvider).textNotePrefix;
    return _generateTitleWithPrefix(prefix);
  }

  Future<Note> addNote({
    required String audioFilePath,
    int audioDurationSeconds = 0,
    String? title,
    String rawTranscription = '',
    String detectedLanguage = 'en',
    String? folderId,
    bool isProcessed = true,
  }) async {
    final isTextNote = audioFilePath.isEmpty;

    // Use text prefix for text notes, voice prefix for voice notes
    final noteTitle = title ??
        (isTextNote ? _generateTextNoteTitle() : _generateTitle());

    // Text notes default to General folder if no folder specified
    String? effectiveFolderId = folderId;
    if (isTextNote && effectiveFolderId == null) {
      final folders = ref.read(foldersProvider);
      final generalFolder = folders
          .where((f) => f.name.toLowerCase() == 'general')
          .firstOrNull;
      if (generalFolder != null) {
        effectiveFolderId = generalFolder.id;
      }
    }

    final repo = ref.read(notesRepositoryProvider);
    final note = await repo.createNote(
      audioFilePath: audioFilePath,
      audioDurationSeconds: audioDurationSeconds,
      title: noteTitle,
      rawTranscription: rawTranscription,
      detectedLanguage: detectedLanguage,
      folderId: effectiveFolderId,
      isProcessed: isProcessed,
    );

    // Add to General folder's noteIds list
    if (isTextNote && effectiveFolderId != null) {
      ref
          .read(foldersProvider.notifier)
          .addNoteToFolder(effectiveFolderId, note.id);
    }

    state = [note, ...state];
    return note;
  }

  /// Toggle pin status. Returns false if max 10 pinned notes reached.
  Future<bool> togglePin(String noteId) async {
    final note = getNoteById(noteId);
    if (note == null) return false;

    if (!note.isPinned) {
      // Check max 10 pinned
      final pinnedCount = state.where((n) => n.isPinned).length;
      if (pinnedCount >= 10) return false;
      note.isPinned = true;
      note.pinnedAt = DateTime.now();
    } else {
      note.isPinned = false;
      note.pinnedAt = null;
    }
    note.updatedAt = DateTime.now();
    await updateNote(note);
    return true;
  }

  /// Transcribe a WAV file in the background using Whisper and update the note.
  /// If voice commands are enabled, parses for folder/project keywords and
  /// auto-links the note (only when user didn't manually select from dropdown).
  Future<void> transcribeInBackground(
    String noteId,
    String wavPath, {
    String language = 'en',
    bool hasManualFolder = false,
    bool hasManualProject = false,
  }) async {
    try {
      // Determine if we need translation to English
      final settings = ref.read(settingsProvider);
      final isTranslate = (language != 'en' && settings.noteOutputMode == 'english');
      var transcription = await WhisperService.instance.transcribe(
        wavPath,
        language: language,
        isTranslate: isTranslate,
      );

      // Apply profanity filter if enabled
      if (settings.blockOffensiveWords) {
        transcription = ProfanityFilter.instance.filter(transcription);
      }

      final note = getNoteById(noteId);
      if (note == null) return;

      // Check if voice commands are enabled
      final voiceCommandsEnabled =
          ref.read(settingsProvider).voiceCommandsEnabled;

      if (voiceCommandsEnabled && transcription.isNotEmpty) {
        debugPrint('VoiceCmd: processing transcription (${transcription.length} chars)');
        final result =
            await VoiceCommandProcessor.process(transcription, ref);
        debugPrint('VoiceCmd: hasFolder=${result.folderId != null}, hasProject=${result.projectId != null}, content="${result.noteContent}"');

        // Use processed content (command prefix stripped)
        note.rawTranscription = result.noteContent.isNotEmpty
            ? result.noteContent
            : 'No speech detected';

        // Auto-assign folder if detected and user didn't manually select one
        if (result.folderId != null && !hasManualFolder) {
          note.folderId = result.folderId;
          ref
              .read(foldersProvider.notifier)
              .addNoteToFolder(result.folderId!, noteId);
          debugPrint('VoiceCmd: assigned folder ${result.folderId}');
        }

        // Auto-link to project if detected and user didn't manually select one
        if (result.projectId != null && !hasManualProject) {
          ref
              .read(projectDocumentsProvider.notifier)
              .addNoteBlock(result.projectId!, noteId);
          debugPrint('VoiceCmd: linked to project ${result.projectId}');
        }

        // Auto-create task item if voice command detected a task keyword
        if (result.taskType != null && result.taskDescription != null) {
          debugPrint('VoiceCmd: creating ${result.taskType} task: "${result.taskDescription}"');
          switch (result.taskType) {
            case 'todo':
              await addTodoItem(noteId: noteId, text: result.taskDescription!);
              break;
            case 'action':
              await addActionItem(noteId: noteId, text: result.taskDescription!);
              break;
            case 'reminder':
              final tomorrow = DateTime.now().add(const Duration(days: 1));
              final notifEnabled = ref.read(settingsProvider).notificationsEnabled;
              await addReminder(
                noteId: noteId,
                text: result.taskDescription!,
                reminderTime: tomorrow,
                notificationsEnabled: notifEnabled,
              );
              break;
          }
        }
      } else {
        note.rawTranscription =
            transcription.isNotEmpty ? transcription : 'No speech detected';
      }

      note.isProcessed = true;
      note.detectedLanguage = 'auto';
      note.transcriptionModel = WhisperService.instance.currentModelName;

      // Auto-generate title from transcription if user hasn't manually edited it
      if (!note.isUserEditedTitle && note.rawTranscription.isNotEmpty) {
        final autoTitle = TitleGeneratorService.generate(
          note.rawTranscription,
          todos: note.todos.map((t) => t.text).toList(),
          actions: note.actions.map((a) => a.text).toList(),
          reminders: note.reminders.map((r) => r.text).toList(),
        );
        if (autoTitle != null) {
          note.title = autoTitle;
        }
      }

      await updateNote(note);
    } catch (_) {
      final note = getNoteById(noteId);
      if (note == null) return;
      note.rawTranscription = 'Transcription failed';
      note.isProcessed = true;
      await updateNote(note);
    }
  }

  /// Re-transcribe an existing note using the currently active Whisper model.
  /// Saves old transcription as a version, replaces rawTranscription,
  /// and updates transcriptionModel. Returns true on success.
  Future<bool> retranscribeNote(String noteId) async {
    final note = getNoteById(noteId);
    if (note == null) return false;
    if (note.audioFilePath.isEmpty) return false;
    final audioFile = File(note.audioFilePath);
    if (!await audioFile.exists()) return false;

    try {
      // Save current transcription as a version before overwriting
      if (note.rawTranscription.isNotEmpty) {
        final oldModel = note.transcriptionModel ?? 'unknown';
        final oldText = note.contentFormat == 'quill_delta'
            ? _extractPlainText(note.rawTranscription)
            : note.rawTranscription;
        await addTranscriptVersion(
          noteId, oldText, 'Before re-transcription (model: $oldModel)',
        );
      }

      // Transcribe with current model
      final settings = ref.read(settingsProvider);
      final language = note.detectedLanguage == 'auto'
          ? (settings.defaultLanguage ?? 'en')
          : note.detectedLanguage;
      final isTranslate =
          (language != 'en' && settings.noteOutputMode == 'english');

      final transcription = await WhisperService.instance.transcribe(
        note.audioFilePath,
        language: language,
        isTranslate: isTranslate,
      );

      note.rawTranscription =
          transcription.isNotEmpty ? transcription : 'No speech detected';
      note.transcriptionModel = WhisperService.instance.currentModelName;
      note.isProcessed = true;
      note.updatedAt = DateTime.now();

      // Auto-generate title if user hasn't manually edited it
      if (!note.isUserEditedTitle && note.rawTranscription.isNotEmpty) {
        final autoTitle = TitleGeneratorService.generate(note.rawTranscription);
        if (autoTitle != null) {
          note.title = autoTitle;
        }
      }

      // Reset rich text format since re-transcription produces plain text
      if (note.contentFormat == 'quill_delta') {
        note.contentFormat = null;
      }

      await updateNote(note);

      // Add new transcription as a version
      await addTranscriptVersion(
        noteId,
        note.rawTranscription,
        'Re-transcribed (model: ${WhisperService.instance.currentModelName})',
      );

      return true;
    } catch (e) {
      debugPrint('retranscribeNote failed: $e');
      return false;
    }
  }

  /// Helper to extract plain text from quill delta JSON.
  String _extractPlainText(String deltaJson) {
    try {
      // Simple extraction: pull all "insert" string values
      final buffer = StringBuffer();
      final regex = RegExp(r'"insert"\s*:\s*"([^"]*)"');
      for (final match in regex.allMatches(deltaJson)) {
        buffer.write(match.group(1)?.replaceAll(r'\n', '\n') ?? '');
      }
      return buffer.toString().trim();
    } catch (_) {
      return deltaJson;
    }
  }

  /// Get notes eligible for re-transcription (have audio file on disk).
  Future<List<Note>> getRetranscribableNotes() async {
    final eligible = <Note>[];
    for (final note in state) {
      if (note.audioFilePath.isEmpty) continue;
      final file = File(note.audioFilePath);
      if (await file.exists()) {
        eligible.add(note);
      }
    }
    return eligible;
  }

  /// Re-transcribe multiple notes sequentially with progress callback.
  /// Returns count of successfully re-transcribed notes.
  Future<int> bulkRetranscribe({
    required List<String> noteIds,
    void Function(int completed, int total)? onProgress,
  }) async {
    await WakelockPlus.enable();
    int success = 0;
    try {
      for (int i = 0; i < noteIds.length; i++) {
        final ok = await retranscribeNote(noteIds[i]);
        if (ok) success++;
        onProgress?.call(i + 1, noteIds.length);
      }
    } finally {
      await WakelockPlus.disable();
    }
    return success;
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

  /// Restore a note from trash.
  Future<void> restoreNote(String id) async {
    await ref.read(notesRepositoryProvider).restoreNote(id);
    refresh();
  }

  /// Permanently delete a note (cannot be undone).
  Future<void> permanentlyDeleteNote(String id) async {
    await ref.read(notesRepositoryProvider).permanentlyDeleteNote(id);
  }

  /// Get all trashed notes.
  List<Note> getTrashedNotes() {
    return ref.read(notesRepositoryProvider).getTrashedNotes();
  }

  /// Purge expired trash items (> 30 days).
  Future<int> purgeExpiredTrash() async {
    return ref.read(notesRepositoryProvider).purgeExpiredTrash();
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
          n.topics.any((t) => t.toLowerCase().contains(lower)) ||
          n.actions.any((a) => a.text.toLowerCase().contains(lower)) ||
          n.todos.any((t) => t.text.toLowerCase().contains(lower)) ||
          n.reminders.any((r) => r.text.toLowerCase().contains(lower));
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

  // --- Transcript Versioning ---

  /// Add a transcript version and update rawTranscription.
  Future<void> addTranscriptVersion(
      String noteId, String newText, String editSource,
      {String? richContentJson}) async {
    await ref
        .read(notesRepositoryProvider)
        .addTranscriptVersion(noteId, newText, editSource,
            richContentJson: richContentJson);
    refresh();
  }

  /// Get all transcript versions for a note.
  List<TranscriptVersion> getTranscriptVersions(String noteId) {
    return ref.read(notesRepositoryProvider).getTranscriptVersions(noteId);
  }

  /// Restore a transcript version.
  Future<void> restoreTranscriptVersion(
      String noteId, String versionId) async {
    await ref
        .read(notesRepositoryProvider)
        .restoreTranscriptVersion(noteId, versionId);
    refresh();
  }

  /// Migrate existing notes to have at least one transcript version.
  Future<void> migrateTranscriptVersions() async {
    final repo = ref.read(notesRepositoryProvider);
    for (final note in state) {
      await repo.ensureTranscriptVersion(note);
    }
    refresh();
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

  // --- Todo Item CRUD ---

  /// Toggle a todo item's completed state.
  Future<void> toggleTodoCompleted({
    required String noteId,
    required String todoId,
  }) async {
    await ref.read(notesRepositoryProvider).toggleTodoCompleted(noteId, todoId);
    refresh();
  }

  /// Add a new todo item to a note.
  Future<void> addTodoItem({
    required String noteId,
    required String text,
    DateTime? dueDate,
  }) async {
    await ref
        .read(notesRepositoryProvider)
        .addTodoItem(noteId, text, dueDate: dueDate);
    refresh();
  }

  /// Update a todo item's text and/or due date.
  Future<void> updateTodoItem({
    required String noteId,
    required String todoId,
    String? text,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    await ref.read(notesRepositoryProvider).updateTodoItem(
          noteId,
          todoId,
          text: text,
          dueDate: dueDate,
          clearDueDate: clearDueDate,
        );
    refresh();
  }

  /// Delete a todo item from a note.
  Future<void> deleteTodoItem({
    required String noteId,
    required String todoId,
  }) async {
    await ref.read(notesRepositoryProvider).deleteTodoItem(noteId, todoId);
    refresh();
  }

  // --- Action Item CRUD ---

  /// Toggle an action item's completed state.
  Future<void> toggleActionCompleted({
    required String noteId,
    required String actionId,
  }) async {
    await ref
        .read(notesRepositoryProvider)
        .toggleActionCompleted(noteId, actionId);
    refresh();
  }

  /// Add a new action item to a note.
  Future<void> addActionItem({
    required String noteId,
    required String text,
  }) async {
    await ref.read(notesRepositoryProvider).addActionItem(noteId, text);
    refresh();
  }

  /// Update an action item's text.
  Future<void> updateActionItem({
    required String noteId,
    required String actionId,
    required String text,
  }) async {
    await ref
        .read(notesRepositoryProvider)
        .updateActionItem(noteId, actionId, text);
    refresh();
  }

  /// Delete an action item from a note.
  Future<void> deleteActionItem({
    required String noteId,
    required String actionId,
  }) async {
    await ref.read(notesRepositoryProvider).deleteActionItem(noteId, actionId);
    refresh();
  }

  // --- Reminder Enhancement ---

  /// Reschedule a reminder to a new time, cancelling the old notification
  /// and scheduling a new one.
  Future<void> rescheduleReminder({
    required String noteId,
    required String reminderId,
    required DateTime newTime,
    required bool notificationsEnabled,
  }) async {
    final note = getNoteById(noteId);
    if (note == null) return;

    final reminder =
        note.reminders.where((r) => r.id == reminderId).firstOrNull;
    if (reminder == null) return;

    // Cancel old notification
    if (reminder.notificationId != null) {
      await NotificationService.instance
          .cancelNotification(reminder.notificationId!);
    }

    // Update in repository
    await ref
        .read(notesRepositoryProvider)
        .rescheduleReminder(noteId, reminderId, newTime);

    // Schedule new notification
    if (notificationsEnabled && newTime.isAfter(DateTime.now())) {
      final notificationId = reminder.notificationId ??
          (reminderId.hashCode & 0x7FFFFFFF);
      await NotificationService.instance.scheduleReminder(
        notificationId: notificationId,
        title: 'Reminder: ${note.title}',
        body: reminder.text,
        scheduledTime: newTime,
        noteId: noteId,
      );
    }

    refresh();
  }

  /// Add an image attachment to a note.
  Future<void> addImageAttachment({
    required String noteId,
    required String attachmentId,
  }) async {
    await ref.read(notesRepositoryProvider).addImageAttachment(noteId, attachmentId);
    refresh();
  }

  /// Remove an image attachment from a note.
  Future<void> removeImageAttachment({
    required String noteId,
    required String attachmentId,
  }) async {
    await ref.read(notesRepositoryProvider).removeImageAttachment(noteId, attachmentId);
    refresh();
  }
}

/// Provider for the notes list.
final notesProvider =
    NotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);
