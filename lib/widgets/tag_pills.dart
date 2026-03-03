import 'package:flutter/material.dart';
import '../theme.dart';

/// Displays a horizontal wrap of tag pills.
///
/// [tags]       — list of tag strings to show.
/// [onTap]      — optional; if provided each pill is tappable (e.g. filter by tag).
/// [onRemove]   — optional; if provided a ✕ button appears on each pill for removal.
/// [onAdd]      — optional; if provided an "+ Add tag" chip is appended.
/// [compact]    — smaller text + padding for use inside note cards.
class TagPills extends StatelessWidget {
  final List<String> tags;
  final void Function(String tag)? onTap;
  final void Function(String tag)? onRemove;
  final VoidCallback? onAdd;
  final bool compact;

  const TagPills({
    super.key,
    required this.tags,
    this.onTap,
    this.onRemove,
    this.onAdd,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty && onAdd == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final pillColor = scheme.secondaryContainer;
    final textColor = scheme.onSecondaryContainer;
    final fontSize = compact ? 11.0 : 12.0;
    final hPad = compact ? 8.0 : 10.0;
    final vPad = compact ? 3.0 : 5.0;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...tags.map((tag) => _TagPill(
              tag: tag,
              pillColor: pillColor,
              textColor: textColor,
              fontSize: fontSize,
              hPad: hPad,
              vPad: vPad,
              onTap: onTap != null ? () => onTap!(tag) : null,
              onRemove: onRemove != null ? () => onRemove!(tag) : null,
            )),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.5), width: 1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded,
                      size: fontSize + 2, color: scheme.secondary),
                  const SizedBox(width: 3),
                  Text(
                    'Add tag',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: scheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  final String tag;
  final Color pillColor;
  final Color textColor;
  final double fontSize;
  final double hPad;
  final double vPad;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _TagPill({
    required this.tag,
    required this.pillColor,
    required this.textColor,
    required this.fontSize,
    required this.hPad,
    required this.vPad,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$tag',
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: fontSize + 1,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
