import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/note.dart';
import '../nav.dart';
import '../providers/notes_provider.dart';
import '../services/whisper_service.dart';

/// Page for bulk re-transcription of voice notes.
/// Shows all notes with audio files, allows multi-select,
/// and re-transcribes selected notes with the current Whisper model.
class RetranscribePage extends ConsumerStatefulWidget {
  const RetranscribePage({super.key});

  @override
  ConsumerState<RetranscribePage> createState() => _RetranscribePageState();
}

class _RetranscribePageState extends ConsumerState<RetranscribePage> {
  List<Note>? _eligibleNotes;
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _processing = false;
  int _completed = 0;
  int _total = 0;
  bool _whisperAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final available = await WhisperService.instance.isModelDownloaded();
    final notes =
        await ref.read(notesProvider.notifier).getRetranscribableNotes();
    // Sort by most recent first
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) {
      setState(() {
        _eligibleNotes = notes;
        _whisperAvailable = available;
        _loading = false;
      });
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    if (_eligibleNotes == null) return;
    setState(() {
      if (_selectedIds.length == _eligibleNotes!.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_eligibleNotes!.map((n) => n.id));
      }
    });
  }

  Future<void> _startRetranscribe() async {
    if (_selectedIds.isEmpty || _processing) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Re-transcribe Notes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedIds.length} note${_selectedIds.length > 1 ? 's' : ''} selected for re-transcription.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text('Please note',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _warningItem(theme,
                        'New transcription will be saved as the latest version of the note.'),
                    const SizedBox(height: 4),
                    _warningItem(theme,
                        'The text will be plain text. Any rich text formatting (bold, colors, lists) will not be preserved.'),
                    const SizedBox(height: 4),
                    _warningItem(theme,
                        'Previous versions are kept in version history and can be restored.'),
                    const SizedBox(height: 4),
                    _warningItem(theme,
                        'Model: ${WhisperService.instance.currentModelName}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processing = true;
      _completed = 0;
      _total = _selectedIds.length;
    });

    final successCount =
        await ref.read(notesProvider.notifier).bulkRetranscribe(
      noteIds: _selectedIds.toList(),
      onProgress: (completed, total) {
        if (mounted) {
          setState(() {
            _completed = completed;
            _total = total;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _processing = false);

      final failed = _selectedIds.length - successCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? '$successCount note${successCount > 1 ? 's' : ''} re-transcribed successfully.'
                : '$successCount succeeded, $failed failed.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Reload the list
      setState(() {
        _loading = true;
        _selectedIds.clear();
      });
      await _loadNotes();
    }
  }

  Widget _warningItem(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 5, color: Colors.orange.shade700),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade800,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _processing
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
        ),
        title: const Text('Re-transcribe'),
        actions: [
          if (_eligibleNotes != null && _eligibleNotes!.isNotEmpty && !_processing)
            TextButton(
              onPressed: _selectAll,
              child: Text(
                _selectedIds.length == _eligibleNotes!.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_eligibleNotes == null || _eligibleNotes!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off_rounded,
                  size: 48, color: theme.hintColor.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No notes with audio files found.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Only voice notes with existing audio recordings can be re-transcribed.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_whisperAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded,
                  size: 48, color: theme.colorScheme.error.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                'Whisper model not downloaded.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Download the Whisper model from Audio & Recording settings before re-transcribing.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.audioSettings,
                    extra: {'highlightWhisper': true}),
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Processing progress bar
        if (_processing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Re-transcribing $_completed of $_total...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _total > 0 ? _completed / _total : 0,
                ),
              ],
            ),
          ),

        // Info banner
        if (!_processing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: theme.hintColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_eligibleNotes!.length} note${_eligibleNotes!.length > 1 ? 's' : ''} with audio. '
                    'Model: ${WhisperService.instance.currentModelName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),

        // Note list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: _eligibleNotes!.length,
            itemBuilder: (ctx, i) {
              final note = _eligibleNotes![i];
              final selected = _selectedIds.contains(note.id);
              return _NoteSelectTile(
                note: note,
                selected: selected,
                enabled: !_processing,
                onToggle: () => _toggleSelect(note.id),
                formatDuration: _formatDuration,
                formatDate: _formatDate,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomBar(ThemeData theme) {
    if (_loading ||
        _eligibleNotes == null ||
        _eligibleNotes!.isEmpty ||
        !_whisperAvailable) {
      return null;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _processing
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                  child: const Text('Cancel'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _selectedIds.isEmpty || _processing
                      ? null
                      : _startRetranscribe,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.replay_rounded, size: 18),
                  label: Text(
                    _selectedIds.isEmpty
                        ? 'Select notes'
                        : 'Re-transcribe (${_selectedIds.length})',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteSelectTile extends StatelessWidget {
  final Note note;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatDate;

  const _NoteSelectTile({
    required this.note,
    required this.selected,
    required this.enabled,
    required this.onToggle,
    required this.formatDuration,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRichText = note.contentFormat == 'quill_delta';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onToggle : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: selected,
                onChanged: enabled ? (_) => onToggle() : null,
              ),
              const SizedBox(width: 8),

              // Note info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      note.title.isNotEmpty ? note.title : 'Untitled',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Transcription preview
                    Text(
                      note.rawTranscription.isNotEmpty
                          ? note.rawTranscription
                          : 'No transcription',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Metadata row
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(theme, Icons.access_time_rounded,
                            formatDuration(note.audioDurationSeconds)),
                        _chip(theme, Icons.calendar_today_rounded,
                            formatDate(note.createdAt)),
                        if (note.transcriptionModel != null)
                          _chip(theme, Icons.model_training_rounded,
                              note.transcriptionModel!),
                        if (note.sourceType == 'shared')
                          _chip(theme, Icons.call_received_rounded, 'Shared'),
                        if (hasRichText)
                          _chip(theme, Icons.format_paint_rounded, 'Rich text',
                              highlight: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, IconData icon, String label,
      {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: highlight
                ? Colors.orange.shade700
                : theme.hintColor.withValues(alpha: 0.6)),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: highlight ? Colors.orange.shade700 : theme.hintColor,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
