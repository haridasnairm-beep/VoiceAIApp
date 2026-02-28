import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/image_attachment.dart';
import 'hive_service.dart';

/// Repository for managing image attachments (metadata in Hive + files on disk).
class ImageAttachmentRepository {
  static const _uuid = Uuid();

  /// Save an image: compress, copy to images dir, create Hive record.
  Future<ImageAttachment> saveImage({
    required File sourceFile,
    required String sourceType,
    String? caption,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final id = _uuid.v4();
    final fileName = '$id.jpg';
    final targetPath = '${imagesDir.path}/$fileName';

    // Compress and save
    final result = await FlutterImageCompress.compressAndGetFile(
      sourceFile.absolute.path,
      targetPath,
      quality: 85,
      minWidth: 2048,
      minHeight: 2048,
    );

    if (result == null) {
      // Fallback: copy original if compression failed
      await sourceFile.copy(targetPath);
    }

    // Get file info
    final fileBytes = await File(targetPath).length();

    final attachment = ImageAttachment(
      id: id,
      filePath: targetPath,
      fileName: fileName,
      caption: caption,
      width: 0,
      height: 0,
      fileSizeBytes: fileBytes,
      sourceType: sourceType,
    );

    await HiveService.imageAttachmentsBox.put(id, attachment);
    debugPrint('ImageAttachmentRepository: saved image $id ($fileBytes bytes)');
    return attachment;
  }

  /// Get an image attachment by ID.
  ImageAttachment? getImageAttachment(String id) {
    return HiveService.imageAttachmentsBox.get(id);
  }

  /// Get the image file for an attachment.
  File? getImageFile(String id) {
    final attachment = getImageAttachment(id);
    if (attachment == null) return null;
    final file = File(attachment.filePath);
    return file.existsSync() ? file : null;
  }

  /// Delete an image attachment (metadata + file).
  Future<void> deleteImageAttachment(String id) async {
    final attachment = getImageAttachment(id);
    if (attachment == null) return;

    // Delete file from disk
    try {
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('ImageAttachmentRepository: failed to delete file: $e');
    }

    // Delete Hive record
    await HiveService.imageAttachmentsBox.delete(id);
    debugPrint('ImageAttachmentRepository: deleted image $id');
  }

  /// Update caption for an image attachment.
  Future<void> updateCaption(String id, String? caption) async {
    final attachment = getImageAttachment(id);
    if (attachment == null) return;
    attachment.caption = caption;
    await HiveService.imageAttachmentsBox.put(id, attachment);
  }

  /// Get count of all image attachments.
  int get count => HiveService.imageAttachmentsBox.length;
}
