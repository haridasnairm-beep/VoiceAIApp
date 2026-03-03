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

  @HiveField(21)
  String? transcriptionModel; // Whisper model used: 'base', 'small', etc. null = unknown/pre-feature

  @HiveField(22, defaultValue: false)
  bool isPinned;

  @HiveField(23)
  DateTime? pinnedAt;

  @HiveField(24, defaultValue: false)
  bool isUserEditedTitle;

  @HiveField(25, defaultValue: false)
  bool isDeleted;

  @HiveField(26)
  DateTime? deletedAt;

  @HiveField(27)
  String? previousFolderId;

  @HiveField(28)
  List<String> tags;

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
    this.isProcessed = true,
    this.hasFollowUpTrigger = false,
    List<TranscriptVersion>? transcriptVersions,
    List<String>? projectDocumentIds,
    List<String>? imageAttachmentIds,
    this.contentFormat,
    this.transcriptionModel,
    this.isPinned = false,
    this.pinnedAt,
    this.isUserEditedTitle = false,
    this.isDeleted = false,
    this.deletedAt,
    this.previousFolderId,
    List<String>? tags,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        topics = topics ?? [],
        actions = actions ?? [],
        todos = todos ?? [],
        reminders = reminders ?? [],
        generalNotes = generalNotes ?? [],
        transcriptVersions = transcriptVersions ?? [],
        projectDocumentIds = projectDocumentIds ?? [],
        imageAttachmentIds = imageAttachmentIds ?? [],
        tags = tags ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'rawTranscription': rawTranscription,
        'detectedLanguage': detectedLanguage,
        'audioFilePath': audioFilePath,
        'audioDurationSeconds': audioDurationSeconds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'folderId': folderId,
        'topics': topics,
        'actions': actions.map((a) => a.toMap()).toList(),
        'todos': todos.map((t) => t.toMap()).toList(),
        'reminders': reminders.map((r) => r.toMap()).toList(),
        'generalNotes': generalNotes,
        'followUpQuestions': followUpQuestions,
        'isProcessed': isProcessed,
        'hasFollowUpTrigger': hasFollowUpTrigger,
        'transcriptVersions': transcriptVersions.map((v) => v.toMap()).toList(),
        'projectDocumentIds': projectDocumentIds,
        'imageAttachmentIds': imageAttachmentIds,
        'contentFormat': contentFormat,
        'transcriptionModel': transcriptionModel,
        'isPinned': isPinned,
        'pinnedAt': pinnedAt?.toIso8601String(),
        'isUserEditedTitle': isUserEditedTitle,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
        'previousFolderId': previousFolderId,
        'tags': tags,
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        title: m['title'] as String,
        rawTranscription: m['rawTranscription'] as String? ?? '',
        detectedLanguage: m['detectedLanguage'] as String? ?? 'en',
        audioFilePath: m['audioFilePath'] as String,
        audioDurationSeconds: m['audioDurationSeconds'] as int? ?? 0,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        folderId: m['folderId'] as String?,
        topics: List<String>.from(m['topics'] as List? ?? []),
        actions: (m['actions'] as List? ?? [])
            .map((a) => ActionItem.fromMap(a as Map<String, dynamic>))
            .toList(),
        todos: (m['todos'] as List? ?? [])
            .map((t) => TodoItem.fromMap(t as Map<String, dynamic>))
            .toList(),
        reminders: (m['reminders'] as List? ?? [])
            .map((r) => ReminderItem.fromMap(r as Map<String, dynamic>))
            .toList(),
        generalNotes: List<String>.from(m['generalNotes'] as List? ?? []),
        followUpQuestions: m['followUpQuestions'] != null
            ? List<String>.from(m['followUpQuestions'] as List)
            : null,
        isProcessed: m['isProcessed'] as bool? ?? true,
        hasFollowUpTrigger: m['hasFollowUpTrigger'] as bool? ?? false,
        transcriptVersions: (m['transcriptVersions'] as List? ?? [])
            .map((v) => TranscriptVersion.fromMap(v as Map<String, dynamic>))
            .toList(),
        projectDocumentIds: List<String>.from(m['projectDocumentIds'] as List? ?? []),
        imageAttachmentIds: List<String>.from(m['imageAttachmentIds'] as List? ?? []),
        contentFormat: m['contentFormat'] as String?,
        transcriptionModel: m['transcriptionModel'] as String?,
        isPinned: m['isPinned'] as bool? ?? false,
        pinnedAt: m['pinnedAt'] != null ? DateTime.parse(m['pinnedAt'] as String) : null,
        isUserEditedTitle: m['isUserEditedTitle'] as bool? ?? false,
        isDeleted: m['isDeleted'] as bool? ?? false,
        deletedAt: m['deletedAt'] != null ? DateTime.parse(m['deletedAt'] as String) : null,
        previousFolderId: m['previousFolderId'] as String?,
        tags: List<String>.from(m['tags'] as List? ?? []),
      );
}
