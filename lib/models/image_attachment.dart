import 'package:hive/hive.dart';

part 'image_attachment.g.dart';

@HiveType(typeId: 10)
class ImageAttachment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  final String fileName;

  @HiveField(3)
  String? caption;

  @HiveField(4)
  final int width;

  @HiveField(5)
  final int height;

  @HiveField(6)
  final int fileSizeBytes;

  @HiveField(7)
  final String sourceType; // 'gallery' or 'camera'

  @HiveField(8)
  final DateTime createdAt;

  ImageAttachment({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.caption,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.sourceType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'filePath': filePath,
        'fileName': fileName,
        'caption': caption,
        'width': width,
        'height': height,
        'fileSizeBytes': fileSizeBytes,
        'sourceType': sourceType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImageAttachment.fromMap(Map<String, dynamic> m) => ImageAttachment(
        id: m['id'] as String,
        filePath: m['filePath'] as String,
        fileName: m['fileName'] as String,
        caption: m['caption'] as String?,
        width: m['width'] as int,
        height: m['height'] as int,
        fileSizeBytes: m['fileSizeBytes'] as int,
        sourceType: m['sourceType'] as String? ?? 'gallery',
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
