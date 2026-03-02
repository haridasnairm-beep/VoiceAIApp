import 'package:home_widget/home_widget.dart';
import 'hive_service.dart';
import '../models/note.dart';

/// Service for updating the home screen widget with current app data.
///
/// Uses the `home_widget` package to push data to the Android widget.
/// Widget display is privacy-aware: content shown adapts based on
/// [appLockEnabled] and [widgetPrivacyLevel] settings.
class HomeWidgetService {
  // Android widget class names (qualified)
  static const String _androidSmall =
      'com.hariappbuilders.voicenotesai.VoiceNotesWidgetSmall';
  static const String _androidDashboard =
      'com.hariappbuilders.voicenotesai.VoiceNotesWidgetDashboard';

  // iOS app group for shared data (requires Xcode configuration)
  static const String _iosAppGroup =
      'group.com.hariappbuilders.voicenotesai';

  /// Initialize the widget service. Call once on app startup.
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_iosAppGroup);
    } catch (_) {
      // App group not configured (iOS requires Xcode setup) — safe to ignore
    }
  }

  /// Push current note/task data to the home screen widget.
  ///
  /// [appLockEnabled] and [widgetPrivacyLevel] control what is displayed:
  /// - App Lock OFF → full display (counts + preview)
  /// - App Lock ON + 'full' → show everything (user accepted tradeoff)
  /// - App Lock ON + 'record_only' → counts only, no preview text (default)
  /// - App Lock ON + 'minimal' → no data (icon + Tap to Record only)
  static Future<void> updateWidgetData({
    required bool appLockEnabled,
    required String widgetPrivacyLevel,
  }) async {
    try {
      final notes = HiveService.notesBox.values
          .where((n) => !n.isDeleted)
          .toList();

      final noteCount = notes.length;

      // Count open tasks across all active notes
      int openTaskCount = 0;
      for (final note in notes) {
        openTaskCount += note.todos.where((t) => !t.isCompleted).length;
        openTaskCount += note.actions.where((a) => !a.isCompleted).length;
      }

      // Get latest note title for preview
      String latestNoteTitle = '';
      if (notes.isNotEmpty) {
        final sorted = List<Note>.from(notes)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = sorted.first;
        latestNoteTitle = latest.title.isNotEmpty
            ? latest.title
            : latest.rawTranscription;
        if (latestNoteTitle.length > 60) {
          latestNoteTitle = '${latestNoteTitle.substring(0, 60)}…';
        }
      }

      // Apply privacy level to determine what data to send to widget
      String displayNoteCount = noteCount.toString();
      String displayTaskCount = openTaskCount.toString();
      String displayPreview = '';
      bool showCounts = true;

      if (!appLockEnabled || widgetPrivacyLevel == 'full') {
        // Full display: counts + preview
        displayPreview = latestNoteTitle;
      } else if (widgetPrivacyLevel == 'record_only') {
        // Counts only — no text preview (default when App Lock on)
        displayPreview = '';
      } else {
        // 'minimal' — no data at all; widget shows only icon + "Tap to Record"
        displayNoteCount = '';
        displayTaskCount = '';
        displayPreview = '';
        showCounts = false;
      }

      await Future.wait([
        HomeWidget.saveWidgetData<String>('note_count', displayNoteCount),
        HomeWidget.saveWidgetData<String>('task_count', displayTaskCount),
        HomeWidget.saveWidgetData<String>('latest_note', displayPreview),
        HomeWidget.saveWidgetData<bool>('show_counts', showCounts),
        HomeWidget.saveWidgetData<bool>(
          'show_preview',
          displayPreview.isNotEmpty,
        ),
      ]);

      // Trigger both widget variants to refresh
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidSmall);
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidDashboard);
    } catch (_) {
      // Widget update is non-critical — silently ignore errors
    }
  }
}
