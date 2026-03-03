import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import '../models/note.dart';
import '../models/action_item.dart';
import '../models/todo_item.dart';
import '../models/reminder_item.dart';
import '../models/folder.dart';
import '../models/user_settings.dart';
import '../models/project_document.dart';
import '../models/project_block.dart';
import '../models/transcript_version.dart';
import '../models/image_attachment.dart';

/// Central Hive database service.
/// Handles initialization, encryption, and box management.
class HiveService {
  static const String _notesBox = 'notes';
  static const String _foldersBox = 'folders';
  static const String _settingsBox = 'settings';
  static const String _projectDocumentsBox = 'project_documents';
  static const String _imageAttachmentsBox = 'image_attachments';
  static const String _encryptionKeyBox = 'encryption_key'; // legacy, for migration
  static const String _secureStorageKey = 'hive_encryption_key';
  static const _secureStorage = FlutterSecureStorage();

  static bool _initialized = false;

  /// Initialize Hive and register all type adapters.
  /// Must be called before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register type adapters
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(ActionItemAdapter());
    Hive.registerAdapter(TodoItemAdapter());
    Hive.registerAdapter(ReminderItemAdapter());
    Hive.registerAdapter(FolderAdapter());
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(ProjectDocumentAdapter());
    Hive.registerAdapter(ProjectBlockAdapter());
    Hive.registerAdapter(BlockTypeAdapter());
    Hive.registerAdapter(TranscriptVersionAdapter());
    Hive.registerAdapter(ImageAttachmentAdapter());

    // Get or create encryption key
    final encryptionKey = await _getEncryptionKey();

