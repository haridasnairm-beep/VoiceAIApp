import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vaanix/nav.dart';
import 'package:vaanix/providers/settings_provider.dart';
import 'package:vaanix/services/audio_recorder_service.dart';
import 'package:vaanix/services/transcription_service.dart';
import 'package:vaanix/services/whisper_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vaanix/theme.dart';
import 'package:vaanix/providers/notes_provider.dart';
import 'package:vaanix/providers/folders_provider.dart';
import 'package:vaanix/providers/project_documents_provider.dart';
import 'package:vaanix/utils/profanity_filter.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';

const _audioFocusChannel = MethodChannel('com.vaanix.app/audio_focus');

/// Request transient exclusive audio focus (pauses other media apps).
Future<void> _requestAudioFocus() async {
  try {
    await _audioFocusChannel.invokeMethod('requestAudioFocus');
  } catch (e) {
    debugPrint('requestAudioFocus failed: $e');
  }
}

/// Abandon audio focus so other media apps resume playback.
Future<void> _abandonAudioFocus() async {
  try {
    await _audioFocusChannel.invokeMethod('abandonAudioFocus');
  } catch (e) {
    debugPrint('abandonAudioFocus failed: $e');
  }
}

/// Send a media "play" key event to resume previous media app.
/// Used for whisper mode where mic policy pauses media independently of audio focus.
Future<void> _resumeMedia() async {
  try {
    await _audioFocusChannel.invokeMethod('resumeMedia');
  } catch (e) {
    debugPrint('resumeMedia failed: $e');
  }
}

class RecordingPage extends ConsumerStatefulWidget {
  final String? folderId;
  final String? projectId;

  const RecordingPage({super.key, this.folderId, this.projectId});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage>
    with SingleTickerProviderStateMixin {
  final AudioRecorderService _recorder = AudioRecorderService.instance;
  final TranscriptionService _transcription = TranscriptionService.instance;
  final WhisperService _whisper = WhisperService.instance;
  final ScrollController _scrollController = ScrollController();

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isStarting = true;
  bool _isPaused = false;


  // Mode: true = whisper (record then transcribe), false = live STT
  bool _useWhisperMode = false;

  // Live transcription state (only used in live mode)
  String _finalizedText = '';
  String _interimText = '';
  String _detectedLanguage = '';
  bool _speechAvailable = false;

  // Folder & project selection
  String? _selectedFolderId;
  String? _selectedProjectId;

  // UI feedback state
  bool _isSaving = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedFolderId =
        widget.folderId ?? ref.read(settingsProvider).defaultFolderId;
    _selectedProjectId = widget.projectId;
    // Ensure WhisperService uses the user's selected model
    final selectedModel = ref.read(settingsProvider).whisperModel;
    WhisperService.instance.switchModel(selectedModel);

    // Pulse animation for the recording indicator dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _scrollController.dispose();
    WakelockPlus.disable(); // Safety net — always release wakelock
    if (!_useWhisperMode) {
      _transcription.onTranscriptionUpdate = null;
      _transcription.onLanguageDetected = null;
      _transcription.onStatusChanged = null;
      _transcription.reset();
    }
    if (!_speechAvailable && !_useWhisperMode) _recorder.cancelAndDelete();
    super.dispose();
  }

