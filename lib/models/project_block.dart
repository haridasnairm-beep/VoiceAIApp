import 'package:hive/hive.dart';

part 'project_block.g.dart';

@HiveType(typeId: 9)
enum BlockType {
  @HiveField(0)
  noteReference,

  @HiveField(1)
  freeText,

  @HiveField(2)
  sectionHeader,
}

@HiveType(typeId: 7)
class ProjectBlock extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final BlockType type;

  @HiveField(2)
  int sortOrder;

  @HiveField(3)
  String? noteId;

  @HiveField(4)
  String? content;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  ProjectBlock({
    required this.id,
    required this.type,
    required this.sortOrder,
    this.noteId,
    this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
