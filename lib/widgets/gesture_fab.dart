import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/haptic_service.dart';
import 'speed_dial_fab.dart';

/// A FAB that supports two gestures:
/// - **Swipe up** → Navigate directly to recording screen
/// - **Tap** → Expand SpeedDial with all actions
///
/// See documents/FEATURE_GESTURE_FAB.md for full spec.
class GestureFab extends StatefulWidget {
  final VoidCallback onRecord;
  final List<SpeedDialItem> speedDialItems;
  final int sessionCount;
  final bool showSubtitleHint;
  final ValueChanged<bool>? onDialToggled;

  const GestureFab({
    required this.onRecord,
    required this.speedDialItems,
    this.sessionCount = 0,
    this.showSubtitleHint = false,
    this.onDialToggled,
    super.key,
  });

  @override
  State<GestureFab> createState() => GestureFabState();
}

class GestureFabState extends State<GestureFab>
    with TickerProviderStateMixin {
  static const double _swipeThreshold = 40.0;
  static const double _maxHorizontalDrift = 20.0;

  double _dragDistance = 0.0;
  double _totalHorizontalDrift = 0.0;
  bool _thresholdReached = false;
  bool _isDragging = false;
  bool _isDialOpen = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // For icon crossfade
  bool _showMicIcon = false;

  // Speed dial state
  final GlobalKey _fabKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late final AnimationController _dialController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _pulseController.dispose();
    _dialController.dispose();
    super.dispose();
  }

  // --- Gesture handlers ---

  void _handleDragStart(DragStartDetails details) {
    // If dial is open, ignore swipe gestures
    if (_isDialOpen) return;
    _isDragging = true;
    _dragDistance = 0.0;
    _totalHorizontalDrift = 0.0;
    _thresholdReached = false;
    _showMicIcon = false;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isDialOpen) return;

    // Only track upward drags (dy < 0 = upward)
    if (details.delta.dy >= 0) return;

    // Accumulate horizontal drift
    _totalHorizontalDrift += details.delta.dx.abs();
    if (_totalHorizontalDrift > _maxHorizontalDrift) {
      // Too much horizontal drift — cancel
      _resetDragState();
      return;
    }

    _dragDistance += details.delta.dy.abs();

    // Icon transition at 20px
    if (_dragDistance >= 20.0 && !_showMicIcon) {
      setState(() => _showMicIcon = true);
    }

    // Threshold reached at 40px
    if (!_thresholdReached && _dragDistance >= _swipeThreshold) {
      _thresholdReached = true;
      HapticService.medium();
      _triggerPulse();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    if (_thresholdReached) {
      HapticService.light();
      widget.onRecord();
    }
    _resetDragState();
  }

  void _handleDragCancel() {
    _resetDragState();
  }

  void _resetDragState() {
    setState(() {
      _dragDistance = 0.0;
      _totalHorizontalDrift = 0.0;
      _thresholdReached = false;
      _isDragging = false;
      _showMicIcon = false;
    });
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });
  }

  // --- SpeedDial (tap) ---

  void _handleTap() {
    if (_isDialOpen) {
      _closeDial();
    } else {
      _openDial();
    }
  }

  void _openDial() {
    _insertOverlay();
    _dialController.forward();
    setState(() => _isDialOpen = true);
    widget.onDialToggled?.call(true);
  }

  void _closeDial() {
    _dialController.reverse().then((_) {
      _removeOverlay();
    });
    setState(() => _isDialOpen = false);
    widget.onDialToggled?.call(false);
  }

  /// Close immediately without animation (for navigation).
  void _closeDialImmediate() {
    _dialController.reset();
    _removeOverlay();
    setState(() => _isDialOpen = false);
    widget.onDialToggled?.call(false);
  }

  /// Close the dial programmatically (e.g. from back button).
  void closeDial() {
    if (_isDialOpen) _closeDial();
  }

  void _insertOverlay() {
    final fabRenderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (fabRenderBox == null) return;
    final fabSize = fabRenderBox.size;

    // Get the overlay's RenderBox to convert coordinates into its space
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox =
        overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    final overlaySize = overlayBox.size;

    // Convert FAB position from global to overlay-local coordinates
    final fabPosInOverlay = fabRenderBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final right = overlaySize.width - fabPosInOverlay.dx - fabSize.width;
    final fabBottom = overlaySize.height - fabPosInOverlay.dy - fabSize.height;
    final menuBottom = overlaySize.height - fabPosInOverlay.dy + 12;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SpeedDialOverlay(
        controller: _dialController,
        items: widget.speedDialItems,
        onClose: _closeDial,
        onItemTap: _closeDialImmediate,
        right: right,
        bottom: menuBottom,
        fabRight: right,
        fabBottom: fabBottom,
        onFabTap: _handleTap,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showLabel = widget.showSubtitleHint &&
        widget.sessionCount <= 10 &&
        !_isDialOpen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Subtitle hint label
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedOpacity(
              opacity: _isDialOpen ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'swipe '),
                    TextSpan(
                      text: '\u2191',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const TextSpan(text: ' to record'),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                ),
                semanticsLabel: '',
              ),
            ),
          ),

        // The FAB with gesture detection
        GestureDetector(
          onVerticalDragStart: _handleDragStart,
          onVerticalDragUpdate: _handleDragUpdate,
          onVerticalDragEnd: _handleDragEnd,
          onVerticalDragCancel: _handleDragCancel,
          onTap: _handleTap,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: FloatingActionButton(
              key: _fabKey,
              heroTag: 'gesture_fab_main',
              elevation: 6,
              backgroundColor: colorScheme.primary,
              onPressed: null, // Handled by GestureDetector
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _showMicIcon
                    ? Icon(Icons.mic_rounded,
                        key: const ValueKey('mic'),
                        color: colorScheme.onPrimary,
                        size: 28)
                    : AnimatedBuilder(
                        animation: _dialController,
                        builder: (context, child) => Transform.rotate(
                          angle: _dialController.value * 0.785398, // 45 deg
                          child: Icon(
                            Icons.add_rounded,
                            color: colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The overlay content: full-screen blur scrim + mini-FABs.
/// Reused from SpeedDialFab with minor adjustments.
class _SpeedDialOverlay extends StatelessWidget {
  final AnimationController controller;
  final List<SpeedDialItem> items;
  final VoidCallback onClose;
  final VoidCallback onItemTap;
  final double right;
  final double bottom;
  final double fabRight;
  final double fabBottom;
  final VoidCallback onFabTap;

  const _SpeedDialOverlay({
    required this.controller,
    required this.items,
    required this.onClose,
    required this.onItemTap,
    required this.right,
    required this.bottom,
    required this.fabRight,
    required this.fabBottom,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Full-screen blur + dim scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: controller.value * 8,
                    sigmaY: controller.value * 8,
                  ),
                  child: ColoredBox(
                    color: Colors.black
                        .withValues(alpha: controller.value * 0.3),
                  ),
                ),
              ),
            ),
          ),

          // Main FAB rendered above the blur scrim
          Positioned(
            right: fabRight,
            bottom: fabBottom,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => FloatingActionButton(
                heroTag: 'gesture_fab_overlay',
                elevation: 6,
                backgroundColor: colorScheme.primary,
                onPressed: onFabTap,
                child: Transform.rotate(
                  angle: controller.value * 0.785398,
                  child: Icon(
                    Icons.add_rounded,
                    color: colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          // Mini-FABs positioned above the main FAB
          Positioned(
            right: right,
            bottom: bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final reverseIndex = items.length - 1 - i;
                final intervalStart = reverseIndex * 0.1;
                final intervalEnd =
                    (intervalStart + 0.6).clamp(0.0, 1.0);

                final animation = CurvedAnimation(
                  parent: controller,
                  curve: Interval(intervalStart, intervalEnd,
                      curve: Curves.easeOutCubic),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Label chip
                          Material(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Text(
                                item.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Mini-FAB
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: FloatingActionButton(
                              heroTag: 'gesture_dial_$i',
                              mini: true,
                              elevation: 4,
                              backgroundColor: colorScheme.surface,
                              onPressed: () {
                                onItemTap();
                                item.onTap();
                              },
                              child: Icon(
                                item.icon,
                                size: 22,
                                color: item.iconColor ??
                                    colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
