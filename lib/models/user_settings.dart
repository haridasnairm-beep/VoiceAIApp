import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 5)
class UserSettings extends HiveObject {
  @HiveField(0)
  String? defaultLanguage; // speaking language code (e.g. 'en', 'hi') — null migrated to 'en'

  @HiveField(1)
  String audioQuality; // 'standard' or 'high'

  @HiveField(2)
  bool notificationsEnabled;

  @HiveField(3)
  int? quietHoursStartMinutes; // stored as minutes from midnight

  @HiveField(4)
  int? quietHoursEndMinutes; // stored as minutes from midnight

  @HiveField(5)
  String themeMode; // 'system', 'light', 'dark'

  @HiveField(6)
  bool onboardingCompleted;

  @HiveField(7)
  String transcriptionMode; // 'live' or 'whisper'

  @HiveField(8)
  String speakerName; // User's display name for transcription timestamps

  @HiveField(9)
  String notePrefix; // Prefix for auto-generated note names (e.g. "VOICE" → VOICE001)

  @HiveField(10)
  String? defaultFolderId; // ID of the default folder for new recordings

  @HiveField(11)
  bool voiceCommandsEnabled; // Parse "Folder/Project <name> Start" in whisper mode

  @HiveField(12)
  String textNotePrefix; // Prefix for auto-generated text note names (e.g. "TXT" → TXT001)

  @HiveField(13)
  bool actionItemsEnabled; // Show action items section in note detail

  @HiveField(14)
  bool todosEnabled; // Show todos section in note detail

  @HiveField(15)
  String whisperModel; // 'base', 'small', 'medium' — which Whisper model to use

  @HiveField(16)
  String noteOutputMode; // 'english' or 'native' — note output language mode

  @HiveField(17, defaultValue: false)
  bool keepScreenAwake; // Keep screen on during recording (for long recordings)

  @HiveField(18, defaultValue: false)
  bool blockOffensiveWords; // Filter offensive words from transcription output

  @HiveField(19, defaultValue: false)
  bool appLockEnabled;

  @HiveField(20)
  String? appLockPinHash; // SHA-256 hash of PIN (never store raw PIN)

  @HiveField(21, defaultValue: false)
  bool biometricEnabled;

  @HiveField(22, defaultValue: 0)
  int autoLockTimeoutSeconds; // 0=immediately, 60, 300, 900

  @HiveField(23, defaultValue: 'record_only')
  String widgetPrivacyLevel; // 'full', 'record_only', 'minimal' — controls Dashboard widget content when App Lock is on

  @HiveField(24)
  DateTime? lastBackupDate; // When the user last created a successful backup

  @HiveField(25, defaultValue: true)
  bool soundCuesEnabled; // Play subtle beep on recording start/stop

  @HiveField(26, defaultValue: false)
  bool guidedRecordingCompleted; // True once first-recording coaching is dismissed or completed

  @HiveField(27, defaultValue: true)
  bool crashReportingEnabled; // Anonymous crash reporting via Sentry (on by default)

  @HiveField(28)
  List<String> dismissedTips; // IDs of contextual tips the user has dismissed

  @HiveField(29)
  String? lastSeenAppVersion; // For What's New screen detection

  @HiveField(30, defaultValue: 'newest')
  String noteSortOrder; // newest, oldest, titleAZ, titleZA, longest

  @HiveField(31, defaultValue: false)
  bool permissionScreenShown; // True once the post-onboarding permission screen has been displayed

  @HiveField(32, defaultValue: 0)
  int fabSwipeHintShownCount; // Idle hint shown count (max 2)

  @HiveField(33, defaultValue: 0)
  int sessionCount; // Incremented on each app launch

  @HiveField(34, defaultValue: 'prefix_auto')
  String noteNamingStyle; // 'prefix_only', 'prefix_auto', 'auto_only'

  @HiveField(35, defaultValue: 0)
  int voiceNoteCounter; // Persistent auto-increment counter for voice notes (V1, V2, ...)

  @HiveField(36, defaultValue: 0)
  int textNoteCounter; // Persistent auto-increment counter for text notes (T1, T2, ...)

  @HiveField(37, defaultValue: false)
  bool whisperReadyShown; // True once the post-download "ready" splash has been displayed

  @HiveField(38, defaultValue: false)
  bool autoBackupEnabled; // Whether automatic backups are enabled

