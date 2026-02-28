import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../providers/settings_provider.dart';
import '../services/hive_service.dart';
import '../services/whisper_service.dart';
import '../widgets/settings_widgets.dart';

class DangerZonePage extends ConsumerStatefulWidget {
  const DangerZonePage({super.key});

  @override
  ConsumerState<DangerZonePage> createState() => _DangerZonePageState();
}

class _DangerZonePageState extends ConsumerState<DangerZonePage> {
  Future<void> _confirmDeleteWhisperModel() async {
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
      final settings = ref.read(settingsProvider);
      if (settings.transcriptionMode == 'whisper') {
        ref.read(settingsProvider.notifier).setTranscriptionMode('live');
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Whisper model deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteRecordings() async {
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

  Future<void> _confirmDeleteAllData() async {
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

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Danger Zone'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsGroup(
                title: "DANGER ZONE",
                titleColor: Theme.of(context).colorScheme.error,
                children: [
                  DangerItem(
                    icon: Icons.delete_outline_rounded,
                    label: "Delete Whisper Model",
                    sublabel: "Free up ~140 MB of storage",
                    onTap: _confirmDeleteWhisperModel,
                  ),
                  const Divider(height: 1, indent: 56),
                  DangerItem(
                    icon: Icons.graphic_eq_rounded,
                    label: "Delete Voice Recordings",
                    sublabel: "Remove all audio files, keep text",
                    onTap: _confirmDeleteRecordings,
                  ),
                  const Divider(height: 1, indent: 56),
                  DangerItem(
                    icon: Icons.delete_forever_rounded,
                    label: "Delete All Data",
                    sublabel: "Remove everything permanently",
                    isDestructive: true,
                    onTap: _confirmDeleteAllData,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
