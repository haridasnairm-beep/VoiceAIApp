import '../models/user_settings.dart';
import 'hive_service.dart';

/// Repository for UserSettings operations against Hive.
class SettingsRepository {
  static const String _settingsKey = 'user_settings';

  /// Get current settings, or create defaults if none exist.
  UserSettings getSettings() {
    final settings = HiveService.settingsBox.get(_settingsKey);
    if (settings != null) return settings;

    // Create default settings
    final defaults = UserSettings();
    HiveService.settingsBox.put(_settingsKey, defaults);
    return defaults;
  }

  /// Save settings.
  Future<void> saveSettings(UserSettings settings) async {
    await HiveService.settingsBox.put(_settingsKey, settings);
  }

  /// Update a single setting field.
  Future<void> setDefaultLanguage(String? language) async {
    final settings = getSettings();
    settings.defaultLanguage = language;
    await saveSettings(settings);
  }

  Future<void> setAudioQuality(String quality) async {
    final settings = getSettings();
    settings.audioQuality = quality;
    await saveSettings(settings);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = getSettings();
    settings.notificationsEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setThemeMode(String mode) async {
    final settings = getSettings();
    settings.themeMode = mode;
    await saveSettings(settings);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final settings = getSettings();
    settings.onboardingCompleted = completed;
    await saveSettings(settings);
  }

  Future<void> setTranscriptionMode(String mode) async {
    final settings = getSettings();
    settings.transcriptionMode = mode;
    await saveSettings(settings);
  }

  Future<void> setSpeakerName(String name) async {
    final settings = getSettings();
    settings.speakerName = name;
    await saveSettings(settings);
  }

  Future<void> setNotePrefix(String prefix) async {
    final settings = getSettings();
    settings.notePrefix = prefix;
    await saveSettings(settings);
  }

  Future<void> setDefaultFolderId(String? folderId) async {
    final settings = getSettings();
    settings.defaultFolderId = folderId;
    await saveSettings(settings);
  }

  Future<void> setVoiceCommandsEnabled(bool enabled) async {
    final settings = getSettings();
    settings.voiceCommandsEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setTextNotePrefix(String prefix) async {
    final settings = getSettings();
    settings.textNotePrefix = prefix;
    await saveSettings(settings);
  }

  Future<void> setActionItemsEnabled(bool enabled) async {
    final settings = getSettings();
    settings.actionItemsEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setTodosEnabled(bool enabled) async {
    final settings = getSettings();
    settings.todosEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setWhisperModel(String model) async {
    final settings = getSettings();
    settings.whisperModel = model;
    await saveSettings(settings);
  }

  Future<void> setNoteOutputMode(String mode) async {
    final settings = getSettings();
    settings.noteOutputMode = mode;
    await saveSettings(settings);
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    final settings = getSettings();
    settings.keepScreenAwake = enabled;
    await saveSettings(settings);
  }

  Future<void> setBlockOffensiveWords(bool enabled) async {
    final settings = getSettings();
    settings.blockOffensiveWords = enabled;
    await saveSettings(settings);
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    final settings = getSettings();
    settings.appLockEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setAppLockPinHash(String? hash) async {
    final settings = getSettings();
    settings.appLockPinHash = hash;
    await saveSettings(settings);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final settings = getSettings();
    settings.biometricEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    final settings = getSettings();
    settings.autoLockTimeoutSeconds = seconds;
    await saveSettings(settings);
  }

  Future<void> setWidgetPrivacyLevel(String level) async {
    final settings = getSettings();
    settings.widgetPrivacyLevel = level;
    await saveSettings(settings);
  }

  Future<void> setLastBackupDate(DateTime? date) async {
    final settings = getSettings();
    settings.lastBackupDate = date;
    await saveSettings(settings);
  }

  Future<void> setSoundCuesEnabled(bool enabled) async {
    final settings = getSettings();
    settings.soundCuesEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setGuidedRecordingCompleted(bool completed) async {
    final settings = getSettings();
    settings.guidedRecordingCompleted = completed;
    await saveSettings(settings);
  }

  Future<void> setCrashReportingEnabled(bool enabled) async {
    final settings = getSettings();
    settings.crashReportingEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setPermissionScreenShown(bool shown) async {
    final settings = getSettings();
    settings.permissionScreenShown = shown;
    await saveSettings(settings);
  }

  Future<void> setFabSwipeHintShownCount(int count) async {
    final settings = getSettings();
    settings.fabSwipeHintShownCount = count;
    await saveSettings(settings);
  }

  Future<void> setNoteNamingStyle(String style) async {
    final settings = getSettings();
    settings.noteNamingStyle = style;
    await saveSettings(settings);
  }

  Future<void> incrementSessionCount() async {
    final settings = getSettings();
    settings.sessionCount += 1;
    await saveSettings(settings);
  }

  Future<void> setWhisperReadyShown(bool shown) async {
    final settings = getSettings();
    settings.whisperReadyShown = shown;
    await saveSettings(settings);
  }

  Future<int> incrementVoiceNoteCounter() async {
    final settings = getSettings();
    settings.voiceNoteCounter += 1;
    await saveSettings(settings);
    return settings.voiceNoteCounter;
  }

  Future<int> incrementTextNoteCounter() async {
    final settings = getSettings();
    settings.textNoteCounter += 1;
    await saveSettings(settings);
    return settings.textNoteCounter;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final settings = getSettings();
    settings.autoBackupEnabled = enabled;
    await saveSettings(settings);
  }

  Future<void> setAutoBackupFrequency(String frequency) async {
    final settings = getSettings();
    settings.autoBackupFrequency = frequency;
    await saveSettings(settings);
  }

  Future<void> setAutoBackupMaxCount(int count) async {
    final settings = getSettings();
    settings.autoBackupMaxCount = count;
    await saveSettings(settings);
  }

  Future<void> setAutoBackupLastRun(DateTime? date) async {
    final settings = getSettings();
    settings.autoBackupLastRun = date;
    await saveSettings(settings);
  }
}
