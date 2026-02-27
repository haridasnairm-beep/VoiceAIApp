import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 5)
class UserSettings extends HiveObject {
  @HiveField(0)
  String? defaultLanguage; // null = auto-detect

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

  UserSettings({
    this.defaultLanguage,
    this.audioQuality = 'standard',
    this.notificationsEnabled = true,
    this.quietHoursStartMinutes,
    this.quietHoursEndMinutes,
    this.themeMode = 'system',
    this.onboardingCompleted = false,
    this.transcriptionMode = 'whisper',
    this.speakerName = 'Speaker 1',
    this.notePrefix = 'VOICE',
    this.defaultFolderId,
    this.voiceCommandsEnabled = true,
  });
}
