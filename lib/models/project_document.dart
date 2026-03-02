import 'package:hive/hive.dart';
import 'project_block.dart';

part 'project_document.g.dart';

@HiveType(typeId: 6)
class ProjectDocument extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<ProjectBlock> blocks;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6, defaultValue: false)
  bool isDeleted;

  @HiveField(7)
  DateTime? deletedAt;

  ProjectDocument({
    required this.id,
    required this.title,
    this.description,
    List<ProjectBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  })  : blocks = blocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
