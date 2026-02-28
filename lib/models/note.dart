import 'package:hive/hive.dart';
import 'action_item.dart';
import 'todo_item.dart';
import 'reminder_item.dart';
import 'transcript_version.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String rawTranscription;

  @HiveField(3)
  String detectedLanguage;

  @HiveField(4)
  final String audioFilePath;

  @HiveField(5)
  int audioDurationSeconds;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  String? folderId;

  @HiveField(9)
  List<String> topics;

  @HiveField(10)
  List<ActionItem> actions;

  @HiveField(11)
  List<TodoItem> todos;

  @HiveField(12)
  List<ReminderItem> reminders;

  @HiveField(13)
  List<String> generalNotes;

  @HiveField(14)
  List<String>? followUpQuestions;

  @HiveField(15)
  bool isProcessed;

  @HiveField(16)
  bool hasFollowUpTrigger;

  @HiveField(17)
  List<TranscriptVersion> transcriptVersions;

  @HiveField(18)
  List<String> projectDocumentIds;

  @HiveField(19)
  List<String> imageAttachmentIds;

  @HiveField(20)
  String? contentFormat; // null/'plain' = plain text, 'quill_delta' = rich text JSON

  Note({
    required this.id,
    required this.title,
    this.rawTranscription = '',
    this.detectedLanguage = 'en',
    required this.audioFilePath,
    this.audioDurationSeconds = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.folderId,
    List<String>? topics,
    List<ActionItem>? actions,
    List<TodoItem>? todos,
    List<ReminderItem>? reminders,
    List<String>? generalNotes,
    this.followUpQuestions,
    this.isProcessed = false,
    this.hasFollowUpTrigger = false,
    List<TranscriptVersion>? transcriptVersions,
    List<String>? projectDocumentIds,
    List<String>? imageAttachmentIds,
    this.contentFormat,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        topics = topics ?? [],
        actions = actions ?? [],
        todos = todos ?? [],
        reminders = reminders ?? [],
        generalNotes = generalNotes ?? [],
        transcriptVersions = transcriptVersions ?? [],
        projectDocumentIds = projectDocumentIds ?? [],
        imageAttachmentIds = imageAttachmentIds ?? [];
}
