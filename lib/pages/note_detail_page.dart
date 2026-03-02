import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'project_document_detail_page.dart' show buildQuillToolbar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../models/note.dart';
import '../models/reminder_item.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../services/audio_player_service.dart';
import '../nav.dart';
import '../services/os_reminder_service.dart';
import '../services/sharing_service.dart';
import '../services/whisper_service.dart';
import '../theme.dart';
import '../widgets/reminder_destination_sheet.dart';
import '../widgets/find_replace_bar.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_attachment_repository.dart';
import 'image_viewer_page.dart';
import '../widgets/share_preview_sheet.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final String? recordingPath;
  final String? noteId;
  final String? transcription;
  final int? duration;
  final String? detectedLanguage;
  final String? folderId;
  final bool isNewTextNote;
  final String? templateContent;
  final String? templateTitle;

  const NoteDetailPage({
    super.key,
    this.recordingPath,
    this.noteId,
    this.transcription,
    this.duration,
    this.detectedLanguage,
    this.folderId,
    this.isNewTextNote = false,
    this.templateContent,
    this.templateTitle,
  });

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  bool _isEditingTitle = false;
  bool _isEditingTranscription = false;
  String? _resolvedNoteId;
  late TextEditingController _titleController;
  QuillController? _quillController;
  bool _versionsExpanded = false;
  // Word/char count for live updates during editing
  int _liveWordCount = 0;
  int _liveCharCount = 0;
  // Find & Replace
  bool _showFindReplace = false;
  String _findQuery = '';
  int _findCurrentIndex = 0;
  List<int> _findMatchPositions = [];
  // Version selection mode
  bool _versionSelectionMode = false;
  final Set<String> _selectedVersionIds = {};
  // Detail tab (0=Actions, 1=Todos, 2=Reminders, 3=Photos)
  int _detailTab = 0;

  // Audio player state
  final AudioPlayerService _playerService = AudioPlayerService.instance;
  bool _audioLoaded = false;
  bool _isPlaying = false;
  Duration _playerPosition = Duration.zero;
  Duration _playerDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  // Waveform simulation
  Timer? _waveformTimer;
  double _waveformLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    if (widget.noteId != null) {
      _resolvedNoteId = widget.noteId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAudioForNote());
    } else if (widget.isNewTextNote) {
      // Create a new text-only note (no audio), optionally from template
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final note = await ref.read(notesProvider.notifier).addNote(
              audioFilePath: '',
              audioDurationSeconds: 0,
              rawTranscription: widget.templateContent ?? '',
              detectedLanguage: 'text',
              title: widget.templateTitle,
            );
        if (mounted) {
          final doc = Document();
          if (widget.templateContent != null &&
              widget.templateContent!.isNotEmpty) {
            doc.insert(0, widget.templateContent!);
          }
          setState(() {
            _resolvedNoteId = note.id;
            _isEditingTranscription = true;
            _isEditingTitle = widget.templateContent == null;
            _titleController.text = note.title;
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
          });
        }
      });
    } else if (widget.recordingPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final note = await ref.read(notesProvider.notifier).addNote(
              audioFilePath: widget.recordingPath!,
              audioDurationSeconds: widget.duration ?? 0,
              rawTranscription: widget.transcription ?? '',
              detectedLanguage: widget.detectedLanguage ?? 'en',
              folderId: widget.folderId,
            );
        // Add note to folder's noteIds list
        if (widget.folderId != null) {
          ref
              .read(foldersProvider.notifier)
              .addNoteToFolder(widget.folderId!, note.id);
        }
        if (mounted) {
          setState(() => _resolvedNoteId = note.id);
          _loadAudioForNote();
        }
      });
    }

    _positionSub = _playerService.positionStream.listen((pos) {
      if (mounted) setState(() => _playerPosition = pos);
    });
    _durationSub = _playerService.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _playerDuration = dur);
    });
    _playerStateSub = _playerService.playerStateStream.listen((state) {
      if (!mounted) return;
      final wasPlaying = _isPlaying;
      setState(() => _isPlaying = state.playing);

      if (state.playing && !wasPlaying) {
        _startWaveformAnimation();
      } else if (!state.playing && wasPlaying) {
        _stopWaveformAnimation();
      }

      if (state.processingState == ProcessingState.completed) {
        _playerService.stop();
        setState(() {
          _isPlaying = false;
          _playerPosition = Duration.zero;
          _waveformLevel = 0.0;
        });
      }
    });
  }

  void _startWaveformAnimation() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _waveformLevel = 0.3 + Random().nextDouble() * 0.7;
        });
      }
    });
  }

  void _stopWaveformAnimation() {
    _waveformTimer?.cancel();
    if (mounted) setState(() => _waveformLevel = 0.0);
  }

  Future<void> _loadAudioForNote() async {
    final note = _findNote();
    if (note == null || note.audioFilePath.isEmpty) return;
    final file = File(note.audioFilePath);
    if (!await file.exists()) return;
    final loaded = await _playerService.load(note.audioFilePath);
    if (mounted) setState(() => _audioLoaded = loaded);
  }

  Future<void> _togglePlayback() async {
    if (!_audioLoaded) return;
    if (_isPlaying) {
      await _playerService.pause();
    } else {
      await _playerService.play();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _waveformTimer?.cancel();
    _playerService.stop();
    _titleController.dispose();
    _quillController?.removeListener(_updateWordCount);
    _quillController?.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatNoteTimestamp(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month $day, $year at $hour:$minute $amPm';
  }

  Note? _findNote({bool watch = false}) {
    if (_resolvedNoteId == null) return null;
    final notes = watch ? ref.watch(notesProvider) : ref.read(notesProvider);
    try {
      return notes.firstWhere((n) => n.id == _resolvedNoteId);
    } catch (_) {
      return null;
    }
  }

  void _saveTitle(Note note) {
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != note.title) {
      note.title = newTitle;
      note.isUserEditedTitle = true;
      note.updatedAt = DateTime.now();
      ref.read(notesProvider.notifier).updateNote(note);
    }
    setState(() => _isEditingTitle = false);
  }

  void _startEditTitle(Note note) {
    _titleController.text = note.title;
    setState(() => _isEditingTitle = true);
  }

  // --- Find & Replace logic ---

  String _getPlainText(Note note) {
    if (_isEditingTranscription && _quillController != null) {
      return _quillController!.document.toPlainText();
    }
    if (note.rawTranscription.isEmpty) return '';
    if (note.contentFormat == 'quill_delta') {
      try {
        final json = jsonDecode(note.rawTranscription) as List;
        return Document.fromJson(json).toPlainText();
      } catch (_) {
        return note.rawTranscription;
      }
    }
    return note.rawTranscription;
  }

  void _onFindSearch(String query, Note note) {
    _findQuery = query;
    if (query.isEmpty) {
      setState(() {
        _findMatchPositions = [];
        _findCurrentIndex = 0;
      });
      return;
    }
    final text = _getPlainText(note).toLowerCase();
    final lower = query.toLowerCase();
    final positions = <int>[];
    int start = 0;
    while (true) {
      final idx = text.indexOf(lower, start);
      if (idx == -1) break;
      positions.add(idx);
      start = idx + 1;
    }
    setState(() {
      _findMatchPositions = positions;
      _findCurrentIndex = positions.isEmpty ? 0 : 0;
    });
    if (positions.isNotEmpty) {
      _selectMatch(positions[0], query.length);
    }
  }

  void _onFindNext() {
    if (_findMatchPositions.isEmpty) return;
    setState(() {
      _findCurrentIndex = (_findCurrentIndex + 1) % _findMatchPositions.length;
    });
    _selectMatch(_findMatchPositions[_findCurrentIndex], _findQuery.length);
  }

  void _onFindPrevious() {
    if (_findMatchPositions.isEmpty) return;
    setState(() {
      _findCurrentIndex = (_findCurrentIndex - 1 + _findMatchPositions.length) %
          _findMatchPositions.length;
    });
    _selectMatch(_findMatchPositions[_findCurrentIndex], _findQuery.length);
  }

  void _selectMatch(int offset, int length) {
    if (_quillController == null || !_isEditingTranscription) return;
    _quillController!.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + length),
      ChangeSource.local,
    );
  }

  void _onReplace(String replacement, Note note) {
    if (_findMatchPositions.isEmpty || _quillController == null) return;
    final offset = _findMatchPositions[_findCurrentIndex];
    final length = _findQuery.length;
    _quillController!.replaceText(offset, length, replacement, null);
    _onFindSearch(_findQuery, note);
  }

  void _onReplaceAll(String replacement, Note note) {
    if (_findMatchPositions.isEmpty || _quillController == null) return;
    // Replace from end to start to preserve offsets
    final sorted = List<int>.from(_findMatchPositions)..sort((a, b) => b.compareTo(a));
    for (final offset in sorted) {
      _quillController!.replaceText(offset, _findQuery.length, replacement, null);
    }
    _onFindSearch(_findQuery, note);
  }

  void _toggleFindReplace(Note note) {
    if (!_isEditingTranscription) {
      _startEditTranscription(note);
    }
    setState(() {
      _showFindReplace = !_showFindReplace;
      if (!_showFindReplace) {
        _findQuery = '';
        _findMatchPositions = [];
        _findCurrentIndex = 0;
      }
    });
  }

  void _updateWordCount() {
    if (_quillController == null) return;
    final text = _quillController!.document.toPlainText().trim();
    final wc = text.isEmpty
        ? 0
        : text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final cc = text.length;
    if (wc != _liveWordCount || cc != _liveCharCount) {
      setState(() {
        _liveWordCount = wc;
        _liveCharCount = cc;
      });
    }
  }

  void _startEditTranscription(Note note) {
    _quillController?.removeListener(_updateWordCount);
    _quillController?.dispose();
    final content = note.rawTranscription;
    if (note.contentFormat == 'quill_delta' && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as List;
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fallback: treat as plain text
        final doc = Document()..insert(0, content);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } else {
      final doc = Document()..insert(0, content);
      _quillController = QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    _quillController!.addListener(_updateWordCount);
    _updateWordCount();
    setState(() => _isEditingTranscription = true);
  }

  Future<void> _saveTranscription(Note note) async {
    if (_quillController == null) return;
    final deltaJson = jsonEncode(_quillController!.document.toDelta().toJson());
    final plainText = _quillController!.document.toPlainText().trim();

    _quillController?.removeListener(_updateWordCount);
    _quillController?.dispose();
    _quillController = null;

    note.rawTranscription = deltaJson;
    note.contentFormat = 'quill_delta';
    note.updatedAt = DateTime.now();

    if (note.isInBox) {
      await note.save();
    } else {
      await ref.read(notesProvider.notifier).updateNote(note);
    }

    // Save version with both plain text and rich content JSON
    if (plainText.isNotEmpty) {
      await ref.read(notesProvider.notifier).addTranscriptVersion(
            note.id, plainText, 'Manual edit',
            richContentJson: deltaJson);
    }

    ref.read(notesProvider.notifier).refresh();

    if (mounted) {
      setState(() => _isEditingTranscription = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transcription saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelEditTranscription() {
    _quillController?.removeListener(_updateWordCount);
    _quillController?.dispose();
    _quillController = null;
    setState(() => _isEditingTranscription = false);
  }

  Widget _buildCustomToolbar(ThemeData theme) {
    return buildQuillToolbar(_quillController!, theme);
  }

  void _shareNote(Note note) {
    final service = SharingService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SharePreviewSheet(
          title: note.title,
          isProject: false,
          assembleText: (options) =>
              service.assembleNoteText(note, options: options),
          onExportPdf: (options) =>
              service.exportNoteAsPdf(note, options: options),
        ),
      ),
    );
  }

  Future<void> _togglePin(Note note) async {
    final ok = await ref.read(notesProvider.notifier).togglePin(note.id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 10 pinned notes. Unpin one first.')),
      );
    }
  }

  Future<void> _retranscribeNote(Note note) async {
    // Check audio file exists
    final audioFile = File(note.audioFilePath);
    if (!await audioFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file not found. Cannot re-transcribe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check model is ready
    if (!await WhisperService.instance.isModelDownloaded()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Whisper model not downloaded. Go to Audio settings to download.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentModel = WhisperService.instance.currentModelName;
    final modelLabel = currentModel == 'small' ? 'Enhanced' : 'Standard';
    final oldModel = note.transcriptionModel ?? 'Unknown';
    final oldModelLabel = oldModel == 'small'
        ? 'Enhanced'
        : (oldModel == 'base' ? 'Standard' : oldModel);

    final isRichText = note.contentFormat == 'quill_delta';
    final richTextWarning = isRichText
        ? '\n\nNote: Rich text formatting will be reset to plain text.'
        : '';

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-transcribe'),
        content: Text(
          'Re-transcribe this note using the $modelLabel model?\n\n'
          'Previous transcription (model: $oldModelLabel) will be saved in version history.'
          '$richTextWarning',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Re-transcribe'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Re-transcribing...'),
          ],
        ),
      ),
    );

    await WhisperService.instance.ensureModelReady();
    final success =
        await ref.read(notesProvider.notifier).retranscribeNote(note.id);

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Re-transcription complete ($modelLabel model).'
            : 'Re-transcription failed. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // === Tab section builders ===

  Widget _buildActionItemsSection(Note note) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: Icons.checklist_rounded,
            title: 'Action Items',
            color: AppColors.lightSuccess,
          ),
          ...note.actions.map(
            (action) => GestureDetector(
              onTap: () => ref
                  .read(notesProvider.notifier)
                  .toggleActionCompleted(
                    noteId: note.id,
                    actionId: action.id,
                  ),
              child: _TaskItem(
                content: action.text,
                checked: action.isCompleted,
                onEdit: () => _showEditActionDialog(
                    note.id, action.id, action.text),
                onDelete: () => _confirmDeleteAction(
                    note.id, action.id, action.text),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddActionDialog(note),
            icon: const Icon(Icons.add_task_rounded, size: 20),
            label: const Text('Add Action'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodosSection(Note note) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: Icons.task_alt_rounded,
            title: 'Todos',
            color: AppColors.lightPrimary,
          ),
          ...note.todos.map(
            (todo) => GestureDetector(
              onTap: () => ref
                  .read(notesProvider.notifier)
                  .toggleTodoCompleted(
                    noteId: note.id,
                    todoId: todo.id,
                  ),
              child: _TaskItem(
                content: todo.text,
                checked: todo.isCompleted,
                hasMeta: todo.dueDate != null,
                metaIcon: Icons.event_rounded,
                metaText: todo.dueDate != null
                    ? _formatReminderTime(todo.dueDate!)
                    : null,
                isOverdue: todo.dueDate != null &&
                    !todo.isCompleted &&
                    todo.dueDate!.isBefore(DateTime.now()),
                onEdit: () => _showEditTodoDialog(
                    note.id, todo.id, todo.text, todo.dueDate),
                onDelete: () =>
                    _confirmDeleteTodo(note.id, todo.id, todo.text),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddTodoDialog(note),
            icon: const Icon(Icons.playlist_add_rounded, size: 20),
            label: const Text('Add Todo'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection(Note note) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            icon: Icons.alarm_rounded,
            title: 'Reminders',
            color: AppColors.lightAccent,
          ),
          ...note.reminders.map(
            (reminder) => GestureDetector(
              onTap: () => ref
                  .read(notesProvider.notifier)
                  .toggleReminderCompleted(
                    noteId: note.id,
                    reminderId: reminder.id,
                  ),
              child: _TaskItem(
                content: reminder.text,
                checked: reminder.isCompleted,
                hasMeta: reminder.reminderTime != null,
                metaIcon: Icons.schedule,
                metaText: reminder.reminderTime != null
                    ? _formatReminderTime(reminder.reminderTime!)
                    : null,
                isOverdue: reminder.reminderTime != null &&
                    !reminder.isCompleted &&
                    reminder.reminderTime!.isBefore(DateTime.now()),
                onEdit: () =>
                    _showRescheduleReminderDialog(note.id, reminder),
                onDelete: () =>
                    _confirmDeleteReminder(note.id, reminder),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddReminderDialog(note),
            icon: const Icon(Icons.alarm_add_rounded, size: 20),
            label: const Text('Add Reminder'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsTab(Note note) {
    final repo = ImageAttachmentRepository();
    final attachmentIds = note.imageAttachmentIds;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_rounded,
                  size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Photos${attachmentIds.isNotEmpty ? ' (${attachmentIds.length})' : ''}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addPhoto(note),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Add Photo'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (attachmentIds.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo_rounded,
                      size: 48, color: theme.hintColor),
                  const SizedBox(height: 12),
                  Text('No photos yet',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 4),
                  Text('Tap "Add Photo" to attach images',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: attachmentIds.length,
              itemBuilder: (context, index) {
                final id = attachmentIds[index];
                final attachment = repo.getImageAttachment(id);
                final file = repo.getImageFile(id);
                return GestureDetector(
                  onTap: () {
                    if (file != null && file.existsSync()) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ImageViewerPage(
                            imageFile: file,
                            caption: attachment?.caption,
                          ),
                        ),
                      );
                    }
                  },
                  onLongPress: () =>
                      _confirmDeletePhoto(note.id, id),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: file != null && file.existsSync()
                        ? Image.file(file, fit: BoxFit.cover)
                        : Container(
                            color:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image_rounded,
                                color: theme.hintColor),
                          ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _addPhoto(Note note) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).colorScheme.surface,
          toolbarWidgetColor: Theme.of(context).colorScheme.onSurface,
          lockAspectRatio: false,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    final repo = ImageAttachmentRepository();
    final attachment = await repo.saveImage(
      sourceFile: File(cropped.path),
      sourceType: source == ImageSource.gallery ? 'gallery' : 'camera',
    );

    ref.read(notesProvider.notifier).addImageAttachment(
          noteId: note.id,
          attachmentId: attachment.id,
        );
  }

  Future<void> _confirmDeletePhoto(
      String noteId, String attachmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ImageAttachmentRepository();
      await repo.deleteImageAttachment(attachmentId);
      ref.read(notesProvider.notifier).removeImageAttachment(
            noteId: noteId,
            attachmentId: attachmentId,
          );
    }
  }

  Future<void> _confirmDelete(Note note) async {
    // Gather usage info for the confirmation message
    final allFolders = ref.read(foldersProvider);
    final allProjects = ref.read(projectDocumentsProvider);
    final noteFolders =
        allFolders.where((f) => f.noteIds.contains(note.id)).toList();
    final noteProjects = allProjects
        .where((p) => note.projectDocumentIds.contains(p.id))
        .toList();

    final usageWarning = StringBuffer();
    if (noteFolders.isNotEmpty) {
      usageWarning.write(
          '\n\nThis will remove the note from ${noteFolders.length} folder(s): ${noteFolders.map((f) => f.name).join(', ')}.');
    }
    if (noteProjects.isNotEmpty) {
      usageWarning.write(
          '\n\nThis will remove the note from ${noteProjects.length} project(s): ${noteProjects.map((p) => p.title).join(', ')}.');
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
            'Are you sure you want to delete this note? This action cannot be undone.$usageWarning'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Remove from folders
      for (final folder in noteFolders) {
        await ref
            .read(foldersProvider.notifier)
            .removeNoteFromFolder(folder.id, note.id);
      }
      await ref.read(notesProvider.notifier).deleteNote(note.id);
      if (mounted) _goBack();
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _exitVersionSelectionMode() {
    setState(() {
      _versionSelectionMode = false;
      _selectedVersionIds.clear();
    });
  }

  Future<void> _deleteSelectedVersions(Note note) async {
    final versions =
        ref.read(notesProvider.notifier).getTranscriptVersions(note.id);
    final selectedVersions =
        versions.where((v) => _selectedVersionIds.contains(v.id)).toList();

    // Check if original is being deleted
    final deletingOriginal = selectedVersions.any((v) => v.isOriginal);

    if (deletingOriginal) {
      // Double confirmation — this deletes the entire note
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Original Version'),
          content: const Text(
              'Deleting the original version will completely delete this note. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Note'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await _confirmDelete(note);
      }
      _exitVersionSelectionMode();
      return;
    }

    // Delete non-original versions
    // For now we don't have a bulk delete API, so just note this limitation
    // We'll remove them from the UI after confirming
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Versions'),
        content: Text(
            'Delete ${_selectedVersionIds.length} selected version(s)? The current transcription will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Restore to the latest non-deleted version if current is being deleted
      for (final versionId in _selectedVersionIds) {
        final version = versions.where((v) => v.id == versionId).firstOrNull;
        if (version != null && version.text == note.rawTranscription) {
          // Find the newest non-selected, non-original version to use
          final remaining = versions
              .where((v) => !_selectedVersionIds.contains(v.id))
              .toList();
          if (remaining.isNotEmpty) {
            await ref
                .read(notesProvider.notifier)
                .restoreTranscriptVersion(note.id, remaining.last.id);
          }
          break;
        }
      }
    }

    _exitVersionSelectionMode();
  }

  @override
  Widget build(BuildContext context) {
    final note = _findNote(watch: true);
    final theme = Theme.of(context);

    if (note == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _goBack,
          ),
        ),
        body: const Center(child: Text('Note not found')),
      );
    }

    String transcription;
    if (note.rawTranscription.isEmpty) {
      transcription = 'No transcription available. Tap the edit icon to add text.';
    } else if (note.contentFormat == 'quill_delta') {
      try {
        final json = jsonDecode(note.rawTranscription) as List;
        transcription = Document.fromJson(json).toPlainText().trim();
        if (transcription.isEmpty) {
          transcription = 'No transcription available. Tap the edit icon to add text.';
        }
      } catch (_) {
        transcription = note.rawTranscription;
      }
    } else {
      transcription = note.rawTranscription;
    }

    // Resolve folder/project usage
    final allFolders = ref.watch(foldersProvider);
    final allProjects = ref.watch(projectDocumentsProvider);
    final noteFolders =
        allFolders.where((f) => f.noteIds.contains(note.id)).toList();
    final noteProjects = allProjects
        .where((p) => note.projectDocumentIds.contains(p.id))
        .toList();

    // Get versions (newest first)
    final versions =
        ref.read(notesProvider.notifier).getTranscriptVersions(note.id);
    final sortedVersions = versions.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _versionSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _exitVersionSelectionMode,
              ),
              title: Text('${_selectedVersionIds.length} selected'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedVersionIds.length == sortedVersions.length) {
                        _selectedVersionIds.clear();
                      } else {
                        _selectedVersionIds
                            .addAll(sortedVersions.map((v) => v.id));
                      }
                    });
                  },
                  child: Text(_selectedVersionIds.length == sortedVersions.length
                      ? 'Deselect All'
                      : 'Select All'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _selectedVersionIds.isEmpty
                      ? null
                      : () => _deleteSelectedVersions(note),
                ),
              ],
            )
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _goBack,
              ),
              title: _isEditingTitle
                  ? TextField(
                      controller: _titleController,
                      autofocus: true,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _saveTitle(note),
                    )
                  : GestureDetector(
                      onTap: () => _startEditTitle(note),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              note.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_rounded,
                              size: 16, color: theme.hintColor),
                        ],
                      ),
                    ),
              actions: [
                if (_isEditingTitle)
                  IconButton(
                    icon: Icon(Icons.check_rounded,
                        color: theme.colorScheme.primary),
                    onPressed: () => _saveTitle(note),
                  )
                else ...[
                  IconButton(
                    icon: Icon(
                      Icons.search_rounded,
                      color: _showFindReplace ? theme.colorScheme.primary : null,
                    ),
                    onPressed: () => _toggleFindReplace(note),
                    tooltip: 'Find & Replace',
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () => _shareNote(note),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      if (value == 'retranscribe') _retranscribeNote(note);
                      if (value == 'pin') _togglePin(note);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned
                                  ? Icons.push_pin_outlined
                                  : Icons.push_pin_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'Unpin' : 'Pin to Top'),
                          ],
                        ),
                      ),
                      if (note.audioFilePath.isNotEmpty)
                        const PopupMenuItem(
                          value: 'retranscribe',
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Re-transcribe'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Metadata — timestamp on row 1, details on row 2
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: timestamp
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(
                        _formatNoteTimestamp(note.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row 2: duration, language, model
                  Row(
                    children: [
                      if (note.audioDurationSeconds > 0) ...[
                        Icon(Icons.timer_outlined,
                            size: 14, color: theme.hintColor),
                        const SizedBox(width: 2),
                        Text(
                          _formatDuration(note.audioDurationSeconds),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        Text(' \u00b7 ',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 12)),
                      ],
                      Icon(Icons.language_rounded,
                          size: 14, color: theme.hintColor),
                      const SizedBox(width: 2),
                      Text(
                        note.detectedLanguage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      if (note.transcriptionModel != null) ...[
                        Text(' \u00b7 ',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 12)),
                        Icon(Icons.psychology_rounded,
                            size: 14, color: theme.hintColor),
                        const SizedBox(width: 2),
                        Text(
                          note.transcriptionModel == 'small'
                              ? 'Enhanced'
                              : 'Standard',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === FIND & REPLACE BAR ===
            if (_showFindReplace)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: FindReplaceBar(
                  onSearch: (query) => _onFindSearch(query, note),
                  onReplace: (replacement) => _onReplace(replacement, note),
                  onReplaceAll: (replacement) => _onReplaceAll(replacement, note),
                  onNext: _onFindNext,
                  onPrevious: _onFindPrevious,
                  onClose: () => _toggleFindReplace(note),
                  currentMatch: _findCurrentIndex,
                  totalMatches: _findMatchPositions.length,
                ),
              ),

            // === TRANSCRIPTION SECTION ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    icon: Icons.notes_rounded,
                    title: 'Transcription',
                    color: theme.colorScheme.primary,
                    trailing: _isEditingTranscription
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: _cancelEditTranscription,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.check_rounded,
                                    size: 20,
                                    color: theme.colorScheme.primary),
                                onPressed: () => _saveTranscription(note),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          )
                        : IconButton(
                            icon: Icon(Icons.edit_rounded,
                                size: 18, color: theme.hintColor),
                            onPressed: () => _startEditTranscription(note),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded,
                                size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${ref.watch(settingsProvider).speakerName} — ${_formatNoteTimestamp(note.createdAt)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        if (_isEditingTranscription && _quillController != null) ...[
                          QuillEditor.basic(
                            controller: _quillController!,
                            config: const QuillEditorConfig(
                              autoFocus: true,
                              minHeight: 80,
                              placeholder: 'Type your text here...',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCustomToolbar(theme),
                        ] else if (note.contentFormat == 'quill_delta' && note.rawTranscription.isNotEmpty) ...[
                          Builder(builder: (context) {
                            try {
                              final json = jsonDecode(note.rawTranscription) as List;
                              final controller = QuillController(
                                document: Document.fromJson(json),
                                selection: const TextSelection.collapsed(offset: 0),
                              );
                              return QuillEditor.basic(
                                controller: controller,
                                config: const QuillEditorConfig(
                                  showCursor: false,
                                  enableInteractiveSelection: false,
                                ),
                              );
                            } catch (_) {
                              return Text(
                                transcription,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  color: theme.colorScheme.onSurface,
                                ),
                              );
                            }
                          }),
                        ] else ...[
                          Text(
                            transcription,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // === WORD & CHARACTER COUNT ===
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 6, 32, 0),
              child: Builder(builder: (_) {
                int wordCount;
                int charCount;
                if (_isEditingTranscription && _quillController != null) {
                  wordCount = _liveWordCount;
                  charCount = _liveCharCount;
                } else {
                  final plainText = note.rawTranscription.isEmpty
                      ? ''
                      : (note.contentFormat == 'quill_delta'
                          ? (() {
                              try {
                                final json = jsonDecode(note.rawTranscription) as List;
                                return Document.fromJson(json).toPlainText().trim();
                              } catch (_) {
                                return note.rawTranscription;
                              }
                            })()
                          : note.rawTranscription);
                  wordCount = plainText.isEmpty
                      ? 0
                      : plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                  charCount = plainText.length;
                }
                return Text(
                  'Words: $wordCount  ·  Characters: $charCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                );
              }),
            ),

            // === VERSION HISTORY (inline collapsible) ===
            if (sortedVersions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _versionsExpanded = !_versionsExpanded),
                  child: Row(
                    children: [
                      Icon(
                        _versionsExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Version History (${sortedVersions.length})',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_versionsExpanded) ...[
                const SizedBox(height: 8),
                ...sortedVersions.map((version) {
                  final isCurrent = version.text == note.rawTranscription;
                  final isSelected =
                      _selectedVersionIds.contains(version.id);
                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _versionSelectionMode = true;
                        _selectedVersionIds.add(version.id);
                      });
                    },
                    onTap: _versionSelectionMode
                        ? () {
                            setState(() {
                              if (isSelected) {
                                _selectedVersionIds.remove(version.id);
                                if (_selectedVersionIds.isEmpty) {
                                  _versionSelectionMode = false;
                                }
                              } else {
                                _selectedVersionIds.add(version.id);
                              }
                            });
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (_versionSelectionMode) ...[
                                Icon(
                                  isSelected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 20,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                'Version ${version.versionNumber}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (version.isOriginal)
                                _VersionTag(
                                  label: 'Original',
                                  color: AppColors.lightSuccess,
                                ),
                              if (isCurrent) ...[
                                const SizedBox(width: 4),
                                _VersionTag(
                                  label: 'Current',
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                              const Spacer(),
                              if (!isCurrent && !_versionSelectionMode)
                                GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(notesProvider.notifier)
                                        .restoreTranscriptVersion(
                                            note.id, version.id);
                                  },
                                  child: Text(
                                    'Restore',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatNoteTimestamp(version.createdAt)} · ${version.editSource}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            version.text,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],

            const SizedBox(height: 20),

            // === AUDIO PLAYER (below transcription) ===
            if (_audioLoaded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(
                      icon: Icons.headphones_rounded,
                      title: 'Audio Player',
                      color: theme.colorScheme.primary,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          // Play/pause button
                          GestureDetector(
                            onTap: _togglePlayback,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Current time
                          Text(
                            _formatDuration(_playerPosition.inSeconds),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontFeatures: [const FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tappable waveform (replaces slider)
                          Expanded(
                            child: GestureDetector(
                              onTapDown: (details) {
                                if (_playerDuration.inMilliseconds > 0) {
                                  final box = context.findRenderObject()
                                      as RenderBox?;
                                  if (box == null) return;
                                  // Calculate tap position relative to waveform width
                                  final waveformWidth = box.size.width - 44 - 8 - 8 - 8 - 40;
                                  final localX = details.localPosition.dx;
                                  final fraction =
                                      (localX / waveformWidth).clamp(0.0, 1.0);
                                  _playerService.seek(Duration(
                                    milliseconds:
                                        (fraction *
                                                _playerDuration
                                                    .inMilliseconds)
                                            .toInt(),
                                  ));
                                }
                              },
                              child: SizedBox(
                                height: 48,
                                child: _PlaybackWaveform(
                                  level: _waveformLevel,
                                  progress:
                                      _playerDuration.inMilliseconds > 0
                                          ? _playerPosition.inMilliseconds /
                                              _playerDuration.inMilliseconds
                                          : 0.0,
                                  isPlaying: _isPlaying,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Total duration
                          Text(
                            _formatDuration(
                                _playerDuration.inSeconds > 0
                                    ? _playerDuration.inSeconds
                                    : note.audioDurationSeconds),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontFeatures: [const FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // === TABBED SECTIONS (Actions / Todos / Reminders / Photos) ===
            Builder(builder: (context) {
              final settings = ref.watch(settingsProvider);
              final tabs = <_DetailTabInfo>[];
              if (settings.actionItemsEnabled) {
                tabs.add(_DetailTabInfo(
                  index: 0,
                  label: 'Actions',
                  icon: Icons.checklist_rounded,
                  badgeCount: note.actions.where((a) => !a.isCompleted).length,
                ));
              }
              if (settings.todosEnabled) {
                tabs.add(_DetailTabInfo(
                  index: 1,
                  label: 'Todos',
                  icon: Icons.task_alt_rounded,
                  badgeCount: note.todos.where((t) => !t.isCompleted).length,
                ));
              }
              if (settings.notificationsEnabled) {
                tabs.add(_DetailTabInfo(
                  index: 2,
                  label: 'Reminders',
                  icon: Icons.alarm_rounded,
                  badgeCount:
                      note.reminders.where((r) => !r.isCompleted).length,
                ));
              }
              tabs.add(_DetailTabInfo(
                index: 3,
                label: 'Photos',
                icon: Icons.photo_library_rounded,
                badgeCount: note.imageAttachmentIds.length,
              ));

              // Clamp selected tab if it's no longer available
              if (!tabs.any((t) => t.index == _detailTab)) {
                _detailTab = tabs.first.index;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab selector row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: Row(
                          children: tabs.map((tab) {
                            final isSelected = tab.index == _detailTab;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _detailTab = tab.index),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                            .withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Badge(
                                        isLabelVisible: tab.badgeCount > 0,
                                        label: Text('${tab.badgeCount}',
                                            style:
                                                const TextStyle(fontSize: 10)),
                                        child: Icon(tab.icon,
                                            size: 18,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.hintColor),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tab.label,
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.hintColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Tab content inside the container
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                        child: Column(
                          children: [
                            if (_detailTab == 0 && settings.actionItemsEnabled)
                              _buildActionItemsSection(note),
                            if (_detailTab == 1 && settings.todosEnabled)
                              _buildTodosSection(note),
                            if (_detailTab == 2 &&
                                settings.notificationsEnabled)
                              _buildRemindersSection(note),
                            if (_detailTab == 3) _buildAttachmentsTab(note),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // === USAGE SECTION ===
            if (noteFolders.isNotEmpty || noteProjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(
                      icon: Icons.bookmark_rounded,
                      title: 'Usage',
                      color: theme.colorScheme.secondary,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (noteFolders.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.folder_rounded,
                                    size: 16,
                                    color: const Color(0xFF1565C0)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: noteFolders
                                        .map((f) => _UsageChip(
                                              label: f.name,
                                              bgColor:
                                                  const Color(0xFFE3F2FD),
                                              textColor:
                                                  const Color(0xFF1565C0),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (noteFolders.isNotEmpty &&
                              noteProjects.isNotEmpty)
                            const SizedBox(height: 10),
                          if (noteProjects.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.article_rounded,
                                    size: 16,
                                    color: const Color(0xFF7B1FA2)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: noteProjects
                                        .map((p) => _UsageChip(
                                              label: p.title,
                                              bgColor:
                                                  const Color(0xFFF3E5F5),
                                              textColor:
                                                  const Color(0xFF7B1FA2),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // === DELETE BUTTON (at bottom) ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(note),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Delete Note',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ===================================================================
  // DIALOG METHODS (unchanged from original)
  // ===================================================================

  Future<void> _showAddReminderDialog(Note note) async {
    final textController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 1)));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'What do you want to be reminded about?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: Text(selectedTime.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final reminderTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      final text = textController.text.trim().isEmpty
          ? 'Reminder for "${note.title}"'
          : textController.text.trim();

      final settings = ref.read(settingsProvider);
      await ref.read(notesProvider.notifier).addReminder(
            noteId: note.id,
            text: text,
            reminderTime: reminderTime,
            notificationsEnabled: settings.notificationsEnabled,
          );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (_) => ReminderDestinationSheet(
            reminderText: text,
            reminderTime: reminderTime,
            onKeepInApp: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Reminder set for ${_formatReminderTime(reminderTime)}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onAlsoAddToCalendar: () async {
              await OsReminderService.instance.addToOsCalendar(
                reminderText: text,
                reminderTime: reminderTime,
                noteTitle: note.title,
              );
            },
          ),
        );
      }
    }
    textController.dispose();
  }

  Future<void> _showAddActionDialog(Note note) async {
    final textController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Action Item'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && textController.text.trim().isNotEmpty) {
      await ref.read(notesProvider.notifier).addActionItem(
            noteId: note.id,
            text: textController.text.trim(),
          );
    }
    textController.dispose();
  }

  Future<void> _showEditActionDialog(
      String noteId, String actionId, String currentText) async {
    final textController = TextEditingController(text: currentText);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Action Item'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && textController.text.trim().isNotEmpty) {
      await ref.read(notesProvider.notifier).updateActionItem(
            noteId: noteId,
            actionId: actionId,
            text: textController.text.trim(),
          );
    }
    textController.dispose();
  }

  Future<void> _confirmDeleteAction(
      String noteId, String actionId, String text) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Action Item'),
        content: Text('Delete "$text"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(notesProvider.notifier).deleteActionItem(
            noteId: noteId,
            actionId: actionId,
          );
    }
  }

  Future<void> _showAddTodoDialog(Note note) async {
    final textController = TextEditingController();
    DateTime? selectedDueDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(
                  selectedDueDate != null
                      ? '${selectedDueDate!.month}/${selectedDueDate!.day}/${selectedDueDate!.year}'
                      : 'No due date',
                ),
                trailing: selectedDueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            setDialogState(() => selectedDueDate = null),
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDueDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted && textController.text.trim().isNotEmpty) {
      await ref.read(notesProvider.notifier).addTodoItem(
            noteId: note.id,
            text: textController.text.trim(),
            dueDate: selectedDueDate,
          );
    }
    textController.dispose();
  }

  Future<void> _showEditTodoDialog(String noteId, String todoId,
      String currentText, DateTime? currentDueDate) async {
    final textController = TextEditingController(text: currentText);
    DateTime? selectedDueDate = currentDueDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text(
                  selectedDueDate != null
                      ? '${selectedDueDate!.month}/${selectedDueDate!.day}/${selectedDueDate!.year}'
                      : 'No due date',
                ),
                trailing: selectedDueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            setDialogState(() => selectedDueDate = null),
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDueDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted && textController.text.trim().isNotEmpty) {
      await ref.read(notesProvider.notifier).updateTodoItem(
            noteId: noteId,
            todoId: todoId,
            text: textController.text.trim(),
            dueDate: selectedDueDate,
            clearDueDate: selectedDueDate == null && currentDueDate != null,
          );
    }
    textController.dispose();
  }

  Future<void> _confirmDeleteTodo(
      String noteId, String todoId, String text) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Delete "$text"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(notesProvider.notifier).deleteTodoItem(
            noteId: noteId,
            todoId: todoId,
          );
    }
  }

  Future<void> _showRescheduleReminderDialog(
      String noteId, ReminderItem reminder) async {
    DateTime selectedDate = reminder.reminderTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
        reminder.reminderTime ?? DateTime.now().add(const Duration(hours: 1)));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reschedule Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded),
                title: Text(selectedTime.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final newTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      final settings = ref.read(settingsProvider);
      await ref.read(notesProvider.notifier).rescheduleReminder(
            noteId: noteId,
            reminderId: reminder.id,
            newTime: newTime,
            notificationsEnabled: settings.notificationsEnabled,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Reminder rescheduled to ${_formatReminderTime(newTime)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteReminder(
      String noteId, ReminderItem reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Delete reminder "${reminder.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(notesProvider.notifier).deleteReminder(
            noteId: noteId,
            reminderId: reminder.id,
          );
    }
  }

  String _formatReminderTime(DateTime time) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final reminderDate = DateTime(time.year, time.month, time.day);

    String dateLabel;
    if (reminderDate == DateTime(now.year, now.month, now.day)) {
      dateLabel = 'Today';
    } else if (reminderDate == tomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = '${time.month}/${time.day}/${time.year}';
    }

    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');

    return '$dateLabel, $hour:$minute $amPm';
  }
}

// =====================================================================
// HELPER WIDGETS
// =====================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String content;
  final bool checked;
  final bool hasMeta;
  final IconData? metaIcon;
  final String? metaText;
  final bool isOverdue;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TaskItem({
    required this.content,
    required this.checked,
    this.hasMeta = false,
    this.metaIcon,
    this.metaText,
    this.isOverdue = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            checked
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: checked
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: checked
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.onSurface,
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                      ),
                ),
                if (hasMeta) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(metaIcon,
                          size: 14,
                          color: isOverdue
                              ? Colors.red
                              : Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        metaText!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: isOverdue
                                  ? Colors.red
                                  : Theme.of(context)
                                      .colorScheme
                                      .secondary,
                              fontWeight:
                                  isOverdue ? FontWeight.bold : null,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VersionTag extends StatelessWidget {
  final String label;
  final Color color;

  const _VersionTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _UsageChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _UsageChip({
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Waveform visualization for audio playback.
class _PlaybackWaveform extends StatelessWidget {
  final double level;
  final double progress;
  final bool isPlaying;

  const _PlaybackWaveform({
    required this.level,
    required this.progress,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 30;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barCount, (i) {
        final barProgress = i / barCount;
        final isPast = barProgress <= progress;

        // Generate a pseudo-random height pattern
        final seed = (i * 7 + 3) % 11;
        final baseHeight = 0.3 + (seed / 11.0) * 0.7;
        final animatedHeight = isPlaying
            ? baseHeight * (0.4 + level * 0.6)
            : baseHeight * 0.4;
        final h = (8.0 + animatedHeight * 40.0).clamp(8.0, 48.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          width: 3,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isPast
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _DetailTabInfo {
  final int index;
  final String label;
  final IconData icon;
  final int badgeCount;
  const _DetailTabInfo({
    required this.index,
    required this.label,
    required this.icon,
    required this.badgeCount,
  });
}
