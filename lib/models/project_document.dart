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

  @HiveField(8)
  String? folderId;

  ProjectDocument({
    required this.id,
    required this.title,
    this.description,
    this.folderId,
    List<ProjectBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  })  : blocks = blocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'folderId': folderId,
        'blocks': blocks.map((b) => b.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory ProjectDocument.fromMap(Map<String, dynamic> m) => ProjectDocument(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        folderId: m['folderId'] as String?,
        blocks: (m['blocks'] as List? ?? [])
            .map((b) => ProjectBlock.fromMap(b as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        isDeleted: m['isDeleted'] as bool? ?? false,
        deletedAt: m['deletedAt'] != null ? DateTime.parse(m['deletedAt'] as String) : null,
      );
}
