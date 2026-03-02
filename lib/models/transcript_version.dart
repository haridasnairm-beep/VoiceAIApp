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

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'versionNumber': versionNumber,
        'editSource': editSource,
        'createdAt': createdAt.toIso8601String(),
        'isOriginal': isOriginal,
        'richContentJson': richContentJson,
      };

  factory TranscriptVersion.fromMap(Map<String, dynamic> m) => TranscriptVersion(
        id: m['id'] as String,
        text: m['text'] as String,
        versionNumber: m['versionNumber'] as int,
        editSource: m['editSource'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        isOriginal: m['isOriginal'] as bool? ?? false,
        richContentJson: m['richContentJson'] as String?,
      );
}
