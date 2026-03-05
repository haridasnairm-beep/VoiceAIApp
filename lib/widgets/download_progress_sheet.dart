import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../services/whisper_service.dart';

/// Animated full-screen download experience for Whisper model downloads.
///
/// Shows app logo, animated waveform, progress bar, and rotating feature tips.
/// Use via [showDownloadSheet] helper.
class DownloadProgressSheet extends StatefulWidget {
  final String modelName; // 'base' or 'small'

  const DownloadProgressSheet({super.key, required this.modelName});

  @override
  State<DownloadProgressSheet> createState() => _DownloadProgressSheetState();
}

class _DownloadProgressSheetState extends State<DownloadProgressSheet>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  bool _downloading = true;

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

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

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
    Navigator.of(context).pop(success);
  }

  void _cancel() {
    WhisperService.instance.cancelDownload();
    Navigator.of(context).pop(false);
  }

  String get _modelLabel => widget.modelName == 'small' ? 'Enhanced' : 'Standard';
  String get _modelSize => widget.modelName == 'small' ? '~466 MB' : '~142 MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (_progress * 100).toInt();
    final tip = _tips[_tipIndex];

    return PopScope(
      canPop: false,
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
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
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

                const SizedBox(height: 32),

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

                const Spacer(flex: 2),

                // Cancel button
                if (_downloading)
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Cancel Download'),
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
/// Returns `true` if download succeeded, `false` if cancelled/failed.
Future<bool?> showDownloadSheet(BuildContext context, {required String modelName}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (_) => DownloadProgressSheet(modelName: modelName),
  );
}
