import 'package:hive/hive.dart';

part 'reminder_item.g.dart';

@HiveType(typeId: 3)
class ReminderItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  DateTime? reminderTime;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  int? notificationId;

  @HiveField(5)
  final DateTime createdAt;

  ReminderItem({
    required this.id,
    required this.text,
    this.reminderTime,
    this.isCompleted = false,
    this.notificationId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
