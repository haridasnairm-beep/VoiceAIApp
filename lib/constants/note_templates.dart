import 'package:flutter/material.dart';

/// A built-in note template with pre-filled content.
class NoteTemplate {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final String content; // Plain text template content

  const NoteTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.content,
  });
}

/// Built-in note templates available from the template picker.
const kNoteTemplates = <NoteTemplate>[
  NoteTemplate(
    id: 'meeting',
    name: 'Meeting Notes',
    icon: Icons.groups_rounded,
    description: 'Capture meeting discussions and actions',
    content: 'Meeting: [Topic]\n'
        'Date: [Today]\n'
        'Attendees:\n'
        '- \n\n'
        'Discussion Points:\n'
        '1. \n\n'
        'Action Items:\n'
        '- \n\n'
        'Next Steps:\n'
        '- ',
  ),
  NoteTemplate(
    id: 'journal',
    name: 'Daily Journal',
    icon: Icons.auto_stories_rounded,
    description: 'Reflect on your day',
    content: 'How am I feeling today?\n\n\n'
        'What happened today?\n\n\n'
        'What am I grateful for?\n'
        '1. \n'
        '2. \n'
        '3. \n\n'
        'Tomorrow\'s priorities:\n'
        '- ',
  ),
  NoteTemplate(
    id: 'idea',
    name: 'Idea Capture',
    icon: Icons.lightbulb_rounded,
    description: 'Capture and develop new ideas',
    content: 'Idea: [Title]\n\n'
        'The idea:\n\n\n'
        'Why it matters:\n\n\n'
        'Next steps to explore:\n'
        '- \n\n'
        'Related to:\n'
        '- ',
  ),
  NoteTemplate(
    id: 'grocery',
    name: 'Grocery List',
    icon: Icons.shopping_cart_rounded,
    description: 'Organize your shopping',
    content: 'Produce:\n'
        '- \n\n'
        'Dairy & Eggs:\n'
        '- \n\n'
        'Meat & Protein:\n'
        '- \n\n'
        'Pantry:\n'
        '- \n\n'
        'Other:\n'
        '- ',
  ),
  NoteTemplate(
    id: 'project',
    name: 'Project Planning',
    icon: Icons.assignment_rounded,
    description: 'Plan and track a project',
    content: 'Project: [Name]\n\n'
        'Goal:\n\n\n'
        'Key milestones:\n'
        '- \n'
        '- \n'
        '- \n\n'
        'Resources needed:\n'
        '- \n\n'
        'Risks:\n'
        '- \n\n'
        'Deadline: ',
  ),
  NoteTemplate(
    id: 'checklist',
    name: 'Quick Checklist',
    icon: Icons.checklist_rounded,
    description: 'Simple task checklist',
    content: '[Checklist Title]\n\n'
        '- \n'
        '- \n'
        '- \n'
        '- \n'
        '- ',
  ),
];
