import 'package:hive/hive.dart';

part 'action_item.g.dart';

@HiveType(typeId: 1)
class ActionItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  final DateTime createdAt;

  ActionItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ActionItem.fromMap(Map<String, dynamic> m) => ActionItem(
        id: m['id'] as String,
        text: m['text'] as String,
        isCompleted: m['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
