import 'dart:ui';

import 'package:flutter/material.dart';

/// A single item in the Speed Dial menu.
class SpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });
}

/// An expandable FAB that reveals mini-FABs with labels.
/// Uses Overlay for full-screen blur scrim.
class SpeedDialFab extends StatefulWidget {
  final List<SpeedDialItem> items;

  const SpeedDialFab({super.key, required this.items});

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _fabKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _controller.reverse().then((_) {
        _removeOverlay();
      });
    } else {
      _insertOverlay();
      _controller.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  /// Close immediately without waiting for reverse animation.
  /// Used when navigating away so the overlay doesn't linger.
  void _closeImmediate() {
    if (!_isOpen) return;
    _controller.reset();
    _removeOverlay();
    setState(() {
      _isOpen = false;
    });
  }

  Offset _getFabPosition() {
    final renderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  Size _getFabSize() {
    final renderBox =
        _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const Size(56, 56);
    return renderBox.size;
  }

  void _insertOverlay() {
    final fabPos = _getFabPosition();
    final fabSize = _getFabSize();
    final screenSize = MediaQuery.of(context).size;

    // Right edge = distance from FAB's right edge to screen right
    final right = screenSize.width - fabPos.dx - fabSize.width;
    // Bottom = distance from FAB's top edge to screen bottom + gap
    final bottom = screenSize.height - fabPos.dy + 12;

    _overlayEntry = OverlayEntry(
      builder: (context) => _SpeedDialOverlay(
        controller: _controller,
        items: widget.items,
        onClose: _close,
        onItemTap: _closeImmediate,
        right: right,
        bottom: bottom,
        fabRight: right,
        fabBottom: screenSize.height - fabPos.dy - fabSize.height,
        onFabTap: _toggle,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      key: _fabKey,
      heroTag: 'speed_dial_main',
      elevation: 6,
      backgroundColor: colorScheme.primary,
      onPressed: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.rotate(
          angle: _controller.value * 0.785398, // 45 degrees
          child: Icon(
            Icons.add_rounded,
            color: colorScheme.onPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// The overlay content: full-screen blur scrim + mini-FABs.
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
                heroTag: 'speed_dial_overlay',
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
                              heroTag: 'speed_dial_$i',
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
