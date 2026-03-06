import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';

/// Non-intrusive banner reminding users to create or update their backup.
///
/// Shows when:
/// - User has 10+ notes and has never backed up, OR
/// - Last backup is older than 30 days
class BackupReminderBanner extends StatelessWidget {
  final bool neverBackedUp;
  final VoidCallback onDismiss;

  const BackupReminderBanner({
    super.key,
    required this.neverBackedUp,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded,
              color: scheme.onTertiaryContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  neverBackedUp
                      ? 'Protect your notes'
                      : 'Backup is outdated',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onTertiaryContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  neverBackedUp
                      ? 'Create your first encrypted backup'
                      : 'Your last backup is over 30 days old',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => context.push(AppRoutes.backupRestore),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Backup'),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded,
                size: 18, color: scheme.onTertiaryContainer),
          ),
        ],
      ),
    );
  }
}
