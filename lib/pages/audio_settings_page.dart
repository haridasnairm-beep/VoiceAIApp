import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../services/whisper_service.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/download_progress_sheet.dart';

class AudioSettingsPage extends ConsumerStatefulWidget {
  final bool highlightWhisper;
  const AudioSettingsPage({super.key, this.highlightWhisper = false});

  @override
  ConsumerState<AudioSettingsPage> createState() => _AudioSettingsPageState();
}

class _AudioSettingsPageState extends ConsumerState<AudioSettingsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _whisperSectionKey = GlobalKey();
  final GlobalKey<_WhisperModelItemState> _whisperModelKey = GlobalKey();
  bool _showHighlight = false;

  /// Icon showing both selection and download status for model picker.
  Widget _modelStatusIcon({required bool isSelected, required bool isDownloaded}) {
    if (isSelected && isDownloaded) {
      // Active + downloaded: filled check circle
      return const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32));
    } else if (isSelected && !isDownloaded) {
      // Active but not downloaded: outlined circle (selected, needs download)
      return const Icon(Icons.radio_button_checked_rounded, color: Color(0xFFEF6C00));
    } else if (!isSelected && isDownloaded) {
      // Not active but downloaded: outline check
      return const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32));
    } else {
      // Not active, not downloaded: download icon
      return const Icon(Icons.download_rounded, color: Color(0xFF757575));
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.highlightWhisper) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToWhisperSection();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToWhisperSection() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final keyContext = _whisperSectionKey.currentContext;
    if (keyContext != null) {
      await Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }

    if (!mounted) return;
    setState(() => _showHighlight = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showHighlight = false);
  }

  Future<void> _showBulkRetranscribe(BuildContext context, WidgetRef ref) async {
    final eligibleNotes =
        await ref.read(notesProvider.notifier).getRetranscribableNotes();

    if (!context.mounted) return;

    if (eligibleNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No notes with audio files found for re-transcription.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check model is ready
    if (!await WhisperService.instance.isModelDownloaded()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Whisper model not downloaded. Download it first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentModel = WhisperService.instance.currentModelName;
    final modelLabel = currentModel == 'small' ? 'Enhanced' : 'Standard';

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-transcribe Notes'),
        content: Text(
          'Found ${eligibleNotes.length} note(s) with audio files.\n\n'
          'Re-transcribe all using the $modelLabel model?\n\n'
          'Previous transcriptions will be saved in version history. '
          'This may take a while.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Re-transcribe ${eligibleNotes.length} Notes'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await WhisperService.instance.ensureModelReady();

    final noteIds = eligibleNotes.map((n) => n.id).toList();
    final progressNotifier = ValueNotifier<int>(0);

    if (!context.mounted) return;

    // Show progress dialog and run bulk operation
    final resultFuture = ref.read(notesProvider.notifier).bulkRetranscribe(
      noteIds: noteIds,
      onProgress: (done, total) => progressNotifier.value = done,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: progressNotifier,
        builder: (ctx, completed, _) {
          // Auto-close when done
          if (completed >= noteIds.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ctx.mounted) Navigator.of(ctx).pop();
            });
          }
          return AlertDialog(
            title: const Text('Re-transcribing...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: noteIds.isEmpty ? 0 : completed / noteIds.length,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 16),
                Text('$completed / ${noteIds.length} notes processed'),
              ],
            ),
          );
        },
      ),
    );

    final successCount = await resultFuture;
    progressNotifier.dispose();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Re-transcription complete. $successCount / ${noteIds.length} notes processed ($modelLabel model).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showModelPicker(
      BuildContext context, WidgetRef ref, String currentModel) async {
    // Check download status for both models
    final baseDownloaded =
        await WhisperService.instance.isSpecificModelDownloaded('base');
    final smallDownloaded =
        await WhisperService.instance.isSpecificModelDownloaded('small');

    if (!context.mounted) return;

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Transcription Model'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'base'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.speed_rounded),
                title: const Text('Standard (142 MB)'),
                subtitle: Text(baseDownloaded
                    ? 'Fast transcription, best for English'
                    : 'Fast transcription, best for English · Not downloaded'),
                trailing: _modelStatusIcon(
                    isSelected: currentModel == 'base',
                    isDownloaded: baseDownloaded),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'small'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Enhanced (466 MB)'),
                subtitle: Text(smallDownloaded
                    ? 'Better accuracy, supports Hindi & other languages'
                    : 'Better accuracy, multi-language · Not downloaded'),
                trailing: _modelStatusIcon(
                    isSelected: currentModel == 'small',
                    isDownloaded: smallDownloaded),
              ),
            ),
          ],
        );
      },
    );

    if (picked == null || !context.mounted) return;

    // Check if selected model is downloaded (even if same model re-selected)
    final isDownloaded =
        await WhisperService.instance.isSpecificModelDownloaded(picked);

    if (isDownloaded) {
      if (picked == currentModel) return; // Already active, nothing to do
      // Model already exists — just switch
      WhisperService.instance.switchModel(picked);
      if (!context.mounted) return;
      ref.read(settingsProvider.notifier).setWhisperModel(picked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Switched to ${picked == 'small' ? 'Enhanced' : 'Standard'} model.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Model needs downloading
    if (!context.mounted) return;
    final sizeLabel = picked == 'small' ? '~466 MB' : '~142 MB';
    final confirmDownload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Download ${picked == 'small' ? 'Enhanced' : 'Standard'} Model'),
        content: Text(
          'This requires a one-time download ($sizeLabel).\n\n'
          'Make sure you are connected to WiFi before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmDownload != true || !context.mounted) return;

    // Show animated download experience
    final success = await showDownloadSheet(context, modelName: picked);

    if (success == true && context.mounted) {
      WhisperService.instance.switchModel(picked);
      ref.read(settingsProvider.notifier).setWhisperModel(picked);
      _whisperModelKey.currentState?.refreshStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${picked == 'small' ? 'Enhanced' : 'Standard'} model downloaded and active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (context.mounted) {
      _whisperModelKey.currentState?.refreshStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showVoiceCommandsInfo(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Voice Commands'),
        content: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How to use voice commands:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('1. Start recording normally'),
              const Text('2. Say your command at the beginning:'),
              const SizedBox(height: 12),

              // --- Folder & Project commands ---
              Text('Folder & Project',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  )),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• "Folder [name] Start" — saves to that folder'),
                    SizedBox(height: 4),
                    Text('• "Project [name] Start" — saves to that project'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _commandExample(
                '"Folder Meeting Notes Start discuss agenda"',
                'Saves note to Meeting Notes folder',
              ),
              _commandExample(
                '"Project App Launch Start finalize the timeline"',
                'Saves note to App Launch project',
              ),

              const SizedBox(height: 16),

              // --- Task commands ---
              Text('Tasks, Actions & Reminders',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  )),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• "Todo [description]" — creates a to-do item'),
                    SizedBox(height: 4),
                    Text('• "Action [description]" — creates an action item'),
                    SizedBox(height: 4),
                    Text('• "Reminder [description]" — creates a reminder'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              _commandExample(
                '"Todo Call the dentist tomorrow"',
                'Creates a to-do: "Call the dentist tomorrow"',
              ),
              _commandExample(
                '"Action Send report to the team"',
                'Creates an action: "Send report to the team"',
              ),
              _commandExample(
                '"Reminder Review pull requests"',
                'Creates a reminder set for tomorrow',
              ),

              const SizedBox(height: 16),

              // --- Limitations ---
              Text('Limitations',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  )),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Only one command per recording '
                        '(folder/project OR task — not both)'),
                    SizedBox(height: 4),
                    Text('• Task description is taken from the first '
                        '30 characters of your note'),
                    SizedBox(height: 4),
                    Text('• Reminders are always set for the next day '
                        '— edit the time manually afterwards'),
                    SizedBox(height: 4),
                    Text('• Commands must be spoken at the very start '
                        'of the recording'),
                    SizedBox(height: 4),
                    Text('• Folder/project names must match an existing '
                        'name or a new one will be created'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- Tips ---
              const Text('Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Say the command clearly before your actual note'),
                    SizedBox(height: 4),
                    Text('• The keyword "Start" signals the end of '
                        'folder/project commands'),
                    SizedBox(height: 4),
                    Text('• If no match is found, the note saves to your '
                        'default folder'),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  static Widget _commandExample(String command, String result) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(command,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 13,
              )),
          Text('  \u2192 $result',
              style: const TextStyle(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }

  static const _nativeScriptSamples = <String, String>{
    'hi': 'हिन्दी',
    'ar': 'العربية',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
    'ru': 'Русский',
  };

  Future<void> _showLanguagePicker(
      BuildContext context, WidgetRef ref, String? currentLang) async {
    // Build options without Auto (null key removed from languageOptions)
    final options = Map<String?, String>.from(languageOptions)
      ..remove(null); // ensure no Auto
    final picked = await showDialog<LanguageChoice>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Speaking Language'),
          children: options.entries.map((e) {
            final isSelected = currentLang == e.key;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, LanguageChoice(e.key)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
    if (picked == null || !context.mounted) return;
    ref.read(settingsProvider.notifier).setDefaultLanguage(picked.code);
    // If switching back to English, reset note output mode
    if (picked.code == 'en') {
      ref.read(settingsProvider.notifier).setNoteOutputMode('english');
    }
  }

  Future<void> _showNoteOutputPicker(
      BuildContext context, WidgetRef ref, SettingsState settings) async {
    final langName = languageOptions[settings.defaultLanguage] ?? settings.defaultLanguage ?? '';
    final scriptSample = _nativeScriptSamples[settings.defaultLanguage] ?? '';
    final nativeLabel = scriptSample.isNotEmpty
        ? 'Native Script ($scriptSample)'
        : 'Native Script';

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Note Output'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'english'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.translate_rounded),
                title: const Text('English Translation'),
                subtitle: Text(
                    '$langName speech translated to English notes'),
                trailing: settings.noteOutputMode == 'english'
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2E7D32))
                    : null,
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'native'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.text_fields_rounded),
                title: Text(nativeLabel),
                subtitle: Text(
                    'Notes in $langName native script — requires Enhanced model'),
                trailing: settings.noteOutputMode == 'native'
                    ? const Icon(Icons.check_rounded, color: Color(0xFF2E7D32))
                    : null,
              ),
            ),
          ],
        );
      },
    );

    if (picked == null || !context.mounted) return;

    if (picked == 'native') {
      // Check if Enhanced model is downloaded
      final isEnhancedReady =
          await WhisperService.instance.isSpecificModelDownloaded('small');
      if (isEnhancedReady) {
        // Switch to Enhanced and save
        WhisperService.instance.switchModel('small');
        if (!context.mounted) return;
        ref.read(settingsProvider.notifier).setWhisperModel('small');
        ref.read(settingsProvider.notifier).setNoteOutputMode('native');
        return;
      }

      // Need to download Enhanced model
      if (!context.mounted) return;
      final confirmDownload = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Enhanced Model Required'),
          content: Text(
            'Native script output${scriptSample.isNotEmpty ? ' ($scriptSample)' : ''} '
            'requires the Enhanced model (466 MB one-time download).\n\n'
            'Make sure you are connected to WiFi before proceeding.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Download Now'),
            ),
          ],
        ),
      );

      if (confirmDownload != true || !context.mounted) return;

      final success = await showDownloadSheet(context, modelName: 'small');

      if (success == true && context.mounted) {
        WhisperService.instance.switchModel('small');
        ref.read(settingsProvider.notifier).setWhisperModel('small');
        ref.read(settingsProvider.notifier).setNoteOutputMode('native');
        _whisperModelKey.currentState?.refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enhanced model downloaded. Native script output active.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        _whisperModelKey.currentState?.refreshStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // English translation — works on any model
      ref.read(settingsProvider.notifier).setNoteOutputMode('english');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    final audioQualityDisplay =
        settings.audioQuality == 'high' ? 'High Quality' : 'Standard';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Audio & Recording'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                title: "AUDIO",
                children: [
                  SettingsItem(
                    icon: Icons.high_quality_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57C00),
                    label: "Audio Quality",
                    sublabel: settings.audioQuality == 'high'
                        ? "Lossless, larger files"
                        : "Smaller size, good quality",
                    type: SettingsType.value,
                    valueText: audioQualityDisplay,
                    hasSublabel: true,
                    onTap: () async {
                      final picked = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Audio Quality'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'standard'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.sd_rounded),
                                  title: Text('Standard'),
                                  subtitle: Text(
                                      'Smaller file size, good quality'),
                                ),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'high'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.hd_rounded),
                                  title: Text('High Quality'),
                                  subtitle: Text(
                                      'Lossless audio, larger files'),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (picked != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setAudioQuality(picked);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.record_voice_over_rounded,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    label: "Transcription",
                    sublabel: settings.transcriptionMode == 'live'
                        ? "Real-time text, no audio saved"
                        : "On-device Whisper — high accuracy",
                    type: SettingsType.value,
                    valueText: settings.transcriptionMode == 'live'
                        ? 'Live'
                        : 'Whisper',
                    hasSublabel: true,
                    trailing: IconButton(
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'About transcription modes',
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Transcription Modes'),
                            content: const SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Record & Transcribe (Whisper)',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text(
                                    '• Audio is saved to your device\n'
                                    '• Transcription runs after you stop recording\n'
                                    '• Supports audio playback\n'
                                    '• Higher accuracy, especially for non-English\n'
                                    '• Works offline — nothing leaves your phone',
                                  ),
                                  SizedBox(height: 16),
                                  Text('Live Transcription',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text(
                                    '• Text appears instantly as you speak\n'
                                    '• No audio file saved — text only\n'
                                    '• No playback available\n'
                                    '• Good for quick capture\n'
                                    '• Output is always in the speaking language',
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () async {
                      final picked = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Transcription Mode'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'whisper'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.mic_rounded),
                                  title: Text('Record & Transcribe (Recommended)'),
                                  subtitle: Text(
                                      'On-device Whisper — nothing leaves your phone. '
                                      'Higher accuracy, transcription takes a moment after recording. '
                                      'Audio saved for playback. '
                                      'Supports English translation for other languages.'),
                                ),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'live'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.subtitles_rounded),
                                  title: Text('Live Transcription'),
                                  subtitle: Text(
                                      'Real-time text while you speak. '
                                      'No audio file saved — text only. Good for quick capture. '
                                      'Output is always in the speaking language — no translation.'),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (picked == null || !context.mounted) return;

                      if (picked == 'live') {
                        ref.read(settingsProvider.notifier).setTranscriptionMode('live');
                        return;
                      }

                      final modelReady = await WhisperService.instance.isModelDownloaded();
                      if (modelReady) {
                        if (!context.mounted) return;
                        ref.read(settingsProvider.notifier).setTranscriptionMode('whisper');
                        return;
                      }

                      if (!context.mounted) return;
                      final confirmDownload = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Download Whisper Model'),
                          content: const Text(
                            'Whisper requires a one-time model download (~140 MB).\n\n'
                            'Make sure you are connected to WiFi before proceeding.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Download'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDownload != true || !context.mounted) return;

                      final success = await showDownloadSheet(context, modelName: 'base');

                      if (success == true && context.mounted) {
                        ref.read(settingsProvider.notifier).setTranscriptionMode('whisper');
                        _whisperModelKey.currentState?.refreshStatus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Whisper model downloaded. Record & Transcribe mode is active.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (context.mounted) {
                        _whisperModelKey.currentState?.refreshStatus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  if (settings.transcriptionMode == 'whisper') ...[
                    const Divider(height: 1, indent: 56),
                    AnimatedContainer(
                      key: _whisperSectionKey,
                      duration: const Duration(milliseconds: 600),
                      decoration: BoxDecoration(
                        color: _showHighlight
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _WhisperModelItem(
                        key: _whisperModelKey,
                        currentModel: settings.whisperModel,
                        onTap: () => _showModelPicker(
                            context, ref, settings.whisperModel),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    SettingsItem(
                      icon: Icons.refresh_rounded,
                      iconBg: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFF57F17),
                      label: 'Re-transcribe Notes',
                      sublabel: 'Re-process notes with current model',
                      type: SettingsType.value,
                      valueText: '',
                      hasSublabel: true,
                      onTap: () => _showBulkRetranscribe(context, ref),
                    ),
                  ],
                  // Speaking Language — shown for ALL transcription modes
                  const Divider(height: 1, indent: 56),
                  Builder(builder: (context) {
                    final langDisplay = languageOptions[settings.defaultLanguage] ?? 'English';
                    final isWhisper = settings.transcriptionMode == 'whisper';
                    final isNonEnglish = settings.defaultLanguage != null &&
                        settings.defaultLanguage != 'en';
                    String langSublabel;
                    if (!isNonEnglish) {
                      langSublabel = 'Language you speak during recording';
                    } else if (isWhisper) {
                      langSublabel = 'Language you speak — choose note output below';
                    } else {
                      langSublabel = 'Output will be in this language (no translation)';
                    }
                    return SettingsItem(
                      icon: Icons.language_rounded,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1976D2),
                      label: "Speaking Language",
                      sublabel: langSublabel,
                      type: SettingsType.value,
                      valueText: langDisplay,
                      hasSublabel: true,
                      onTap: () => _showLanguagePicker(context, ref, settings.defaultLanguage),
                    );
                  }),
                  // Note Output — Whisper-only, non-English only
                  if (settings.transcriptionMode == 'whisper' &&
                      settings.defaultLanguage != null &&
                      settings.defaultLanguage != 'en') ...[
                    const Divider(height: 1, indent: 56),
                    Builder(builder: (context) {
                      final isNative = settings.noteOutputMode == 'native';
                      final scriptSample = _nativeScriptSamples[settings.defaultLanguage] ?? '';
                      final outputDisplay = isNative ? 'Native' : 'English';
                      final outputSublabel = isNative
                          ? 'Notes in native script${scriptSample.isNotEmpty ? ' ($scriptSample)' : ''}'
                          : 'Speech translated to English notes';
                      return SettingsItem(
                        icon: Icons.text_fields_rounded,
                        iconBg: const Color(0xFFFCE4EC),
                        iconColor: const Color(0xFFC62828),
                        label: "Note Output",
                        sublabel: outputSublabel,
                        type: SettingsType.value,
                        valueText: outputDisplay,
                        hasSublabel: true,
                        onTap: () => _showNoteOutputPicker(context, ref, settings),
                      );
                    }),
                  ],
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.record_voice_over_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "Voice Commands",
                    sublabel:
                        'Organize recordings by voice — tap to learn more',
                    type: SettingsType.toggle,
                    switchValue: settings.voiceCommandsEnabled,
                    hasSublabel: true,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setVoiceCommandsEnabled(value);
                    },
                    onTap: () => _showVoiceCommandsInfo(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.screen_lock_portrait_rounded,
                    iconBg: const Color(0xFFE0F7FA),
                    iconColor: const Color(0xFF00838F),
                    label: "Keep Screen Awake",
                    sublabel:
                        'Prevents screen from locking during recording',
                    type: SettingsType.toggle,
                    switchValue: settings.keepScreenAwake,
                    hasSublabel: true,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setKeepScreenAwake(value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified Whisper model item showing model type + download status in one row.
class _WhisperModelItem extends StatefulWidget {
  final String currentModel;
  final VoidCallback onTap;

  const _WhisperModelItem({
    super.key,
    required this.currentModel,
    required this.onTap,
  });

  @override
  State<_WhisperModelItem> createState() => _WhisperModelItemState();
}

class _WhisperModelItemState extends State<_WhisperModelItem> {
  bool _isDownloaded = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  @override
  void didUpdateWidget(covariant _WhisperModelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentModel != widget.currentModel) {
      _checkModel();
    }
  }

  /// Public method to re-check model download status from outside.
  void refreshStatus() => _checkModel();

  Future<void> _checkModel() async {
    setState(() => _isChecking = true);
    final downloaded = await WhisperService.instance
        .isSpecificModelDownloaded(widget.currentModel);
    if (!mounted) return;
    setState(() {
      _isDownloaded = downloaded;
      _isChecking = false;
    });
  }

  String get _modelDisplayName =>
      widget.currentModel == 'small' ? 'Enhanced' : 'Standard';

  String get _modelSize =>
      widget.currentModel == 'small' ? '466 MB' : '142 MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.psychology_rounded,
                    color: Color(0xFF3949AB), size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Whisper Model',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$_modelDisplayName ($_modelSize)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontSize: 11,
                          ),
                        ),
                        TextSpan(
                          text: _isChecking
                              ? '  ···'
                              : _isDownloaded
                                  ? '  ✓'
                                  : '  ⚠',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isChecking
                                ? theme.colorScheme.onSurfaceVariant
                                : _isDownloaded
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFD32F2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _modelDisplayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

