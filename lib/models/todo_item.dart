import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 2)
class TodoItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoItem.fromMap(Map<String, dynamic> m) => TodoItem(
        id: m['id'] as String,
        text: m['text'] as String,
        isCompleted: m['isCompleted'] as bool? ?? false,
        dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate'] as String) : null,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
