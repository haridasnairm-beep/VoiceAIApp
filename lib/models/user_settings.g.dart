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
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.voiceCommandsEnabled);
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
