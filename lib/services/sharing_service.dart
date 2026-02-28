import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/project_document.dart';
import '../models/project_block.dart';

/// Service for assembling share text and generating export files.
class SharingService {
  /// Assemble formatted text for sharing a single note.
  String assembleNoteText(Note note) {
    final buffer = StringBuffer();
    buffer.writeln(note.title);
    buffer.writeln('─' * 30);
    buffer.writeln();

    if (note.rawTranscription.isNotEmpty) {
      buffer.writeln(note.contentFormat == 'quill_delta'
          ? _stripQuillDelta(note.rawTranscription)
          : note.rawTranscription);
      buffer.writeln();
    }

    if (note.actions.isNotEmpty) {
      buffer.writeln('Action Items:');
      for (final action in note.actions) {
        final check = action.isCompleted ? '[x]' : '[ ]';
        buffer.writeln('$check ${action.text}');
      }
      buffer.writeln();
    }

    if (note.todos.isNotEmpty) {
      buffer.writeln('Todos:');
      for (final todo in note.todos) {
        final check = todo.isCompleted ? '[x]' : '[ ]';
        final due = todo.dueDate != null
            ? ' (due: ${_formatDate(todo.dueDate!)})'
            : '';
        buffer.writeln('$check ${todo.text}$due');
      }
      buffer.writeln();
    }

    if (note.reminders.isNotEmpty) {
      buffer.writeln('Reminders:');
      for (final reminder in note.reminders) {
        final check = reminder.isCompleted ? '[x]' : '[ ]';
        final time = reminder.reminderTime != null
            ? ' (${_formatDateTime(reminder.reminderTime!)})'
            : '';
        buffer.writeln('$check ${reminder.text}$time');
      }
      buffer.writeln();
    }

    buffer.writeln('— Shared from VoiceNotes AI');
    return buffer.toString().trimRight();
  }

  /// Assemble formatted text for sharing a project document.
  String assembleDocumentText(ProjectDocument doc, List<Note> allNotes) {
    final buffer = StringBuffer();
    buffer.writeln(doc.title);
    if (doc.description != null && doc.description!.isNotEmpty) {
      buffer.writeln(doc.description);
    }
    buffer.writeln('═' * 30);
    buffer.writeln();

    final sortedBlocks = List.of(doc.blocks)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final block in sortedBlocks) {
      switch (block.type) {
        case BlockType.sectionHeader:
          buffer.writeln('## ${block.content ?? ''}');
          buffer.writeln();
          break;
        case BlockType.freeText:
          final content = block.content ?? '';
          if (block.contentFormat == 'quill_delta') {
            buffer.writeln(_stripQuillDelta(content));
          } else {
            buffer.writeln(content);
          }
          buffer.writeln();
          break;
        case BlockType.noteReference:
          if (block.noteId != null) {
            final note = allNotes.where((n) => n.id == block.noteId).firstOrNull;
            if (note != null) {
              buffer.writeln('📝 ${note.title}');
              buffer.writeln(note.contentFormat == 'quill_delta'
                  ? _stripQuillDelta(note.rawTranscription)
                  : note.rawTranscription);
            } else {
              buffer.writeln('📝 [Note deleted]');
            }
          }
          buffer.writeln();
          break;
        case BlockType.imageBlock:
          final caption = block.content ?? 'Photo';
          buffer.writeln('🖼️ [$caption]');
          buffer.writeln();
          break;
      }
    }

    buffer.writeln('— Shared from VoiceNotes AI');
    return buffer.toString().trimRight();
  }

  /// Export project document as Markdown file.
  Future<File> exportDocumentAsMarkdown(
      ProjectDocument doc, List<Note> allNotes) async {
    final buffer = StringBuffer();
    buffer.writeln('# ${doc.title}');
    if (doc.description != null && doc.description!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('*${doc.description}*');
    }
    buffer.writeln();

    final sortedBlocks = List.of(doc.blocks)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final block in sortedBlocks) {
      switch (block.type) {
        case BlockType.sectionHeader:
          buffer.writeln('## ${block.content ?? ''}');
          buffer.writeln();
          break;
        case BlockType.freeText:
          final content = block.content ?? '';
          if (block.contentFormat == 'quill_delta') {
            buffer.writeln(_deltaToMarkdown(content));
          } else {
            buffer.writeln(content);
          }
          buffer.writeln();
          break;
        case BlockType.noteReference:
          if (block.noteId != null) {
            final note = allNotes.where((n) => n.id == block.noteId).firstOrNull;
            if (note != null) {
              buffer.writeln('### ${note.title}');
              buffer.writeln();
              final noteText = note.contentFormat == 'quill_delta'
                  ? _stripQuillDelta(note.rawTranscription)
                  : note.rawTranscription;
              buffer.writeln('> ${noteText.replaceAll('\n', '\n> ')}');
            } else {
              buffer.writeln('### [Note deleted]');
            }
          }
          buffer.writeln();
          break;
        case BlockType.imageBlock:
          final caption = block.content ?? 'Photo';
          buffer.writeln('*[Image: $caption]*');
          buffer.writeln();
          break;
      }
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = doc.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final date = _formatDateShort(DateTime.now());
    final file = File('${tempDir.path}/${safeName}_$date.md');
    await file.writeAsString(buffer.toString());
    return file;
  }

  /// Export project document as plain text file.
  Future<File> exportDocumentAsPlainText(
      ProjectDocument doc, List<Note> allNotes) async {
    final text = assembleDocumentText(doc, allNotes);
    final tempDir = await getTemporaryDirectory();
    final safeName = doc.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final date = _formatDateShort(DateTime.now());
    final file = File('${tempDir.path}/${safeName}_$date.txt');
    await file.writeAsString(text);
    return file;
  }

  /// Strip Quill Delta JSON to plain text.
  String _stripQuillDelta(String deltaJson) {
    try {
      // Simple extraction: Quill Delta is [{insert: "text\n"}, ...]
      // Extract all 'insert' string values
      final buffer = StringBuffer();
      final regex = RegExp(r'"insert"\s*:\s*"([^"]*)"');
      for (final match in regex.allMatches(deltaJson)) {
        buffer.write(match.group(1)?.replaceAll(r'\n', '\n') ?? '');
      }
      return buffer.toString().trim();
    } catch (e) {
      return deltaJson;
    }
  }

  /// Convert Quill Delta JSON to basic Markdown.
  String _deltaToMarkdown(String deltaJson) {
    // For Phase 1, use simple text extraction.
    // Full Delta-to-Markdown conversion can be enhanced later.
    return _stripQuillDelta(deltaJson);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $hour:$min $amPm';
  }

  String _formatDateShort(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
