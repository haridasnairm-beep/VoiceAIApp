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
}
