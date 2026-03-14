import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/settings_provider.dart';

/// A tip card shown above the pinned section on the Home page.
/// - Shuffled on each app launch.
/// - Auto-hides after 1 minute.
/// - Close button hides for the current session only.
/// - Permanent disable via Help & Support > Home Tips toggle.
class HomeTipTile extends ConsumerStatefulWidget {
  const HomeTipTile({super.key});

  static const _tips = <_Tip>[
    _Tip(
      text: 'Swipe up on the floating button to start recording instantly.',
      actionText: 'Try it now',
      route: null,
      guideSectionIndex: 1, // Recording
    ),
    _Tip(
      text: 'Download the Whisper model for more accurate transcription.',
      actionText: 'Go to Settings',
      route: AppRoutes.audioSettings,
      routeExtra: {'highlightWhisper': true},
      guideSectionIndex: 0, // Getting Started
    ),
    _Tip(
      text: 'Create folders to organize your voice notes by topic or project.',
      actionText: 'Open Library',
      route: AppRoutes.folders,
      guideSectionIndex: 3, // Folders
    ),
    _Tip(
      text: 'Switch to the Tasks tab to see all action items across your notes.',
      actionText: null,
      route: null,
      guideSectionIndex: 5, // Tasks
    ),
    _Tip(
      text: 'Set up App Lock to protect your notes with a PIN or fingerprint.',
      actionText: 'Security Settings',
      route: AppRoutes.security,
      guideSectionIndex: 10, // App Lock
    ),
    _Tip(
      text: 'Enable auto-backup to keep your notes safe automatically.',
      actionText: 'Backup Settings',
      route: AppRoutes.backupRestore,
      guideSectionIndex: 11, // Backup
    ),
    _Tip(
      text: 'Pin your most important notes so they always appear at the top.',
      actionText: null,
      route: null,
      guideSectionIndex: 2, // Notes
    ),
    _Tip(
      text: 'Use voice commands like "Folder Work start" to auto-organize notes.',
      actionText: null,
      route: null,
      guideSectionIndex: 3, // Folders
    ),
    _Tip(
      text: 'Add tags to notes for flexible cross-folder categorization.',
      actionText: 'Manage Tags',
      route: AppRoutes.tags,
      guideSectionIndex: 7, // Tags
    ),
    _Tip(
      text: 'Share audio from WhatsApp or Telegram into Vaanix for transcription.',
      actionText: null,
      route: null,
      guideSectionIndex: 13, // Tips & Privacy
    ),
    _Tip(
      text: 'Project Documents let you combine notes, text, images, and tasks.',
      actionText: 'View Projects',
      route: AppRoutes.folders,
      guideSectionIndex: 4, // Projects
    ),
    _Tip(
      text: 'Read the full User Guide to discover all features.',
      actionText: 'Open Guide',
      route: AppRoutes.userGuide,
      guideSectionIndex: 0, // Getting Started
    ),
    _Tip(
      text: 'Re-transcribe old notes with a better Whisper model from Audio settings.',
      actionText: 'Re-transcribe',
      route: AppRoutes.retranscribe,
      guideSectionIndex: 13, // Tips & Privacy
    ),
    _Tip(
      text: 'Add Vaanix widgets to your home screen for quick recording and stats at a glance.',
      actionText: null,
      route: null,
      guideSectionIndex: 9, // Widgets
    ),
  ];

  /// Shuffled order — created once per app session.
  static final List<int> _shuffledOrder = _buildShuffledOrder();

  static List<int> _buildShuffledOrder() {
    final indices = List.generate(_tips.length, (i) => i);
    indices.shuffle(Random());
    return indices;
  }

  @override
  ConsumerState<HomeTipTile> createState() => _HomeTipTileState();
}

class _HomeTipTileState extends ConsumerState<HomeTipTile> {
  bool _sessionDismissed = false;
  bool _autoHidden = false;
  Timer? _autoHideTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(minutes: 1), () {
      if (mounted) setState(() => _autoHidden = true);
    });
  }

  void _resetAutoHideTimer() {
    _autoHidden = false;
    _startAutoHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // Permanently disabled via settings
    if (settings.tipTileDismissed) return const SizedBox.shrink();

    // Hide tips after 1 month from first launch
    final firstLaunch = settings.firstLaunchDate;
    if (firstLaunch != null &&
        DateTime.now().difference(firstLaunch).inDays >= 30) {
      return const SizedBox.shrink();
    }

    // Session-only dismiss or auto-hidden after 1 min
    if (_sessionDismissed || _autoHidden) return const SizedBox.shrink();

    final shuffled = HomeTipTile._shuffledOrder;
    final tipIndex = shuffled[_currentIndex.clamp(0, shuffled.length - 1)];
    final tip = HomeTipTile._tips[tipIndex];
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFF9A825),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lightbulb icon
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.tips_and_updates_rounded,
                size: 20,
                color: Color(0xFFF9A825),
              ),
            ),
            const SizedBox(width: 10),

            // Tip content — tap body to open User Guide at the relevant section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push(AppRoutes.userGuide,
                          extra: {'openSectionIndex': tip.guideSectionIndex});
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Counter
                        Text(
                          'Tip ${_currentIndex + 1} of ${HomeTipTile._tips.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Tip text
                        Text(
                          tip.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action link (separate tap target)
                  if (tip.actionText != null && tip.route != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        context.push(tip.route!, extra: tip.routeExtra);
                      },
                      child: Text(
                        tip.actionText!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Navigation + dismiss
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dismiss (session only)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(Icons.close_rounded, color: theme.hintColor),
                    onPressed: () {
                      setState(() => _sessionDismissed = true);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                // Navigation row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: _currentIndex > 0
                              ? theme.colorScheme.onSurface
                              : theme.hintColor.withValues(alpha: 0.3),
                        ),
                        onPressed: _currentIndex > 0
                            ? () {
                                setState(() => _currentIndex--);
                                _resetAutoHideTimer();
                              }
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: _currentIndex < HomeTipTile._tips.length - 1
                              ? theme.colorScheme.onSurface
                              : theme.hintColor.withValues(alpha: 0.3),
                        ),
                        onPressed: _currentIndex < HomeTipTile._tips.length - 1
                            ? () {
                                setState(() => _currentIndex++);
                                _resetAutoHideTimer();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip {
  final String text;
  final String? actionText;
  final String? route;
  final Map<String, dynamic>? routeExtra;
  /// User Guide section index to open when the tip body is tapped.
  final int guideSectionIndex;

  const _Tip({
    required this.text,
    this.actionText,
    this.route,
    this.routeExtra,
    this.guideSectionIndex = 0,
  });
}
