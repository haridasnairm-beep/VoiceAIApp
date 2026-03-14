import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings.dart';
import '../services/home_widget_service.dart';
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
  final bool isAmoled; // True when user selected AMOLED dark theme
  final bool appLockEnabled;
  final bool biometricEnabled;
  final int autoLockTimeoutSeconds;
  final String widgetPrivacyLevel; // 'full', 'record_only', 'minimal'
  final DateTime? lastBackupDate;
  final bool soundCuesEnabled; // Play subtle beep on recording start/stop
  final bool guidedRecordingCompleted; // First-recording coaching done
  final bool crashReportingEnabled; // Opt-in anonymous crash reporting
  final List<String> dismissedTips; // Contextual tip IDs dismissed by user
  final String? lastSeenAppVersion; // For What's New screen
  final String noteSortOrder; // newest, oldest, titleAZ, titleZA, longest
  final bool permissionScreenShown;
  final int fabSwipeHintShownCount; // Idle hint shown count (max 2)
  final int sessionCount; // Incremented on each app launch
  final String noteNamingStyle; // 'prefix_only', 'prefix_auto', 'auto_only'
  final int voiceNoteCounter; // Persistent auto-increment for voice notes
  final int textNoteCounter; // Persistent auto-increment for text notes
  final bool whisperReadyShown; // Post-download ready splash shown once
  final bool autoBackupEnabled; // Auto-backup toggle
  final String autoBackupFrequency; // 'daily', 'every3days', 'weekly'
  final int autoBackupMaxCount; // Max auto-backup files to keep
  final DateTime? autoBackupLastRun; // Last auto-backup timestamp
  final int currentTipIndex; // Home tip tile current index
  final bool tipTileDismissed; // Home tip tile dismissed
  final int failedPinAttempts; // Persistent failed PIN attempts
  final DateTime? pinLockoutUntil; // Persistent lockout deadline
  final int pinLength; // PIN digit count (4-6) for auto-verify
  final DateTime? firstLaunchDate; // When the app was first launched
  final int reviewPromptCount; // Times review prompt shown (max 2)
  final DateTime? lastReviewPromptDate; // When review was last prompted
  final int noteCountAtLastReviewPrompt; // Note count at last prompt
  final DateTime? lastUpdateCheckDate; // When update check was last run
  final String? dismissedUpdateVersion; // Version user dismissed

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
    this.isAmoled = false,
    this.appLockEnabled = false,
    this.biometricEnabled = false,
    this.autoLockTimeoutSeconds = 0,
    this.widgetPrivacyLevel = 'record_only',
    this.lastBackupDate,
    this.soundCuesEnabled = true,
    this.guidedRecordingCompleted = false,
    this.crashReportingEnabled = false,
    this.dismissedTips = const [],
    this.lastSeenAppVersion,
    this.noteSortOrder = 'newest',
    this.permissionScreenShown = false,
    this.fabSwipeHintShownCount = 0,
    this.sessionCount = 0,
    this.noteNamingStyle = 'prefix_auto',
    this.voiceNoteCounter = 0,
    this.textNoteCounter = 0,
    this.whisperReadyShown = false,
    this.autoBackupEnabled = false,
    this.autoBackupFrequency = 'weekly',
    this.autoBackupMaxCount = 5,
    this.autoBackupLastRun,
    this.currentTipIndex = 0,
    this.tipTileDismissed = false,
    this.failedPinAttempts = 0,
    this.pinLockoutUntil,
    this.pinLength = 4,
    this.firstLaunchDate,
    this.reviewPromptCount = 0,
    this.lastReviewPromptDate,
    this.noteCountAtLastReviewPrompt = 0,
    this.lastUpdateCheckDate,
    this.dismissedUpdateVersion,
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
    bool? isAmoled,
    bool? appLockEnabled,
    bool? biometricEnabled,
    int? autoLockTimeoutSeconds,
    String? widgetPrivacyLevel,
    DateTime? Function()? lastBackupDate,
    bool? soundCuesEnabled,
    bool? guidedRecordingCompleted,
    bool? crashReportingEnabled,
    List<String>? dismissedTips,
    String? Function()? lastSeenAppVersion,
    String? noteSortOrder,
    bool? permissionScreenShown,
    int? fabSwipeHintShownCount,
    int? sessionCount,
    String? noteNamingStyle,
    int? voiceNoteCounter,
    int? textNoteCounter,
    bool? whisperReadyShown,
    bool? autoBackupEnabled,
    String? autoBackupFrequency,
    int? autoBackupMaxCount,
    DateTime? Function()? autoBackupLastRun,
    int? currentTipIndex,
    bool? tipTileDismissed,
    int? failedPinAttempts,
    DateTime? Function()? pinLockoutUntil,
    int? pinLength,
    DateTime? Function()? firstLaunchDate,
    int? reviewPromptCount,
    DateTime? Function()? lastReviewPromptDate,
    int? noteCountAtLastReviewPrompt,
    DateTime? Function()? lastUpdateCheckDate,
    String? Function()? dismissedUpdateVersion,
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
      isAmoled: isAmoled ?? this.isAmoled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockTimeoutSeconds: autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      widgetPrivacyLevel: widgetPrivacyLevel ?? this.widgetPrivacyLevel,
      lastBackupDate: lastBackupDate != null ? lastBackupDate() : this.lastBackupDate,
      soundCuesEnabled: soundCuesEnabled ?? this.soundCuesEnabled,
      guidedRecordingCompleted: guidedRecordingCompleted ?? this.guidedRecordingCompleted,
      crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
      dismissedTips: dismissedTips ?? this.dismissedTips,
      lastSeenAppVersion: lastSeenAppVersion != null ? lastSeenAppVersion() : this.lastSeenAppVersion,
      noteSortOrder: noteSortOrder ?? this.noteSortOrder,
      permissionScreenShown: permissionScreenShown ?? this.permissionScreenShown,
      fabSwipeHintShownCount: fabSwipeHintShownCount ?? this.fabSwipeHintShownCount,
      sessionCount: sessionCount ?? this.sessionCount,
      noteNamingStyle: noteNamingStyle ?? this.noteNamingStyle,
      voiceNoteCounter: voiceNoteCounter ?? this.voiceNoteCounter,
      textNoteCounter: textNoteCounter ?? this.textNoteCounter,
      whisperReadyShown: whisperReadyShown ?? this.whisperReadyShown,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      autoBackupMaxCount: autoBackupMaxCount ?? this.autoBackupMaxCount,
      autoBackupLastRun: autoBackupLastRun != null ? autoBackupLastRun() : this.autoBackupLastRun,
      currentTipIndex: currentTipIndex ?? this.currentTipIndex,
      tipTileDismissed: tipTileDismissed ?? this.tipTileDismissed,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      pinLockoutUntil: pinLockoutUntil != null ? pinLockoutUntil() : this.pinLockoutUntil,
      pinLength: pinLength ?? this.pinLength,
      firstLaunchDate: firstLaunchDate != null ? firstLaunchDate() : this.firstLaunchDate,
      reviewPromptCount: reviewPromptCount ?? this.reviewPromptCount,
      lastReviewPromptDate: lastReviewPromptDate != null ? lastReviewPromptDate() : this.lastReviewPromptDate,
      noteCountAtLastReviewPrompt: noteCountAtLastReviewPrompt ?? this.noteCountAtLastReviewPrompt,
      lastUpdateCheckDate: lastUpdateCheckDate != null ? lastUpdateCheckDate() : this.lastUpdateCheckDate,
      dismissedUpdateVersion: dismissedUpdateVersion != null ? dismissedUpdateVersion() : this.dismissedUpdateVersion,
    );
  }

  static ThemeMode parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'amoled':
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
      isAmoled: settings.themeMode == 'amoled',
      appLockEnabled: settings.appLockEnabled,
      biometricEnabled: settings.biometricEnabled,
      autoLockTimeoutSeconds: settings.autoLockTimeoutSeconds,
      widgetPrivacyLevel: settings.widgetPrivacyLevel,
      lastBackupDate: settings.lastBackupDate,
      soundCuesEnabled: settings.soundCuesEnabled,
      guidedRecordingCompleted: settings.guidedRecordingCompleted,
      crashReportingEnabled: settings.crashReportingEnabled,
      dismissedTips: settings.dismissedTips,
      lastSeenAppVersion: settings.lastSeenAppVersion,
      noteSortOrder: settings.noteSortOrder,
      permissionScreenShown: settings.permissionScreenShown,
      fabSwipeHintShownCount: settings.fabSwipeHintShownCount,
      sessionCount: settings.sessionCount,
      noteNamingStyle: settings.noteNamingStyle,
      voiceNoteCounter: settings.voiceNoteCounter,
      textNoteCounter: settings.textNoteCounter,
      whisperReadyShown: settings.whisperReadyShown,
      autoBackupEnabled: settings.autoBackupEnabled,
      autoBackupFrequency: settings.autoBackupFrequency,
      autoBackupMaxCount: settings.autoBackupMaxCount,
      autoBackupLastRun: settings.autoBackupLastRun,
      currentTipIndex: settings.currentTipIndex,
      tipTileDismissed: settings.tipTileDismissed,
      failedPinAttempts: settings.failedPinAttempts,
      pinLockoutUntil: settings.pinLockoutUntil,
      pinLength: settings.pinLength,
      firstLaunchDate: _ensureFirstLaunchDate(settings),
      reviewPromptCount: settings.reviewPromptCount,
      lastReviewPromptDate: settings.lastReviewPromptDate,
      noteCountAtLastReviewPrompt: settings.noteCountAtLastReviewPrompt,
      lastUpdateCheckDate: settings.lastUpdateCheckDate,
      dismissedUpdateVersion: settings.dismissedUpdateVersion,
    );
  }

  /// Sets firstLaunchDate on first launch and returns it.
  DateTime _ensureFirstLaunchDate(UserSettings settings) {
    if (settings.firstLaunchDate != null) return settings.firstLaunchDate!;
    final now = DateTime.now();
    settings.firstLaunchDate = now;
    settings.save();
    return now;
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

  Future<void> setThemeMode(ThemeMode mode, {bool amoled = false}) async {
    final modeString = amoled ? 'amoled' : SettingsState.themeModeToString(mode);
    await ref.read(settingsRepositoryProvider).setThemeMode(modeString);
    state = state.copyWith(themeMode: mode, isAmoled: amoled);
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

  Future<void> setAppLockEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setAppLockEnabled(enabled);
    state = state.copyWith(appLockEnabled: enabled);
    // Refresh widget to reflect lock state change
    HomeWidgetService.updateWidgetData(
      appLockEnabled: enabled,
      widgetPrivacyLevel: state.widgetPrivacyLevel,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setBiometricEnabled(enabled);
    state = state.copyWith(biometricEnabled: enabled);
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    await ref.read(settingsRepositoryProvider).setAutoLockTimeout(seconds);
    state = state.copyWith(autoLockTimeoutSeconds: seconds);
  }

  Future<void> setWidgetPrivacyLevel(String level) async {
    await ref.read(settingsRepositoryProvider).setWidgetPrivacyLevel(level);
    state = state.copyWith(widgetPrivacyLevel: level);
    // Immediately push updated privacy level to home screen widgets
    HomeWidgetService.updateWidgetData(
      appLockEnabled: state.appLockEnabled,
      widgetPrivacyLevel: level,
    );
  }

  Future<void> setLastBackupDate(DateTime? date) async {
    await ref.read(settingsRepositoryProvider).setLastBackupDate(date);
    state = state.copyWith(lastBackupDate: () => date);
  }

  Future<void> setSoundCuesEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setSoundCuesEnabled(enabled);
    state = state.copyWith(soundCuesEnabled: enabled);
  }

  Future<void> setGuidedRecordingCompleted(bool completed) async {
    await ref.read(settingsRepositoryProvider).setGuidedRecordingCompleted(completed);
    state = state.copyWith(guidedRecordingCompleted: completed);
  }

  Future<void> setCrashReportingEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setCrashReportingEnabled(enabled);
    state = state.copyWith(crashReportingEnabled: enabled);
  }

  Future<void> setPermissionScreenShown(bool shown) async {
    await ref.read(settingsRepositoryProvider).setPermissionScreenShown(shown);
    state = state.copyWith(permissionScreenShown: shown);
  }

  Future<void> setNoteSortOrder(String order) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.noteSortOrder = order;
    await repo.saveSettings(settings);
    state = state.copyWith(noteSortOrder: order);
  }

  Future<void> setFabSwipeHintShownCount(int count) async {
    await ref.read(settingsRepositoryProvider).setFabSwipeHintShownCount(count);
    state = state.copyWith(fabSwipeHintShownCount: count);
  }

  Future<void> setNoteNamingStyle(String style) async {
    await ref.read(settingsRepositoryProvider).setNoteNamingStyle(style);
    state = state.copyWith(noteNamingStyle: style);
  }

  Future<void> incrementSessionCount() async {
    await ref.read(settingsRepositoryProvider).incrementSessionCount();
    state = state.copyWith(sessionCount: state.sessionCount + 1);
  }

  Future<void> setWhisperReadyShown(bool shown) async {
    await ref.read(settingsRepositoryProvider).setWhisperReadyShown(shown);
    state = state.copyWith(whisperReadyShown: shown);
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setAutoBackupEnabled(enabled);
    state = state.copyWith(autoBackupEnabled: enabled);
  }

  Future<void> setAutoBackupFrequency(String frequency) async {
    await ref.read(settingsRepositoryProvider).setAutoBackupFrequency(frequency);
    state = state.copyWith(autoBackupFrequency: frequency);
  }

  Future<void> setAutoBackupMaxCount(int count) async {
    await ref.read(settingsRepositoryProvider).setAutoBackupMaxCount(count);
    state = state.copyWith(autoBackupMaxCount: count);
  }

  Future<void> setAutoBackupLastRun(DateTime? date) async {
    await ref.read(settingsRepositoryProvider).setAutoBackupLastRun(date);
    state = state.copyWith(autoBackupLastRun: () => date);
  }

  Future<void> setCurrentTipIndex(int index) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.currentTipIndex = index;
    await repo.saveSettings(settings);
    state = state.copyWith(currentTipIndex: index);
  }

  Future<void> setTipTileDismissed(bool dismissed) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.tipTileDismissed = dismissed;
    if (!dismissed) settings.currentTipIndex = 0;
    await repo.saveSettings(settings);
    state = state.copyWith(
      tipTileDismissed: dismissed,
      currentTipIndex: dismissed ? state.currentTipIndex : 0,
    );
  }

  Future<void> setFailedPinAttempts(int count) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.failedPinAttempts = count;
    await repo.saveSettings(settings);
    state = state.copyWith(failedPinAttempts: count);
  }

  Future<void> setPinLength(int length) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.pinLength = length;
    await repo.saveSettings(settings);
    state = state.copyWith(pinLength: length);
  }

  Future<void> setPinLockoutUntil(DateTime? deadline) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.pinLockoutUntil = deadline;
    await repo.saveSettings(settings);
    state = state.copyWith(pinLockoutUntil: () => deadline);
  }

  /// Record that the review prompt was shown. Increments count and stores current note count.
  Future<void> recordReviewPrompt(int currentNoteCount) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.reviewPromptCount = state.reviewPromptCount + 1;
    settings.lastReviewPromptDate = DateTime.now();
    settings.noteCountAtLastReviewPrompt = currentNoteCount;
    await repo.saveSettings(settings);
    state = state.copyWith(
      reviewPromptCount: settings.reviewPromptCount,
      lastReviewPromptDate: () => settings.lastReviewPromptDate,
      noteCountAtLastReviewPrompt: currentNoteCount,
    );
  }

  Future<void> setLastUpdateCheckDate(DateTime date) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.lastUpdateCheckDate = date;
    await repo.saveSettings(settings);
    state = state.copyWith(lastUpdateCheckDate: () => date);
  }

  Future<void> setDismissedUpdateVersion(String? version) async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = repo.getSettings();
    settings.dismissedUpdateVersion = version;
    await repo.saveSettings(settings);
    state = state.copyWith(dismissedUpdateVersion: () => version);
  }

  /// Increment voice note counter and return the new value.
  Future<int> incrementVoiceNoteCounter() async {
    final repo = ref.read(settingsRepositoryProvider);
    final newVal = await repo.incrementVoiceNoteCounter();
    state = state.copyWith(voiceNoteCounter: newVal);
    return newVal;
  }

  /// Increment text note counter and return the new value.
  Future<int> incrementTextNoteCounter() async {
    final repo = ref.read(settingsRepositoryProvider);
    final newVal = await repo.incrementTextNoteCounter();
    state = state.copyWith(textNoteCounter: newVal);
    return newVal;
  }
}

/// Provider for user settings.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
