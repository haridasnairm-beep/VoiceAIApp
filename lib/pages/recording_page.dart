import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicenotes_ai/nav.dart';
import 'package:voicenotes_ai/services/audio_recorder_service.dart';
import 'package:voicenotes_ai/theme.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final AudioRecorderService _recorder = AudioRecorderService.instance;

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isStarting = true;
  bool _isPaused = false;
  String? _activePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _isStarting = true;
      _elapsed = Duration.zero;
      _isPaused = false;
    });

    final path = await _recorder.start();
    if (!mounted) return;

    if (path == null) {
      debugPrint('Recording start failed (no permission or error).');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Microphone permission is required to record.')),
      );
      context.pop();
      return;
    }

    setState(() {
      _activePath = path;
      _isStarting = false;
    });
    _startTimer();
  }

  Future<void> _togglePause() async {
    try {
      if (_isStarting) return;
      if (_isPaused) {
        await _recorder.resume();
        _startTimer();
      } else {
        await _recorder.pause();
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
    await _recorder.cancelAndDelete();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _saveAndProcess() async {
    if (_isStarting) return;
    _timer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    context.go(AppRoutes.noteDetail,
        extra: {'recordingPath': path ?? _activePath});
  }

  Widget build(BuildContext context) {
    final timerText = _formatDuration(_elapsed);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
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
                    onPressed: () => context.pop(),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          "Auto-detecting...",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
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
                          return _WaveformRow(level: _isPaused ? 0 : level);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    timerText,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const Spacer(),

              // Live Transcription
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
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          "LIVE TRANSCRIPTION",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "So, for the Project Alpha meeting tomorrow, we need to make sure the budget proposal is finalized.",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Also, remind me to email Sarah about the design assets. We might need a few more iterations on the mobile mockups...",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 2,
                              height: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                          iconColor: Theme.of(context).colorScheme.onSurface,
                          bg: Theme.of(context).colorScheme.surface,
                          borderColor: Theme.of(context).dividerColor,
                          onTap: _togglePause,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isPaused ? 'Resume' : 'Pause',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
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
                              color: Theme.of(context).colorScheme.primary,
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
                                color: Theme.of(context).colorScheme.onPrimary,
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
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _ActionButton(
                          icon: Icons.delete_outline_rounded,
                          iconColor: Theme.of(context).colorScheme.error,
                          bg: Theme.of(context).colorScheme.surface,
                          borderColor: Theme.of(context).dividerColor,
                          onTap: _discard,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Discard",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
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

class _WaveformRow extends StatelessWidget {
  final double level;

  const _WaveformRow({required this.level});

  @override
  Widget build(BuildContext context) {
    // 10 bars, slightly different multipliers to feel organic.
    const multipliers = [0.35, 0.55, 0.8, 1.0, 0.7, 0.92, 1.05, 0.75, 0.5, 0.3];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(multipliers.length, (i) {
        final m = multipliers[i];
        final opacity = 0.55 + (m * 0.4);
        final minH = 18.0 + (i.isEven ? 4 : 0);
        final maxH = 120.0;
        final h = (minH + (maxH - minH) * (level * m)).clamp(minH, maxH);
        return _WaveBarAnimated(height: h, opacity: opacity.clamp(0.0, 1.0));
      }),
    );
  }
}

class _WaveBarAnimated extends StatelessWidget {
  final double height;
  final double opacity;

  const _WaveBarAnimated({required this.height, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      width: 4,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
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
