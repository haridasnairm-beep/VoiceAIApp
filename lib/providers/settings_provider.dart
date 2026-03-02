import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/settings_repository.dart';

/// Provider for the SettingsRepository singleton.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// User settings state (derived from Hive UserSettings model).
class SettingsState {
  final String? defaultLanguage; // speaking language code ('en', 'hi', etc.)
  final String audioQuality; // 'standard' or 'high'
  final bool notificationsEnabled;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final ThemeMode themeMode;
  final bool onboardingCompleted;
  final String transcriptionMode; // 'live' or 'whisper'
  final String speakerName; // User's display name for transcription timestamps
  final String notePrefix; // Prefix for auto-generated note names
  final String? defaultFolderId; // ID of the default folder for new recordings
  final bool voiceCommandsEnabled; // Parse voice commands in whisper mode
  final String textNotePrefix; // Prefix for auto-generated text note names
  final bool actionItemsEnabled; // Show action items section in note detail
  final bool todosEnabled; // Show todos section in note detail
  final String whisperModel; // 'base', 'small', 'medium'
  final String noteOutputMode; // 'english' or 'native'
  final bool keepScreenAwake; // Keep screen on during recording
  final bool blockOffensiveWords; // Filter offensive words from transcription

  const SettingsState({
    this.defaultLanguage = 'en',
    this.audioQuality = 'standard',
    this.notificationsEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.themeMode = ThemeMode.system,
    this.onboardingCompleted = false,
    this.transcriptionMode = 'whisper',
    this.speakerName = 'Speaker 1',
    this.notePrefix = 'VOICE',
    this.defaultFolderId,
    this.voiceCommandsEnabled = true,
    this.textNotePrefix = 'TXT',
    this.actionItemsEnabled = true,
    this.todosEnabled = true,
    this.whisperModel = 'base',
    this.noteOutputMode = 'english',
    this.keepScreenAwake = true,
    this.blockOffensiveWords = false,
  });

  SettingsState copyWith({
    String? Function()? defaultLanguage,
    String? audioQuality,
    bool? notificationsEnabled,
    TimeOfDay? Function()? quietHoursStart,
    TimeOfDay? Function()? quietHoursEnd,
    ThemeMode? themeMode,
    bool? onboardingCompleted,
    String? transcriptionMode,
    String? speakerName,
    String? notePrefix,
    String? Function()? defaultFolderId,
    bool? voiceCommandsEnabled,
    String? textNotePrefix,
    bool? actionItemsEnabled,
    bool? todosEnabled,
    String? whisperModel,
    String? noteOutputMode,
    bool? keepScreenAwake,
    bool? blockOffensiveWords,
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
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      transcriptionMode: transcriptionMode ?? this.transcriptionMode,
      speakerName: speakerName ?? this.speakerName,
      notePrefix: notePrefix ?? this.notePrefix,
      defaultFolderId: defaultFolderId != null ? defaultFolderId() : this.defaultFolderId,
      voiceCommandsEnabled: voiceCommandsEnabled ?? this.voiceCommandsEnabled,
      textNotePrefix: textNotePrefix ?? this.textNotePrefix,
      actionItemsEnabled: actionItemsEnabled ?? this.actionItemsEnabled,
      todosEnabled: todosEnabled ?? this.todosEnabled,
      whisperModel: whisperModel ?? this.whisperModel,
      noteOutputMode: noteOutputMode ?? this.noteOutputMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      blockOffensiveWords: blockOffensiveWords ?? this.blockOffensiveWords,
    );
  }

  static ThemeMode parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Notifier for user settings, backed by Hive.
class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();

    TimeOfDay? quietStart;
    if (settings.quietHoursStartMinutes != null) {
      quietStart = TimeOfDay(
        hour: settings.quietHoursStartMinutes! ~/ 60,
        minute: settings.quietHoursStartMinutes! % 60,
      );
    }
    TimeOfDay? quietEnd;
    if (settings.quietHoursEndMinutes != null) {
      quietEnd = TimeOfDay(
        hour: settings.quietHoursEndMinutes! ~/ 60,
        minute: settings.quietHoursEndMinutes! % 60,
      );
    }

