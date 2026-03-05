import 'package:flutter/material.dart';
import '../theme.dart';

/// Bottom sheet shown after creating a reminder, letting the user choose
/// whether to also add it to the OS calendar.
class ReminderDestinationSheet extends StatelessWidget {
  final String reminderText;
  final DateTime reminderTime;
  final VoidCallback onKeepInApp;
  final VoidCallback onAlsoAddToCalendar;

  const ReminderDestinationSheet({
    super.key,
    required this.reminderText,
    required this.reminderTime,
    required this.onKeepInApp,
    required this.onAlsoAddToCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reminder set!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '"$reminderText"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Text(
              'Where should this reminder live?',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            // Keep in-app
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onKeepInApp();
              },
              icon: const Icon(Icons.notifications_active_rounded, size: 20),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keep in Vaanix'),
                  Text(
                    'Notification with link to this note',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Also add to OS calendar
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onAlsoAddToCalendar();
              },
              icon: const Icon(Icons.calendar_month_rounded, size: 20),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Also add to Calendar'),
                  Text(
                    'Syncs across your devices',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.8),
                        ),
                  ),
                ],
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