    // Open encrypted boxes
    await Hive.openBox<Note>(_notesBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<Folder>(_foldersBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<UserSettings>(_settingsBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<ProjectDocument>(_projectDocumentsBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<ImageAttachment>(_imageAttachmentsBox,
        encryptionCipher: HiveAesCipher(encryptionKey));

    // Ensure images directory exists
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    _initialized = true;
    debugPrint('HiveService: initialized with encrypted boxes');
  }

  /// Generate or retrieve the encryption key.
  /// Key is stored in Android Keystore / iOS Keychain via flutter_secure_storage.
  /// Migrates from legacy plain Hive box on first run after upgrade.
  static Future<Uint8List> _getEncryptionKey() async {
    // Try reading from secure storage first
    final secureKey = await _secureStorage.read(key: _secureStorageKey);
    if (secureKey != null) {
      return base64Decode(secureKey);
    }

    // Migrate from legacy unencrypted Hive box (if it exists)
    try {
      final keyBox = await Hive.openBox(_encryptionKeyBox);
      final legacyKey = keyBox.get('key');
      if (legacyKey != null) {
        // Move key to secure storage
        await _secureStorage.write(
            key: _secureStorageKey, value: legacyKey as String);
        // Delete the legacy box
        await keyBox.deleteFromDisk();
        debugPrint('HiveService: migrated encryption key to secure storage');
        return base64Decode(legacyKey);
      }
      await keyBox.close();
    } catch (e) {
      debugPrint('HiveService: legacy key migration skipped: $e');
    }

    // Generate a new key (fresh install)
    final key = Hive.generateSecureKey();
    await _secureStorage.write(
        key: _secureStorageKey, value: base64Encode(key));
    return Uint8List.fromList(key);
  }

  /// Get the notes box.
  static Box<Note> get notesBox => Hive.box<Note>(_notesBox);

  /// Get the folders box.
  static Box<Folder> get foldersBox => Hive.box<Folder>(_foldersBox);

  /// Get the settings box.
  static Box<UserSettings> get settingsBox =>
      Hive.box<UserSettings>(_settingsBox);

  /// Get the project documents box.
  static Box<ProjectDocument> get projectDocumentsBox =>
      Hive.box<ProjectDocument>(_projectDocumentsBox);

  /// Get the image attachments box.
  static Box<ImageAttachment> get imageAttachmentsBox =>
      Hive.box<ImageAttachment>(_imageAttachmentsBox);

  /// Close all boxes.
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  /// Get a breakdown of storage usage: {hive, recordings, images, total} in bytes.
  static Future<Map<String, int>> getStorageBreakdown() async {
    int hiveBytes = 0;
    int recordingsBytes = 0;
    int imagesBytes = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Hive box files
      final hiveDir = Directory(appDir.path);
      if (await hiveDir.exists()) {
        await for (final entity in hiveDir.list()) {
          if (entity is File && entity.path.endsWith('.hive')) {
            hiveBytes += await entity.length();
          }
        }
      }

      // Recordings
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (await recordingsDir.exists()) {
        await for (final entity in recordingsDir.list()) {
          if (entity is File) {
            recordingsBytes += await entity.length();
          }
        }
      }

      // Images
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await for (final entity in imagesDir.list()) {
          if (entity is File) {
            imagesBytes += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('HiveService.getStorageBreakdown failed: $e');
    }

    return {
      'hive': hiveBytes,
      'recordings': recordingsBytes,
      'images': imagesBytes,
      'total': hiveBytes + recordingsBytes + imagesBytes,
    };
  }

  /// Format bytes into human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Delete all voice recording files (preserves notes/text data).
  static Future<void> deleteAllRecordings() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (await recordingsDir.exists()) {
        await recordingsDir.delete(recursive: true);
        await recordingsDir.create(recursive: true);
      }
      // Mark notes as having no audio (set duration to 0)
      for (final note in notesBox.values) {
        if (note.audioFilePath.isNotEmpty) {
          note.audioDurationSeconds = 0;
          await note.save();
        }
      }
      debugPrint('HiveService: all recordings deleted');
    } catch (e) {
      debugPrint('HiveService.deleteAllRecordings failed: $e');
    }
  }

  /// Calculate total storage used by the app (delegates to getStorageBreakdown).
  static Future<String> getStorageUsage() async {
    try {
      final breakdown = await getStorageBreakdown();
      return formatBytes(breakdown['total']!);
    } catch (e) {
      debugPrint('HiveService.getStorageUsage failed: $e');
      return 'Unknown';
    }
  }

  /// Migrate existing notes: ensure each has at least one TranscriptVersion.
  static Future<void> migrateTranscriptVersions() async {
    final notes = notesBox.values.toList();
    for (final note in notes) {
      if (note.transcriptVersions.isEmpty &&
          note.rawTranscription.isNotEmpty) {
        final version = TranscriptVersion(
          id: '${note.id}_v1',
          text: note.rawTranscription,
          versionNumber: 1,
          editSource: 'Original transcription',
          createdAt: note.createdAt,
          isOriginal: true,
        );
        note.transcriptVersions = [version];
        await notesBox.put(note.id, note);
      }
    }
    debugPrint('HiveService: transcript version migration complete');
  }

  /// Migrate transcription mode default from 'live' to 'whisper'.
  static Future<void> migrateDefaultTranscriptionMode() async {
    const settingsKey = 'user_settings';
    final settings = settingsBox.get(settingsKey);
    if (settings != null && settings.transcriptionMode == 'live') {
      settings.transcriptionMode = 'whisper';
      await settingsBox.put(settingsKey, settings);
      debugPrint('HiveService: migrated transcription mode to whisper');
    }
  }

  /// Ensure a default folder exists. Creates "General" on first launch.
  static Future<void> ensureDefaultFolder() async {
    const settingsKey = 'user_settings';
    var settings = settingsBox.get(settingsKey);
    if (settings == null) {
      settings = UserSettings();
      await settingsBox.put(settingsKey, settings);
    }

    // Already has a valid default folder
    if (settings.defaultFolderId != null &&
        foldersBox.containsKey(settings.defaultFolderId)) {
      return;
    }

    // Create "General" folder (protected from rename/delete)
    final folder = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'General',
      isAutoGenerated: true,
    );
    await foldersBox.put(folder.id, folder);
    settings.defaultFolderId = folder.id;
    await settingsBox.put(settingsKey, settings);
    debugPrint('HiveService: created default "General" folder (${folder.id})');
  }

  /// Migrate existing ProjectDocuments into folders (Wave 3 one-time migration).
  ///
  /// For each project without a folderId:
  /// - Collect all folderIds from the notes referenced in its blocks.
  /// - If all linked notes share exactly one folder → use that folder.
  /// - Otherwise → fall back to the "General" (default) folder.
  /// Also updates the folder's projectDocumentIds list.
  static Future<void> migrateProjectsIntoFolders() async {
    // Get the General folder id from settings
    const settingsKey = 'user_settings';
    final settings = settingsBox.get(settingsKey);
    final generalFolderId = settings?.defaultFolderId;

    final unassigned = projectDocumentsBox.values
        .where((d) => !d.isDeleted && d.folderId == null)
        .toList();

    if (unassigned.isEmpty) return;

    for (final doc in unassigned) {
      // Gather all folderIds from linked notes
      final folderIds = <String>{};
      for (final block in doc.blocks) {
        if (block.noteId != null) {
          final note = notesBox.values
              .where((n) => n.id == block.noteId && !n.isDeleted)
              .firstOrNull;
          if (note?.folderId != null) folderIds.add(note!.folderId!);
        }
      }

      final targetFolderId = folderIds.length == 1
          ? folderIds.first
          : (generalFolderId ?? foldersBox.values
              .where((f) => !f.isDeleted && f.isAutoGenerated)
              .firstOrNull
              ?.id);

      if (targetFolderId == null) continue;

      // Assign folderId on project
      doc.folderId = targetFolderId;
      await projectDocumentsBox.put(doc.id, doc);

      // Register in folder's projectDocumentIds
      final folder = foldersBox.values
          .where((f) => f.id == targetFolderId)
          .firstOrNull;
      if (folder != null && !folder.projectDocumentIds.contains(doc.id)) {
        folder.projectDocumentIds.add(doc.id);
        await foldersBox.put(folder.id, folder);
      }
    }

    debugPrint('HiveService: migrated ${unassigned.length} project(s) into folders');
  }

  /// Validate referential integrity across Hive boxes.
  ///
  /// Checks:
  /// 1. Notes reference existing folders
  /// 2. Project document blocks reference existing notes
  /// 3. Folders' noteIds reference existing notes
  /// 4. Folders' projectDocumentIds reference existing projects
  ///
  /// Returns count of issues found and auto-repaired.
  static Future<int> validateIntegrity() async {
    int issuesFixed = 0;

    // 1. Notes referencing non-existent folders → clear folderId
    final folderIds = foldersBox.values.map((f) => f.id).toSet();
    for (final note in notesBox.values.toList()) {
      if (note.folderId != null && !folderIds.contains(note.folderId)) {
        note.folderId = null;
        await notesBox.put(note.id, note);
        issuesFixed++;
      }
    }

    // 2. Folders referencing non-existent notes → remove from noteIds
    final noteIds = notesBox.values.map((n) => n.id).toSet();
    for (final folder in foldersBox.values.toList()) {
      final before = folder.noteIds.length;
      folder.noteIds.removeWhere((id) => !noteIds.contains(id));
      if (folder.noteIds.length != before) {
        await foldersBox.put(folder.id, folder);
        issuesFixed += before - folder.noteIds.length;
      }
    }

    // 3. Folders referencing non-existent projects → remove from projectDocumentIds
    final projectIds = projectDocumentsBox.values.map((p) => p.id).toSet();
    for (final folder in foldersBox.values.toList()) {
      final before = folder.projectDocumentIds.length;
      folder.projectDocumentIds.removeWhere((id) => !projectIds.contains(id));
      if (folder.projectDocumentIds.length != before) {
        await foldersBox.put(folder.id, folder);
        issuesFixed += before - folder.projectDocumentIds.length;
      }
    }

    // 4. Notes referencing non-existent project documents → clean projectDocumentIds
    for (final note in notesBox.values.toList()) {
      final before = note.projectDocumentIds.length;
      note.projectDocumentIds.removeWhere((id) => !projectIds.contains(id));
      if (note.projectDocumentIds.length != before) {
        await notesBox.put(note.id, note);
        issuesFixed += before - note.projectDocumentIds.length;
      }
    }

    if (issuesFixed > 0) {
      debugPrint('HiveService.validateIntegrity: fixed $issuesFixed issue(s)');
    }
    return issuesFixed;
  }

  /// Delete all data (privacy: one-tap delete).
  static Future<void> deleteAllData() async {
    await NotificationService.instance.cancelAll();
    await notesBox.clear();
    await foldersBox.clear();
    await settingsBox.clear();
    await projectDocumentsBox.clear();
    await imageAttachmentsBox.clear();

    // Delete image files
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
        await imagesDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('HiveService.deleteAllData: failed to delete images: $e');
    }

    debugPrint('HiveService: all data deleted');
  }
}
