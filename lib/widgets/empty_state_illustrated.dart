import 'package:flutter/material.dart';

/// Reusable empty-state widget with an icon, title, subtitle, and optional CTA.
///
/// Used on Home (Notes tab), Tasks tab, Library, Search, and similar list pages
/// to provide contextual guidance instead of a blank screen.
class EmptyStateIllustrated extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Color? iconColor;

  const EmptyStateIllustrated({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.5,
              ),
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onCta,
                child: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
