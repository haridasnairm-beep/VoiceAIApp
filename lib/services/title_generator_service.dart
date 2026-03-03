/// Pure Dart utility for generating meaningful note titles from transcription
/// text using local heuristics (no AI, no cloud).
class TitleGeneratorService {
  TitleGeneratorService._();

  static const int _maxLength = 60;

  /// Filler phrases to strip from the beginning of sentences.
  static final _fillerPhrases = RegExp(
    r'^(so|okay|ok|um|uh|like|you know|I was thinking|'
    r'remind me to|I need to|let me|basically|actually|'
    r'well|alright|right|hey|hi|hello|oh|ah|hmm|'
    r'I want to|I wanted to|can you|could you|please)\b\s*',
    caseSensitive: false,
  );

  /// Trailing conjunctions to remove.
  static final _trailingConjunctions = RegExp(
    r'\s+(and|but|or|so|because|since|while|although|however)\s*$',
    caseSensitive: false,
  );

  /// Generate a meaningful title from transcription text.
  ///
  /// Returns null if no good title could be generated (caller should keep
  /// the existing prefix-based title like VOICE001).
  static String? generate(
    String transcription, {
    List<String>? todos,
    List<String>? actions,
    List<String>? reminders,
  }) {
    if (transcription.isEmpty) return null;

    // Step 1: Try extracting from transcription text
    final fromText = _extractFromText(transcription);
    if (fromText != null) return fromText;

    // Step 2: Fallback to task-based titles
    if (todos != null && todos.isNotEmpty) {
      return _truncate('Tasks: ${todos.first}');
    }
    if (reminders != null && reminders.isNotEmpty) {
      return _truncate('Reminder: ${reminders.first}');
    }
    if (actions != null && actions.isNotEmpty) {
      return _truncate('Action: ${actions.first}');
    }

    // Step 3: No good title found — return null (keep prefix title)
    return null;
  }

  /// Try to extract a meaningful title from raw transcription text.
  static String? _extractFromText(String text) {
    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]+'));

    String? bestShort; // Fallback: best short sentence (1-2 words after cleaning)

    for (var sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.isEmpty) continue;

      // Strip filler phrases (repeatedly, in case of stacked fillers)
      var cleaned = sentence;
      String previous;
      do {
        previous = cleaned;
        cleaned = cleaned.replaceFirst(_fillerPhrases, '').trim();
      } while (cleaned != previous && cleaned.isNotEmpty);

      if (cleaned.isEmpty) continue;

      // Check if remaining sentence has enough substance (> 2 words)
      final words = cleaned.split(RegExp(r'\s+'));
      if (words.length <= 2) {
        // Keep as fallback if nothing better is found
        bestShort ??= cleaned;
        continue;
      }

      // Good sentence found — clean and truncate
      return _truncate(_capitalize(cleaned));
    }

    // Fallback: if no 3+ word sentence found, try the raw first sentence
    // (useful for non-English text where filler stripping doesn't apply)
    if (bestShort == null) {
      final firstSentence = sentences.firstWhere(
        (s) => s.trim().isNotEmpty,
        orElse: () => '',
      ).trim();
      if (firstSentence.isNotEmpty && firstSentence.split(RegExp(r'\s+')).length > 1) {
        return _truncate(_capitalize(firstSentence));
      }
    }

    return null;
  }

  /// Truncate text at word boundary and add "..." if needed.
  static String _truncate(String text) {
    // Remove trailing conjunctions
    text = text.replaceFirst(_trailingConjunctions, '').trim();

    if (text.length <= _maxLength) {
      return _capitalize(text);
    }

    // Find last space before max length
    final sub = text.substring(0, _maxLength);
    final lastSpace = sub.lastIndexOf(' ');
    if (lastSpace > 20) {
      return '${_capitalize(sub.substring(0, lastSpace))}...';
    }
    return '${_capitalize(sub)}...';
  }

  /// Capitalize the first letter.
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
