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
}
