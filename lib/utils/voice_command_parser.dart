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

  /// Task type detected from command: 'todo', 'action', or 'reminder'.
  final String? taskType;

  /// Description for the task item (first 30 chars of note content).
  final String? taskDescription;

  const VoiceCommandResult({
    this.folderName,
    this.projectName,
    required this.noteContent,
    required this.hasCommand,
    this.taskType,
    this.taskDescription,
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
  static const _todoKeyword = 'todo';
  static const _actionKeyword = 'action';
  static const _reminderKeyword = 'reminder';

  /// Task keyword set for quick lookup.
  static const _taskKeywords = {_todoKeyword, _actionKeyword, _reminderKeyword};

  /// Normalize common multi-word/hyphenated transcription variants into
  /// single keywords before splitting.
  static String _normalizeTaskKeywords(String text) {
    // "to do" / "To Do" / "TO DO" → "todo"
    // "to-do" / "To-Do" → "todo"
    return text
        .replaceAllMapped(
          RegExp(r'\bto[\s-]+do\b', caseSensitive: false),
          (m) => 'todo',
        );
  }

  /// Parse transcription text for voice commands.
  static VoiceCommandResult parse(String transcription) {
    final text = _normalizeTaskKeywords(transcription.trim());
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

    // Find "start" keyword position
    final startIndex = lowerWords.indexOf(_startKeyword);

    // Find first task keyword position
    int taskIndex = -1;
    String? taskType;
    for (var i = 0; i < lowerWords.length; i++) {
      if (_taskKeywords.contains(lowerWords[i])) {
        taskIndex = i;
        taskType = lowerWords[i];
        break;
      }
    }

    // Determine the content delimiter: "Start" takes priority if it exists,
    // otherwise the task keyword acts as the delimiter.
    final hasStart = startIndex >= 0;
    final hasTask = taskIndex >= 0;

    if (!hasStart && !hasTask) {
      // No command keywords at all — return full text as-is
      return VoiceCommandResult(
        noteContent: text,
        hasCommand: false,
      );
    }

    // Determine where content begins:
    // - If "Start" exists, content is after "Start"
    // - If only task keyword exists (no "Start"), content is after the task keyword
    int contentDelimiterIndex;
    if (hasStart) {
      contentDelimiterIndex = startIndex;
    } else {
      contentDelimiterIndex = taskIndex;
    }

    // Extract content after the delimiter
    final contentWords = words.sublist(contentDelimiterIndex + 1);
    final noteContent = contentWords.join(' ').trim();

    // Parse the prefix (everything before the delimiter) for folder/project/task
    final prefixEnd = contentDelimiterIndex;
    final prefixLower = lowerWords.sublist(0, prefixEnd);
    final prefixOriginal = words.sublist(0, prefixEnd);

    String? folderName;
    String? projectName;

    // If task keyword is in the prefix (before "Start"), detect it there
    if (hasStart && hasTask && taskIndex < startIndex) {
      // Task keyword is in the prefix — already detected above
    } else if (hasStart && hasTask && taskIndex >= startIndex) {
      // Task keyword is after "Start" — not a command, ignore it
      taskType = null;
    }
    // If !hasStart && hasTask: task keyword IS the delimiter, already handled

    // Collect keyword positions in the prefix (folder/project only)
    final keywordPositions = <int, String>{}; // index -> keyword type
    for (var i = 0; i < prefixLower.length; i++) {
      if (prefixLower[i] == _folderKeyword) {
        keywordPositions[i] = _folderKeyword;
      } else if (prefixLower[i] == _projectKeyword) {
        keywordPositions[i] = _projectKeyword;
      }
    }

    if (keywordPositions.isEmpty && taskType == null) {
      // "Start" found but no folder/project/task keywords — just strip the prefix
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

      // Name extends from pos+1 to the next keyword or task keyword or end of prefix
      int nameEnd;
      if (k + 1 < sortedPositions.length) {
        nameEnd = sortedPositions[k + 1];
      } else if (hasTask && taskIndex < prefixEnd) {
        // Task keyword is in the prefix — names stop before it
        nameEnd = taskIndex;
      } else {
        nameEnd = prefixOriginal.length;
      }

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

    // Build task description from note content (first 30 chars)
    String? taskDescription;
    if (taskType != null && noteContent.isNotEmpty) {
      taskDescription = noteContent.length > 30
          ? noteContent.substring(0, 30)
          : noteContent;
    }

    return VoiceCommandResult(
      folderName: folderName,
      projectName: projectName,
      noteContent: noteContent,
      hasCommand: true,
      taskType: taskType,
      taskDescription: taskDescription,
    );
  }
}
