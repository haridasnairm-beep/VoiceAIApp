import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart';
import '../models/note.dart';
import '../models/action_item.dart';
import '../models/todo_item.dart';
import '../models/reminder_item.dart';
import '../models/folder.dart';
import '../models/user_settings.dart';

/// Central Hive database service.
/// Handles initialization, encryption, and box management.
class HiveService {
  static const String _notesBox = 'notes';
  static const String _foldersBox = 'folders';
  static const String _settingsBox = 'settings';
  static const String _encryptionKeyBox = 'encryption_key';

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

    // Get or create encryption key
    final encryptionKey = await _getEncryptionKey();

    // Open encrypted boxes
    await Hive.openBox<Note>(_notesBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<Folder>(_foldersBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<UserSettings>(_settingsBox,
        encryptionCipher: HiveAesCipher(encryptionKey));

    _initialized = true;
    debugPrint('HiveService: initialized with encrypted boxes');
  }

  /// Generate or retrieve the encryption key.
  /// Key is stored in a separate unencrypted box.
  static Future<Uint8List> _getEncryptionKey() async {
    final keyBox = await Hive.openBox(_encryptionKeyBox);
    final existingKey = keyBox.get('key');

    if (existingKey != null) {
      return base64Decode(existingKey as String);
    }

    // Generate a new key
    final key = Hive.generateSecureKey();
    await keyBox.put('key', base64Encode(key));
    return Uint8List.fromList(key);
  }

  /// Get the notes box.
  static Box<Note> get notesBox => Hive.box<Note>(_notesBox);

  /// Get the folders box.
  static Box<Folder> get foldersBox => Hive.box<Folder>(_foldersBox);

  /// Get the settings box.
  static Box<UserSettings> get settingsBox =>
      Hive.box<UserSettings>(_settingsBox);

  /// Close all boxes.
  static Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  /// Calculate total storage used by the app (Hive data + recordings).
  static Future<String> getStorageUsage() async {
    try {
      int totalBytes = 0;

      // Hive box files
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory(appDir.path);
      if (await hiveDir.exists()) {
        await for (final entity in hiveDir.list()) {
          if (entity is File && entity.path.endsWith('.hive')) {
            totalBytes += await entity.length();
          }
        }
      }

      // Recordings directory
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (await recordingsDir.exists()) {
        await for (final entity in recordingsDir.list()) {
          if (entity is File) {
            totalBytes += await entity.length();
          }
        }
      }

      // Format
      if (totalBytes < 1024) return '$totalBytes B';
      if (totalBytes < 1024 * 1024) {
        return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
      }
      if (totalBytes < 1024 * 1024 * 1024) {
        return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      debugPrint('HiveService.getStorageUsage failed: $e');
      return 'Unknown';
    }
  }

  /// Delete all data (privacy: one-tap delete).
  static Future<void> deleteAllData() async {
    await NotificationService.instance.cancelAll();
    await notesBox.clear();
    await foldersBox.clear();
    await settingsBox.clear();
    debugPrint('HiveService: all data deleted');
  }
}
