import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';

/// Current app version string — update this on each release.
const currentAppVersion = '1.1.0';

/// What's New content — each entry is a feature highlight for the latest release.
const _whatsNewItems = <_WhatsNewEntry>[
  _WhatsNewEntry(
    icon: Icons.label_rounded,
    title: 'Tags',
    description: 'Organize notes with #tags. Add from voice commands or note detail.',
  ),
  _WhatsNewEntry(
    icon: Icons.folder_special_rounded,
    title: 'Projects Inside Folders',
    description: 'Projects now live inside folders for simpler navigation.',
  ),
  _WhatsNewEntry(
    icon: Icons.palette_rounded,
    title: 'Folder Colors',
    description: 'Pick a color when creating folders for visual distinction.',
  ),
  _WhatsNewEntry(
    icon: Icons.warning_amber_rounded,
    title: 'Overdue Task Badges',
    description: 'Note cards now show overdue task count at a glance.',
  ),
  _WhatsNewEntry(
    icon: Icons.backup_rounded,
    title: 'Smart Backup Reminders',
    description: 'Get reminded to back up once you have 10+ notes.',
  ),
  _WhatsNewEntry(
    icon: Icons.bug_report_outlined,
    title: 'Crash Reporting (Opt-In)',
    description: 'Help improve the app with anonymous crash reports.',
  ),
];

class _WhatsNewEntry {
  final IconData icon;
  final String title;
  final String description;

  const _WhatsNewEntry({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Returns true if the What's New screen should be shown.
bool shouldShowWhatsNew(SettingsState settings) {
  return settings.lastSeenAppVersion != null &&
      settings.lastSeenAppVersion != currentAppVersion;
}

/// Marks the current version as seen so What's New won't show again.
Future<void> markWhatsNewSeen(WidgetRef ref) async {
  final repo = ref.read(settingsRepositoryProvider);
  final settings = repo.getSettings();
  settings.lastSeenAppVersion = currentAppVersion;
  await repo.saveSettings(settings);
}

class WhatsNewPage extends ConsumerWidget {
  final VoidCallback onDismiss;

  const WhatsNewPage({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("What's New"),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              await markWhatsNewSeen(ref);
              onDismiss();
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _whatsNewItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _whatsNewItems[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(item.icon,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
