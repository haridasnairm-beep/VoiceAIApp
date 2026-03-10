import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/folder.dart';
import '../nav.dart';
import '../providers/folders_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../services/whisper_service.dart';

/// Bottom sheet shown when a user shares an audio file into Vaanix.
class ShareReceiveSheet extends ConsumerStatefulWidget {
  final String audioPath;
  final String? originalFilename;

  const ShareReceiveSheet({
    super.key,
    required this.audioPath,
    this.originalFilename,
  });

  @override
  ConsumerState<ShareReceiveSheet> createState() => _ShareReceiveSheetState();
}

class _ShareReceiveSheetState extends ConsumerState<ShareReceiveSheet> {
  final _fromController = TextEditingController();
  String? _selectedFolderId;
  bool _isProcessing = false;
  bool _whisperAvailable = false;
  bool _checkingWhisper = true;
  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    // Pre-select the user's default folder from preferences
    _selectedFolderId = ref.read(settingsProvider).defaultFolderId;
    _checkWhisperModel();
    _getFileSize();
  }

  @override
  void dispose() {
    _fromController.dispose();
    super.dispose();
  }

  Future<void> _checkWhisperModel() async {
    final available = await WhisperService.instance.isModelDownloaded();
    if (mounted) {
      setState(() {
        _whisperAvailable = available;
        _checkingWhisper = false;
      });
    }
  }

  void _getFileSize() {
    try {
      final file = File(widget.audioPath);
      if (file.existsSync()) {
        setState(() => _fileSizeBytes = file.lengthSync());
      }
    } catch (_) {}
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _saveAndTranscribe() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Copy shared audio to permanent recordings directory
      final docsDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${docsDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final ext = widget.originalFilename?.split('.').last ?? 'm4a';
      final permanentPath = '${recordingsDir.path}/shared_$ts.$ext';

      await File(widget.audioPath).copy(permanentPath);

      // Get audio duration estimate from file size (rough: ~16KB/sec for typical audio)
      final estimatedDuration = (_fileSizeBytes / 16000).round().clamp(1, 7200);

      // Determine language
      final settings = ref.read(settingsProvider);
      final language = settings.defaultLanguage ?? 'en';

      // Create note with isProcessed=false (transcription pending)
      final sharedFrom = _fromController.text.trim();
      final note = await ref.read(notesProvider.notifier).addNote(
        audioFilePath: permanentPath,
        audioDurationSeconds: estimatedDuration,
        rawTranscription: '',
        detectedLanguage: language,
        folderId: _selectedFolderId,
        isProcessed: false,
        isVoiceNote: true,
        sourceType: 'shared',
        sharedFrom: sharedFrom.isEmpty ? null : sharedFrom,
        originalFilename: widget.originalFilename,
      );

      // If folder was selected, add to folder's noteIds
      if (_selectedFolderId != null) {
        ref
            .read(foldersProvider.notifier)
            .addNoteToFolder(_selectedFolderId!, note.id);
      }

      // Trigger Whisper transcription in background
      ref.read(notesProvider.notifier).transcribeInBackground(
        note.id,
        permanentPath,
        language: language,
        hasManualFolder: _selectedFolderId != null,
      );

      // Clean up temp file
      try {
        await File(widget.audioPath).delete();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop();
        // Navigate to home so user can see the transcribing note
        AppRouter.router.go(AppRoutes.home);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio saved. Transcribing in background...'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: bottomInset + navBarPadding + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Row(
            children: [
              Icon(Icons.call_received_rounded,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Shared Audio',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // File info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.audio_file_rounded,
                    color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.originalFilename ?? 'Audio file',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_fileSizeBytes > 0)
                        Text(
                          _formatFileSize(_fileSizeBytes),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // "From" text field
          TextField(
            controller: _fromController,
            decoration: InputDecoration(
              labelText: 'From (optional)',
              hintText: 'e.g. Mom, Work Group, Friend',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Folder picker
          DropdownButtonFormField<String>(
            initialValue: _selectedFolderId,
            decoration: InputDecoration(
              labelText: 'Save to folder',
              prefixIcon: const Icon(Icons.folder_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No folder'),
              ),
              ...folders.map((Folder f) => DropdownMenuItem<String>(
                    value: f.id,
                    child: Text(f.name),
                  )),
            ],
            onChanged: (value) => setState(() => _selectedFolderId = value),
          ),
          const SizedBox(height: 16),

          // Large file warning
          if (_fileSizeBytes > 50 * 1024 * 1024)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Large file (${_formatFileSize(_fileSizeBytes)}). Transcription may take longer.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Whisper not available warning
          if (!_checkingWhisper && !_whisperAvailable)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Whisper model not downloaded. Audio will be saved but cannot be transcribed until the model is set up.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        AppRouter.router.go(AppRoutes.audioSettings,
                            extra: {'highlightWhisper': true});
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Set Up Whisper'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            // Clean up temp file
                            try {
                              File(widget.audioPath).deleteSync();
                            } catch (_) {}
                            Navigator.of(context).pop();
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
                    onPressed: _isProcessing || _checkingWhisper
                        ? null
                        : _saveAndTranscribe,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _whisperAvailable ? 'Save & Transcribe' : 'Save Audio',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
