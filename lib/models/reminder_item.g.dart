// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderItemAdapter extends TypeAdapter<ReminderItem> {
  @override
  final int typeId = 3;

  @override
  ReminderItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderItem(
      id: fields[0] as String,
      text: fields[1] as String,
      reminderTime: fields[2] as DateTime?,
      isCompleted: fields[3] as bool,
      notificationId: fields[4] as int?,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.reminderTime)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.notificationId)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
