import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                            "My Notes",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            "VoiceNotes AI",
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
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.settings),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          child: const Text("JD"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                          subtitle: "24 items",
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          iconColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 16),
                        _CategoryCard(
                          icon: Icons.star_rounded,
                          title: "Favorites",
                          subtitle: "5 items",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          iconColor: Theme.of(context).colorScheme.tertiary,
                          hasBorder: true,
                        ),
                        const SizedBox(width: 16),
                        _CategoryCard(
                          icon: Icons.folder_rounded,
                          title: "Projects",
                          subtitle: "12 items",
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          iconColor: Theme.of(context).colorScheme.secondary,
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
                        onPressed: () {}, // Maybe go to list view
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

                  // Recent Notes List
                  _NoteCard(
                    title: "Project Alpha Sync",
                    timestamp: "Today, 10:30 AM",
                    lang: "English",
                    icon: Icons.business_center,
                    iconBg: const Color(0xFFE3F2FD),
                    iconColor: const Color(0xFF1E88E5),
                    preview:
                        "Discussed the new milestones for the Q4 roadmap. Need to finalize the design system by Friday.",
                    hasTodo: true,
                    hasAction: true,
                    hasReminder: false,
                    onTap: () => context.push(AppRoutes.noteDetail),
                  ),
                  _NoteCard(
                    title: "Grocery List",
                    timestamp: "Yesterday, 6:45 PM",
                    lang: "Spanish",
                    icon: Icons.shopping_cart,
                    iconBg: const Color(0xFFF1F8E9),
                    iconColor: const Color(0xFF43A047),
                    preview:
                        "Comprar leche, huevos, pan y frutas para la semana. No olvidar las bolsas reutilizables.",
                    hasTodo: true,
                    hasAction: false,
                    hasReminder: true,
                    onTap: () => context.push(AppRoutes.noteDetail),
                  ),
                  _NoteCard(
                    title: "Ideas for Blog",
                    timestamp: "Oct 24, 2:15 PM",
                    lang: "English",
                    icon: Icons.lightbulb,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFFB8C00),
                    preview:
                        "Write about the benefits of voice-first interfaces and how AI is changing productivity tools.",
                    hasTodo: false,
                    hasAction: false,
                    hasReminder: false,
                    onTap: () => context.push(AppRoutes.noteDetail),
                  ),
                  _NoteCard(
                    title: "Meeting with Sarah",
                    timestamp: "Oct 23, 11:00 AM",
                    lang: "French",
                    icon: Icons.person,
                    iconBg: const Color(0xFFF3E5F5),
                    iconColor: const Color(0xFF8E24AA),
                    preview:
                        "Réunion pour discuter du budget marketing. Elle a suggéré d'augmenter les dépenses sur les réseaux sociaux.",
                    hasTodo: true,
                    hasAction: true,
                    hasReminder: false,
                    onTap: () => context.push(AppRoutes.noteDetail),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            // Floating Record Button
            Align(
              alignment: const Alignment(0, 0.9),
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.recording),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mic_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                    color: textColor.withOpacity(0.8),
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
                          width: 150, // Constrain width for ellipsis
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
