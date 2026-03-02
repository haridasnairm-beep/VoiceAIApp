/// A privacy-first, offline profanity filter for English text.
///
/// Uses whole-word matching to avoid false positives (e.g., "class" in
/// "classification"). Replaces matched words with asterisks of the same length.
class ProfanityFilter {
  ProfanityFilter._();
  static final ProfanityFilter instance = ProfanityFilter._();

  late final RegExp _pattern = _buildPattern();

  RegExp _buildPattern() {
    // Escape any regex-special chars in words and join with alternation
    final escaped = _words.map(RegExp.escape).join('|');
    return RegExp('\\b($escaped)\\b', caseSensitive: false);
  }

  /// Filters offensive words from [text], replacing them with asterisks.
  /// Returns the filtered string. If [enabled] is false, returns [text] as-is.
  String filter(String text, {bool enabled = true}) {
    if (!enabled || text.isEmpty) return text;
    return text.replaceAllMapped(_pattern, (match) {
      return '*' * match.group(0)!.length;
    });
  }

  // Common English profanity words — kept minimal and non-explicit.
  // This list covers the most commonly encountered offensive words.
  static const _words = <String>[
    'ass',
    'asshole',
    'bastard',
    'bitch',
    'bloody',
    'bollocks',
    'bugger',
    'bullshit',
    'crap',
    'cunt',
    'damn',
    'dick',
    'douchebag',
    'fag',
    'faggot',
    'fuck',
    'fucking',
    'fucked',
    'fucker',
    'goddamn',
    'hell',
    'horseshit',
    'jackass',
    'jerk',
    'motherfucker',
    'nigga',
    'nigger',
    'piss',
    'pissed',
    'prick',
    'pussy',
    'shit',
    'shitty',
    'slut',
    'sob',
    'twat',
    'wanker',
    'whore',
    'wtf',
  ];
}