  Future<void> _goBack() async {
    _timer?.cancel();
    if (_useWhisperMode) {
      await _recorder.cancelAndDelete();
    } else if (_speechAvailable) {
      _transcription.reset();
    } else {
      await _recorder.cancelAndDelete();
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  /// Map ISO 639-1 language code to BCP-47 locale ID for speech_to_text.
  String? _mapToLocaleId(String? isoCode) {
    if (isoCode == null) return null; // auto-detect → use OS default
    const mapping = {
      'en': 'en-US',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'hi': 'hi-IN',
      'ar': 'ar-SA',
      'pt': 'pt-BR',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'ru': 'ru-RU',
      'it': 'it-IT',
    };
    return mapping[isoCode] ?? isoCode;
  }

  Future<void> _startRecording() async {
    final settings = ref.read(settingsProvider);
    _useWhisperMode = settings.transcriptionMode == 'whisper';

    // Keep screen awake during recording if enabled
    if (settings.keepScreenAwake) {
      WakelockPlus.enable();
    }

    setState(() {
      _isStarting = true;
      _elapsed = Duration.zero;
      _isPaused = false;
      _finalizedText = '';
      _interimText = '';
      _detectedLanguage = '';
    });

    if (_useWhisperMode) {
      // Check if Whisper model is downloaded
      final modelReady = await _whisper.isModelDownloaded();
      if (!modelReady) {
        if (!mounted) return;
        final choice = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Whisper Model Not Ready'),
            content: const Text(
              'The Whisper model is still downloading or has not been downloaded yet.\n\n'
              'You can wait for the download to finish in Settings, or switch to Live Transcription mode to start recording now.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'download'),
                child: const Text('Go to Settings'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'live'),
                child: const Text('Use Live Mode'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (choice == 'download') {
          context.pushReplacement(AppRoutes.audioSettings, extra: {'highlightWhisper': true});
          return;
        } else if (choice == 'live') {
          // Switch to live mode for this session only
          _useWhisperMode = false;
          // Continue below to start live transcription
        } else {
          // Cancel — go back
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
          return;
        }
      }
    }

    if (_useWhisperMode) {
      // Play sound cue BEFORE starting recorder — playing audio after
      // the recorder starts can steal audio focus on Samsung devices,
      // causing the recorder to capture no audio data.
      HapticService.medium();
      if (ref.read(settingsProvider).soundCuesEnabled) {
        await SoundService.instance.playStart();
        // Brief delay to let audio player release focus
        await Future.delayed(const Duration(milliseconds: 150));
      }

      // Request transient audio focus so other media apps pause properly
      // and auto-resume when we abandon focus after recording ends.
      await _requestAudioFocus();

      // Record-then-transcribe: use audio recorder with WAV format
      final path = await _recorder.startWav();
      if (!mounted) return;

      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is required to record.')),
        );
        context.go(AppRoutes.home);
        return;
      }

      setState(() {
        _isStarting = false;
      });
      _startTimer();

      // Pre-load Whisper model in background
      _whisper.ensureModelReady();
    } else {
      // Live transcription mode: use speech_to_text
      _speechAvailable = await _transcription.initialize();
      if (!mounted) return;

      if (_speechAvailable) {
        _transcription.onTranscriptionUpdate = _onTranscriptionUpdate;
        _transcription.onStatusChanged = _onStatusChanged;
        final settings = ref.read(settingsProvider);
        if (settings.blockOffensiveWords) {
          _transcription.textFilter = (text) =>
              ProfanityFilter.instance.filter(text);
        } else {
          _transcription.textFilter = null;
        }
        final langCode = settings.defaultLanguage;
        await _transcription.startListening(localeId: _mapToLocaleId(langCode));

        if (!mounted) return;
        setState(() {
          _isStarting = false;
        });
        _startTimer();

        // Haptic + sound cue: live recording started
        HapticService.medium();
        if (ref.read(settingsProvider).soundCuesEnabled) {
          SoundService.instance.playStart();
        }
      } else {
        // Fallback: STT unavailable, use audio recorder only
        final path = await _recorder.start();
        if (!mounted) return;

        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Microphone permission is required to record.')),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
          return;
        }

        setState(() {
          _isStarting = false;
        });
        _startTimer();
      }
    }
  }

  void _onTranscriptionUpdate(String finalText, String interimText) {
    if (!mounted) return;
    setState(() {
      _finalizedText = finalText;
      _interimText = interimText;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onStatusChanged(String status) {
    if (!mounted) return;
    debugPrint('STT status: $status');
  }

  Future<void> _togglePause() async {
    try {
      if (_isStarting) return;
      if (_isPaused) {
        if (_useWhisperMode) {
          await _recorder.resume();
        } else if (_speechAvailable) {
          await _transcription.resumeListening();
        } else {
          await _recorder.resume();
        }
        _startTimer();
      } else {
        if (_useWhisperMode) {
          await _recorder.pause();
        } else if (_speechAvailable) {
          await _transcription.pauseListening();
        } else {
          await _recorder.pause();
        }
        _timer?.cancel();
      }
      if (!mounted) return;
      HapticService.light();
      setState(() => _isPaused = !_isPaused);
    } catch (e) {
      debugPrint('Pause/resume failed: $e');
    }
  }

  Future<void> _discard() async {
    _timer?.cancel();
    WakelockPlus.disable();
    HapticService.heavy();
    if (_useWhisperMode) {
      await _recorder.cancelAndDelete();
    } else if (_speechAvailable) {
      _transcription.reset();
    } else {
      await _recorder.cancelAndDelete();
    }
    // Abandon audio focus so other media apps (Spotify, etc.) resume.
    // For whisper mode, also send a media-play key event because Android's
    // mic policy pauses media independently of audio focus.
    await _abandonAudioFocus();
    if (_useWhisperMode) {
      await _resumeMedia();
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _saveAndProcess() async {
    if (_isStarting || _isSaving) return;
    _timer?.cancel();
    WakelockPlus.disable();
    HapticService.medium();
    setState(() => _isSaving = true);

    if (_useWhisperMode) {
      // Stop recorder FIRST, then play sound cue — playing audio while
      // recording is active can corrupt the audio session on Samsung.
      final path = await _recorder.stop();
      if (ref.read(settingsProvider).soundCuesEnabled) {
        SoundService.instance.playStop();
        // Wait for sound cue to finish before abandoning focus
        await Future.delayed(const Duration(milliseconds: 300));
      }
      // Abandon audio focus and simulate media-play key so other media apps
      // (Spotify, etc.) resume — whisper mode pauses media via Android mic
      // policy, not audio focus, so we need the key event too.
      await _abandonAudioFocus();
      await _resumeMedia();
      if (!mounted || path == null) return;

      // Use selected folder or the one passed via constructor
      final folderId = _selectedFolderId ?? widget.folderId;

      // Create note with empty transcription — mark as unprocessed
      final lang = ref.read(settingsProvider).defaultLanguage;
      final note = await ref.read(notesProvider.notifier).addNote(
            audioFilePath: path,
            audioDurationSeconds: _elapsed.inSeconds,
            rawTranscription: '',
            detectedLanguage: lang ?? 'auto',
            folderId: folderId,
            isProcessed: false,
          );

      // Add note to selected folder if chosen
      if (folderId != null) {
        ref.read(foldersProvider.notifier).addNoteToFolder(folderId, note.id);
      }

      // Link note to selected project if chosen
      if (_selectedProjectId != null) {
        ref.read(projectDocumentsProvider.notifier).addNoteBlock(_selectedProjectId!, note.id);
      }

      // Fire-and-forget background transcription
      // Pass manual selection flags so voice commands don't override user choices
      ref.read(notesProvider.notifier).transcribeInBackground(
            note.id,
            path,
            language: lang ?? 'en',
            hasManualFolder: folderId != null,
          );

      if (!mounted) return;
      // Return to project detail if initiated from a project, otherwise home
      if (widget.projectId != null && context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      // Live mode
      String transcription = '';
      String? path;

      if (_speechAvailable) {
        transcription = await _transcription.stopListening();
        // No audio file in live STT mode (mic is owned by speech_to_text)
      } else {
        path = await _recorder.stop();
      }
      // Play stop cue after recording/transcription has stopped
      if (ref.read(settingsProvider).soundCuesEnabled) {
        SoundService.instance.playStop();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      // Abandon audio focus so other media apps (Spotify, etc.) resume
      await _abandonAudioFocus();
      if (!mounted) return;

      // Default to General folder if no folder selected
      String? folderId = _selectedFolderId ?? widget.folderId;
      if (folderId == null) {
        final folders = ref.read(foldersProvider);
        final generalFolder = folders
            .where((f) => f.name.toLowerCase() == 'general')
            .firstOrNull;
        if (generalFolder != null) {
          folderId = generalFolder.id;
        }
      }

      // Save note via provider
      final audioPath = path ?? '';
      final note = await ref.read(notesProvider.notifier).addNote(
            audioFilePath: audioPath,
            audioDurationSeconds: _elapsed.inSeconds,
            rawTranscription: transcription,
            detectedLanguage: _transcription.detectedLanguage.isNotEmpty
                ? _transcription.detectedLanguage
                : (ref.read(settingsProvider).defaultLanguage ?? 'en'),
            folderId: folderId,
            isVoiceNote: true,
          );

      // Add note to selected folder if chosen
      if (folderId != null) {
        ref.read(foldersProvider.notifier).addNoteToFolder(folderId, note.id);
      }

      // Link note to selected project if chosen
      if (_selectedProjectId != null) {
        ref.read(projectDocumentsProvider.notifier).addNoteBlock(_selectedProjectId!, note.id);
      }

      if (!mounted) return;
      // Return to project detail if initiated from a project, otherwise home
      if (widget.projectId != null && context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerText = _formatDuration(_elapsed);
    final hasTranscription =
        _finalizedText.isNotEmpty || _interimText.isNotEmpty;
    final languageLabel = _detectedLanguage.isNotEmpty
        ? _detectedLanguage.toUpperCase()
        : 'Auto-detecting...';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Scrollable content area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                color: Theme.of(context).colorScheme.onSurface,
                                onPressed: _goBack,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: Theme.of(context).dividerColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        _useWhisperMode
                                            ? Icons.mic_rounded
                                            : Icons.language,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      _useWhisperMode
                                          ? 'Record & Transcribe'
                                          : languageLabel,
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
                              const SizedBox(width: 48),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Waveform & Timer
                          Column(
                            children: [
                              SizedBox(
                                height: 100,
                                child: Center(
                                  child: ValueListenableBuilder<double>(
                                    valueListenable: _useWhisperMode
                                        ? _recorder.level
                                        : _transcription.soundLevel,
                                    builder: (context, level, _) {
                                      return _WaveformRow(
                                          level: _isPaused ? 0 : level);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                timerText,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.onSurface,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              if (_isStarting || _isPaused) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _isStarting ? 'Starting…' : 'Paused',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.secondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _useWhisperMode
                                    ? 'Audio saved · transcribed after recording'
                                    : 'Instant text as you speak · no audio replay',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Transcription area
                          if (_useWhisperMode) ...[
                            // Compact whisper recording indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) => Transform.scale(
                                      scale: _isPaused ? 1.0 : _pulseAnimation.value,
                                      child: child,
                                    ),
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _isPaused
                                            ? Theme.of(context).colorScheme.secondary
                                            : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Recording audio for Whisper transcription',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              height: 220,
                              padding: const EdgeInsets.all(24),
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
                              child: _buildLiveModeBox(context, hasTranscription),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildScreenAwakeToggle(context),
                          const SizedBox(height: 12),
                          _buildFolderSelection(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Fixed bottom controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: _isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              iconColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                              bg: Theme.of(context).colorScheme.surface,
                              borderColor:
                                  Theme.of(context).dividerColor,
                              onTap: _togglePause,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isPaused ? 'Resume' : 'Pause',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: 'Stop and save recording',
                              button: true,
                              child: GestureDetector(
                                onTap: _saveAndProcess,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.stop_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Save & Process",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              iconColor:
                                  Theme.of(context).colorScheme.error,
                              bg: Theme.of(context).colorScheme.surface,
                              borderColor:
                                  Theme.of(context).dividerColor,
                              onTap: _discard,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Discard",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
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
                ],
              ),

              // Saving overlay
              if (_isSaving)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: 0.75),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Saving…',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _newFolderSentinel = '__new_folder__';
  static const _newProjectSentinel = '__new_project__';

  Future<void> _showNewFolderDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && mounted) {
      final folder =
          await ref.read(foldersProvider.notifier).addFolder(name: name);
      setState(() => _selectedFolderId = folder.id);
    }
  }

  Future<void> _showNewProjectDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty && mounted) {
      final project = await ref
          .read(projectDocumentsProvider.notifier)
          .create(title: name, folderId: _selectedFolderId);
      setState(() => _selectedProjectId = project.id);
    }
  }

  /// Folder & Project selection UI
  Widget _buildScreenAwakeToggle(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final newVal = !settings.keepScreenAwake;
        await ref.read(settingsProvider.notifier).setKeepScreenAwake(newVal);
        if (newVal) {
          await WakelockPlus.enable();
        } else {
          await WakelockPlus.disable();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              settings.keepScreenAwake
                  ? Icons.lock_open_rounded
                  : Icons.screen_lock_portrait_rounded,
              size: 18,
              color: settings.keepScreenAwake
                  ? AppColors.lightSuccess
                  : theme.colorScheme.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Keep Screen Awake',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: 24,
              child: Switch(
                value: settings.keepScreenAwake,
                onChanged: (val) async {
                  await ref.read(settingsProvider.notifier).setKeepScreenAwake(val);
                  if (val) {
                    await WakelockPlus.enable();
                  } else {
                    await WakelockPlus.disable();
                  }
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelection(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final projects = ref.watch(projectDocumentsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVE TO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          // Folder selector
          Row(
            children: [
              Icon(Icons.folder_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedFolderId,
                    isExpanded: true,
                    hint: Text(
                      'None',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary)),
                      ),
                      ...folders.map((f) => DropdownMenuItem<String?>(
                            value: f.id,
                            child: Text(f.name),
                          )),
                      DropdownMenuItem<String?>(
                        value: _newFolderSentinel,
                        child: Row(
                          children: [
                            Icon(Icons.add,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text('New Folder',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == _newFolderSentinel) {
                        _showNewFolderDialog();
                        return;
                      }
                      setState(() => _selectedFolderId = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          // Project selector
          Divider(height: 20, color: Theme.of(context).dividerColor),
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedProjectId,
                    isExpanded: true,
                    hint: Text(
                      'No project',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No project',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary)),
                      ),
                      ...projects.map((p) => DropdownMenuItem<String?>(
                            value: p.id,
                            child: Text(p.title),
                          )),
                      DropdownMenuItem<String?>(
                        value: _newProjectSentinel,
                        child: Row(
                          children: [
                            Icon(Icons.add,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 6),
                            Text('New Project',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == _newProjectSentinel) {
                        _showNewProjectDialog();
                        return;
                      }
                      setState(() => _selectedProjectId = value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Live mode: show live transcription text or placeholder
  Widget _buildLiveModeBox(BuildContext context, bool hasTranscription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FadeTransition(
              opacity: _isPaused
                  ? const AlwaysStoppedAnimation(1.0)
                  : _pulseAnimation,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isPaused
                      ? Theme.of(context).colorScheme.secondary
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "LIVE TRANSCRIPTION",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (!_speechAvailable && !_isStarting) ...[
              const SizedBox(width: 8),
              Text(
                "(unavailable)",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: hasTranscription
                ? _buildTranscriptionText(context)
                : _buildPlaceholderText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptionText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_finalizedText.isNotEmpty)
          Text(
            _finalizedText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
          ),
        if (_interimText.isNotEmpty) ...[
          if (_finalizedText.isNotEmpty) const SizedBox(height: 4),
          Text(
            _interimText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
        const SizedBox(height: 8),
        if (!_isPaused && !_isStarting)
          _BlinkingCursor(color: Theme.of(context).colorScheme.primary),
      ],
    );
  }

  Widget _buildPlaceholderText(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _speechAvailable ? Icons.mic : Icons.mic_off,
              size: 32,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              _isStarting
                  ? 'Initializing...'
                  : _speechAvailable
                      ? 'Listening... Start speaking'
                      : 'Speech recognition unavailable.\nYour audio is still being recorded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${two(m)}:${two(s)}';
  }
}

// --- Blinking cursor widget ---

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 20,
        color: widget.color,
      ),
    );
  }
}

// --- Waveform and action button widgets ---

class _WaveformRow extends StatelessWidget {
  final double level;

  const _WaveformRow({required this.level});

  @override
  Widget build(BuildContext context) {
    const multipliers = [
      0.35, 0.55, 0.8, 1.0, 0.7, 0.92, 1.05, 0.75, 0.5, 0.3
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(multipliers.length, (i) {
        final m = multipliers[i];
        final opacity = 0.55 + (m * 0.4);
        final minH = 18.0 + (i.isEven ? 4 : 0);
        final maxH = 120.0;
        final h =
            (minH + (maxH - minH) * (level * m)).clamp(minH, maxH);
        return _WaveBarAnimated(
            height: h, opacity: opacity.clamp(0.0, 1.0));
      }),
    );
  }
}

class _WaveBarAnimated extends StatelessWidget {
  final double height;
  final double opacity;

  const _WaveBarAnimated(
      {required this.height, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color borderColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }
}
