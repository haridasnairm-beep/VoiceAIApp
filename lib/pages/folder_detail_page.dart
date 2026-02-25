import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';

class FolderDetailPage extends StatelessWidget {
  const FolderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.recording),
        icon: Icon(Icons.mic_rounded,
            color: Theme.of(context).colorScheme.onPrimary),
        label: Text("Record Note",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                      bottom:
                          BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: Theme.of(context).colorScheme.onSurface,
                          onPressed: () => context.pop(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.search_rounded),
                              color: Theme.of(context).colorScheme.onSurface,
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded),
                              color: Theme.of(context).colorScheme.onSurface,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Project Alpha",
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "8 voice notes • Created Oct 12",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(
                          child: _StatChip(
                            icon: Icons.mic_rounded,
                            color: AppColors.lightPrimary,
                            value: "14m",
                            label: "Total Audio",
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.checklist_rounded,
                            color: AppColors.lightSuccess,
                            value: "12",
                            label: "Open Tasks",
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatChip(
                            icon: Icons.lightbulb_rounded,
                            color: AppColors.lightAccent,
                            value: "5",
                            label: "AI Insights",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // AI Summary
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFF1F8E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "AI Project Summary",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Most notes focus on the frontend migration and API documentation. Next steps involve finalizing the schema by Friday.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),

              // Recent Notes Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Notes",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.sort_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          "Newest",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _FolderNoteCard(
                      title: "UI Design Review",
                      lang: "English",
                      preview:
                          "We discussed the warm color palette and the need for softer rounded corners in the recording screen...",
                      hasTasks: true,
                      taskCount: "4",
                      hasReminders: true,
                      reminderCount: "1",
                      date: "2 hours ago",
                      onTap: () => context.push(AppRoutes.noteDetail),
                    ),
                    _FolderNoteCard(
                      title: "Reunión de Backend",
                      lang: "Spanish",
                      preview:
                          "Discutimos la migración de la base de datos y cómo manejar los archivos de audio de gran tamaño...",
                      hasTasks: true,
                      taskCount: "2",
                      hasReminders: false,
                      reminderCount: "0",
                      date: "Yesterday",
                      onTap: () => context.push(AppRoutes.noteDetail),
                    ),
                    _FolderNoteCard(
                      title: "Sprint Planning Notes",
                      lang: "English",
                      preview:
                          "Key objectives for the next two weeks include finishing the transcription engine and testing...",
                      hasTasks: true,
                      taskCount: "6",
                      hasReminders: true,
                      reminderCount: "2",
                      date: "Oct 24",
                      onTap: () => context.push(AppRoutes.noteDetail),
                    ),
                    _FolderNoteCard(
                      title: "Marketing Brainstorm",
                      lang: "English",
                      preview:
                          "Potential taglines: 'Speak your mind, we'll do the rest.' Focus on the voice-first experience...",
                      hasTasks: false,
                      taskCount: "0",
                      hasReminders: false,
                      reminderCount: "0",
                      date: "Oct 22",
                      onTap: () => context.push(AppRoutes.noteDetail),
                    ),
                    _FolderNoteCard(
                      title: "Client Feedback - Session 1",
                      lang: "French",
                      preview:
                          "Le client souhaite une interface plus simple pour les utilisateurs âgés...",
                      hasTasks: true,
                      taskCount: "1",
                      hasReminders: true,
                      reminderCount: "1",
                      date: "Oct 20",
                      onTap: () => context.push(AppRoutes.noteDetail),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FolderNoteCard extends StatelessWidget {
  final String title;
  final String lang;
  final String preview;
  final bool hasTasks;
  final String taskCount;
  final bool hasReminders;
  final String reminderCount;
  final String date;
  final VoidCallback? onTap;

  const _FolderNoteCard({
    required this.title,
    required this.lang,
    required this.preview,
    required this.hasTasks,
    required this.taskCount,
    required this.hasReminders,
    required this.reminderCount,
    required this.date,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language,
                          size: 12,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        lang,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (hasTasks)
                      Row(
                        children: [
                          const Icon(Icons.task_alt_rounded,
                              size: 16, color: AppColors.lightSuccess),
                          const SizedBox(width: 4),
                          Text(
                            taskCount,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    if (hasReminders)
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              size: 16, color: AppColors.lightAccent),
                          const SizedBox(width: 4),
                          Text(
                            reminderCount,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
                Text(
                  date,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
