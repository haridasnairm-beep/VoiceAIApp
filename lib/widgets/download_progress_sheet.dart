import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../services/whisper_service.dart';

/// Result from the download sheet.
/// [success] indicates if download completed.
/// [wantsUpgrade] is true when user tapped "Try Enhanced Model" on the ready splash.
/// [wasPaused] is true when user paused the download (partial file kept for resume).
class DownloadSheetResult {
  final bool success;
  final bool wantsUpgrade;
  final bool wasPaused;
  final bool goBack;
  const DownloadSheetResult({
    required this.success,
    this.wantsUpgrade = false,
    this.wasPaused = false,
    this.goBack = false,
  });
}

/// Animated full-screen download experience for Whisper model downloads.
///
/// Shows app logo, animated waveform, progress bar, and rotating feature tips.
/// Supports pause (keeps partial file) and cancel (deletes partial file).
/// On success, shows a one-time "Ready!" splash with option to upgrade model.
/// Use via [showDownloadSheet] helper.
class DownloadProgressSheet extends StatefulWidget {
  final String modelName; // 'base' or 'small'
  final bool showReadySplash; // Show the post-download ready splash

  const DownloadProgressSheet({
    super.key,
    required this.modelName,
    this.showReadySplash = false,
  });

  @override
  State<DownloadProgressSheet> createState() => _DownloadProgressSheetState();
}

class _DownloadProgressSheetState extends State<DownloadProgressSheet>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  bool _downloading = true;
  bool _showReady = false; // Transition to ready splash

  // Tip rotation
  int _tipIndex = 0;
  Timer? _tipTimer;

  static const _tips = [
    ('shield_rounded', 'Privacy First', 'All data stays on your device'),
    ('wifi_off_rounded', 'No Cloud Required', 'Works completely offline'),
    ('psychology_rounded', 'On-Device AI', 'Powered by Whisper'),
    ('block_rounded', 'No Ads, No Tracking', 'Your voice, your data'),
    ('format_bold_rounded', 'Rich Text Notes', 'Format your transcriptions'),
  ];

  // Wave animation
  late final AnimationController _waveController;

  // Ready splash fade-in
  late final AnimationController _readyFadeController;
  late final Animation<double> _readyFade;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _readyFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _readyFade = CurvedAnimation(
      parent: _readyFadeController,
      curve: Curves.easeOut,
    );

    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
    });

    _startDownload();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _waveController.dispose();
    _readyFadeController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final success = await WhisperService.instance.downloadModel(
      modelName: widget.modelName,
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _progress = p);
      },
    );
    if (!mounted) return;
    setState(() => _downloading = false);

    if (success && widget.showReadySplash) {
      _tipTimer?.cancel();
      setState(() => _showReady = true);
      _readyFadeController.forward();
    } else {
      Navigator.of(context).pop(DownloadSheetResult(success: success));
    }
  }

  /// Pause: stop the download but keep the partial file for resume.
  void _pause() {
    WhisperService.instance.cancelDownload();
    Navigator.of(context).pop(
      const DownloadSheetResult(success: false, wasPaused: true),
    );
  }

  /// Cancel: stop the download and delete partial file.
  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Download?'),
        content: const Text(
          'This will delete the downloaded portion. '
          'You will need to start the download from scratch next time.\n\n'
          'If you just need to step away, use Pause instead — '
          'it keeps your progress for later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete & Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    WhisperService.instance.cancelDownload();
    await WhisperService.instance.deletePartialDownload(widget.modelName);
    if (!mounted) return;
    Navigator.of(context).pop(const DownloadSheetResult(success: false));
  }

  /// Handle back button / system back — treat as pause.
  void _onBackPressed() {
    if (_downloading) {
      _pause();
    }
  }

  void _onReadyDismiss() {
    Navigator.of(context).pop(const DownloadSheetResult(success: true));
  }

  void _onUpgradeTap() {
    Navigator.of(context).pop(
      const DownloadSheetResult(success: true, wantsUpgrade: true),
    );
  }

  String get _modelLabel =>
      widget.modelName == 'small' ? 'Enhanced' : 'Standard';
  String get _modelSize =>
      widget.modelName == 'small' ? '~466 MB' : '~142 MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_showReady) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: FadeTransition(
              opacity: _readyFade,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 48),

                    // Success icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF2E7D32),
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Vaanix is Ready!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your voice notes will now be transcribed\non-device with high accuracy.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Upgrade suggestion (only for base model)
                    if (widget.modelName == 'base')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Want even better accuracy?',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The Enhanced model (~466 MB) provides superior '
                              'transcription quality. You can download it '
                              'anytime from Audio Settings.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _onUpgradeTap,
                                child: const Text('Try Enhanced Model'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Start recording button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _onReadyDismiss,
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Start Recording'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .pop(const DownloadSheetResult(success: true, goBack: true)),
                      child: const Text('Go Back'),
                    ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final percent = (_progress * 100).toInt();
    final tip = _tips[_tipIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _downloading) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vaanix',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                const Spacer(),

                // Animated waveform
                SizedBox(
                  height: 80,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) => _buildWaveform(theme),
                  ),
                ),

                const Spacer(),

                // Progress section
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloading $_modelLabel Model',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress > 0 ? _progress : null,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_modelSize  ·  Keep app open',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Rotating feature tip
                SizedBox(
                  height: 64,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _TipRow(
                      key: ValueKey(_tipIndex),
                      iconName: tip.$1,
                      title: tip.$2,
                      subtitle: tip.$3,
                      theme: theme,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info tile — "Need to record urgently?"
                if (_downloading)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'Need to record urgently? Pause the download and use ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Live mode',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                                TextSpan(
                                  text: '.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(flex: 2),

                // Action buttons — Pause & Cancel
                if (_downloading)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pause,
                          icon: const Icon(Icons.pause_rounded, size: 18),
                          label: const Text('Pause'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancel,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform(ThemeData theme) {
    const barCount = 12;
    final t = _waveController.value;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barCount, (i) {
        // Traveling sine wave — each bar offset by its index
        final phase = t * 2 * pi + i * (pi / 4);
        final wave = (sin(phase) + 1) / 2; // 0..1
        final h = 16.0 + wave * 48.0;
        final opacity = 0.4 + wave * 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 5,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String iconName;
  final String title;
  final String subtitle;
  final ThemeData theme;

  const _TipRow({
    super.key,
    required this.iconName,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  IconData _resolveIcon() {
    switch (iconName) {
      case 'shield_rounded':
        return Icons.shield_rounded;
      case 'wifi_off_rounded':
        return Icons.wifi_off_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'block_rounded':
        return Icons.block_rounded;
      case 'format_bold_rounded':
        return Icons.format_bold_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _resolveIcon(),
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Helper to show the download sheet as a full-screen dialog.
/// Returns [DownloadSheetResult] with success status and optional upgrade request.
/// When [showReadySplash] is true, shows a "Ready!" splash after successful download.
Future<DownloadSheetResult?> showDownloadSheet(
  BuildContext context, {
  required String modelName,
  bool showReadySplash = false,
}) {
  return showDialog<DownloadSheetResult>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (_) => DownloadProgressSheet(
      modelName: modelName,
      showReadySplash: showReadySplash,
    ),
  );
}
