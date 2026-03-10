import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/settings_provider.dart';
import '../services/whisper_service.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/download_progress_sheet.dart';
import 'package:permission_handler/permission_handler.dart';

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
        _highlightWhisperSection();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _highlightWhisperSection() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _showHighlight = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showHighlight = false);
  }

  Future<void> _showModelPicker(
      BuildContext context, WidgetRef ref, String currentModel) async {
    // Check download status for both models
    final baseDownloaded =
        await WhisperService.instance.isSpecificModelDownloaded('base');
    final smallDownloaded =
        await WhisperService.instance.isSpecificModelDownloaded('small');

    if (!context.mounted) return;

    final theme = Theme.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Transcription Model'),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TranscriptionModeOption(
                icon: Icons.speed_rounded,
                title: 'Standard (142 MB)',
                recommended: false,
                isSelected: currentModel == 'base',
                description: baseDownloaded
                    ? 'Fast transcription, best for English.'
                    : 'Fast transcription, best for English. Not yet downloaded.',
                theme: theme,
                onTap: () => Navigator.pop(ctx, 'base'),
                trailing: _modelStatusIcon(
                    isSelected: currentModel == 'base',
                    isDownloaded: baseDownloaded),
              ),
              const SizedBox(height: 10),
              _TranscriptionModeOption(
                icon: Icons.tune_rounded,
                title: 'Enhanced (466 MB)',
                recommended: true,
                isSelected: currentModel == 'small',
                description: smallDownloaded
                    ? 'Better accuracy, supports Hindi & other languages.'
                    : 'Better accuracy, multi-language support. Not yet downloaded.',
                theme: theme,
                onTap: () => Navigator.pop(ctx, 'small'),
                trailing: _modelStatusIcon(
                    isSelected: currentModel == 'small',
                    isDownloaded: smallDownloaded),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
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
    final showSplash = !ref.read(settingsProvider).whisperReadyShown;
    final result = await showDownloadSheet(
      context,
      modelName: picked,
      showReadySplash: showSplash,
    );

    if (result != null && result.success && context.mounted) {
      WhisperService.instance.switchModel(picked);
      ref.read(settingsProvider.notifier).setWhisperModel(picked);
      _whisperModelKey.currentState?.refreshStatus();
      if (showSplash) {
        ref.read(settingsProvider.notifier).setWhisperReadyShown(true);
        if (result.wantsUpgrade) {
          // User wants to download enhanced model — trigger that flow
          _showModelPicker(context, ref, picked);
        } else if (!result.goBack) {
          // Navigate to recording page
          if (context.mounted) context.push(AppRoutes.recording);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${picked == 'small' ? 'Enhanced' : 'Standard'} model downloaded and active.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (context.mounted) {
      _whisperModelKey.currentState?.refreshStatus();
      if (result?.wasPaused == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download paused. Your progress is saved — resume anytime from Audio Settings.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

      final result = await showDownloadSheet(context, modelName: 'small');

      if (result != null && result.success && context.mounted) {
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
        if (result?.wasPaused == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download paused. Your progress is saved — resume anytime from Audio Settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
                    onTap: () async {
                      final currentMode = settings.transcriptionMode;
                      final picked = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final dialogTheme = Theme.of(ctx);
                          return AlertDialog(
                            title: const Text('Transcription Mode'),
                            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TranscriptionModeOption(
                                  icon: Icons.mic_rounded,
                                  title: 'Record & Transcribe',
                                  recommended: true,
                                  isSelected: currentMode == 'whisper',
                                  description:
                                      'On-device Whisper — nothing leaves your phone. '
                                      'Higher accuracy, transcription takes a moment after recording. '
                                      'Audio saved for playback. '
                                      'Supports English translation for other languages.',
                                  theme: dialogTheme,
                                  onTap: () => Navigator.pop(ctx, 'whisper'),
                                ),
                                const SizedBox(height: 12),
                                _TranscriptionModeOption(
                                  icon: Icons.subtitles_rounded,
                                  title: 'Live Transcription',
                                  recommended: false,
                                  isSelected: currentMode == 'live',
                                  description:
                                      'Real-time text while you speak. '
                                      'No audio file saved — text only. Good for quick capture. '
                                      'Output is always in the speaking language — no translation.',
                                  theme: dialogTheme,
                                  onTap: () => Navigator.pop(ctx, 'live'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
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

                      final result = await showDownloadSheet(
                        context,
                        modelName: 'base',
                        showReadySplash: !ref.read(settingsProvider).whisperReadyShown,
                      );

                      if (result != null && result.success && context.mounted) {
                        // Mark ready splash as shown
                        if (!ref.read(settingsProvider).whisperReadyShown) {
                          ref.read(settingsProvider.notifier).setWhisperReadyShown(true);
                        }
                        ref.read(settingsProvider.notifier).setTranscriptionMode('whisper');
                        _whisperModelKey.currentState?.refreshStatus();

                        if (result.wantsUpgrade && context.mounted) {
                          // User wants the enhanced model — trigger download
                          _showModelPicker(context, ref, 'base');
                        } else if (!result.goBack && context.mounted) {
                          // Navigate to recording page
                          context.push(AppRoutes.recording);
                        }
                      } else if (context.mounted) {
                        _whisperModelKey.currentState?.refreshStatus();
                        if (result?.wasPaused == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download paused. Your progress is saved — resume anytime from Audio Settings.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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
                      onTap: () => context.push(AppRoutes.retranscribe),
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
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.music_note_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "Recording Sound Cues",
                    sublabel: 'Subtle beep when recording starts and stops',
                    type: SettingsType.toggle,
                    switchValue: settings.soundCuesEnabled,
                    hasSublabel: true,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setSoundCuesEnabled(value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _PermissionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Permissions section showing mic & notification status with link to app settings.
class _PermissionsSection extends StatefulWidget {
  const _PermissionsSection();

  @override
  State<_PermissionsSection> createState() => _PermissionsSectionState();
}

class _PermissionsSectionState extends State<_PermissionsSection>
    with WidgetsBindingObserver {
  PermissionStatus _micStatus = PermissionStatus.denied;
  PermissionStatus _notifStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    final mic = await Permission.microphone.status;
    final notif = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _micStatus = mic;
        _notifStatus = notif;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final micGranted = _micStatus.isGranted;
    final notifGranted = _notifStatus.isGranted;

    return SettingsGroup(
      title: 'PERMISSIONS',
      children: [
        SettingsItem(
          icon: Icons.mic_rounded,
          iconBg: micGranted ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          iconColor: micGranted ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          label: 'Microphone',
          sublabel: micGranted
              ? 'Granted — recording is available'
              : 'Required for recording — tap to open settings',
          type: SettingsType.chevron,
          hasSublabel: true,
          onTap: () => openAppSettings(),
        ),
        const Divider(height: 1, indent: 56),
        SettingsItem(
          icon: Icons.notifications_rounded,
          iconBg: notifGranted ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0),
          iconColor: notifGranted ? const Color(0xFF1565C0) : const Color(0xFFE65100),
          label: 'Notifications',
          sublabel: notifGranted
              ? 'Granted — reminders will appear'
              : 'Denied — tap to enable for reminders',
          type: SettingsType.chevron,
          hasSublabel: true,
          onTap: () => openAppSettings(),
        ),
      ],
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

class _TranscriptionModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool recommended;
  final bool isSelected;
  final String description;
  final ThemeData theme;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TranscriptionModeOption({
    required this.icon,
    required this.title,
    required this.recommended,
    required this.isSelected,
    required this.description,
    required this.theme,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (recommended)
                          TextSpan(
                            text: '  (Recommended)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

