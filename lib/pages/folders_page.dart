import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Library",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            "Smart organized by AI",
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: Icon(Icons.search_rounded,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Smart Topics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Smart Topics",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      TextButton(
                        onPressed: () {},
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: const [
                        _TopicChip(
                            label: "Project Alpha",
                            dotColor: AppColors.lightAccent),
                        SizedBox(width: 8),
                        _TopicChip(
                            label: "Grocery Lists",
                            dotColor: AppColors.lightSuccess),
                        SizedBox(width: 8),
                        _TopicChip(
                            label: "Client Meetings",
                            dotColor: AppColors.lightPrimary),
                        SizedBox(width: 8),
                        _TopicChip(
                            label: "Personal Ideas",
                            dotColor: Color(0xFFFF9800)),
                        SizedBox(width: 8),
                        _TopicChip(
                            label: "Study Notes", dotColor: Color(0xFF9C27B0)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Folders List
                  Text(
                    "Folders",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _FolderCard(
                    title: "Work Brainstorming",
                    count: 12,
                    lastActive: "2h ago",
                    hasUpdate: true,
                    icon: Icons.folder_rounded,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1E88E5),
                    onTap: () => context.push(AppRoutes.folderDetail),
                  ),
                  _FolderCard(
                    title: "Daily Reflections",
                    count: 45,
                    lastActive: "Yesterday",
                    hasUpdate: true,
                    icon: Icons.auto_awesome_rounded,
                    iconBg: const Color(0xFFF1F8E9),
                    iconColor: const Color(0xFF43A047),
                    onTap: () => context.push(AppRoutes.folderDetail),
                  ),
                  _FolderCard(
                    title: "Language Practice",
                    count: 8,
                    lastActive: "3 days ago",
                    hasUpdate: false,
                    icon: Icons.translate_rounded,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFB8C00),
                    onTap: () => context.push(AppRoutes.folderDetail),
                  ),
                  _FolderCard(
                    title: "Uncategorized",
                    count: 4,
                    lastActive: "",
                    hasUpdate: false,
                    icon: Icons.inventory_2_rounded,
                    iconBg: const Color(0xFFF5F5F5),
                    iconColor: const Color(0xFF757575),
                    onTap: () => context.push(AppRoutes.folderDetail),
                  ),
                  const SizedBox(height: 24),

                  // AI Tip
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(Icons.lightbulb_rounded,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Organization Tip",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "You can ask 'Group all notes about the garden project' to create a new folder instantly.",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

            // FAB
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FloatingActionButton.extended(
                  onPressed: () {},
                  icon: Icon(Icons.create_new_folder_rounded,
                      color: Theme.of(context).colorScheme.onSurface),
                  label: Text("New Folder",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "$count notes",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      if (hasUpdate) ...[
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
                                color: Theme.of(context).colorScheme.secondary,
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
