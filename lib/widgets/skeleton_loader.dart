import 'package:flutter/material.dart';
import '../theme.dart';

/// Shimmer skeleton placeholder matching a note card layout.
///
/// Shows animated placeholder bars for timestamp, title, preview lines.
class NoteCardSkeleton extends StatefulWidget {
  const NoteCardSkeleton({super.key});

  @override
  State<NoteCardSkeleton> createState() => _NoteCardSkeletonState();
}

class _NoteCardSkeletonState extends State<NoteCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata row skeleton
            Row(
              children: [
                _ShimmerBar(width: 60, height: 10, animation: _animation),
                const SizedBox(width: 12),
                _ShimmerBar(width: 40, height: 10, animation: _animation),
                const SizedBox(width: 12),
                _ShimmerBar(width: 30, height: 10, animation: _animation),
              ],
            ),
            const SizedBox(height: 10),
            // Preview lines
            _ShimmerBar(
                width: double.infinity, height: 12, animation: _animation),
            const SizedBox(height: 8),
            _ShimmerBar(width: 200, height: 12, animation: _animation),
            const SizedBox(height: 12),
            // Title + chips row
            Row(
              children: [
                _ShimmerBar(width: 80, height: 20, animation: _animation),
                const SizedBox(width: 8),
                _ShimmerBar(width: 60, height: 20, animation: _animation),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> animation;

  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor =
        Theme.of(context).colorScheme.surface;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (animation.value - 0.3).clamp(0.0, 1.0),
            animation.value.clamp(0.0, 1.0),
            (animation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}

/// Shows a column of skeleton note cards.
class SkeletonNoteList extends StatelessWidget {
  final int count;

  const SkeletonNoteList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(count, (_) => const NoteCardSkeleton()),
      ),
    );
  }
}
