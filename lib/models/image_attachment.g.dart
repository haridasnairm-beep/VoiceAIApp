// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_attachment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageAttachmentAdapter extends TypeAdapter<ImageAttachment> {
  @override
  final int typeId = 10;

  @override
  ImageAttachment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageAttachment(
      id: fields[0] as String,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      caption: fields[3] as String?,
      width: fields[4] as int,
      height: fields[5] as int,
      fileSizeBytes: fields[6] as int,
      sourceType: fields[7] as String,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageAttachment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.caption)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.fileSizeBytes)
      ..writeByte(7)
      ..write(obj.sourceType)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageAttachmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