    return SettingsState(
      defaultLanguage: settings.defaultLanguage ?? 'en',
      audioQuality: settings.audioQuality,
      notificationsEnabled: settings.notificationsEnabled,
      quietHoursStart: quietStart,
      quietHoursEnd: quietEnd,
      themeMode: SettingsState.parseThemeMode(settings.themeMode),
      onboardingCompleted: settings.onboardingCompleted,
      transcriptionMode: settings.transcriptionMode,
      speakerName: settings.speakerName,
      notePrefix: settings.notePrefix,
      defaultFolderId: settings.defaultFolderId,
      voiceCommandsEnabled: settings.voiceCommandsEnabled,
      textNotePrefix: settings.textNotePrefix,
      actionItemsEnabled: settings.actionItemsEnabled,
      todosEnabled: settings.todosEnabled,
      whisperModel: settings.whisperModel,
      noteOutputMode: settings.noteOutputMode,
      keepScreenAwake: settings.keepScreenAwake,
      blockOffensiveWords: settings.blockOffensiveWords,
    );
  }

  Future<void> setDefaultLanguage(String? language) async {
    await ref.read(settingsRepositoryProvider).setDefaultLanguage(language);
    state = state.copyWith(defaultLanguage: () => language);
  }

  Future<void> setAudioQuality(String quality) async {
    await ref.read(settingsRepositoryProvider).setAudioQuality(quality);
    state = state.copyWith(audioQuality: quality);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
    if (!enabled) {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> setQuietHours(TimeOfDay? start, TimeOfDay? end) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.quietHoursStartMinutes =
        start != null ? start.hour * 60 + start.minute : null;
    settings.quietHoursEndMinutes =
        end != null ? end.hour * 60 + end.minute : null;
    await repo.saveSettings(settings);
    state = state.copyWith(
      quietHoursStart: () => start,
      quietHoursEnd: () => end,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref
        .read(settingsRepositoryProvider)
        .setThemeMode(SettingsState.themeModeToString(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await ref
        .read(settingsRepositoryProvider)
        .setOnboardingCompleted(completed);
    state = state.copyWith(onboardingCompleted: completed);
  }

  Future<void> setTranscriptionMode(String mode) async {
    await ref.read(settingsRepositoryProvider).setTranscriptionMode(mode);
    state = state.copyWith(transcriptionMode: mode);
  }

  Future<void> setSpeakerName(String name) async {
    await ref.read(settingsRepositoryProvider).setSpeakerName(name);
    state = state.copyWith(speakerName: name);
  }

  Future<void> setNotePrefix(String prefix) async {
    await ref.read(settingsRepositoryProvider).setNotePrefix(prefix);
    state = state.copyWith(notePrefix: prefix);
  }

  Future<void> setDefaultFolderId(String? folderId) async {
    await ref.read(settingsRepositoryProvider).setDefaultFolderId(folderId);
    state = state.copyWith(defaultFolderId: () => folderId);
  }

  Future<void> setVoiceCommandsEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setVoiceCommandsEnabled(enabled);
    state = state.copyWith(voiceCommandsEnabled: enabled);
  }

  Future<void> setTextNotePrefix(String prefix) async {
    await ref.read(settingsRepositoryProvider).setTextNotePrefix(prefix);
    state = state.copyWith(textNotePrefix: prefix);
  }

  Future<void> setActionItemsEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setActionItemsEnabled(enabled);
    state = state.copyWith(actionItemsEnabled: enabled);
  }

  Future<void> setTodosEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setTodosEnabled(enabled);
    state = state.copyWith(todosEnabled: enabled);
  }

  Future<void> setWhisperModel(String model) async {
    await ref.read(settingsRepositoryProvider).setWhisperModel(model);
    state = state.copyWith(whisperModel: model);
  }

  Future<void> setNoteOutputMode(String mode) async {
    await ref.read(settingsRepositoryProvider).setNoteOutputMode(mode);
    state = state.copyWith(noteOutputMode: mode);
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setKeepScreenAwake(enabled);
    state = state.copyWith(keepScreenAwake: enabled);
  }

  Future<void> setBlockOffensiveWords(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setBlockOffensiveWords(enabled);
    state = state.copyWith(blockOffensiveWords: enabled);
  }
}

/// Provider for user settings.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
