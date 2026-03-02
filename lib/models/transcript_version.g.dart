// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_version.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptVersionAdapter extends TypeAdapter<TranscriptVersion> {
  @override
  final int typeId = 8;

  @override
  TranscriptVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranscriptVersion(
      id: fields[0] as String,
      text: fields[1] as String,
      versionNumber: fields[2] as int,
      editSource: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      isOriginal: fields[5] as bool,
      richContentJson: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TranscriptVersion obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.versionNumber)
      ..writeByte(3)
      ..write(obj.editSource)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isOriginal)
      ..writeByte(6)
      ..write(obj.richContentJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