  @HiveField(39, defaultValue: 'weekly')
  String autoBackupFrequency; // 'daily', 'every3days', 'weekly'

  @HiveField(40, defaultValue: 5)
  int autoBackupMaxCount; // Max number of auto-backup files to keep (3, 5, 10)

  @HiveField(41)
  DateTime? autoBackupLastRun; // When the last auto-backup was performed

  @HiveField(42, defaultValue: 0)
  int currentTipIndex; // Index of the currently displayed home tip (0-based)

  @HiveField(43, defaultValue: false)
  bool tipTileDismissed; // Whether the user has dismissed the home tip tile

  @HiveField(44, defaultValue: 0)
  int failedPinAttempts; // Persistent failed PIN attempt counter (survives app restart)

  @HiveField(45)
  DateTime? pinLockoutUntil; // Persistent lockout deadline (survives app restart)

  @HiveField(46, defaultValue: 4)
  int pinLength; // Length of the PIN (4-6 digits) — needed for auto-verify

  UserSettings({
    this.defaultLanguage = 'en',
    this.audioQuality = 'standard',
    this.notificationsEnabled = true,
    this.quietHoursStartMinutes,
    this.quietHoursEndMinutes,
    this.themeMode = 'system',
    this.onboardingCompleted = false,
    this.transcriptionMode = 'whisper',
    this.speakerName = 'Speaker 1',
    this.notePrefix = 'V',
    this.defaultFolderId,
    this.voiceCommandsEnabled = true,
    this.textNotePrefix = 'T',
    this.actionItemsEnabled = true,
    this.todosEnabled = true,
    this.whisperModel = 'base',
    this.noteOutputMode = 'english',
    this.keepScreenAwake = false,
    this.blockOffensiveWords = false,
    this.appLockEnabled = false,
    this.appLockPinHash,
    this.biometricEnabled = false,
    this.autoLockTimeoutSeconds = 0,
    this.widgetPrivacyLevel = 'record_only',
    this.lastBackupDate,
    this.soundCuesEnabled = true,
    this.guidedRecordingCompleted = false,
    this.crashReportingEnabled = true,
    List<String>? dismissedTips,
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
  })  : dismissedTips = dismissedTips ?? [];

  Map<String, dynamic> toMap() => {
        'defaultLanguage': defaultLanguage,
        'audioQuality': audioQuality,
        'notificationsEnabled': notificationsEnabled,
        'quietHoursStartMinutes': quietHoursStartMinutes,
        'quietHoursEndMinutes': quietHoursEndMinutes,
        'themeMode': themeMode,
        'onboardingCompleted': onboardingCompleted,
        'transcriptionMode': transcriptionMode,
        'speakerName': speakerName,
        'notePrefix': notePrefix,
        'defaultFolderId': defaultFolderId,
        'voiceCommandsEnabled': voiceCommandsEnabled,
        'textNotePrefix': textNotePrefix,
        'actionItemsEnabled': actionItemsEnabled,
        'todosEnabled': todosEnabled,
        'whisperModel': whisperModel,
        'noteOutputMode': noteOutputMode,
        'keepScreenAwake': keepScreenAwake,
        'blockOffensiveWords': blockOffensiveWords,
        'appLockEnabled': appLockEnabled,
        'appLockPinHash': appLockPinHash,
        'biometricEnabled': biometricEnabled,
        'autoLockTimeoutSeconds': autoLockTimeoutSeconds,
        'widgetPrivacyLevel': widgetPrivacyLevel,
        'lastBackupDate': lastBackupDate?.toIso8601String(),
        'soundCuesEnabled': soundCuesEnabled,
        'guidedRecordingCompleted': guidedRecordingCompleted,
        'crashReportingEnabled': crashReportingEnabled,
        'dismissedTips': dismissedTips,
        'lastSeenAppVersion': lastSeenAppVersion,
        'noteSortOrder': noteSortOrder,
        'permissionScreenShown': permissionScreenShown,
        'fabSwipeHintShownCount': fabSwipeHintShownCount,
        'sessionCount': sessionCount,
        'noteNamingStyle': noteNamingStyle,
        'voiceNoteCounter': voiceNoteCounter,
        'textNoteCounter': textNoteCounter,
        'whisperReadyShown': whisperReadyShown,
        'autoBackupEnabled': autoBackupEnabled,
        'autoBackupFrequency': autoBackupFrequency,
        'autoBackupMaxCount': autoBackupMaxCount,
        'autoBackupLastRun': autoBackupLastRun?.toIso8601String(),
        'currentTipIndex': currentTipIndex,
        'tipTileDismissed': tipTileDismissed,
        'failedPinAttempts': failedPinAttempts,
        'pinLockoutUntil': pinLockoutUntil?.toIso8601String(),
        'pinLength': pinLength,
      };

