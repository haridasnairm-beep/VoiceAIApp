import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User settings state.
/// Will be persisted to Hive in Step 3.
class SettingsState {
  final String? defaultLanguage; // null = auto-detect
  final String audioQuality; // 'standard' or 'high'
  final bool notificationsEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final ThemeMode themeMode;

  const SettingsState({
    this.defaultLanguage,
    this.audioQuality = 'standard',
    this.notificationsEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    String? Function()? defaultLanguage,
    String? audioQuality,
    bool? notificationsEnabled,
    TimeOfDay? Function()? quietHoursStart,
    TimeOfDay? Function()? quietHoursEnd,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      defaultLanguage:
          defaultLanguage != null ? defaultLanguage() : this.defaultLanguage,
      audioQuality: audioQuality ?? this.audioQuality,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      quietHoursStart:
          quietHoursStart != null ? quietHoursStart() : this.quietHoursStart,
      quietHoursEnd:
          quietHoursEnd != null ? quietHoursEnd() : this.quietHoursEnd,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

/// Notifier for user settings.
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setDefaultLanguage(String? language) {
    state = state.copyWith(defaultLanguage: () => language);
  }

  void setAudioQuality(String quality) {
    state = state.copyWith(audioQuality: quality);
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setQuietHours(TimeOfDay? start, TimeOfDay? end) {
    state = state.copyWith(
      quietHoursStart: () => start,
      quietHoursEnd: () => end,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }
}

/// Provider for user settings.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
