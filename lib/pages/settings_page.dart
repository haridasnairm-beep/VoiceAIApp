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
import '../widgets/download_progress_sheet.dart';

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
                    sublabel: "Speaker label",
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
                    sublabel: "${settings.notePrefix}001, ${settings.notePrefix}002...",
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
                    icon: Icons.edit_note_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFE65100),
                    label: "Text Prefix",
                    sublabel: "${settings.textNotePrefix}001, ${settings.textNotePrefix}002...",
                    type: _SettingsType.value,
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
                        ? "Lossless, larger files"
                        : "Smaller size, good quality",
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

                      final modelReady = await WhisperService.instance.isModelDownloaded();
                      if (modelReady) {
                        if (!context.mounted) return;
                        ref.read(settingsProvider.notifier).setTranscriptionMode('whisper');
                        return;
                      }

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

                      final success = await showDownloadSheet(context, modelName: 'base');

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
                            content: Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
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
                      sublabel: "New recordings saved here",
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
                        'Say "Folder/Project <name> Start"',
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

              // Storage Usage — detailed breakdown
              _StorageBreakdownSection(
                noteCount: notes.length,
                folderCount: folders.length,
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
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.feedback_outlined,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF57C00),
                    label: "Send Feedback",
                    sublabel: "Bug reports, ideas & suggestions",
                    type: _SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.feedback);
                    },
                  ),
                ],
              ),

              // About
              _SettingsGroup(
                title: "ABOUT",
                children: [
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF7B1FA2),
                    label: "About VoiceNotes AI",
                    sublabel: "App info, credits & support",
                    type: _SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.about);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    label: "Privacy & Data Policy",
                    sublabel: "How your data is handled",
                    type: _SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.privacyPolicy);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1565C0),
                    label: "Terms & Conditions",
                    sublabel: "Usage terms and legal info",
                    type: _SettingsType.chevron,
                    hasSublabel: true,
                    onTap: () {
                      context.push(AppRoutes.termsConditions);
                    },
                  ),
                ],
              ),

              // Danger Zone
              _SettingsGroup(
                title: "DANGER ZONE",
                titleColor: Theme.of(context).colorScheme.error,
                children: [
                  _DangerItem(
                    icon: Icons.delete_outline_rounded,
                    label: "Delete Whisper Model",
                    sublabel: "Free up ~140 MB of storage",
                    onTap: () => _confirmDeleteWhisperModel(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _DangerItem(
                    icon: Icons.graphic_eq_rounded,
                    label: "Delete Voice Recordings",
                    sublabel: "Remove all audio files, keep text",
                    onTap: () => _confirmDeleteRecordings(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _DangerItem(
                    icon: Icons.delete_forever_rounded,
                    label: "Delete All Data",
                    sublabel: "Remove everything permanently",
                    isDestructive: true,
                    onTap: () => _confirmDeleteAllData(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteWhisperModel(BuildContext context) async {
    final isDownloaded = await WhisperService.instance.isModelDownloaded();
    if (!isDownloaded) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Whisper model to delete.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Whisper Model'),
        content: const Text(
          'This will delete the downloaded Whisper AI model (~140 MB). '
          'You will need to re-download it to use Record & Transcribe mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await WhisperService.instance.deleteModel();
      // Switch to live mode if currently using whisper
      final settings = ref.read(settingsProvider);
      if (settings.transcriptionMode == 'whisper') {
        ref.read(settingsProvider.notifier).setTranscriptionMode('live');
      }
      if (mounted) {
        setState(() {}); // Refresh storage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Whisper model deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteRecordings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Voice Recordings'),
        content: const Text(
          'This will permanently delete all audio recording files. '
          'Your text notes and transcriptions will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Recordings'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await HiveService.deleteAllRecordings();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All voice recordings deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAllData(BuildContext context) async {
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
                foregroundColor: Theme.of(context).colorScheme.error,
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

  String _truncateValue(String value) {
    if (value.length <= 6) return value;
    return '${value.substring(0, 6)}..';
  }

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
                          fontSize: 11,
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
            Text(
              _truncateValue(valueText ?? ""),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
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

/// Danger zone item with alarming red/orange tint.
class _DangerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DangerItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: isDestructive ? const Color(0x22FF5722) : const Color(0x10FF5722),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
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
                  Text(
                    sublabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Storage breakdown section showing Whisper model, recordings, and text data sizes.
class _StorageBreakdownSection extends StatefulWidget {
  final int noteCount;
  final int folderCount;

  const _StorageBreakdownSection({
    required this.noteCount,
    required this.folderCount,
  });

  @override
  State<_StorageBreakdownSection> createState() =>
      _StorageBreakdownSectionState();
}

class _StorageBreakdownSectionState extends State<_StorageBreakdownSection> {
  Map<String, int>? _breakdown;
  int _whisperBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    final breakdown = await HiveService.getStorageBreakdown();
    final whisperSize = await WhisperService.instance.getModelSizeBytes();
    if (mounted) {
      setState(() {
        _breakdown = breakdown;
        _whisperBytes = whisperSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (_breakdown?['total'] ?? 0) + _whisperBytes;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Local Storage",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                "${widget.noteCount} notes · ${widget.folderCount} folders",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total
          _StorageRow(
            icon: Icons.storage_rounded,
            color: theme.colorScheme.primary,
            label: 'Total',
            size: HiveService.formatBytes(total),
          ),
          const SizedBox(height: 10),
          // Whisper Model
          _StorageRow(
            icon: Icons.downloading_rounded,
            color: const Color(0xFFE65100),
            label: 'Whisper Model',
            size: _whisperBytes > 0
                ? HiveService.formatBytes(_whisperBytes)
                : 'Not installed',
          ),
          const SizedBox(height: 10),
          // Voice Recordings
          _StorageRow(
            icon: Icons.graphic_eq_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Voice Recordings',
            size: HiveService.formatBytes(_breakdown?['recordings'] ?? 0),
          ),
          const SizedBox(height: 10),
          // Text & Database
          _StorageRow(
            icon: Icons.text_snippet_rounded,
            color: const Color(0xFF1565C0),
            label: 'Notes & Database',
            size: HiveService.formatBytes(_breakdown?['hive'] ?? 0),
          ),
          if ((_breakdown?['images'] ?? 0) > 0) ...[
            const SizedBox(height: 10),
            _StorageRow(
              icon: Icons.image_rounded,
              color: const Color(0xFF7B1FA2),
              label: 'Images',
              size: HiveService.formatBytes(_breakdown?['images'] ?? 0),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: theme.hintColor, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "All data is stored locally on this device.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String size;

  const _StorageRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Text(
          size,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
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
              Text('Download couldn\'t be completed. Tap on Whisper Model to try again.'),
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
        width: 100,
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
      sublabel = 'Downloading...';
    } else if (_isDownloaded) {
      trailing = const Icon(
        Icons.check_circle_rounded,
        color: Color(0xFF2E7D32),
        size: 22,
      );
      sublabel = 'Ready to use';
    } else {
      trailing = IconButton(
        onPressed: _startDownload,
        icon: const Icon(Icons.download_rounded),
        color: theme.colorScheme.primary,
        tooltip: 'Download (~140 MB)',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
      sublabel = 'Not downloaded (~140 MB)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Center(
              child: Icon(
                Icons.downloading_rounded,
                color: Color(0xFFE65100),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Whisper Model',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  sublabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontSize: 11,
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

