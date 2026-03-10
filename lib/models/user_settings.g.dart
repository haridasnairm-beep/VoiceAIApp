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
      soundCuesEnabled: fields[25] == null ? true : fields[25] as bool,
      guidedRecordingCompleted: fields[26] == null ? false : fields[26] as bool,
      crashReportingEnabled: fields[27] == null ? true : fields[27] as bool,
      dismissedTips: (fields[28] as List?)?.cast<String>(),
      lastSeenAppVersion: fields[29] as String?,
      noteSortOrder: fields[30] == null ? 'newest' : fields[30] as String,
      permissionScreenShown: fields[31] == null ? false : fields[31] as bool,
      fabSwipeHintShownCount: fields[32] == null ? 0 : fields[32] as int,
      sessionCount: fields[33] == null ? 0 : fields[33] as int,
      noteNamingStyle:
          fields[34] == null ? 'prefix_auto' : fields[34] as String,
      voiceNoteCounter: fields[35] == null ? 0 : fields[35] as int,
      textNoteCounter: fields[36] == null ? 0 : fields[36] as int,
      whisperReadyShown: fields[37] == null ? false : fields[37] as bool,
      autoBackupEnabled: fields[38] == null ? false : fields[38] as bool,
      autoBackupFrequency: fields[39] == null ? 'weekly' : fields[39] as String,
      autoBackupMaxCount: fields[40] == null ? 5 : fields[40] as int,
      autoBackupLastRun: fields[41] as DateTime?,
      currentTipIndex: fields[42] == null ? 0 : fields[42] as int,
      tipTileDismissed: fields[43] == null ? false : fields[43] as bool,
      failedPinAttempts: fields[44] == null ? 0 : fields[44] as int,
      pinLockoutUntil: fields[45] as DateTime?,
      pinLength: fields[46] == null ? 4 : fields[46] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(47)
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
      ..write(obj.lastBackupDate)
      ..writeByte(25)
      ..write(obj.soundCuesEnabled)
      ..writeByte(26)
      ..write(obj.guidedRecordingCompleted)
      ..writeByte(27)
      ..write(obj.crashReportingEnabled)
      ..writeByte(28)
      ..write(obj.dismissedTips)
      ..writeByte(29)
      ..write(obj.lastSeenAppVersion)
      ..writeByte(30)
      ..write(obj.noteSortOrder)
      ..writeByte(31)
      ..write(obj.permissionScreenShown)
      ..writeByte(32)
      ..write(obj.fabSwipeHintShownCount)
      ..writeByte(33)
      ..write(obj.sessionCount)
      ..writeByte(34)
      ..write(obj.noteNamingStyle)
      ..writeByte(35)
      ..write(obj.voiceNoteCounter)
      ..writeByte(36)
      ..write(obj.textNoteCounter)
      ..writeByte(37)
      ..write(obj.whisperReadyShown)
      ..writeByte(38)
      ..write(obj.autoBackupEnabled)
      ..writeByte(39)
      ..write(obj.autoBackupFrequency)
      ..writeByte(40)
      ..write(obj.autoBackupMaxCount)
      ..writeByte(41)
      ..write(obj.autoBackupLastRun)
      ..writeByte(42)
      ..write(obj.currentTipIndex)
      ..writeByte(43)
      ..write(obj.tipTileDismissed)
      ..writeByte(44)
      ..write(obj.failedPinAttempts)
      ..writeByte(45)
      ..write(obj.pinLockoutUntil)
      ..writeByte(46)
      ..write(obj.pinLength);
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
