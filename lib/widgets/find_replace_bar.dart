import 'package:flutter/material.dart';

/// A compact Find & Replace toolbar for note editing.
class FindReplaceBar extends StatefulWidget {
  /// Called when the search query changes (debounced).
  final ValueChanged<String> onSearch;

  /// Called to replace the current match.
  final void Function(String replacement) onReplace;

  /// Called to replace all matches.
  final void Function(String replacement) onReplaceAll;

  /// Navigate to next match.
  final VoidCallback onNext;

  /// Navigate to previous match.
  final VoidCallback onPrevious;

  /// Close the bar.
  final VoidCallback onClose;

  /// Current match index (0-based).
  final int currentMatch;

  /// Total number of matches.
  final int totalMatches;

  const FindReplaceBar({
    super.key,
    required this.onSearch,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
    required this.currentMatch,
    required this.totalMatches,
  });

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  bool _showReplace = false;

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMatches = widget.totalMatches > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Find row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _findController,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Find...',
                      hintStyle: TextStyle(color: theme.hintColor),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onChanged: widget.onSearch,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Match counter
              SizedBox(
                width: 52,
                child: Text(
                  _findController.text.isEmpty
                      ? ''
                      : hasMatches
                          ? '${widget.currentMatch + 1}/${widget.totalMatches}'
                          : '0/0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: hasMatches
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Navigation arrows
              _IconBtn(
                icon: Icons.keyboard_arrow_up_rounded,
                onPressed: hasMatches ? widget.onPrevious : null,
                tooltip: 'Previous',
              ),
              _IconBtn(
                icon: Icons.keyboard_arrow_down_rounded,
                onPressed: hasMatches ? widget.onNext : null,
                tooltip: 'Next',
              ),
              // Toggle replace row
              _IconBtn(
                icon: _showReplace
                    ? Icons.find_replace_rounded
                    : Icons.find_replace_rounded,
                onPressed: () =>
                    setState(() => _showReplace = !_showReplace),
                tooltip: 'Find & Replace',
                isActive: _showReplace,
              ),
              // Close
              _IconBtn(
                icon: Icons.close_rounded,
                onPressed: widget.onClose,
                tooltip: 'Close',
              ),
            ],
          ),

          // Replace row (expandable)
          if (_showReplace) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _replaceController,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Replace...',
                        hintStyle: TextStyle(color: theme.hintColor),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: theme.colorScheme.primary),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: hasMatches
                      ? () => widget.onReplace(_replaceController.text)
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Replace'),
                ),
                TextButton(
                  onPressed: hasMatches
                      ? () => widget.onReplaceAll(_replaceController.text)
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('All'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isActive;

  const _IconBtn({
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: isActive ? theme.colorScheme.primary : null,
      visualDensity: VisualDensity.compact,
    );
  }
}
