// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      rawTranscription: fields[2] as String,
      detectedLanguage: fields[3] as String,
      audioFilePath: fields[4] as String,
      audioDurationSeconds: fields[5] as int,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
      folderId: fields[8] as String?,
      topics: (fields[9] as List?)?.cast<String>(),
      actions: (fields[10] as List?)?.cast<ActionItem>(),
      todos: (fields[11] as List?)?.cast<TodoItem>(),
      reminders: (fields[12] as List?)?.cast<ReminderItem>(),
      generalNotes: (fields[13] as List?)?.cast<String>(),
      followUpQuestions: (fields[14] as List?)?.cast<String>(),
      isProcessed: fields[15] as bool,
      hasFollowUpTrigger: fields[16] as bool,
      transcriptVersions: (fields[17] as List?)?.cast<TranscriptVersion>(),
      projectDocumentIds: (fields[18] as List?)?.cast<String>(),
      imageAttachmentIds: (fields[19] as List?)?.cast<String>(),
      contentFormat: fields[20] as String?,
      transcriptionModel: fields[21] as String?,
      isPinned: fields[22] == null ? false : fields[22] as bool,
      pinnedAt: fields[23] as DateTime?,
      isUserEditedTitle: fields[24] == null ? false : fields[24] as bool,
      isDeleted: fields[25] == null ? false : fields[25] as bool,
      deletedAt: fields[26] as DateTime?,
      previousFolderId: fields[27] as String?,
      tags: (fields[28] as List?)?.cast<String>(),
      sourceType: fields[29] == null ? 'in_app' : fields[29] as String,
      sharedFrom: fields[30] as String?,
      originalFilename: fields[31] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.rawTranscription)
      ..writeByte(3)
      ..write(obj.detectedLanguage)
      ..writeByte(4)
      ..write(obj.audioFilePath)
      ..writeByte(5)
      ..write(obj.audioDurationSeconds)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.folderId)
      ..writeByte(9)
      ..write(obj.topics)
      ..writeByte(10)
      ..write(obj.actions)
      ..writeByte(11)
      ..write(obj.todos)
      ..writeByte(12)
      ..write(obj.reminders)
      ..writeByte(13)
      ..write(obj.generalNotes)
      ..writeByte(14)
      ..write(obj.followUpQuestions)
      ..writeByte(15)
      ..write(obj.isProcessed)
      ..writeByte(16)
      ..write(obj.hasFollowUpTrigger)
      ..writeByte(17)
      ..write(obj.transcriptVersions)
      ..writeByte(18)
      ..write(obj.projectDocumentIds)
      ..writeByte(19)
      ..write(obj.imageAttachmentIds)
      ..writeByte(20)
      ..write(obj.contentFormat)
      ..writeByte(21)
      ..write(obj.transcriptionModel)
      ..writeByte(22)
      ..write(obj.isPinned)
      ..writeByte(23)
      ..write(obj.pinnedAt)
      ..writeByte(24)
      ..write(obj.isUserEditedTitle)
      ..writeByte(25)
      ..write(obj.isDeleted)
      ..writeByte(26)
      ..write(obj.deletedAt)
      ..writeByte(27)
      ..write(obj.previousFolderId)
      ..writeByte(28)
      ..write(obj.tags)
      ..writeByte(29)
      ..write(obj.sourceType)
      ..writeByte(30)
      ..write(obj.sharedFrom)
      ..writeByte(31)
      ..write(obj.originalFilename);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
