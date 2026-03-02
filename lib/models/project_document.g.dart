// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectDocumentAdapter extends TypeAdapter<ProjectDocument> {
  @override
  final int typeId = 6;

  @override
  ProjectDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      blocks: (fields[3] as List?)?.cast<ProjectBlock>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      isDeleted: fields[6] == null ? false : fields[6] as bool,
      deletedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectDocument obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.blocks)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isDeleted)
      ..writeByte(7)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
