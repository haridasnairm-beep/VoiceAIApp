// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectBlockAdapter extends TypeAdapter<ProjectBlock> {
  @override
  final int typeId = 7;

  @override
  ProjectBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectBlock(
      id: fields[0] as String,
      type: fields[1] as BlockType,
      sortOrder: fields[2] as int,
      noteId: fields[3] as String?,
      content: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
      imageAttachmentId: fields[7] as String?,
      contentFormat: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectBlock obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.sortOrder)
      ..writeByte(3)
      ..write(obj.noteId)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.imageAttachmentId)
      ..writeByte(8)
      ..write(obj.contentFormat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockTypeAdapter extends TypeAdapter<BlockType> {
  @override
  final int typeId = 9;

  @override
  BlockType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BlockType.noteReference;
      case 1:
        return BlockType.freeText;
      case 2:
        return BlockType.sectionHeader;
      case 3:
        return BlockType.imageBlock;
      case 4:
        return BlockType.taskBlock;
      default:
        return BlockType.noteReference;
    }
  }

  @override
  void write(BinaryWriter writer, BlockType obj) {
    switch (obj) {
      case BlockType.noteReference:
        writer.writeByte(0);
        break;
      case BlockType.freeText:
        writer.writeByte(1);
        break;
      case BlockType.sectionHeader:
        writer.writeByte(2);
        break;
      case BlockType.imageBlock:
        writer.writeByte(3);
        break;
      case BlockType.taskBlock:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
