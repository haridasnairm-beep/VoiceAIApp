import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../widgets/speed_dial_fab.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final projects = ref.watch(projectDocumentsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'VoiceNotes AI',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Bar
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Theme.of(context).hintColor, size: 22),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Search your notes...",
                              style:
                                  TextStyle(color: Theme.of(context).hintColor),
                            ),
                          ),
                          Icon(Icons.tune,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryCard(
                          icon: Icons.description,
                          title: "All Notes",
                          subtitle: "${notes.length} items",
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          iconColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 16),
                        _CategoryCard(
                          icon: Icons.folder_rounded,
                          title: "Folders",
                          subtitle: "${folders.length} items",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          hasBorder: true,
                          onTap: () => context.push(AppRoutes.folders),
                        ),
                        const SizedBox(width: 16),
                        _CategoryCard(
                          icon: Icons.article_rounded,
                          title: "Projects",
                          subtitle: "${projects.length} items",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          iconColor: const Color(0xFF8E24AA),
                          hasBorder: true,
                          onTap: () => context.push(AppRoutes.folders),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recent Notes Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Notes",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.search),
                        child: Text(
                          "See All",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes List or Empty State
                  if (notes.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...notes.map((note) => _NoteCard(
                          title: note.title,
                          timestamp: _formatDate(note.createdAt),
                          lang: note.detectedLanguage,
                          icon: Icons.mic_rounded,
                          iconBg: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1E88E5),
                          preview: note.rawTranscription.length > 100
                              ? note.rawTranscription.substring(0, 100)
                              : note.rawTranscription,
                          hasTodo: note.todos.isNotEmpty,
                          hasAction: note.actions.isNotEmpty,
                          hasReminder: note.reminders.isNotEmpty,
                          isProcessed: note.isProcessed,
                          audioDurationSeconds: note.audioDurationSeconds,
                          createdAt: note.createdAt,
                          onTap: () => context.push(
                            AppRoutes.noteDetail,
                            extra: {'noteId': note.id},
                          ),
                        )),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Speed Dial FAB
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SpeedDialFab(
                  items: [
                    SpeedDialItem(
                      icon: Icons.mic_rounded,
                      label: 'Record Note',
                      onTap: () => context.push(AppRoutes.recording),
                    ),
                    SpeedDialItem(
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Folder',
                      onTap: () => _showNewFolderDialog(context, ref),
                    ),
                    SpeedDialItem(
                      icon: Icons.article_rounded,
                      label: 'New Project',
                      onTap: () => _showNewProjectDialog(context, ref),
                    ),
                    SpeedDialItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      onTap: () => context.push(AppRoutes.search),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No notes yet",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the record button to create\nyour first voice note",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(foldersProvider.notifier).addFolder(name: name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showNewProjectDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Project title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final desc = descController.text.trim();
                ref.read(projectDocumentsProvider.notifier).create(
                      title: title,
                      description: desc.isEmpty ? null : desc,
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final noteDay = DateTime(date.year, date.month, date.day);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (noteDay == today) {
      return 'Today, $time';
    } else if (noteDay == yesterday) {
      return 'Yesterday, $time';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      return '$month $day';
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final bool hasBorder;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    this.hasBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        constraints: const BoxConstraints(minWidth: 140),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: hasBorder
              ? Border.all(color: Theme.of(context).dividerColor)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final String title;
  final String timestamp;
  final String lang;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String preview;
  final bool hasTodo;
  final bool hasAction;
  final bool hasReminder;
  final bool isProcessed;
  final int audioDurationSeconds;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const _NoteCard({
    required this.title,
    required this.timestamp,
    required this.lang,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.preview,
    required this.hasTodo,
    required this.hasAction,
    required this.hasReminder,
    this.isProcessed = true,
    this.audioDurationSeconds = 0,
    required this.createdAt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Center(
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timestamp,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                _NoteTag(
                  label: lang,
                  bg: Theme.of(context).scaffoldBackgroundColor,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isProcessed)
              _TranscribingProgress(
                audioDurationSeconds: audioDurationSeconds,
                createdAt: createdAt,
              )
            else
              Text(
                preview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (hasTodo || hasAction || hasReminder) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (hasTodo)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: const _NoteTag(
                        label: "Todo",
                        bg: Color(0xFFE3F2FD),
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  if (hasAction)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: const _NoteTag(
                        label: "Action",
                        bg: Color(0xFFE8F5E9),
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  if (hasReminder)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: const _NoteTag(
                        label: "Reminder",
                        bg: Color(0xFFFFF3E0),
                        color: Color(0xFFEF6C00),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TranscribingProgress extends StatefulWidget {
  final int audioDurationSeconds;
  final DateTime createdAt;

  const _TranscribingProgress({
    required this.audioDurationSeconds,
    required this.createdAt,
  });

  @override
  State<_TranscribingProgress> createState() => _TranscribingProgressState();
}

class _TranscribingProgressState extends State<_TranscribingProgress> {
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateProgress();
    });
  }

  void _updateProgress() {
    // Estimate: ~1.2x realtime, minimum 5 seconds
    final estimatedSeconds =
        (widget.audioDurationSeconds * 1.2).clamp(5.0, double.infinity);
    final elapsed =
        DateTime.now().difference(widget.createdAt).inSeconds.toDouble();
    setState(() {
      _progress = (elapsed / estimatedSeconds).clamp(0.0, 0.95);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Transcribing... $percent%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: 0.1),
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

class _NoteTag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;

  const _NoteTag({
    required this.label,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
