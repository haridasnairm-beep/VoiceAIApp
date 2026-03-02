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
    this.notePrefix = 'VOICE',
    this.defaultFolderId,
    this.voiceCommandsEnabled = true,
    this.textNotePrefix = 'TXT',
    this.actionItemsEnabled = true,
    this.todosEnabled = true,
    this.whisperModel = 'base',
    this.noteOutputMode = 'english',
    this.keepScreenAwake = false,
    this.blockOffensiveWords = false,
  });
}
