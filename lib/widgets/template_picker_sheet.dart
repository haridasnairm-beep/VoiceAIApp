import 'package:flutter/material.dart';
import '../constants/note_templates.dart';

/// Bottom sheet for selecting a note template when creating a new text note.
/// Returns the selected [NoteTemplate], the string 'blank' for a blank note,
/// or null when dismissed (no action).
///
/// Must be shown with `isScrollControlled: true` in [showModalBottomSheet].
class TemplatePickerSheet extends StatelessWidget {
  const TemplatePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final itemCount = 1 + kNoteTemplates.length;
    final estimatedHeight = 80.0 + (itemCount * 72.0) + 8.0;
    final initialSize = (estimatedHeight / screenHeight).clamp(0.35, 0.7);

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.note_add_rounded,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('New Text Note',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Blank note option
              ListTile(
                leading: Icon(Icons.description_outlined,
                    color: theme.colorScheme.onSurface),
                title: const Text('Blank Note'),
                subtitle: Text('Start from scratch',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
                onTap: () => Navigator.pop(context, 'blank'),
              ),
              const Divider(height: 1),
              // Template options
              ...kNoteTemplates.map((template) => ListTile(
                    leading: Icon(template.icon,
                        color: theme.colorScheme.primary),
                    title: Text(template.name),
                    subtitle: Text(template.description,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                    onTap: () => Navigator.pop(context, template),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
