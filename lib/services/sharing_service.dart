import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/note.dart';
import '../models/project_document.dart';
import '../models/project_block.dart';

/// Options controlling what to include in shared content.
class ShareOptions {
  final bool includeTitle;
  final bool includeTimestamp;
  final bool plainTextOnly;
  final bool includeNoteTitles; // For project documents — show/hide note titles

  const ShareOptions({
    this.includeTitle = true,
    this.includeTimestamp = false,
    this.plainTextOnly = false,
    this.includeNoteTitles = true,
  });
}

/// Service for assembling share text, generating export files, and PDF export.
class SharingService {
  // ---------------------------------------------------------------------------
  // Email subject helpers
  // ---------------------------------------------------------------------------

  static String noteSubject(String title) =>
      '$title — Notes from VoiceNotes AI';

  static String documentSubject(String title) =>
      '$title — Project from VoiceNotes AI';

  // ---------------------------------------------------------------------------
  // Text assembly — Notes
  // ---------------------------------------------------------------------------

  String assembleNoteText(Note note,
      {ShareOptions options = const ShareOptions()}) {
    final buffer = StringBuffer();

    if (options.includeTitle) {
      buffer.writeln(note.title);
      buffer.writeln('_' * max(note.title.length, 10));
      buffer.writeln();
    }

    if (options.includeTimestamp) {
      buffer.writeln('Created: ${_formatDateTime(note.createdAt)}');
      buffer.writeln();
    }

    if (note.rawTranscription.isNotEmpty) {
      buffer.writeln(_renderContent(
        note.rawTranscription,
        note.contentFormat,
        options.plainTextOnly,
      ));
      buffer.writeln();
    }

    _appendActionsAndTasks(buffer, note);

    buffer.writeln('— Shared from VoiceNotes AI');
    return buffer.toString().trimRight();
  }

  // ---------------------------------------------------------------------------
  // Text assembly — Project Documents
  // ---------------------------------------------------------------------------

