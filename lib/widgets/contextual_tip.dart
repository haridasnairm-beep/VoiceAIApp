import 'package:flutter/material.dart';
import '../theme.dart';

/// Small, non-blocking tooltip banner for first-time feature discovery.
///
/// Shows a tip message with an optional CTA and a dismiss button.
/// One-time only — caller is responsible for checking/dismissing via TipService.
class ContextualTip extends StatelessWidget {
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final VoidCallback onDismiss;
  final IconData icon;

  const ContextualTip({
    super.key,
    required this.message,
    this.ctaLabel,
    this.onCta,
    required this.onDismiss,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: onCta,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(ctaLabel!,
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
          GestureDetector(
            onTap: onDismiss,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 16, color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
