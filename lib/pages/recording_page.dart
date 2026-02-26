import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voicenotes_ai/nav.dart';
import 'package:voicenotes_ai/providers/settings_provider.dart';
import 'package:voicenotes_ai/services/audio_recorder_service.dart';
import 'package:voicenotes_ai/services/transcription_service.dart';
import 'package:voicenotes_ai/services/whisper_service.dart';
import 'package:voicenotes_ai/theme.dart';

class RecordingPage extends ConsumerStatefulWidget {
  final String? folderId;

  const RecordingPage({super.key, this.folderId});

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends ConsumerState<RecordingPage> {
  final AudioRecorderService _recorder = AudioRecorderService.instance;
  final TranscriptionService _transcription = TranscriptionService.instance;
  final WhisperService _whisper = WhisperService.instance;
  final ScrollController _scrollController = ScrollController();

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isStarting = true;
  bool _isPaused = false;
  bool _isTranscribing = false;
  String? _activePath;

  // Mode: true = whisper (record then transcribe), false = live STT
  bool _useWhisperMode = false;

  // Live transcription state (only used in live mode)
  String _finalizedText = '';
  String _interimText = '';
  String _detectedLanguage = '';
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
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
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _startRecording() async {
    final settings = ref.read(settingsProvider);
    _useWhisperMode = settings.transcriptionMode == 'whisper';

    setState(() {
      _isStarting = true;
      _elapsed = Duration.zero;
      _isPaused = false;
      _isTranscribing = false;
      _finalizedText = '';
      _interimText = '';
      _detectedLanguage = '';
    });

    if (_useWhisperMode) {
      // Safety check: ensure Whisper model is downloaded
      final modelReady = await _whisper.isModelDownloaded();
      if (!modelReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Whisper model not downloaded. Go to Settings to download it.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
        // Fall back to live mode for this recording
        _useWhisperMode = false;
      }
    }

    if (_useWhisperMode) {
      // Record-then-transcribe: use audio recorder with WAV format
      final path = await _recorder.startWav();
      if (!mounted) return;

      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone permission is required to record.')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
        return;
      }

      setState(() {
        _activePath = path;
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
        await _transcription.startListening();

        // Create a placeholder audio file path for the note
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _activePath = '${recordingsDir.path}/voicenote_$timestamp.m4a';

        if (!mounted) return;
        setState(() {
          _isStarting = false;
        });
        _startTimer();
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
          _activePath = path;
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
      if (_isStarting || _isTranscribing) return;
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
      setState(() => _isPaused = !_isPaused);
    } catch (e) {
      debugPrint('Pause/resume failed: $e');
    }
  }

  Future<void> _discard() async {
    _timer?.cancel();
    if (_useWhisperMode) {
      await _recorder.cancelAndDelete();
    } else if (_speechAvailable) {
      _transcription.reset();
    } else {
      await _recorder.cancelAndDelete();
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _saveAndProcess() async {
    if (_isStarting || _isTranscribing) return;
    _timer?.cancel();

    if (_useWhisperMode) {
      // Whisper mode: stop recording, then transcribe the audio file
      final path = await _recorder.stop();
      if (!mounted || path == null) return;

      setState(() => _isTranscribing = true);

      // Transcribe using Whisper
      debugPrint('RecordingPage: starting Whisper transcription for $path');
      final transcription = await _whisper.transcribe(path);
      debugPrint('RecordingPage: Whisper result: ${transcription.length} chars');
      if (!mounted) return;

      if (transcription.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcription failed — you can edit the note manually'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }

      context.pushReplacement(AppRoutes.noteDetail, extra: {
        'recordingPath': path,
        'transcription': transcription,
        'duration': _elapsed.inSeconds,
        'detectedLanguage': 'auto',
        if (widget.folderId != null) 'folderId': widget.folderId,
      });
    } else {
      // Live mode: existing behavior
      String transcription = '';
      String? path = _activePath;

      if (_speechAvailable) {
        transcription = await _transcription.stopListening();
      } else {
        path = await _recorder.stop();
      }
      if (!mounted) return;

      context.pushReplacement(AppRoutes.noteDetail, extra: {
        'recordingPath': path ?? _activePath,
        'transcription': transcription,
        'duration': _elapsed.inSeconds,
        'detectedLanguage': _transcription.detectedLanguage.isNotEmpty
            ? _transcription.detectedLanguage
            : 'en',
        if (widget.folderId != null) 'folderId': widget.folderId,
      });
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
              Padding(
                padding: const EdgeInsets.all(24.0),
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
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          color: Theme.of(context).colorScheme.onSurface,
                          onPressed: () => context.push(AppRoutes.settings),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Waveform & Timer
                    Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: Center(
                            child: ValueListenableBuilder<double>(
                              valueListenable: _recorder.level,
                              builder: (context, level, _) {
                                return _WaveformRow(
                                    level: _isPaused ? 0 : level);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 4),
                        Text(
                          _isStarting
                              ? 'Starting…'
                              : _isPaused
                                  ? 'Paused'
                                  : 'Recording in progress',
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
                    ),

                    const Spacer(),

                    // Transcription area
                    Container(
                      height: 240,
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
                      child: _useWhisperMode
                          ? _buildWhisperModeBox(context)
                          : _buildLiveModeBox(context, hasTranscription),
                    ),

                    const Spacer(),

                    // Controls
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
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
                            children: [
                              GestureDetector(
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
              ),

              // Transcribing overlay (Whisper mode only)
              if (_isTranscribing)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.symmetric(horizontal: 48),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Transcribing...',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Processing your recording with Whisper AI',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Whisper mode: show info text instead of live transcription
  Widget _buildWhisperModeBox(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isPaused
                    ? Theme.of(context).colorScheme.secondary
                    : AppColors.lightSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "RECORDING AUDIO",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recording audio for transcription',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap Stop to transcribe with Whisper AI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Live mode: show live transcription text or placeholder
  Widget _buildLiveModeBox(BuildContext context, bool hasTranscription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isPaused
                    ? Theme.of(context).colorScheme.secondary
                    : AppColors.lightSuccess,
                shape: BoxShape.circle,
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
