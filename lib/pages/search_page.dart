import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Search Input
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: Theme.of(context).colorScheme.onSurface,
                            onPressed: () => context.pop(),
                          ),
                          Text(
                            "Search Notes",
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune_rounded),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
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
                            Icon(Icons.search_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 22),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      "Search keywords, topics, or people...",
                                  hintStyle: TextStyle(
                                      color: Theme.of(context).hintColor),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.mic_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 22),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: const [
                      _FilterChip(
                        label: "All Results",
                        selected: true,
                        hasIcon: false,
                        icon: Icons.check, // Dummy
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: "Tasks",
                        selected: false,
                        hasIcon: true,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: "English",
                        selected: false,
                        hasIcon: true,
                        icon: Icons.translate_rounded,
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: "Last 7 Days",
                        selected: false,
                        hasIcon: true,
                        icon: Icons.calendar_today_rounded,
                      ),
                      SizedBox(width: 8),
                      _FilterChip(
                        label: "Project Alpha",
                        selected: false,
                        hasIcon: true,
                        icon: Icons.folder_open_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, indent: 24, endIndent: 24),

                // Results List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        "Found 12 notes matching 'Project'",
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _SearchResultCard(
                        title: "Project Alpha: Kickoff Meeting",
                        lang: "English",
                        preview:
                            "We discussed the main milestones for Q4. Sarah is responsible for the UI mockups while Jim handles the backend...",
                        catLabel: "MEETING",
                        catIcon: Icons.groups_rounded,
                        catBg: const Color(0xFFE3F2FD),
                        catColor: const Color(0xFF1976D2),
                        date: "Oct 24, 10:30 AM",
                        onTap: () => context.push(AppRoutes.noteDetail),
                      ),
                      _SearchResultCard(
                        title: "Ideas for Project Website",
                        lang: "Spanish",
                        preview:
                            "Necesitamos un diseño más limpio y minimalista. Considerar el uso de animaciones Lottie para el hero section...",
                        catLabel: "GENERAL",
                        catIcon: Icons.lightbulb_outline_rounded,
                        catBg: const Color(0xFFF3E5F5),
                        catColor: const Color(0xFF7B1FA2),
                        date: "Oct 22, 4:15 PM",
                        onTap: () => context.push(AppRoutes.noteDetail),
                      ),
                      _SearchResultCard(
                        title: "Project Alpha: Task List",
                        lang: "English",
                        preview:
                            "1. Update the dependency list. 2. Schedule the demo with stakeholders. 3. Review the budget for 2024...",
                        catLabel: "TODO",
                        catIcon: Icons.task_alt_rounded,
                        catBg: const Color(0xFFE8F5E9),
                        catColor: const Color(0xFF388E3C),
                        date: "Oct 21, 9:00 AM",
                        onTap: () => context.push(AppRoutes.noteDetail),
                      ),
                      _SearchResultCard(
                        title: "Project Budget Discussion",
                        lang: "German",
                        preview:
                            "Das Budget für das nächste Quartal wurde genehmigt. Wir müssen die Hardware-Kosten bis Freitag einreichen...",
                        catLabel: "ACTION",
                        catIcon: Icons.flash_on_rounded,
                        catBg: const Color(0xFFFFF3E0),
                        catColor: const Color(0xFFF57C00),
                        date: "Oct 19, 2:45 PM",
                        onTap: () => context.push(AppRoutes.noteDetail),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Theme.of(context).hintColor, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              "End of search results",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),

            // Floating Mic Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded, size: 32),
                  color: Theme.of(context).colorScheme.onPrimary,
                  onPressed: () => context.push(AppRoutes.recording),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool hasIcon;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.hasIcon,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.surface;
    final borderColor =
        selected ? theme.colorScheme.primary : theme.dividerColor;
    final textColor =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final iconColor =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIcon) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final String title;
  final String lang;
  final String preview;
  final String catLabel;
  final IconData catIcon;
  final Color catBg;
  final Color catColor;
  final String date;
  final VoidCallback? onTap;

  const _SearchResultCard({
    required this.title,
    required this.lang,
    required this.preview,
    required this.catLabel,
    required this.catIcon,
    required this.catBg,
    required this.catColor,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Icon(Icons.language_rounded,
                          size: 14,
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: catBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(catIcon, size: 14, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            catLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
