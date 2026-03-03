import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notes_provider.dart';

/// Derived provider: returns all unique tags with their note counts,
/// sorted alphabetically. Recalculates whenever notesProvider changes.
///
/// Returns a List of (tag, count) records sorted by tag name.
final tagsProvider = Provider<List<({String tag, int count})>>((ref) {
  final notes = ref.watch(notesProvider);
  final counts = <String, int>{};
  for (final note in notes) {
    for (final tag in note.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final entries = counts.entries.map((e) => (tag: e.key, count: e.value)).toList();
  entries.sort((a, b) => a.tag.compareTo(b.tag));
  return entries;
});

/// Derived provider: returns only the tag names (sorted alphabetically).
/// Useful for autocomplete pickers.
final tagNamesProvider = Provider<List<String>>((ref) {
  return ref.watch(tagsProvider).map((e) => e.tag).toList();
});
