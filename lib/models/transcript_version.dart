import 'package:hive/hive.dart';

part 'transcript_version.g.dart';

@HiveType(typeId: 8)
class TranscriptVersion extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  final int versionNumber;

  @HiveField(3)
  final String editSource;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isOriginal;

  /// Quill Delta JSON for rich text versions. Null means plain text only.
  @HiveField(6)
  final String? richContentJson;

  TranscriptVersion({
    required this.id,
    required this.text,
    required this.versionNumber,
    required this.editSource,
    DateTime? createdAt,
    this.isOriginal = false,
    this.richContentJson,
  }) : createdAt = createdAt ?? DateTime.now();
}
