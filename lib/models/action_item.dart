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
}