  String assembleDocumentText(ProjectDocument doc, List<Note> allNotes,
      {ShareOptions options = const ShareOptions()}) {
    final buffer = StringBuffer();

    if (options.includeTitle) {
      buffer.writeln(doc.title);
      if (doc.description != null && doc.description!.isNotEmpty) {
        buffer.writeln(doc.description);
      }
      buffer.writeln('_' * max(doc.title.length, 10));
      buffer.writeln();
    }

    if (options.includeTimestamp) {
      buffer.writeln('Created: ${_formatDateTime(doc.createdAt)}');
      buffer.writeln();
    }

    final sortedBlocks = List.of(doc.blocks)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final block in sortedBlocks) {
      switch (block.type) {
        case BlockType.sectionHeader:
          final text = _renderContent(
              block.content ?? '', block.contentFormat, options.plainTextOnly);
          buffer.writeln('## $text');
          buffer.writeln();
          break;
        case BlockType.freeText:
          buffer.writeln(_renderContent(
              block.content ?? '', block.contentFormat, options.plainTextOnly));
          buffer.writeln();
          break;
        case BlockType.noteReference:
          if (block.noteId != null) {
            final note =
                allNotes.where((n) => n.id == block.noteId).firstOrNull;
            if (note != null) {
              if (options.includeNoteTitles) {
                buffer.writeln('📝 ${note.title}');
              }
              buffer.writeln(_renderContent(
                note.rawTranscription,
                note.contentFormat,
                options.plainTextOnly,
              ));
            } else {
              if (options.includeNoteTitles) {
                buffer.writeln('📝 [Note deleted]');
              }
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

  // ---------------------------------------------------------------------------
  // Markdown file export (Project Documents)
  // ---------------------------------------------------------------------------

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
          final text = _renderContent(
              block.content ?? '', block.contentFormat, false);
          buffer.writeln('## $text');
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
            final note =
                allNotes.where((n) => n.id == block.noteId).firstOrNull;
            if (note != null) {
              buffer.writeln('### ${note.title}');
              buffer.writeln();
              final noteText = note.contentFormat == 'quill_delta'
                  ? _deltaToMarkdown(note.rawTranscription)
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

  // ---------------------------------------------------------------------------
  // PDF export — Notes
  // ---------------------------------------------------------------------------

  Future<File> exportNoteAsPdf(Note note,
      {ShareOptions options = const ShareOptions()}) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Shared from VoiceNotes AI',
            style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
                fontStyle: pw.FontStyle.italic)),
      ),
      build: (context) {
        final widgets = <pw.Widget>[];

        if (options.includeTitle) {
          widgets.add(pw.Text(note.title,
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold)));
          widgets.add(pw.Divider());
          widgets.add(pw.SizedBox(height: 8));
        }

        if (options.includeTimestamp) {
          widgets.add(pw.Text(
              'Created: ${_formatDateTime(note.createdAt)}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)));
          widgets.add(pw.SizedBox(height: 12));
        }

        if (note.rawTranscription.isNotEmpty) {
          if (!options.plainTextOnly &&
              note.contentFormat == 'quill_delta') {
            widgets.addAll(_deltaToPdfWidgets(note.rawTranscription));
          } else {
            final plain = note.contentFormat == 'quill_delta'
                ? _stripQuillDelta(note.rawTranscription)
                : note.rawTranscription;
            widgets.add(
                pw.Text(plain, style: const pw.TextStyle(fontSize: 12)));
          }
          widgets.add(pw.SizedBox(height: 12));
        }

        _appendPdfTasks(widgets, note);

        return widgets;
      },
    ));

    final tempDir = await getTemporaryDirectory();
    final safeName = note.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final date = _formatDateShort(DateTime.now());
    final file = File('${tempDir.path}/${safeName}_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ---------------------------------------------------------------------------
  // PDF export — Project Documents
  // ---------------------------------------------------------------------------

  Future<File> exportDocumentAsPdf(
      ProjectDocument doc, List<Note> allNotes,
      {ShareOptions options = const ShareOptions()}) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Shared from VoiceNotes AI',
            style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
                fontStyle: pw.FontStyle.italic)),
      ),
      build: (context) {
        final widgets = <pw.Widget>[];

        if (options.includeTitle) {
          widgets.add(pw.Text(doc.title,
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold)));
          if (doc.description != null && doc.description!.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text(doc.description!,
                style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic)));
          }
          widgets.add(pw.Divider());
          widgets.add(pw.SizedBox(height: 8));
        }

        if (options.includeTimestamp) {
          widgets.add(pw.Text(
              'Created: ${_formatDateTime(doc.createdAt)}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)));
          widgets.add(pw.SizedBox(height: 12));
        }

        final sortedBlocks = List.of(doc.blocks)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        for (final block in sortedBlocks) {
          switch (block.type) {
            case BlockType.sectionHeader:
              widgets.add(pw.SizedBox(height: 8));
              final text = _getPlainContent(
                  block.content ?? '', block.contentFormat);
              widgets.add(pw.Text(text,
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)));
              widgets.add(pw.SizedBox(height: 6));
              break;
            case BlockType.freeText:
              final content = block.content ?? '';
              if (!options.plainTextOnly &&
                  block.contentFormat == 'quill_delta') {
                widgets.addAll(_deltaToPdfWidgets(content));
              } else {
                widgets.add(pw.Text(
                    _getPlainContent(content, block.contentFormat),
                    style: const pw.TextStyle(fontSize: 12)));
              }
              widgets.add(pw.SizedBox(height: 8));
              break;
            case BlockType.noteReference:
              if (block.noteId != null) {
                final note = allNotes
                    .where((n) => n.id == block.noteId)
                    .firstOrNull;
                if (note != null) {
                  widgets.add(pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    margin:
                        const pw.EdgeInsets.only(bottom: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: PdfColors.grey300, width: 0.5),
                      borderRadius:
                          pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        if (options.includeNoteTitles) ...[
                          pw.Text(note.title,
                              style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                        ],
                        if (!options.plainTextOnly &&
                            note.contentFormat ==
                                'quill_delta')
                          ..._deltaToPdfWidgets(
                              note.rawTranscription)
                        else
                          pw.Text(
                              _getPlainContent(
                                  note.rawTranscription,
                                  note.contentFormat),
                              style: const pw.TextStyle(
                                  fontSize: 11)),
                      ],
                    ),
                  ));
                } else {
                  widgets.add(pw.Text('[Note deleted]',
                      style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey500,
                          fontStyle: pw.FontStyle.italic)));
                }
              }
              break;
            case BlockType.imageBlock:
              final caption = block.content ?? 'Photo';
              widgets.add(pw.Text('[Image: $caption]',
                  style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic)));
              widgets.add(pw.SizedBox(height: 8));
              break;
          }
        }

        return widgets;
      },
    ));

    final tempDir = await getTemporaryDirectory();
    final safeName = doc.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final date = _formatDateShort(DateTime.now());
    final file = File('${tempDir.path}/${safeName}_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ---------------------------------------------------------------------------
  // Temp file cleanup
  // ---------------------------------------------------------------------------

  static Future<void> cleanupTempExports() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = tempDir.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final name = entity.path.split(Platform.pathSeparator).last;
          if (name.endsWith('.pdf') ||
              name.endsWith('.md') ||
              name.endsWith('.txt')) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Private helpers — content rendering
  // ---------------------------------------------------------------------------

  /// Render content as plain text or markdown depending on format & options.
  String _renderContent(
      String content, String? contentFormat, bool plainTextOnly) {
    if (contentFormat == 'quill_delta') {
      return plainTextOnly
          ? _stripQuillDelta(content)
          : _deltaToMarkdown(content);
    }
    return content;
  }

  /// Get plain text from content regardless of format.
  String _getPlainContent(String content, String? contentFormat) {
    if (contentFormat == 'quill_delta') {
      return _stripQuillDelta(content);
    }
    return content;
  }

  /// Append action items, todos, reminders to a StringBuffer.
  void _appendActionsAndTasks(StringBuffer buffer, Note note) {
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
  }

  /// Append action items, todos, reminders as PDF widgets.
  void _appendPdfTasks(List<pw.Widget> widgets, Note note) {
    if (note.actions.isNotEmpty) {
      widgets.add(pw.Text('Action Items',
          style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
      widgets.add(pw.SizedBox(height: 4));
      for (final a in note.actions) {
        final check = a.isCompleted ? '☑' : '☐';
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
          child: pw.Text('$check ${a.text}',
              style: pw.TextStyle(
                fontSize: 11,
                decoration:
                    a.isCompleted ? pw.TextDecoration.lineThrough : null,
              )),
        ));
      }
      widgets.add(pw.SizedBox(height: 8));
    }

    if (note.todos.isNotEmpty) {
      widgets.add(pw.Text('Todos',
          style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
      widgets.add(pw.SizedBox(height: 4));
      for (final t in note.todos) {
        final check = t.isCompleted ? '☑' : '☐';
        final due =
            t.dueDate != null ? ' (due: ${_formatDate(t.dueDate!)})' : '';
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
          child: pw.Text('$check ${t.text}$due',
              style: pw.TextStyle(
                fontSize: 11,
                decoration:
                    t.isCompleted ? pw.TextDecoration.lineThrough : null,
              )),
        ));
      }
      widgets.add(pw.SizedBox(height: 8));
    }

    if (note.reminders.isNotEmpty) {
      widgets.add(pw.Text('Reminders',
          style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
      widgets.add(pw.SizedBox(height: 4));
      for (final r in note.reminders) {
        final check = r.isCompleted ? '☑' : '☐';
        final time = r.reminderTime != null
            ? ' (${_formatDateTime(r.reminderTime!)})'
            : '';
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
          child: pw.Text('$check ${r.text}$time',
              style: const pw.TextStyle(fontSize: 11)),
        ));
      }
      widgets.add(pw.SizedBox(height: 8));
    }
  }

  // ---------------------------------------------------------------------------
  // Quill Delta conversion — Plain text
  // ---------------------------------------------------------------------------

  String _stripQuillDelta(String deltaJson) {
    try {
      final ops = jsonDecode(deltaJson) as List;
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is Map<String, dynamic>) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      // Fallback: regex extraction
      try {
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
  }

  // ---------------------------------------------------------------------------
  // Quill Delta conversion — Markdown
  // ---------------------------------------------------------------------------

  String _deltaToMarkdown(String deltaJson) {
    try {
      final ops = jsonDecode(deltaJson) as List;
      // Accumulate segments for the current line, flush on \n
      final resultLines = <String>[];
      final lineSegments = <String>[];
      Map<String, dynamic>? pendingLineAttrs;

      for (final op in ops) {
        if (op is! Map<String, dynamic>) continue;
        final insert = op['insert'];
        if (insert is! String) continue;
        final attrs = op['attributes'] as Map<String, dynamic>? ?? {};

        final parts = insert.split('\n');
        for (int i = 0; i < parts.length; i++) {
          final segment = parts[i];

          // Apply inline formatting to non-empty segments
          if (segment.isNotEmpty) {
            String formatted = segment;
            final hasBold = attrs.containsKey('bold');
            final hasItalic = attrs.containsKey('italic');
            if (hasBold && hasItalic) {
              formatted = '***$formatted***';
            } else if (hasBold) {
              formatted = '**$formatted**';
            } else if (hasItalic) {
              formatted = '*$formatted*';
            }
            lineSegments.add(formatted);
          }

          // If not the last part, we hit a \n — flush the line
          if (i < parts.length - 1) {
            // Line-level attrs are on the op containing the \n
            pendingLineAttrs = attrs;
            final line = lineSegments.join();
            lineSegments.clear();

            if (pendingLineAttrs.containsKey('header')) {
              final level = pendingLineAttrs['header'] as int;
              final prefix = '#' * level;
              resultLines.add('$prefix $line');
            } else if (pendingLineAttrs.containsKey('list')) {
              final listType = pendingLineAttrs['list'];
              if (listType == 'bullet') {
                resultLines.add('- $line');
              } else if (listType == 'ordered') {
                resultLines.add('1. $line');
              } else {
                resultLines.add(line);
              }
            } else {
              resultLines.add(line);
            }
            pendingLineAttrs = null;
          }
        }
      }

      // Flush remaining segments (if no trailing \n)
      if (lineSegments.isNotEmpty) {
        resultLines.add(lineSegments.join());
      }

      return resultLines.join('\n').trim();
    } catch (_) {
      return _stripQuillDelta(deltaJson);
    }
  }

  // ---------------------------------------------------------------------------
  // Quill Delta conversion — PDF widgets
  // ---------------------------------------------------------------------------

  List<pw.Widget> _deltaToPdfWidgets(String deltaJson) {
    try {
      final ops = jsonDecode(deltaJson) as List;
      final resultWidgets = <pw.Widget>[];
      final lineSpans = <pw.InlineSpan>[];
      Map<String, dynamic>? pendingLineAttrs;

      for (final op in ops) {
        if (op is! Map<String, dynamic>) continue;
        final insert = op['insert'];
        if (insert is! String) continue;
        final attrs = op['attributes'] as Map<String, dynamic>? ?? {};

        final parts = insert.split('\n');
        for (int i = 0; i < parts.length; i++) {
          final segment = parts[i];

          if (segment.isNotEmpty) {
            pw.FontWeight? fontWeight;
            pw.FontStyle? fontStyle;
            double fontSize = 12;

            if (attrs.containsKey('bold')) {
              fontWeight = pw.FontWeight.bold;
            }
            if (attrs.containsKey('italic')) {
              fontStyle = pw.FontStyle.italic;
            }
            if (attrs.containsKey('size')) {
              final s = attrs['size'];
              if (s is num) {
                fontSize = s.toDouble();
              } else if (s is String) {
                fontSize = double.tryParse(s) ?? 12;
              }
            }

            PdfColor? color;
            if (attrs.containsKey('color')) {
              color = _parsePdfColor(attrs['color']);
            }

            lineSpans.add(pw.TextSpan(
              text: segment,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                fontStyle: fontStyle,
                color: color,
              ),
            ));
          }

          // Newline — flush line
          if (i < parts.length - 1) {
            pendingLineAttrs = attrs;

            if (lineSpans.isEmpty) {
              // Empty line
              resultWidgets
                  .add(pw.SizedBox(height: 6));
            } else {
              final lineWidget = pw.RichText(
                  text: pw.TextSpan(children: List.of(lineSpans)));

              if (pendingLineAttrs.containsKey('header')) {
                final level = pendingLineAttrs['header'] as int;
                final headerSize = level == 1 ? 20.0 : 16.0;
                // Rebuild with header size
                final headerSpans = lineSpans
                    .map((s) {
                      if (s is pw.TextSpan) {
                        return pw.TextSpan(
                          text: s.text,
                          style: s.style?.copyWith(
                                fontSize: headerSize,
                                fontWeight: pw.FontWeight.bold,
                              ) ??
                              pw.TextStyle(
                                  fontSize: headerSize,
                                  fontWeight: pw.FontWeight.bold),
                        );
                      }
                      return s;
                    })
                    .toList();
                resultWidgets.add(pw.RichText(
                    text: pw.TextSpan(children: headerSpans)));
                resultWidgets.add(pw.SizedBox(height: 4));
              } else if (pendingLineAttrs.containsKey('list')) {
                resultWidgets.add(pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Expanded(child: lineWidget),
                    ],
                  ),
                ));
              } else {
                resultWidgets.add(lineWidget);
              }
            }

            lineSpans.clear();
            pendingLineAttrs = null;
          }
        }
      }

      // Flush remaining spans
      if (lineSpans.isNotEmpty) {
        resultWidgets.add(pw.RichText(
            text: pw.TextSpan(children: List.of(lineSpans))));
      }

      if (resultWidgets.isEmpty) {
        return [
          pw.Text(_stripQuillDelta(deltaJson),
              style: const pw.TextStyle(fontSize: 12))
        ];
      }

      return resultWidgets;
    } catch (_) {
      return [
        pw.Text(_stripQuillDelta(deltaJson),
            style: const pw.TextStyle(fontSize: 12))
      ];
    }
  }

  /// Parse a color value from Quill Delta attributes to PdfColor.
  PdfColor? _parsePdfColor(dynamic colorValue) {
    if (colorValue is String) {
      // Hex format: "#RRGGBB" or "0xAARRGGBB"
      final hex = colorValue.replaceAll('#', '').replaceAll('0x', '');
      final intVal = int.tryParse(hex, radix: 16);
      if (intVal != null) {
        if (hex.length == 6) {
          return PdfColor.fromInt(0xFF000000 | intVal);
        } else if (hex.length == 8) {
          return PdfColor.fromInt(intVal);
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Date formatting
  // ---------------------------------------------------------------------------

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
