/// Result of parsing a transcription for voice commands.
class VoiceCommandResult {
  /// Folder name extracted from command, or null if not specified.
  final String? folderName;

  /// Project name extracted from command, or null if not specified.
  final String? projectName;

  /// The actual note content (after "Start", or full text if no command).
  final String noteContent;

  /// True if any voice command keyword was detected and parsed.
  final bool hasCommand;

  const VoiceCommandResult({
    this.folderName,
    this.projectName,
    required this.noteContent,
    required this.hasCommand,
  });
}

/// Parses transcription text for voice command prefixes.
///
/// Supported formats (case-insensitive):
/// - "Folder <name> Project <name> Start <content>"
/// - "Folder <name> Start <content>"
/// - "Project <name> Start <content>"
/// - "Start <content>"
/// - "<content>" (no command)
///
/// "Start" is required as a delimiter. Without it, text is treated as normal.
class VoiceCommandParser {
  static const _folderKeyword = 'folder';
  static const _projectKeyword = 'project';
  static const _startKeyword = 'start';

  /// Parse transcription text for voice commands.
  static VoiceCommandResult parse(String transcription) {
    final text = transcription.trim();
    if (text.isEmpty) {
      return const VoiceCommandResult(
        noteContent: '',
        hasCommand: false,
      );
    }

    // Split into words, preserving original case for name extraction
    final words = text.split(RegExp(r'\s+'));
    // Strip trailing punctuation for keyword matching (Whisper adds periods, commas, etc.)
    final lowerWords = words
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[.,!?;:]+$'), ''))
        .toList();

    // Find "start" keyword — required for any command parsing
    final startIndex = lowerWords.indexOf(_startKeyword);
    if (startIndex < 0) {
      // No "start" keyword — return full text as-is
      return VoiceCommandResult(
        noteContent: text,
        hasCommand: false,
      );
    }

    // Extract content after "start"
    final contentWords = words.sublist(startIndex + 1);
    final noteContent = contentWords.join(' ').trim();

    // Parse the prefix (everything before "start") for folder/project names
    final prefixLower = lowerWords.sublist(0, startIndex);
    final prefixOriginal = words.sublist(0, startIndex);

    String? folderName;
    String? projectName;

    // Collect keyword positions in the prefix
    final keywordPositions = <int, String>{}; // index -> keyword type
    for (var i = 0; i < prefixLower.length; i++) {
      if (prefixLower[i] == _folderKeyword) {
        keywordPositions[i] = _folderKeyword;
      } else if (prefixLower[i] == _projectKeyword) {
        keywordPositions[i] = _projectKeyword;
      }
    }

    if (keywordPositions.isEmpty) {
      // "Start" found but no folder/project keywords — just strip the prefix
      return VoiceCommandResult(
        noteContent: noteContent,
        hasCommand: true,
      );
    }

    // Sort keyword positions
    final sortedPositions = keywordPositions.keys.toList()..sort();

    // Extract names between keywords
    for (var k = 0; k < sortedPositions.length; k++) {
      final pos = sortedPositions[k];
      final keyword = keywordPositions[pos]!;

      // Name extends from pos+1 to the next keyword (or end of prefix)
      final nameEnd = k + 1 < sortedPositions.length
          ? sortedPositions[k + 1]
          : prefixOriginal.length;

      final nameWords = prefixOriginal.sublist(pos + 1, nameEnd);
      if (nameWords.isEmpty) continue; // No name given — skip

      // Strip trailing punctuation from name words (Whisper may add periods)
      final cleanedWords = nameWords
          .map((w) => w.replaceAll(RegExp(r'[.,!?;:]+$'), ''))
          .where((w) => w.isNotEmpty)
          .toList();
      if (cleanedWords.isEmpty) continue;

      final name = cleanedWords.join(' ').trim();
      if (name.isEmpty) continue;

      if (keyword == _folderKeyword) {
        folderName = name;
      } else if (keyword == _projectKeyword) {
        projectName = name;
      }
    }

    return VoiceCommandResult(
      folderName: folderName,
      projectName: projectName,
      noteContent: noteContent,
      hasCommand: true,
    );
  }
}
