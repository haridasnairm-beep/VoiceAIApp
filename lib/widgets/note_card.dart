import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/note.dart';
import '../theme.dart';
import '../widgets/settings_widgets.dart' show friendlyLanguageName;

/// Compact voice note card with metadata, folder/project labels, and gestures.
class NoteCard extends StatelessWidget {
  final Note note;
  final String timestamp;
  final List<String> folderNames;
  final List<String> projectNames;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool selectionMode;
  final void Function(String name)? onFolderTap;
  final void Function(String name)? onProjectTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.timestamp,
    required this.folderNames,
    required this.projectNames,
    required this.onTap,
    required this.onDelete,
    required this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
    this.onFolderTap,
    this.onProjectTap,
  });

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String rawText = note.rawTranscription;
    if (note.contentFormat == 'quill_delta' && rawText.isNotEmpty) {
      try {
        final json = jsonDecode(rawText) as List;
        rawText = Document.fromJson(json).toPlainText().trim();
      } catch (_) {
        // fallback to raw string
      }
    }
    final preview = rawText.length > 120 ? rawText.substring(0, 120) : rawText;
    final duration = _formatDuration(note.audioDurationSeconds);
    final hasTags = note.todos.isNotEmpty ||
        note.actions.isNotEmpty ||
        note.reminders.isNotEmpty ||
        note.imageAttachmentIds.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Metadata (timestamp · duration · language)
            Row(
              children: [
                if (selectionMode) ...[
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.hintColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.access_time_rounded,
                    size: 12, color: theme.hintColor),
                const SizedBox(width: 3),
                Text(
                  timestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (duration.isNotEmpty) ...[
                  Text(' · ',
                      style: TextStyle(
                          color: theme.hintColor, fontSize: 12)),
                  Icon(Icons.timer_outlined,
                      size: 12, color: theme.hintColor),
                  const SizedBox(width: 2),
                  Text(
                    duration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
                Text(' · ',
                    style:
                        TextStyle(color: theme.hintColor, fontSize: 12)),
                Icon(Icons.language_rounded,
                    size: 12, color: theme.hintColor),
                const SizedBox(width: 2),
                Text(
                  friendlyLanguageName(note.detectedLanguage),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                if (note.isPinned) ...[
                  const Spacer(),
                  Icon(Icons.push_pin_rounded,
                      size: 14, color: theme.colorScheme.primary),
                ],
              ],
            ),

            // Row 2: Preview or transcribing progress
            const SizedBox(height: 6),
            if (!note.isProcessed)
              _TranscribingProgress(
                audioDurationSeconds: note.audioDurationSeconds,
                createdAt: note.createdAt,
              )
            else if (preview.isNotEmpty)
              Text(
                preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

            // Row 4: Title + Folder/Project labels on same line
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _LabelChip(
                  icon: note.audioFilePath.isEmpty
                      ? Icons.edit_note_rounded
                      : Icons.mic_rounded,
                  label: note.title,
                  bgColor: note.audioFilePath.isEmpty
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE8F5E9),
                  textColor: note.audioFilePath.isEmpty
                      ? const Color(0xFFE65100)
                      : const Color(0xFF2E7D32),
                ),
                ...folderNames.map((name) => GestureDetector(
                      onTap: onFolderTap != null ? () => onFolderTap!(name) : null,
                      child: _LabelChip(
                        icon: Icons.folder_rounded,
                        label: name,
                        bgColor: const Color(0xFFE3F2FD),
                        textColor: const Color(0xFF1565C0),
                      ),
                    )),
                ...projectNames.map((name) => GestureDetector(
                      onTap: onProjectTap != null ? () => onProjectTap!(name) : null,
                      child: _LabelChip(
                        icon: Icons.article_rounded,
                        label: name,
                        bgColor: const Color(0xFFF3E5F5),
                        textColor: const Color(0xFF7B1FA2),
                      ),
                    )),
                ...note.tags.map((tag) => _LabelChip(
                      icon: Icons.label_rounded,
                      label: '#$tag',
                      bgColor: theme.colorScheme.secondaryContainer,
                      textColor: theme.colorScheme.onSecondaryContainer,
                    )),
              ],
            ),

            // Row 5: Tags (Todo, Action, Reminder, Photos)
            if (hasTags) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (note.todos.isNotEmpty)
                    _TagChip(
                      label: 'Todo',
                      bg: const Color(0xFFE3F2FD),
                      color: const Color(0xFF1976D2),
                    ),
                  if (note.actions.isNotEmpty)
                    _TagChip(
                      label: 'Action',
                      bg: const Color(0xFFE8F5E9),
                      color: const Color(0xFF2E7D32),
                    ),
                  if (note.reminders.isNotEmpty)
                    _TagChip(
                      label: 'Reminder',
                      bg: const Color(0xFFFFF3E0),
                      color: const Color(0xFFEF6C00),
                    ),
                  if (note.imageAttachmentIds.isNotEmpty)
                    _TagChip(
                      label: '${note.imageAttachmentIds.length} photo${note.imageAttachmentIds.length > 1 ? 's' : ''}',
                      bg: const Color(0xFFFCE4EC),
                      color: const Color(0xFFC62828),
                      icon: Icons.photo_rounded,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small chip for folder/project labels.
class _LabelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;

  const _LabelChip({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tag pill (Todo, Action, Reminder, Photos).
class _TagChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.bg,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Transcription progress indicator shown while note is being processed.
class _TranscribingProgress extends StatefulWidget {
  final int audioDurationSeconds;
  final DateTime createdAt;

  const _TranscribingProgress({
    required this.audioDurationSeconds,
    required this.createdAt,
  });

  @override
  State<_TranscribingProgress> createState() => _TranscribingProgressState();
}

class _TranscribingProgressState extends State<_TranscribingProgress> {
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateProgress();
    });
  }

  void _updateProgress() {
    final estimatedSeconds =
        (widget.audioDurationSeconds * 1.2).clamp(5.0, double.infinity);
    final elapsed =
        DateTime.now().difference(widget.createdAt).inSeconds.toDouble();
    setState(() {
      _progress = (elapsed / estimatedSeconds).clamp(0.0, 0.95);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Transcribing... $percent%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.1),
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}
