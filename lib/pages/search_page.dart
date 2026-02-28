import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../nav.dart';
import '../theme.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../models/note.dart';

class SearchPage extends ConsumerStatefulWidget {
  /// Optional pre-selected folder ID for contextual search.
  final String? initialFolderId;

  /// Optional pre-selected project ID for contextual search.
  final String? initialProjectId;

  const SearchPage({
    super.key,
    this.initialFolderId,
    this.initialProjectId,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedFolderId;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _selectedProjectId = widget.initialProjectId;
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

    // Filter by project
    if (_selectedProjectId != null) {
      results = results
          .where((n) => n.projectDocumentIds.contains(_selectedProjectId))
          .toList();
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
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
          'Search Notes',
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
                        _selectedProjectId == null,
                    onTap: () => setState(() {
                      _selectedFolderId = null;
                      _selectedProjectId = null;
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
                            _selectedProjectId = null;
                          }),
                        ),
                      )),
                  // Project chips
                  ...projects.map((project) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          label: project.title,
                          icon: Icons.article_rounded,
                          selected: _selectedProjectId == project.id,
                          onTap: () => setState(() {
                            _selectedProjectId =
                                _selectedProjectId == project.id
                                    ? null
                                    : project.id;
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
              child: _buildResultsBody(context, allNotes, results),
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

  Widget _buildResultsBody(
      BuildContext context, List<Note> allNotes, List<Note> results) {
    if (allNotes.isEmpty) {
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
                "No notes yet. Record your first voice note!",
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

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  color: Theme.of(context).hintColor, size: 48),
              const SizedBox(height: 16),
              Text(
                _query.isNotEmpty
                    ? "No notes found for '$_query'"
                    : "No notes in this filter",
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

    final countLabel = _query.isEmpty
        ? "Found ${results.length} notes"
        : "Found ${results.length} notes matching '$_query'";

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          countLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
        const SizedBox(height: 12),
        ...results.map((note) {
          String rawText = note.rawTranscription;
          if (note.contentFormat == 'quill_delta' && rawText.isNotEmpty) {
            try {
              final json = jsonDecode(rawText) as List;
              rawText = Document.fromJson(json).toPlainText().trim();
            } catch (_) {}
          }
          final preview = rawText.length > 100 ? rawText.substring(0, 100) : rawText;
          return _SearchResultCard(
            title: note.title,
            lang: note.detectedLanguage,
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
        if (results.isNotEmpty)
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
