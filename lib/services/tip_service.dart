import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

/// IDs for contextual first-time tips.
class TipId {
  static const voiceTask = 'voice_task';
  static const projectReorder = 'project_reorder';
  static const searchFilter = 'search_filter';
  static const voiceOrganize = 'voice_organize';
  static const folderProject = 'folder_project';
}

/// Manages contextual first-time tips.
///
/// Checks `UserSettings.dismissedTips` to decide whether to show a tip.
/// Dismissing a tip persists the ID so it never shows again.
class TipService {
  /// Returns true if the tip with [tipId] should be shown.
  static bool shouldShow(WidgetRef ref, String tipId) {
    final settings = ref.read(settingsProvider);
    return !settings.dismissedTips.contains(tipId);
  }

  /// Dismiss a tip permanently.
  static Future<void> dismiss(WidgetRef ref, String tipId) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    if (!settings.dismissedTips.contains(tipId)) {
      settings.dismissedTips = [...settings.dismissedTips, tipId];
      await repo.saveSettings(settings);
    }
  }
}
