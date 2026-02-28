import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/image_attachment_repository.dart';
import '../pages/image_viewer_page.dart';
import '../theme.dart';

class NoteAttachmentsSection extends ConsumerWidget {
  final Note note;

  const NoteAttachmentsSection({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ImageAttachmentRepository();
    final attachmentIds = note.imageAttachmentIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              Icon(Icons.photo_library_rounded,
                  size: 18, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Attachments${attachmentIds.isNotEmpty ? ' (${attachmentIds.length})' : ''}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addPhoto(context, ref),
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Add Photo'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ),
        // Thumbnails
        if (attachmentIds.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: attachmentIds.length,
              itemBuilder: (context, index) {
                final id = attachmentIds[index];
                final attachment = repo.getImageAttachment(id);
                final file = repo.getImageFile(id);

                return Padding(
                  padding: EdgeInsets.only(
                      right: index < attachmentIds.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      if (file != null && file.existsSync()) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ImageViewerPage(
                              imageFile: file,
                              caption: attachment?.caption,
                            ),
                          ),
                        );
                      }
                    },
                    onLongPress: () =>
                        _confirmDeletePhoto(context, ref, note.id, id),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: file != null && file.existsSync()
                          ? Image.file(
                              file,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Icon(Icons.broken_image_rounded,
                                  color: Theme.of(context).hintColor),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (attachmentIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No photos attached. Tap "Add Photo" to attach images.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
      ],
    );
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final repo = ImageAttachmentRepository();
    final attachment = await repo.saveImage(
      sourceFile: File(picked.path),
      sourceType: source == ImageSource.gallery ? 'gallery' : 'camera',
    );

    ref.read(notesProvider.notifier).addImageAttachment(
          noteId: note.id,
          attachmentId: attachment.id,
        );
  }

  Future<void> _confirmDeletePhoto(
      BuildContext context, WidgetRef ref, String noteId, String attachmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ImageAttachmentRepository();
      await repo.deleteImageAttachment(attachmentId);
      ref.read(notesProvider.notifier).removeImageAttachment(
            noteId: noteId,
            attachmentId: attachmentId,
          );
    }
  }
}
