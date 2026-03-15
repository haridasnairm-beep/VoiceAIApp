import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/project_documents_provider.dart';
import '../models/note.dart';
import '../models/project_document.dart';
import '../models/project_block.dart';
import '../widgets/settings_widgets.dart' show friendlyLanguageName;
import '../utils/responsive.dart';
import '../widgets/empty_state_illustrated.dart';

class SearchPage extends ConsumerStatefulWidget {
  /// Optional pre-selected folder ID for contextual search.
  final String? initialFolderId;

  const SearchPage({
    super.key,
    this.initialFolderId,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedFolderId;
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);

    if (noteDate == today) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  List<Note> _getFilteredResults() {
    final allNotes = ref.read(notesProvider);
    List<Note> results = _query.isEmpty
        ? allNotes
        : ref.read(notesProvider.notifier).searchNotes(_query);

    // Filter by folder
    if (_selectedFolderId != null) {
      final folders = ref.read(foldersProvider);
      final folder = folders.where((f) => f.id == _selectedFolderId).firstOrNull;
      if (folder != null) {
        final noteIds = folder.noteIds.toSet();
        results = results.where((n) => noteIds.contains(n.id)).toList();
      }
    }

    // Filter by tag
    if (_selectedTag != null) {
      results = results
          .where((n) => n.tags.contains(_selectedTag))
          .toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final tags = ref.watch(tagNamesProvider);
    final projects = ref.watch(projectDocumentsProvider);
    final results = _getFilteredResults();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Search',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border:
                      Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() => _query = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search keywords, topics...',
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.close_rounded,
                            color: Theme.of(context).hintColor, size: 20),
                      ),
                  ],
                ),
              ),
            ),

            // Filter chips: All, Folders, Projects
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // "All" chip
                  _buildFilterChip(
                    label: 'All',
                    selected: _selectedFolderId == null &&
                        _selectedTag == null,
                    onTap: () => setState(() {
                      _selectedFolderId = null;
                      _selectedTag = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  // Folder chips
                  ...folders.map((folder) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: folder.name,
                          icon: Icons.folder_rounded,
                          selected: _selectedFolderId == folder.id,
                          onTap: () => setState(() {
                            _selectedFolderId =
                                _selectedFolderId == folder.id
                                    ? null
                                    : folder.id;
                            _selectedTag = null;
                          }),
                        ),
                      )),
                  // Tag chips
                  ...tags.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: '#$tag',
                          icon: Icons.label_rounded,
                          selected: _selectedTag == tag,
                          onTap: () => setState(() {
                            _selectedTag =
                                _selectedTag == tag ? null : tag;
                            _selectedFolderId = null;
                          }),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, indent: 20, endIndent: 20),

            // Results
            Expanded(
              child: _buildResultsBody(context, allNotes, results, projects),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.secondary),
              const SizedBox(width: 4),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _plainText(Note note) {
    String rawText = note.rawTranscription;
    if (note.contentFormat == 'quill_delta' && rawText.isNotEmpty) {
      try {
        final json = jsonDecode(rawText) as List;
        rawText = Document.fromJson(json).toPlainText().trim();
      } catch (_) {}
    }
    return rawText;
  }

  /// Extract plain text from a project block's content (handles quill_delta).
  String _blockPlainText(ProjectBlock block) {
    final content = block.content ?? '';
    if (content.isEmpty) return '';
    if (block.contentFormat == 'quill_delta') {
      try {
        final json = jsonDecode(content) as List;
        return Document.fromJson(json).toPlainText().trim();
      } catch (_) {}
    }
    return content;
  }

  /// Search projects by title, description, section headers, and free text blocks.
  List<ProjectDocument> _searchProjects(List<ProjectDocument> projects) {
    if (_query.isEmpty) return projects;
    final lower = _query.toLowerCase();
    return projects.where((p) {
      if (p.title.toLowerCase().contains(lower)) return true;
      if (p.description != null &&
          p.description!.toLowerCase().contains(lower)) return true;
      for (final block in p.blocks) {
        if (block.type == BlockType.sectionHeader ||
            block.type == BlockType.freeText) {
          if (_blockPlainText(block).toLowerCase().contains(lower)) return true;
        }
      }
      return false;
    }).toList();
  }

  Widget _buildResultsBody(
      BuildContext context, List<Note> allNotes, List<Note> results,
      List<ProjectDocument> projects) {
    if (allNotes.isEmpty && projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_none_rounded,
                  color: Theme.of(context).hintColor, size: 48),
              const SizedBox(height: 16),
              Text(
                "No notes or projects yet. Record your first voice note!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Check if there are any project matches too before showing empty state
    final projectResults = _searchProjects(projects);
    if (results.isEmpty && projectResults.isEmpty) {
      return Center(
        child: EmptyStateIllustrated(
          icon: Icons.search_off_rounded,
          title: _query.isNotEmpty
              ? "No results for '$_query'"
              : 'No notes in this filter',
          subtitle:
              'Try different keywords or search across\nnotes, projects, tasks, and reminders',
          iconColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    // When no query, show flat note + project list (no sectioning needed)
    if (_query.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
          vertical: 20,
        ),
        children: [
          Text(
            "${results.length} notes · ${projects.length} projects",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          const SizedBox(height: 12),
          ...results.map((note) {
            final rawText = _plainText(note);
            final preview =
                rawText.length > 100 ? rawText.substring(0, 100) : rawText;
            return _SearchResultCard(
              title: note.title,
              lang: friendlyLanguageName(note.detectedLanguage),
              preview: preview,
              catLabel: "NOTE",
              catIcon: Icons.description_rounded,
              catBg: const Color(0xFFE3F2FD),
              catColor: const Color(0xFF1976D2),
              date: _formatDate(note.createdAt),
              onTap: () => context.push(AppRoutes.noteDetail,
                  extra: {'noteId': note.id}),
            );
          }),
          ...projects.map((project) {
            final blockTexts = project.blocks
                .where((b) =>
                    b.type == BlockType.sectionHeader ||
                    b.type == BlockType.freeText)
                .map((b) => _blockPlainText(b))
                .where((t) => t.isNotEmpty)
                .take(2)
                .join(' · ');
            final preview = project.description?.isNotEmpty == true
                ? project.description!
                : blockTexts;
            return _SearchResultCard(
              title: project.title,
              lang: '${project.blocks.length} blocks',
              preview: preview.length > 100
                  ? preview.substring(0, 100)
                  : preview,
              catLabel: "PROJECT",
              catIcon: Icons.article_rounded,
              catBg: const Color(0xFFF3E5F5),
              catColor: const Color(0xFF7B1FA2),
              date: _formatDate(project.createdAt),
              onTap: () => context.push(AppRoutes.projectDocumentDetail,
                  extra: {'documentId': project.id}),
            );
          }),
        ],
      );
    }

    // Sectioned results: categorize matches
    final lower = _query.toLowerCase();

    // Notes section: title or transcription match
    final noteMatches = results.where((n) =>
        n.title.toLowerCase().contains(lower) ||
        _plainText(n).toLowerCase().contains(lower) ||
        n.topics.any((t) => t.toLowerCase().contains(lower)));

    // Projects section: reuse pre-computed results
    final projectMatches = projectResults;

    // Action items section
    final actionMatches = <({Note note, String text})>[];
    for (final n in results) {
      for (final a in n.actions) {
        if (a.text.toLowerCase().contains(lower)) {
          actionMatches.add((note: n, text: a.text));
        }
      }
    }

    // Todos section
    final todoMatches = <({Note note, String text, bool done})>[];
    for (final n in results) {
      for (final t in n.todos) {
        if (t.text.toLowerCase().contains(lower)) {
          todoMatches.add((note: n, text: t.text, done: t.isCompleted));
        }
      }
    }

    // Reminders section
    final reminderMatches =
        <({Note note, String text, DateTime? time})>[];
    for (final n in results) {
      for (final r in n.reminders) {
        if (r.text.toLowerCase().contains(lower)) {
          reminderMatches
              .add((note: n, text: r.text, time: r.reminderTime));
        }
      }
    }

    final totalCount = noteMatches.length +
        projectMatches.length +
        actionMatches.length +
        todoMatches.length +
        reminderMatches.length;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 20,
      ),
      children: [
        Text(
          "$totalCount results for '$_query'",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
        const SizedBox(height: 12),

        // Notes section
        if (noteMatches.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.description_rounded,
            label: 'Notes',
            count: noteMatches.length,
            color: const Color(0xFF1976D2),
          ),
          const SizedBox(height: 8),
          ...noteMatches.map((note) {
            final rawText = _plainText(note);
            final preview =
                rawText.length > 100 ? rawText.substring(0, 100) : rawText;
            return _SearchResultCard(
              title: note.title,
              lang: friendlyLanguageName(note.detectedLanguage),
              preview: preview,
              catLabel: "NOTE",
              catIcon: Icons.description_rounded,
              catBg: const Color(0xFFE3F2FD),
              catColor: const Color(0xFF1976D2),
              date: _formatDate(note.createdAt),
              onTap: () => context.push(AppRoutes.noteDetail,
                  extra: {'noteId': note.id}),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Projects section
        if (projectMatches.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.article_rounded,
            label: 'Projects',
            count: projectMatches.length,
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(height: 8),
          ...projectMatches.map((project) {
            // Build preview from matching blocks
            final matchingBlocks = project.blocks
                .where((b) =>
                    b.type == BlockType.sectionHeader ||
                    b.type == BlockType.freeText)
                .map((b) => _blockPlainText(b))
                .where((t) => t.toLowerCase().contains(lower))
                .take(2)
                .join(' · ');
            final preview = matchingBlocks.isNotEmpty
                ? matchingBlocks
                : (project.description?.isNotEmpty == true
                    ? project.description!
                    : '${project.blocks.length} blocks');
            return _SearchResultCard(
              title: project.title,
              lang: '${project.blocks.length} blocks',
              preview: preview.length > 100
                  ? preview.substring(0, 100)
                  : preview,
              catLabel: "PROJECT",
              catIcon: Icons.article_rounded,
              catBg: const Color(0xFFF3E5F5),
              catColor: const Color(0xFF7B1FA2),
              date: _formatDate(project.createdAt),
              onTap: () => context.push(AppRoutes.projectDocumentDetail,
                  extra: {'documentId': project.id}),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Actions section
        if (actionMatches.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.flash_on_rounded,
            label: 'Action Items',
            count: actionMatches.length,
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 8),
          ...actionMatches.map((m) => _SearchResultCard(
                title: m.text,
                lang: friendlyLanguageName(m.note.detectedLanguage),
                preview: 'From: ${m.note.title}',
                catLabel: "ACTION",
                catIcon: Icons.flash_on_rounded,
                catBg: const Color(0xFFE8F5E9),
                catColor: const Color(0xFF2E7D32),
                date: _formatDate(m.note.createdAt),
                onTap: () => context.push(AppRoutes.noteDetail,
                    extra: {'noteId': m.note.id}),
              )),
          const SizedBox(height: 8),
        ],

        // Todos section
        if (todoMatches.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.check_circle_outline_rounded,
            label: 'Todos',
            count: todoMatches.length,
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(height: 8),
          ...todoMatches.map((m) => _SearchResultCard(
                title: '${m.done ? '✓ ' : ''}${m.text}',
                lang: friendlyLanguageName(m.note.detectedLanguage),
                preview: 'From: ${m.note.title}',
                catLabel: "TODO",
                catIcon: Icons.check_circle_outline_rounded,
                catBg: const Color(0xFFE3F2FD),
                catColor: const Color(0xFF1565C0),
                date: _formatDate(m.note.createdAt),
                onTap: () => context.push(AppRoutes.noteDetail,
                    extra: {'noteId': m.note.id}),
              )),
          const SizedBox(height: 8),
        ],

        // Reminders section
        if (reminderMatches.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.alarm_rounded,
            label: 'Reminders',
            count: reminderMatches.length,
            color: const Color(0xFFEF6C00),
          ),
          const SizedBox(height: 8),
          ...reminderMatches.map((m) {
            final timeStr = m.time != null
                ? ' · ${_formatDate(m.time!)}'
                : '';
            return _SearchResultCard(
              title: m.text,
              lang: friendlyLanguageName(m.note.detectedLanguage),
              preview: 'From: ${m.note.title}$timeStr',
              catLabel: "REMINDER",
              catIcon: Icons.alarm_rounded,
              catBg: const Color(0xFFFFF3E0),
              catColor: const Color(0xFFEF6C00),
              date: _formatDate(m.note.createdAt),
              onTap: () => context.push(AppRoutes.noteDetail,
                  extra: {'noteId': m.note.id}),
            );
          }),
          const SizedBox(height: 8),
        ],

        // End marker
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Theme.of(context).hintColor, size: 32),
              const SizedBox(height: 8),
              Text(
                "End of search results",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border:
                        Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language_rounded,
                          size: 12,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 3),
                      Text(
                        lang,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              preview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: catBg,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(catIcon, size: 12, color: catColor),
                          const SizedBox(width: 3),
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
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
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
