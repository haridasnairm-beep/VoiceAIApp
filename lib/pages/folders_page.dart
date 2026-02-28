import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../models/project_block.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../widgets/speed_dial_fab.dart';

class FoldersPage extends ConsumerStatefulWidget {
  const FoldersPage({super.key});

  @override
  ConsumerState<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends ConsumerState<FoldersPage> {
  bool _foldersExpanded = true;
  bool _projectsExpanded = true;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final documents = ref.watch(projectDocumentsProvider);

    // Extract unique topics from all folders
    final allTopics = <String>{};
    for (final folder in folders) {
      allTopics.addAll(folder.topics);
    }
    final topicsList = allTopics.toList();

    // Topic chip colors cycle
    const topicColors = [
      AppColors.lightAccent,
      AppColors.lightSuccess,
      AppColors.lightPrimary,
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
    ];

    final hasContent = folders.isNotEmpty || documents.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Library',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'Folders & Projects',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.search),
            icon: Icon(Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            !hasContent
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          size: 64,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No folders or projects yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first folder or project',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Topics section
                        if (topicsList.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Topics',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push(AppRoutes.search),
                                child: Text(
                                  'See All',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int i = 0;
                                    i < topicsList.length;
                                    i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  _TopicChip(
                                    label: topicsList[i],
                                    dotColor: topicColors[
                                        i % topicColors.length],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // --- Folders Section (collapsible) ---
                        _CollapsibleHeader(
                          title: 'Folders',
                          count: folders.length,
                          expanded: _foldersExpanded,
                          onToggle: () => setState(
                              () => _foldersExpanded = !_foldersExpanded),
                        ),
                        if (_foldersExpanded) ...[
                          const SizedBox(height: 12),
                          if (folders.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No folders yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...folders.map((folder) => _FolderCard(
                                  title: folder.name,
                                  count: folder.noteIds.length,
                                  lastActive:
                                      _formatDate(folder.updatedAt),
                                  hasUpdate: true,
                                  icon: Icons.folder_rounded,
                                  iconBg: const Color(0xFFE3F2FD),
                                  iconColor: const Color(0xFF1E88E5),
                                  onTap: () => context.push(
                                    AppRoutes.folderDetail,
                                    extra: {'folderId': folder.id},
                                  ),
                                )),
                        ],

                        const SizedBox(height: 16),

                        // --- Projects Section (collapsible) ---
                        _CollapsibleHeader(
                          title: 'Projects',
                          count: documents.length,
                          expanded: _projectsExpanded,
                          onToggle: () => setState(
                              () => _projectsExpanded = !_projectsExpanded),
                        ),
                        if (_projectsExpanded) ...[
                          const SizedBox(height: 12),
                          if (documents.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No projects yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...documents.map((doc) {
                              final noteCount = doc.blocks
                                  .where((b) =>
                                      b.type == BlockType.noteReference)
                                  .length;
                              return _ProjectCard(
                                title: doc.title,
                                description: doc.description,
                                blockCount: doc.blocks.length,
                                noteCount: noteCount,
                                lastUpdated: _formatDate(doc.updatedAt),
                                onTap: () => context.push(
                                  AppRoutes.projectDocumentDetail,
                                  extra: {'documentId': doc.id},
                                ),
                                onDelete: () => _showDeleteProjectDialog(
                                    context, doc.id, doc.title),
                                onRename: () =>
                                    _showRenameProjectDialog(context, doc),
                              );
                            }),
                        ],

                        const SizedBox(height: 80),
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
                      icon: Icons.create_new_folder_rounded,
                      label: 'New Folder',
                      onTap: () => _showNewFolderDialog(context),
                    ),
                    SpeedDialItem(
                      icon: Icons.article_rounded,
                      label: 'New Project',
                      onTap: () => _showNewProjectDialog(context),
                    ),
                    SpeedDialItem(
                      icon: Icons.mic_rounded,
                      label: 'Record Note',
                      onTap: () => context.push(AppRoutes.recording),
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

  void _showNewFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
          ),
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

  void _showNewProjectDialog(BuildContext context) {
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
              decoration:
                  const InputDecoration(hintText: 'Project title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                  hintText: 'Description (optional)'),
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

  void _showRenameProjectDialog(BuildContext context, dynamic doc) {
    final controller = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project title'),
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
                doc.title = name;
                ref
                    .read(projectDocumentsProvider.notifier)
                    .updateDocument(doc);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectDialog(
      BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
            'Delete "$title"? This will not delete any linked notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectDocumentsProvider.notifier).delete(id);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// --- Collapsible Section Header ---

class _CollapsibleHeader extends StatelessWidget {
  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        children: [
          Icon(
            expanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_right_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final String label;
  final Color dotColor;

  const _TopicChip({required this.label, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String title;
  final int count;
  final String lastActive;
  final bool hasUpdate;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  const _FolderCard({
    required this.title,
    required this.count,
    required this.lastActive,
    required this.hasUpdate,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$count notes',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      if (hasUpdate && lastActive.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastActive,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final String title;
  final String? description;
  final int blockCount;
  final int noteCount;
  final String lastUpdated;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  const _ProjectCard({
    required this.title,
    this.description,
    required this.blockCount,
    required this.noteCount,
    required this.lastUpdated,
    this.onTap,
    this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Icon(Icons.article_rounded,
                    color: Color(0xFF8E24AA), size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null &&
                      description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.secondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$noteCount notes · $blockCount blocks',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lastUpdated,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'rename') onRename?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'rename', child: Text('Rename')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
              ],
              icon: Icon(Icons.more_vert,
                  color: Theme.of(context).hintColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
