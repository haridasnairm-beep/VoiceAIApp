import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';

/// Full User Guide page with 14 collapsible sections.
class UserGuidePage extends StatefulWidget {
  final int? openSectionIndex;

  const UserGuidePage({super.key, this.openSectionIndex});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  late int _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.openSectionIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('User Guide'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Everything you need to know about Vaanix. Tap a section to expand it.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
            ..._sections.asMap().entries.map((entry) {
              final i = entry.key;
              final section = entry.value;
              return _SectionTile(
                icon: section.icon,
                title: section.title,
                items: section.items,
                isExpanded: i == _expandedIndex,
                onToggle: () {
                  setState(() {
                    _expandedIndex = _expandedIndex == i ? -1 : i;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _GuideSection {
  final IconData icon;
  final String title;
  final List<_GuideItem> items;
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });
}

class _GuideItem {
  final String label;
  final String description;
  const _GuideItem({required this.label, required this.description});
}

const _sections = <_GuideSection>[
  // 0: Getting Started
  _GuideSection(
    icon: Icons.rocket_launch_rounded,
    title: 'Getting Started',
    items: [
      _GuideItem(
        label: 'First Launch',
        description:
            'On first launch, Vaanix shows a Quick Guide. You can revisit it anytime from Help & Support.',
      ),
      _GuideItem(
        label: 'Permissions',
        description:
            'Vaanix needs microphone access to record voice notes and notification access for reminders. Grant these when prompted.',
      ),
      _GuideItem(
        label: 'Whisper Setup',
        description:
            'For best transcription quality, download the Whisper model from Audio & Recording settings. This is a one-time ~150 MB download.',
      ),
    ],
  ),

  // 1: Recording
  _GuideSection(
    icon: Icons.mic_rounded,
    title: 'Recording Voice Notes',
    items: [
      _GuideItem(
        label: 'Gesture FAB',
        description:
            'Swipe up on the floating button to start recording instantly. Tap it to open the speed dial menu.',
      ),
      _GuideItem(
        label: 'Live Mode',
        description:
            'See your words appear in real-time as you speak. Best for short notes. Green text is still processing; white text is confirmed.',
      ),
      _GuideItem(
        label: 'Whisper Mode',
        description:
            'Record first, transcribe after. Better accuracy, especially for longer recordings or noisy environments. Whisper also handles shared audio in any format (.opus, .ogg, .mp3, etc.).',
      ),
      _GuideItem(
        label: 'Pause & Resume',
        description:
            'Tap the pause button during recording to take a break without stopping. Resume when ready.',
      ),
    ],
  ),

  // 2: Notes
  _GuideSection(
    icon: Icons.note_rounded,
    title: 'Notes & Editing',
    items: [
      _GuideItem(
        label: 'Text Notes',
        description:
            'Create text notes from the speed dial menu. Use rich text formatting — bold, italic, colors, lists.',
      ),
      _GuideItem(
        label: 'Edit Transcription',
        description:
            'Tap the edit icon on any note to modify the transcription. Each edit is saved as a version you can restore later.',
      ),
      _GuideItem(
        label: 'Version History',
        description:
            'Tap the history icon to see all previous versions of a note. Restore any version with one tap.',
      ),
      _GuideItem(
        label: 'Find & Replace',
        description:
            'Use the search icon in the note detail AppBar to find and replace text within a note.',
      ),
      _GuideItem(
        label: 'Pin Notes',
        description:
            'Swipe right on a note or use the pin icon to keep important notes at the top of your list. Up to 10 pinned notes.',
      ),
    ],
  ),

  // 3: Folders
  _GuideSection(
    icon: Icons.folder_rounded,
    title: 'Folders',
    items: [
      _GuideItem(
        label: 'Create Folders',
        description:
            'Go to Library and tap the + button. Choose a name and color for your folder.',
      ),
      _GuideItem(
        label: 'Organize Notes',
        description:
            'Move notes into folders from the note detail page or by long-pressing a note on the home screen.',
      ),
      _GuideItem(
        label: 'Default Folder',
        description:
            'Set a default folder in Audio & Recording settings. New voice notes will automatically go there.',
      ),
      _GuideItem(
        label: 'Voice Commands',
        description:
            'Say "Folder [name] start" at the beginning of a recording to auto-assign it to a folder.',
      ),
    ],
  ),

  // 4: Projects
  _GuideSection(
    icon: Icons.article_rounded,
    title: 'Project Documents',
    items: [
      _GuideItem(
        label: 'What Are Projects?',
        description:
            'Projects let you combine multiple notes, free text, section headers, images, and tasks into a single document.',
      ),
      _GuideItem(
        label: 'Add Blocks',
        description:
            'Use the speed dial FAB in a project to add voice notes, text notes, free text, section headers, images, or tasks.',
      ),
      _GuideItem(
        label: 'Reorder Blocks',
        description:
            'Long-press and drag blocks to reorder them. Use the 3-dot menu on each block for more options.',
      ),
      _GuideItem(
        label: 'Share & Export',
        description:
            'Share projects as text, Markdown, or PDF. Use the share icon in the project AppBar.',
      ),
    ],
  ),

  // 5: Tasks
  _GuideSection(
    icon: Icons.checklist_rounded,
    title: 'Tasks & Reminders',
    items: [
      _GuideItem(
        label: 'Action Items & Todos',
        description:
            'Add action items and todos to any note. Toggle them complete with a single tap.',
      ),
      _GuideItem(
        label: 'Reminders',
        description:
            'Set reminders with a date and time. Get a notification when it\'s due. Optionally add to your OS calendar.',
      ),
      _GuideItem(
        label: 'Tasks Tab',
        description:
            'Switch to the Tasks tab on the home screen to see all tasks across all notes in one view.',
      ),
      _GuideItem(
        label: 'Task Blocks',
        description:
            'In project documents, add a Task Block to include specific tasks. These appear in share/export output.',
      ),
    ],
  ),

  // 6: Search
  _GuideSection(
    icon: Icons.search_rounded,
    title: 'Search',
    items: [
      _GuideItem(
        label: 'Full-Text Search',
        description:
            'Search across note titles, transcriptions, actions, todos, reminders, tags, and project content.',
      ),
      _GuideItem(
        label: 'Sectioned Results',
        description:
            'Results are grouped by type — Notes, Actions, Todos, Reminders, Projects — for easy scanning.',
      ),
    ],
  ),

  // 7: Tags
  _GuideSection(
    icon: Icons.label_rounded,
    title: 'Tags',
    items: [
      _GuideItem(
        label: 'Add Tags',
        description:
            'Tap the + button in the tags section of a note detail to add tags. Tags help you categorize and filter.',
      ),
      _GuideItem(
        label: 'Voice Commands',
        description:
            'Say "Tag [name] start" at the beginning of a recording to auto-assign a tag.',
      ),
      _GuideItem(
        label: 'Manage Tags',
        description:
            'Go to Library > Tags to see all tags, rename them, or delete unused ones.',
      ),
    ],
  ),

  // 8: Calendar
  _GuideSection(
    icon: Icons.calendar_month_rounded,
    title: 'Calendar View',
    items: [
      _GuideItem(
        label: 'Browse by Date',
        description:
            'The calendar shows color-coded dots for notes, tasks, and projects on each day.',
      ),
      _GuideItem(
        label: 'Filter & Sort',
        description:
            'Use filter chips to show only notes with tasks, projects, or all notes. Sort by date or title.',
      ),
    ],
  ),

  // 9: Widgets
  _GuideSection(
    icon: Icons.widgets_rounded,
    title: 'Home Screen Widgets',
    items: [
      _GuideItem(
        label: 'Quick Record Widget',
        description:
            'A 2x1 widget with a beautiful background and REC button. Tap anywhere to jump straight into recording — even when the app is locked.',
      ),
      _GuideItem(
        label: 'Dashboard Widget',
        description:
            'A 4x2 widget showing your note count and open tasks over a visual background. Tap the Notes cell to open the Notes tab, or the Tasks cell to open the Tasks tab. The REC button starts a new recording.',
      ),
      _GuideItem(
        label: 'Quick Capture (App Lock)',
        description:
            'When App Lock is enabled, the REC button on either widget lets you record without unlocking. A lock icon appears during recording. After saving, you\'ll be taken to the lock screen to authenticate before accessing the full app.',
      ),
      _GuideItem(
        label: 'Widget Privacy',
        description:
            'Control what the dashboard widget shows when App Lock is on: Full (counts + preview), Record-Only (counts only), or Minimal (just REC button). Changes take effect immediately. Go to Security > Widget Privacy.',
      ),
      _GuideItem(
        label: 'Live Updates',
        description:
            'Widget data updates automatically when you create, edit, or delete notes and tasks — no need to reopen the app.',
      ),
    ],
  ),

  // 10: App Lock
  _GuideSection(
    icon: Icons.lock_rounded,
    title: 'App Lock & Security',
    items: [
      _GuideItem(
        label: 'PIN Lock',
        description:
            'Set a 4 to 6 digit PIN to protect your notes. Go to Security in settings. The PIN auto-verifies once you enter the correct number of digits.',
      ),
      _GuideItem(
        label: 'Biometric Unlock',
        description:
            'Enable fingerprint or face unlock for faster access while keeping your data secure.',
      ),
      _GuideItem(
        label: 'Auto-Lock',
        description:
            'Choose when the app locks after going to the background — immediately, 1 min, 5 min, or 15 min.',
      ),
      _GuideItem(
        label: 'Widget Access',
        description:
            'When App Lock is on, widget REC buttons bypass the lock for quick recording. A lock icon shows during recording, and authentication is required after saving. Other widget actions (Notes, Tasks) require full authentication first.',
      ),
    ],
  ),

  // 11: Backup
  _GuideSection(
    icon: Icons.backup_rounded,
    title: 'Backup & Restore',
    items: [
      _GuideItem(
        label: 'Manual Backup',
        description:
            'Create an encrypted .vnbak backup file. Share it via WhatsApp, email, or save to your files.',
      ),
      _GuideItem(
        label: 'Auto-Backup',
        description:
            'Enable automatic backups in Backup & Restore settings. Choose daily, every 3 days, or weekly.',
      ),
      _GuideItem(
        label: 'Restore',
        description:
            'Open a .vnbak file to restore your data. You\'ll need the same passphrase used during backup.',
      ),
      _GuideItem(
        label: 'Passphrase Security',
        description:
            'Your backup passphrase is never stored in the cloud. If you lose it, the backup cannot be recovered.',
      ),
    ],
  ),

  // 12: Settings
  _GuideSection(
    icon: Icons.settings_rounded,
    title: 'Settings Overview',
    items: [
      _GuideItem(
        label: 'Preferences',
        description:
            'Set your name, theme (light/dark/AMOLED), note naming style, and sort order.',
      ),
      _GuideItem(
        label: 'Audio & Recording',
        description:
            'Choose transcription mode (Live or Whisper), language, Whisper model, and recording options.',
      ),
      _GuideItem(
        label: 'Storage',
        description:
            'View how much space notes, recordings, images, and Whisper models are using.',
      ),
    ],
  ),

  // 13: Tips & Privacy
  _GuideSection(
    icon: Icons.tips_and_updates_rounded,
    title: 'Tips & Privacy',
    items: [
      _GuideItem(
        label: 'Share to Vaanix',
        description:
            'Share audio files from WhatsApp, Telegram, or any app directly into Vaanix for transcription. Supports .opus, .ogg, .mp3, .aac, .m4a, and more — audio is automatically converted to the right format.',
      ),
      _GuideItem(
        label: 'Shared Notes',
        description:
            'Notes from shared audio show a gold badge. You can see who sent it and the original filename. Your default folder is pre-selected when saving.',
      ),
      _GuideItem(
        label: 'Re-transcribe',
        description:
            'Go to Audio & Recording settings > Re-transcribe Notes to re-transcribe any voice note with a different Whisper model. Select multiple notes at once. New transcription replaces the current text as plain text; previous versions are kept in version history.',
      ),
      _GuideItem(
        label: 'Privacy First',
        description:
            'All data stays on your device. No cloud storage, no accounts, no tracking. Your notes are yours.',
      ),
      _GuideItem(
        label: 'Home Tips',
        description:
            'The tip card on the home page shows helpful hints that rotate each session. It auto-hides after 1 minute. Close it to hide for the current session, or disable permanently from Help & Support > Home Tips.',
      ),
      _GuideItem(
        label: 'Trash & Recovery',
        description:
            'Deleted notes go to Trash for 30 days. Restore them anytime before they\'re permanently removed.',
      ),
    ],
  ),
];

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_GuideItem> items;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SectionTile({
    required this.icon,
    required this.title,
    required this.items,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: '${item.label}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: item.description,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