  factory UserSettings.fromMap(Map<String, dynamic> m) => UserSettings(
        defaultLanguage: m['defaultLanguage'] as String?,
        audioQuality: m['audioQuality'] as String? ?? 'standard',
        notificationsEnabled: m['notificationsEnabled'] as bool? ?? true,
        quietHoursStartMinutes: m['quietHoursStartMinutes'] as int?,
        quietHoursEndMinutes: m['quietHoursEndMinutes'] as int?,
        themeMode: m['themeMode'] as String? ?? 'system',
        onboardingCompleted: m['onboardingCompleted'] as bool? ?? false,
        transcriptionMode: m['transcriptionMode'] as String? ?? 'whisper',
        speakerName: m['speakerName'] as String? ?? 'Speaker 1',
        notePrefix: m['notePrefix'] as String? ?? 'V',
        defaultFolderId: m['defaultFolderId'] as String?,
        voiceCommandsEnabled: m['voiceCommandsEnabled'] as bool? ?? true,
        textNotePrefix: m['textNotePrefix'] as String? ?? 'T',
        actionItemsEnabled: m['actionItemsEnabled'] as bool? ?? true,
        todosEnabled: m['todosEnabled'] as bool? ?? true,
        whisperModel: m['whisperModel'] as String? ?? 'base',
        noteOutputMode: m['noteOutputMode'] as String? ?? 'english',
        keepScreenAwake: m['keepScreenAwake'] as bool? ?? false,
        blockOffensiveWords: m['blockOffensiveWords'] as bool? ?? false,
        appLockEnabled: m['appLockEnabled'] as bool? ?? false,
        appLockPinHash: m['appLockPinHash'] as String?,
        biometricEnabled: m['biometricEnabled'] as bool? ?? false,
        autoLockTimeoutSeconds: m['autoLockTimeoutSeconds'] as int? ?? 0,
        widgetPrivacyLevel: m['widgetPrivacyLevel'] as String? ?? 'record_only',
        lastBackupDate: m['lastBackupDate'] != null
            ? DateTime.parse(m['lastBackupDate'] as String)
            : null,
        soundCuesEnabled: m['soundCuesEnabled'] as bool? ?? true,
        guidedRecordingCompleted: m['guidedRecordingCompleted'] as bool? ?? false,
        crashReportingEnabled: m['crashReportingEnabled'] as bool? ?? true,
        dismissedTips: List<String>.from(m['dismissedTips'] as List? ?? []),
        lastSeenAppVersion: m['lastSeenAppVersion'] as String?,
        noteSortOrder: m['noteSortOrder'] as String? ?? 'newest',
        permissionScreenShown: m['permissionScreenShown'] as bool? ?? false,
        fabSwipeHintShownCount: m['fabSwipeHintShownCount'] as int? ?? 0,
        sessionCount: m['sessionCount'] as int? ?? 0,
        noteNamingStyle: m['noteNamingStyle'] as String? ?? 'prefix_auto',
        voiceNoteCounter: m['voiceNoteCounter'] as int? ?? 0,
        textNoteCounter: m['textNoteCounter'] as int? ?? 0,
        whisperReadyShown: m['whisperReadyShown'] as bool? ?? false,
        autoBackupEnabled: m['autoBackupEnabled'] as bool? ?? false,
        autoBackupFrequency: m['autoBackupFrequency'] as String? ?? 'weekly',
        autoBackupMaxCount: m['autoBackupMaxCount'] as int? ?? 5,
        autoBackupLastRun: m['autoBackupLastRun'] != null
            ? DateTime.parse(m['autoBackupLastRun'] as String)
            : null,
        currentTipIndex: m['currentTipIndex'] as int? ?? 0,
        tipTileDismissed: m['tipTileDismissed'] as bool? ?? false,
        failedPinAttempts: m['failedPinAttempts'] as int? ?? 0,
        pinLockoutUntil: m['pinLockoutUntil'] != null
            ? DateTime.parse(m['pinLockoutUntil'] as String)
            : null,
        pinLength: m['pinLength'] as int? ?? 4,
      );
}
