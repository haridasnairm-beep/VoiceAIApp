// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 5;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      defaultLanguage: fields[0] as String?,
      audioQuality: fields[1] as String,
      notificationsEnabled: fields[2] as bool,
      quietHoursStartMinutes: fields[3] as int?,
      quietHoursEndMinutes: fields[4] as int?,
      themeMode: fields[5] as String,
      onboardingCompleted: fields[6] as bool,
      transcriptionMode: fields[7] as String,
      speakerName: fields[8] as String,
      notePrefix: fields[9] as String,
      defaultFolderId: fields[10] as String?,
      voiceCommandsEnabled: fields[11] as bool,
      textNotePrefix: fields[12] as String,
      actionItemsEnabled: fields[13] as bool,
      todosEnabled: fields[14] as bool,
      whisperModel: fields[15] as String,
      noteOutputMode: fields[16] as String,
      keepScreenAwake: fields[17] == null ? false : fields[17] as bool,
      blockOffensiveWords: fields[18] == null ? false : fields[18] as bool,
      appLockEnabled: fields[19] == null ? false : fields[19] as bool,
      appLockPinHash: fields[20] as String?,
      biometricEnabled: fields[21] == null ? false : fields[21] as bool,
      autoLockTimeoutSeconds: fields[22] == null ? 0 : fields[22] as int,
      widgetPrivacyLevel:
          fields[23] == null ? 'record_only' : fields[23] as String,
      lastBackupDate: fields[24] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.defaultLanguage)
      ..writeByte(1)
      ..write(obj.audioQuality)
      ..writeByte(2)
      ..write(obj.notificationsEnabled)
      ..writeByte(3)
      ..write(obj.quietHoursStartMinutes)
      ..writeByte(4)
      ..write(obj.quietHoursEndMinutes)
      ..writeByte(5)
      ..write(obj.themeMode)
      ..writeByte(6)
      ..write(obj.onboardingCompleted)
      ..writeByte(7)
      ..write(obj.transcriptionMode)
      ..writeByte(8)
      ..write(obj.speakerName)
      ..writeByte(9)
      ..write(obj.notePrefix)
      ..writeByte(10)
      ..write(obj.defaultFolderId)
      ..writeByte(11)
      ..write(obj.voiceCommandsEnabled)
      ..writeByte(12)
      ..write(obj.textNotePrefix)
      ..writeByte(13)
      ..write(obj.actionItemsEnabled)
      ..writeByte(14)
      ..write(obj.todosEnabled)
      ..writeByte(15)
      ..write(obj.whisperModel)
      ..writeByte(16)
      ..write(obj.noteOutputMode)
      ..writeByte(17)
      ..write(obj.keepScreenAwake)
      ..writeByte(18)
      ..write(obj.blockOffensiveWords)
      ..writeByte(19)
      ..write(obj.appLockEnabled)
      ..writeByte(20)
      ..write(obj.appLockPinHash)
      ..writeByte(21)
      ..write(obj.biometricEnabled)
      ..writeByte(22)
      ..write(obj.autoLockTimeoutSeconds)
      ..writeByte(23)
      ..write(obj.widgetPrivacyLevel)
      ..writeByte(24)
      ..write(obj.lastBackupDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
