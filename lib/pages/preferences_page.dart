import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/folders_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    String themeModeDisplay;
    if (settings.isAmoled) {
      themeModeDisplay = 'AMOLED Dark';
    } else {
      switch (settings.themeMode) {
        case ThemeMode.light:
          themeModeDisplay = 'Light';
          break;
        case ThemeMode.dark:
          themeModeDisplay = 'Dark';
          break;
        case ThemeMode.system:
          themeModeDisplay = 'System';
          break;
      }
    }

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
        title: const Text('Preferences'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                title: "PREFERENCES",
                children: [
                  SettingsItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: const Color(0xFFFCE4EC),
                    iconColor: const Color(0xFFC62828),
                    label: "Your Name",
                    sublabel: "Speaker label",
                    type: SettingsType.value,
                    valueText: settings.speakerName,
                    hasSublabel: true,
                    onTap: () async {
                      final controller = TextEditingController(
                          text: settings.speakerName);
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Your Name'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter your name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        ref
                            .read(settingsProvider.notifier)
                            .setSpeakerName(result);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.text_fields_rounded,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    label: "Note Prefix",
                    sublabel: "${settings.notePrefix}001, ${settings.notePrefix}002...",
                    type: SettingsType.value,
                    valueText: settings.notePrefix,
                    hasSublabel: true,
                    onTap: () async {
                      final controller = TextEditingController(
                          text: settings.notePrefix);
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Note Prefix'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            maxLength: 10,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'e.g. VOICE, NOTE, REC',
                              border: OutlineInputBorder(),
                              counterText: 'Max 10 characters',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        ref
                            .read(settingsProvider.notifier)
                            .setNotePrefix(result);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.edit_note_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFE65100),
                    label: "Text Prefix",
                    sublabel: "${settings.textNotePrefix}001, ${settings.textNotePrefix}002...",
                    type: SettingsType.value,
                    valueText: settings.textNotePrefix,
                    hasSublabel: true,
                    onTap: () async {
                      final controller = TextEditingController(
                          text: settings.textNotePrefix);
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Text Note Prefix'),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            maxLength: 10,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'e.g. TXT, NOTE, MEMO',
                              border: OutlineInputBorder(),
                              counterText: 'Max 10 characters',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, controller.text.trim()),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        ref
                            .read(settingsProvider.notifier)
                            .setTextNotePrefix(result);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.auto_fix_high_rounded,
                    iconBg: const Color(0xFFE8EAF6),
                    iconColor: const Color(0xFF3949AB),
                    label: "Auto Naming",
                    sublabel: _namingStyleDescription(settings.noteNamingStyle),
                    type: SettingsType.value,
                    valueText: _namingStyleLabel(settings.noteNamingStyle),
                    hasSublabel: true,
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (ctx) => _NamingStyleDialog(
                          current: settings.noteNamingStyle,
                          voicePrefix: settings.notePrefix,
                          textPrefix: settings.textNotePrefix,
                        ),
                      );
                      if (result != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setNoteNamingStyle(result);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.notifications_active_rounded,
                    iconBg: const Color(0xFFF1F8E9),
                    iconColor: const Color(0xFF388E3C),
                    label: "Reminders",
                    type: SettingsType.toggle,
                    switchValue: settings.notificationsEnabled,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setNotificationsEnabled(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.playlist_add_check_rounded,
                    iconBg: const Color(0xFFE8EAF6),
                    iconColor: const Color(0xFF3949AB),
                    label: "Action Items",
                    sublabel: "Show action items in note detail",
                    type: SettingsType.toggle,
                    switchValue: settings.actionItemsEnabled,
                    hasSublabel: true,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setActionItemsEnabled(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.checklist_rounded,
                    iconBg: const Color(0xFFFFF8E1),
                    iconColor: const Color(0xFFF9A825),
                    label: "To-Dos",
                    sublabel: "Show to-dos in note detail",
                    type: SettingsType.toggle,
                    switchValue: settings.todosEnabled,
                    hasSublabel: true,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setTodosEnabled(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.dark_mode_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "Appearance",
                    type: SettingsType.value,
                    valueText: themeModeDisplay,
                    onTap: () async {
                      final picked = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Choose Theme'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'system'),
                                child: const Text('System'),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'light'),
                                child: const Text('Light'),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'dark'),
                                child: const Text('Dark'),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'amoled'),
                                child: const Text('AMOLED Dark'),
                              ),
                            ],
                          );
                        },
                      );
                      if (picked != null) {
                        final notifier = ref.read(settingsProvider.notifier);
                        if (picked == 'amoled') {
                          notifier.setThemeMode(ThemeMode.dark, amoled: true);
                        } else {
                          notifier.setThemeMode(
                            SettingsState.parseThemeMode(picked),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  Builder(builder: (context) {
                    final folders = ref.watch(foldersProvider);
                    final defaultId = settings.defaultFolderId;
                    String folderName = 'None';
                    for (final f in folders) {
                      if (f.id == defaultId) {
                        folderName = f.name;
                        break;
                      }
                    }
                    return SettingsItem(
                      icon: Icons.folder_special_rounded,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      label: "Default Folder",
                      sublabel: "New recordings saved here",
                      type: SettingsType.value,
                      valueText: folderName,
                      hasSublabel: true,
                      onTap: () async {
                        final picked = await showDialog<String?>(
                          context: context,
                          builder: (ctx) {
                            return SimpleDialog(
                              title: const Text('Default Folder'),
                              children: [
                                ...folders.map((f) => SimpleDialogOption(
                                      onPressed: () => Navigator.pop(ctx, f.id),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.folder_rounded),
                                        title: Text(f.name),
                                        trailing: f.id == defaultId
                                            ? const Icon(Icons.check_rounded,
                                                color: Color(0xFF2E7D32))
                                            : null,
                                      ),
                                    )),
                              ],
                            );
                          },
                        );
                        if (picked == null || !context.mounted) return;
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultFolderId(picked);
                      },
                    );
                  }),
                  const Divider(height: 1, indent: 56),
                  SettingsItem(
                    icon: Icons.bug_report_outlined,
                    iconBg: const Color(0xFFEDE7F6),
                    iconColor: const Color(0xFF5E35B1),
                    label: "Anonymous Crash Reports",
                    sublabel: "Help improve the app (no personal data)",
                    type: SettingsType.toggle,
                    switchValue: settings.crashReportingEnabled,
                    hasSublabel: true,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setCrashReportingEnabled(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _namingStyleLabel(String style) {
    switch (style) {
      case 'prefix_only':
        return 'Prefix Only';
      case 'auto_only':
        return 'Auto Only';
      case 'prefix_auto':
      default:
        return 'Prefix + Auto';
    }
  }

  String _namingStyleDescription(String style) {
    switch (style) {
      case 'prefix_only':
        return 'Keep prefix title (e.g. V001)';
      case 'auto_only':
        return 'Auto-rename from transcription';
      case 'prefix_auto':
      default:
        return 'Prefix + auto title (e.g. V001 — Meeting notes)';
    }
  }
}

class _NamingStyleDialog extends StatefulWidget {
  final String current;
  final String voicePrefix;
  final String textPrefix;

  const _NamingStyleDialog({
    required this.current,
    required this.voicePrefix,
    required this.textPrefix,
  });

  @override
  State<_NamingStyleDialog> createState() => _NamingStyleDialogState();
}

class _NamingStyleDialogState extends State<_NamingStyleDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final vp = widget.voicePrefix;
    return AlertDialog(
      title: const Text('Auto Naming Style'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption(
            'prefix_auto',
            'Prefix + Auto (Recommended)',
            '${vp}001 — Meeting notes about...',
          ),
          _buildOption(
            'prefix_only',
            'Prefix Only',
            '${vp}001, ${vp}002, ${vp}003...',
          ),
          _buildOption(
            'auto_only',
            'Auto Only',
            'Meeting notes about budget...',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildOption(String value, String title, String example) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selected,
      onChanged: (v) => setState(() => _selected = v!),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(example, style: const TextStyle(fontSize: 12)),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
