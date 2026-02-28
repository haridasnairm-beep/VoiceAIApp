import 'dart:io';
import 'package:flutter/material.dart';
import '../models/image_attachment.dart';
import '../pages/image_viewer_page.dart';
import '../theme.dart';

class ImageBlockWidget extends StatelessWidget {
  final ImageAttachment? attachment;
  final File? imageFile;
  final String? caption;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final void Function(String)? onEditCaption;

  const ImageBlockWidget({
    super.key,
    required this.attachment,
    required this.imageFile,
    this.caption,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    this.onEditCaption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sm),
                  bottom: (caption != null && caption!.isNotEmpty)
                      ? Radius.zero
                      : Radius.circular(AppRadius.sm),
                ),
                child: imageFile != null && imageFile!.existsSync()
                    ? GestureDetector(
                        onTap: () => _openFullScreen(context),
                        child: Image.file(
                          imageFile!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          frameBuilder:
                              (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: frame != null
                                  ? child
                                  : Container(
                                      height: 200,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Center(
                                          child: CircularProgressIndicator()),
                                    ),
                            );
                          },
                        ),
                      )
                    : Container(
                        height: 120,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  size: 32,
                                  color: Theme.of(context).hintColor),
                              const SizedBox(height: 4),
                              Text('Image not found',
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
              ),
              // Overflow menu
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.more_vert,
                        size: 20, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'view') _openFullScreen(context);
                      if (value == 'edit_caption') _showEditCaptionDialog(context);
                      if (value == 'move_up') onMoveUp();
                      if (value == 'move_down') onMoveDown();
                      if (value == 'remove') onRemove();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.fullscreen_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('View full screen'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit_caption',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Edit caption'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'move_up',
                        enabled: !isFirst,
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Move up'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move_down',
                        enabled: !isLast,
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Move down'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Caption
          if (caption != null && caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Text(
                caption!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    if (imageFile == null || !imageFile!.existsSync()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerPage(
          imageFile: imageFile!,
          caption: caption,
        ),
      ),
    );
  }

  void _showEditCaptionDialog(BuildContext context) {
    final controller = TextEditingController(text: caption ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter caption...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onEditCaption?.call(controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}