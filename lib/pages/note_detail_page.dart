import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../models/note.dart';
import '../models/reminder_item.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../services/audio_player_service.dart';
import '../nav.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class NoteDetailPage extends ConsumerStatefulWidget {
  final String? recordingPath;
  final String? noteId;
  final String? transcription;
  final int? duration;
  final String? detectedLanguage;
  final String? folderId;

  const NoteDetailPage({
    super.key,
    this.recordingPath,
    this.noteId,
    this.transcription,
    this.duration,
    this.detectedLanguage,
    this.folderId,
  });

  @override
  ConsumerState<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<NoteDetailPage> {
  bool _isEditing = false;
  String? _resolvedNoteId;
  late TextEditingController _titleController;
  late TextEditingController _transcriptionController;

  // Audio player state
  final AudioPlayerService _playerService = AudioPlayerService.instance;
  bool _audioLoaded = false;
  bool _isPlaying = false;
  Duration _playerPosition = Duration.zero;
  Duration _playerDuration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _transcriptionController = TextEditingController();

    if (widget.noteId != null) {
      _resolvedNoteId = widget.noteId;
      // Load audio for existing note after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAudioForNote());
    } else if (widget.recordingPath != null) {
      // New recording — create a note after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final note = await ref.read(notesProvider.notifier).addNote(
              audioFilePath: widget.recordingPath!,
              audioDurationSeconds: widget.duration ?? 0,
              rawTranscription: widget.transcription ?? '',
              detectedLanguage: widget.detectedLanguage ?? 'en',
              folderId: widget.folderId,
            );
        if (mounted) {
          setState(() {
            _resolvedNoteId = note.id;
          });
          _loadAudioForNote();
        }
      });
    }

    // Listen to player streams
    _positionSub = _playerService.positionStream.listen((pos) {
      if (mounted) setState(() => _playerPosition = pos);
    });
    _durationSub = _playerService.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _playerDuration = dur);
    });
    _playerStateSub = _playerService.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
      // Reset to start when playback completes
      if (state.processingState == ProcessingState.completed) {
        _playerService.stop();
        setState(() {
          _isPlaying = false;
          _playerPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _loadAudioForNote() async {
    final note = _findNote();
    if (note == null || note.audioFilePath.isEmpty) return;
    final file = File(note.audioFilePath);
    if (!await file.exists()) return;
    final loaded = await _playerService.load(note.audioFilePath);
    if (mounted) {
      setState(() => _audioLoaded = loaded);
    }
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
    _playerService.stop();
    _titleController.dispose();
    _transcriptionController.dispose();
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

  void _toggleEditMode(Note note) {
    if (_isEditing) {
      // Save changes
      note.title = _titleController.text;
      note.rawTranscription = _transcriptionController.text;
      note.updatedAt = DateTime.now();
      ref.read(notesProvider.notifier).updateNote(note);
    } else {
      // Enter edit mode — populate controllers
      _titleController.text = note.title;
      _transcriptionController.text = note.rawTranscription;
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note? This action cannot be undone.'),
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

  @override
  Widget build(BuildContext context) {
    final note = _findNote(watch: true);

    if (note == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: _goBack,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Note not found'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final transcription = note.rawTranscription.isNotEmpty
        ? note.rawTranscription
        : 'No transcription available. Tap "Edit Note" to add text manually.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: _goBack,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (_isEditing)
                          SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _titleController,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          )
                        else
                          Text(
                            note.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.lightSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Detected: ${note.detectedLanguage}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete Note',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Audio Player Card — only show when audio file exists
                    if (_audioLoaded)
                      Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                              color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _togglePlayback,
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 4,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 12),
                                      activeTrackColor: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      inactiveTrackColor: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.2),
                                      thumbColor: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    child: Slider(
                                      value: _playerDuration.inMilliseconds > 0
                                          ? _playerPosition.inMilliseconds
                                              .clamp(0, _playerDuration.inMilliseconds)
                                              .toDouble()
                                          : 0,
                                      max: _playerDuration.inMilliseconds > 0
                                          ? _playerDuration.inMilliseconds
                                              .toDouble()
                                          : 1,
                                      onChanged: (value) {
                                        _playerService.seek(Duration(
                                            milliseconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(
                                              _playerPosition.inSeconds),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                        Text(
                                          _formatDuration(
                                              _playerDuration.inSeconds > 0
                                                  ? _playerDuration.inSeconds
                                                  : note.audioDurationSeconds),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Transcription
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionHeader(
                            icon: Icons.notes_rounded,
                            title: 'Transcription',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                  color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timestamp header
                                Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${ref.watch(settingsProvider).speakerName} — ${_formatNoteTimestamp(note.createdAt)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Content
                                if (_isEditing)
                                  TextField(
                                    controller: _transcriptionController,
                                    maxLines: null,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          height: 1.6,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  )
                                else
                                  Text(
                                    transcription,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          height: 1.6,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Items
                    if (note.actions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SectionHeader(
                              icon: Icons.checklist_rounded,
                              title: 'Action Items',
                              color: AppColors.lightSuccess,
                            ),
                            ...note.actions.map(
                              (action) => _TaskItem(
                                content: action.text,
                                checked: action.isCompleted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Reminders — only show when enabled in settings
                    if (ref.watch(settingsProvider).notificationsEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                onLongPress: () =>
                                    _confirmDeleteReminder(note.id, reminder),
                                child: _TaskItem(
                                  content: reminder.text,
                                  checked: reminder.isCompleted,
                                  hasMeta: reminder.reminderTime != null,
                                  metaIcon: Icons.schedule,
                                  metaText: reminder.reminderTime != null
                                      ? _formatReminderTime(
                                          reminder.reminderTime!)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _showAddReminderDialog(note),
                              icon: const Icon(Icons.alarm_add_rounded, size: 20),
                              label: const Text('Add Reminder'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: GestureDetector(
          onTap: () => _toggleEditMode(note),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _isEditing
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: _isEditing
                  ? null
                  : Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_note_rounded,
                  color: _isEditing
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Save Note' : 'Edit Note',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _isEditing
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${_formatReminderTime(reminderTime)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    textController.dispose();
  }

  Future<void> _confirmDeleteReminder(String noteId, ReminderItem reminder) async {
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
      dateLabel =
          '${time.month}/${time.day}/${time.year}';
    }

    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');

    return '$dateLabel, $hour:$minute $amPm';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
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

  const _TaskItem({
    required this.content,
    required this.checked,
    this.hasMeta = false,
    this.metaIcon,
    this.metaText,
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
                          color:
                              Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        metaText!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary,
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
    );
  }
}

