import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/folders_provider.dart';
import '../providers/project_documents_provider.dart';
import '../utils/voice_command_parser.dart';

/// Result of processing voice commands against existing folders/projects.
class VoiceCommandProcessResult {
  final String? folderId;
  final String? projectId;
  final List<String> tags;
  final String noteContent;
  final bool folderCreated;
  final bool projectCreated;
  final String? taskType;        // 'todo', 'action', or 'reminder'
  final String? taskDescription; // truncated description for the task item

  const VoiceCommandProcessResult({
    this.folderId,
    this.projectId,
    this.tags = const [],
    required this.noteContent,
    this.folderCreated = false,
    this.projectCreated = false,
    this.taskType,
    this.taskDescription,
  });
}

/// Processes voice command keywords by looking up or creating folders/projects.
class VoiceCommandProcessor {
  /// Parse transcription for voice commands and resolve folder/project references.
  static Future<VoiceCommandProcessResult> process(
    String transcription,
    Ref ref,
  ) async {
    final parsed = VoiceCommandParser.parse(transcription);

    if (!parsed.hasCommand) {
      return VoiceCommandProcessResult(noteContent: parsed.noteContent);
    }

    debugPrint(
        'VoiceCommand: folder="${parsed.folderName}", project="${parsed.projectName}"');

    String? folderId;
    bool folderCreated = false;

    // Lookup or create folder
    if (parsed.folderName != null) {
      folderId = _findFolderByName(ref, parsed.folderName!);
      if (folderId == null) {
        final folder = await ref
            .read(foldersProvider.notifier)
            .addFolder(name: parsed.folderName!);
        folderId = folder.id;
        folderCreated = true;
        debugPrint('VoiceCommand: created folder "${parsed.folderName}"');
      } else {
        debugPrint('VoiceCommand: matched folder "${parsed.folderName}"');
      }
    }

    String? projectId;
    bool projectCreated = false;

    // Lookup or create project
    if (parsed.projectName != null) {
      projectId = _findProjectByTitle(ref, parsed.projectName!);
      if (projectId == null) {
        final project = await ref
            .read(projectDocumentsProvider.notifier)
            .create(title: parsed.projectName!);
        projectId = project.id;
        projectCreated = true;
        debugPrint('VoiceCommand: created project "${parsed.projectName}"');
      } else {
        debugPrint('VoiceCommand: matched project "${parsed.projectName}"');
      }
    }

    return VoiceCommandProcessResult(
      folderId: folderId,
      projectId: projectId,
      tags: parsed.tagNames,
      noteContent: parsed.noteContent,
      folderCreated: folderCreated,
      projectCreated: projectCreated,
      taskType: parsed.taskType,
      taskDescription: parsed.taskDescription,
    );
  }

  /// Case-insensitive folder name lookup.
  static String? _findFolderByName(Ref ref, String name) {
    final folders = ref.read(foldersProvider);
    final lower = name.toLowerCase();
    for (final folder in folders) {
      if (folder.name.toLowerCase() == lower) return folder.id;
    }
    return null;
  }

  /// Case-insensitive project title lookup.
  static String? _findProjectByTitle(Ref ref, String title) {
    final projects = ref.read(projectDocumentsProvider);
    final lower = title.toLowerCase();
    for (final project in projects) {
      if (project.title.toLowerCase() == lower) return project.id;
    }
    return null;
  }
}
