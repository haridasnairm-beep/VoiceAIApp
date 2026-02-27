import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/settings_provider.dart';
import '../services/hive_service.dart';
import '../services/whisper_service.dart';

const _languageOptions = <String?, String>{
  null: 'Automatic',
  'en': 'English',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'hi': 'Hindi',
  'ar': 'Arabic',
  'pt': 'Portuguese',
  'zh': 'Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
  'ru': 'Russian',
  'it': 'Italian',
};

class SettingsPage extends ConsumerStatefulWidget {
  final bool highlightWhisper;
  const SettingsPage({super.key, this.highlightWhisper = false});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _whisperSectionKey = GlobalKey();
  bool _showHighlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.highlightWhisper) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToWhisperSection();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToWhisperSection() async {
    // Wait for layout
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final keyContext = _whisperSectionKey.currentContext;
    if (keyContext != null) {
      await Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }

    if (!mounted) return;
    // Flash highlight
    setState(() => _showHighlight = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _showHighlight = false);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final settings = ref.watch(settingsProvider);
    final notes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);

    // Derive display strings from state
    final languageDisplay =
        _languageOptions[settings.defaultLanguage] ?? 'Automatic';
    final languageSublabel = settings.defaultLanguage == null
        ? 'Auto-detect is active'
        : languageDisplay;
    final audioQualityDisplay =
        settings.audioQuality == 'high' ? 'High Quality' : 'Standard';

    String themeModeDisplay;
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              "Personalize your experience",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preferences Group
              _SettingsGroup(
                title: "PREFERENCES",
                children: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: const Color(0xFFFCE4EC),
                    iconColor: const Color(0xFFC62828),
                    label: "Your Name",
                    sublabel: "Used as speaker label in transcriptions",
                    type: _SettingsType.value,
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
                  _SettingsItem(
                    icon: Icons.text_fields_rounded,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    label: "Note Prefix",
                    sublabel: "Auto-name: ${settings.notePrefix}001, ${settings.notePrefix}002...",
                    type: _SettingsType.value,
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
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1976D2),
                    label: "Detection Language",
                    sublabel: languageSublabel,
                    type: _SettingsType.value,
                    valueText: languageDisplay,
                    hasSublabel: true,
                    onTap: () async {
                      final picked = await showDialog<_LanguageChoice>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Detection Language'),
                            children: _languageOptions.entries.map((e) {
                              final isSelected =
                                  settings.defaultLanguage == e.key;
                              return SimpleDialogOption(
                                onPressed: () => Navigator.pop(
                                    ctx, _LanguageChoice(e.key)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 20),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                      if (picked != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultLanguage(picked.code);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.notifications_active_rounded,
                    iconBg: const Color(0xFFF1F8E9),
                    iconColor: const Color(0xFF388E3C),
                    label: "Reminders",
                    type: _SettingsType.toggle,
                    switchValue: settings.notificationsEnabled,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setNotificationsEnabled(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.dark_mode_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "Appearance",
                    type: _SettingsType.value,
                    valueText: themeModeDisplay,
                    onTap: () async {
                      final picked = await showDialog<ThemeMode>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Choose Theme'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, ThemeMode.system),
                                child: const Text('System'),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, ThemeMode.light),
                                child: const Text('Light'),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, ThemeMode.dark),
                                child: const Text('Dark'),
                              ),
                            ],
                          );
                        },
                      );
                      if (picked != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(picked);
                      }
                    },
                  ),
                ],
              ),

              // Audio Group
              _SettingsGroup(
                title: "AUDIO",
                children: [
                  _SettingsItem(
                    icon: Icons.high_quality_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57C00),
                    label: "Audio Quality",
                    sublabel: settings.audioQuality == 'high'
                        ? "Lossless audio, larger files"
                        : "Smaller file size, good quality",
                    type: _SettingsType.value,
                    valueText: audioQualityDisplay,
                    hasSublabel: true,
                    onTap: () async {
                      final picked = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Audio Quality'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'standard'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.sd_rounded),
                                  title: Text('Standard'),
                                  subtitle: Text(
                                      'Smaller file size, good quality'),
                                ),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'high'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.hd_rounded),
                                  title: Text('High Quality'),
                                  subtitle: Text(
                                      'Lossless audio, larger files'),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (picked != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setAudioQuality(picked);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.record_voice_over_rounded,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    label: "Transcription",
                    sublabel: settings.transcriptionMode == 'live'
                        ? "Live text, no audio file"
                        : "Audio + text after recording",
                    type: _SettingsType.value,
                    valueText: settings.transcriptionMode == 'live'
                        ? 'Live'
                        : 'Whisper',
                    hasSublabel: true,
                    onTap: () async {
                      final picked = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          return SimpleDialog(
                            title: const Text('Transcription Mode'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'live'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.subtitles_rounded),
                                  title: Text('Live Transcription'),
                                  subtitle: Text(
                                      'Real-time text while recording. No audio file saved.'),
                                ),
                              ),
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(ctx, 'whisper'),
                                child: const ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.mic_rounded),
                                  title: Text('Record & Transcribe'),
                                  subtitle: Text(
                                      'Records audio first, then transcribes. Supports playback.'),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (picked == null || !context.mounted) return;

                      if (picked == 'live') {
                        ref.read(settingsProvider.notifier).setTranscriptionMode('live');
                        return;
                      }

                      // Whisper selected — check if model is downloaded
                      final modelReady = await WhisperService.instance.isModelDownloaded();
                      if (modelReady) {
                        if (!context.mounted) return;
                        ref.read(settingsProvider.notifier).setTranscriptionMode('whisper');
                        return;
                      }

                      // Model not downloaded — ask user to download
                      if (!context.mounted) return;
                      final confirmDownload = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Download Whisper Model'),
                          content: const Text(
                            'Whisper AI requires a one-time model download (~140 MB).\n\n'
                            'Make sure you are connected to WiFi before proceeding.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Download'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDownload != true || !context.mounted) return;

                      // Show download progress dialog
                      final success = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => _WhisperDownloadDialog(),
                      );

                      if (success == true && context.mounted) {
                        ref.read(settingsProvider.notifier).setTranscriptionMode('whisper');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Whisper model downloaded. Record & Transcribe mode is active.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download failed. Please check your connection and try again.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  if (settings.transcriptionMode == 'whisper') ...[
                    const Divider(height: 1, indent: 56),
                    AnimatedContainer(
                      key: _whisperSectionKey,
                      duration: const Duration(milliseconds: 600),
                      decoration: BoxDecoration(
                        color: _showHighlight
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _WhisperModelStatusItem(),
                    ),
                  ],
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
                    return _SettingsItem(
                      icon: Icons.folder_special_rounded,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      label: "Default Folder",
                      sublabel: "New recordings are saved here",
                      type: _SettingsType.value,
                      valueText: folderName,
                      hasSublabel: true,
                      onTap: () async {
                        final picked = await showDialog<String?>(
                          context: context,
                          builder: (ctx) {
                            return SimpleDialog(
                              title: const Text('Default Folder'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () => Navigator.pop(ctx, '__none__'),
                                  child: const ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(Icons.block_rounded),
                                    title: Text('None'),
                                    subtitle: Text('No default folder'),
                                  ),
                                ),
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
                        final newId = picked == '__none__' ? null : picked;
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultFolderId(newId);
                      },
                    );
                  }),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.record_voice_over_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "Voice Commands",
                    sublabel:
                        'Say "Folder/Project <name> Start" to auto-organize',
                    type: _SettingsType.toggle,
                    switchValue: settings.voiceCommandsEnabled,
                    hasSublabel: true,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setVoiceCommandsEnabled(value);
                    },
                  ),
                ],
              ),

              // Storage Usage
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Local Storage",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          "${notes.length} notes · ${folders.length} folders",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<String>(
                      future: HiveService.getStorageUsage(),
                      builder: (context, snapshot) {
                        final usage = snapshot.data ?? 'Calculating...';
                        return Row(
                          children: [
                            Icon(Icons.storage_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Storage used: $usage",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Theme.of(context).hintColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Your voice notes are stored locally on this device.",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Support Group
              _SettingsGroup(
                title: "SUPPORT",
                children: [
                  _SettingsItem(
                    icon: Icons.menu_book_rounded,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    label: "Quick Guide",
                    sublabel: "Learn how VoiceNotes AI works",
                    type: _SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.onboarding);
                    },
                  ),
                ],
              ),

              // Danger Zone
              _SettingsGroup(
                title: "DANGER ZONE",
                titleColor: Theme.of(context).colorScheme.error,
                children: [
                  _SettingsItem(
                    icon: Icons.delete_forever_rounded,
                    iconBg: const Color(0xFFFFEBEE),
                    iconColor: const Color(0xFFD32F2F),
                    label: "Delete All Data",
                    sublabel: "Permanently remove all notes and settings",
                    type: _SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text('Delete All Data'),
                            content: const Text(
                              'This will permanently delete all your voice notes, folders, and settings. This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed == true && context.mounted) {
                        await HiveService.deleteAllData();
                        if (context.mounted) {
                          context.go(AppRoutes.home);
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "VoiceNotes AI v1.0.0",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper to distinguish null (Automatic) from dialog dismissal.
class _LanguageChoice {
  final String? code;
  const _LanguageChoice(this.code);
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: titleColor ?? Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

enum _SettingsType { toggle, chevron, value }

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? sublabel;
  final _SettingsType type;
  final bool switchValue;
  final String? valueText;
  final bool hasSublabel;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.sublabel,
    required this.type,
    this.switchValue = false,
    this.valueText,
    this.hasSublabel = false,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                if (hasSublabel && sublabel != null)
                  Text(
                    sublabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
              ],
            ),
          ),
          if (type == _SettingsType.toggle)
            Switch(
              value: switchValue,
              onChanged: onChanged ?? (val) {},
              activeColor: Theme.of(context).colorScheme.primary,
            )
          else if (type == _SettingsType.chevron)
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20)
          else if (type == _SettingsType.value)
            Row(
              children: [
                Text(
                  valueText ?? "",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor, size: 20),
              ],
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Always-visible Whisper model status row in the AUDIO settings section.
class _WhisperModelStatusItem extends StatefulWidget {
  @override
  State<_WhisperModelStatusItem> createState() =>
      _WhisperModelStatusItemState();
}

class _WhisperModelStatusItemState extends State<_WhisperModelStatusItem> {
  bool _isDownloaded = false;
  bool _isChecking = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    final downloaded = await WhisperService.instance.isModelDownloaded();
    if (!mounted) return;
    setState(() {
      _isDownloaded = downloaded;
      _isChecking = false;
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final success = await WhisperService.instance.downloadModel(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _downloadProgress = progress);
      },
    );

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _isDownloaded = success;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Whisper model downloaded successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Download failed. Please check your connection and retry.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget trailing;
    String sublabel;

    if (_isChecking) {
      trailing = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
      sublabel = 'Checking...';
    } else if (_isDownloading) {
      trailing = SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LinearProgressIndicator(
              value: _downloadProgress > 0 ? _downloadProgress : null,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
      sublabel = 'Downloading ~140 MB...';
    } else if (_isDownloaded) {
      trailing = Icon(
        Icons.check_circle_rounded,
        color: const Color(0xFF2E7D32),
        size: 22,
      );
      sublabel = 'Ready to use';
    } else {
      trailing = FilledButton.tonal(
        onPressed: _startDownload,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Download'),
      );
      sublabel = 'One-time download (~140 MB)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.downloading_rounded,
              color: Color(0xFFE65100),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Whisper Model',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Dialog that downloads the Whisper model with a progress indicator.
class _WhisperDownloadDialog extends StatefulWidget {
  @override
  State<_WhisperDownloadDialog> createState() => _WhisperDownloadDialogState();
}

class _WhisperDownloadDialogState extends State<_WhisperDownloadDialog> {
  double _progress = 0.0;
  bool _downloading = true;
  String _statusText = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    final success = await WhisperService.instance.downloadModel(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _progress = progress;
          final percent = (progress * 100).toInt();
          _statusText = 'Downloading... $percent%';
        });
      },
    );

    if (!mounted) return;
    setState(() => _downloading = false);
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Downloading Whisper Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: _downloading ? (_progress > 0 ? _progress : null) : 1.0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '~140 MB',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
