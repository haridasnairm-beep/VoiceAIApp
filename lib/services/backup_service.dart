import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/folder.dart';
import '../models/image_attachment.dart';
import '../models/note.dart';
import '../models/project_document.dart';
import '../models/user_settings.dart';
import 'hive_service.dart';
import 'settings_repository.dart';

/// Metadata returned after a successful backup or restore preview.
class BackupManifest {
  final int schemaVersion;
  final DateTime createdAt;
  final String appVersion;
  final int noteCount;
  final int folderCount;
  final int projectDocumentCount;
  final int imageCount;
  final bool includesAudio;

  const BackupManifest({
    required this.schemaVersion,
    required this.createdAt,
    required this.appVersion,
    required this.noteCount,
    required this.folderCount,
    required this.projectDocumentCount,
    required this.imageCount,
    required this.includesAudio,
  });

  factory BackupManifest.fromMap(Map<String, dynamic> m) => BackupManifest(
        schemaVersion: m['schemaVersion'] as int? ?? 1,
        createdAt: DateTime.parse(m['createdAt'] as String),
        appVersion: m['appVersion'] as String? ?? '',
        noteCount: m['noteCount'] as int? ?? 0,
        folderCount: m['folderCount'] as int? ?? 0,
        projectDocumentCount: m['projectDocumentCount'] as int? ?? 0,
        imageCount: m['imageCount'] as int? ?? 0,
        includesAudio: m['includesAudio'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toIso8601String(),
        'appVersion': appVersion,
        'noteCount': noteCount,
        'folderCount': folderCount,
        'projectDocumentCount': projectDocumentCount,
        'imageCount': imageCount,
        'includesAudio': includesAudio,
      };
}

/// Local backup/restore service.
/// Backup format: binary file with header + AES-256-CBC encrypted ZIP archive.
///
/// File layout (.vnbak):
///   [4 bytes] magic: 0x564E424B ("VNBK")
///   [4 bytes] schema version (uint32 big-endian) = 1
///   [16 bytes] random salt
///   [16 bytes] random IV
///   [remaining] AES-256-CBC encrypted ZIP bytes (PKCS7-padded)
///
/// Key derivation: 10,000 rounds of SHA-256(hash || passphrase_bytes || salt)
///
/// ZIP contents:
///   manifest.json — metadata counts + version
///   data.json — all Hive records serialized to JSON
///   images/ — image attachment files (binary)
///   audio/ — audio recording files (binary, if includeAudio=true)
class BackupService {
  static const List<int> _magic = [0x56, 0x4E, 0x42, 0x4B]; // VNBK
  static const int _schemaVersion = 1;
  static const String _appVersion = '1.0.2';

  // ─── Key Derivation ───────────────────────────────────────────────────────

  static Uint8List _deriveKey(String passphrase, Uint8List salt) {
    final passphraseBytes = utf8.encode(passphrase);
    List<int> hash = sha256.convert([...passphraseBytes, ...salt]).bytes;
    for (int i = 1; i < 10000; i++) {
      hash = sha256.convert([...hash, ...passphraseBytes, ...salt]).bytes;
    }
    return Uint8List.fromList(hash); // 32 bytes = AES-256
  }

  // ─── Encrypt / Decrypt ───────────────────────────────────────────────────

  static Uint8List _encrypt(Uint8List plainBytes, String passphrase, Uint8List salt, Uint8List iv) {
    final keyBytes = _deriveKey(passphrase, salt);
    final key = enc.Key(keyBytes);
    final encIv = enc.IV(iv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return Uint8List.fromList(encrypter.encryptBytes(plainBytes, iv: encIv).bytes);
  }

  static Uint8List _decrypt(Uint8List cipherBytes, String passphrase, Uint8List salt, Uint8List iv) {
    final keyBytes = _deriveKey(passphrase, salt);
    final key = enc.Key(keyBytes);
    final encIv = enc.IV(iv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return Uint8List.fromList(
        encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: encIv));
  }

  // ─── Create Backup ───────────────────────────────────────────────────────

  /// Create an encrypted backup file and share it with the system share sheet.
  /// Returns the BackupManifest on success.
  static Future<BackupManifest> createAndShareBackup({
    required String passphrase,
    bool includeAudio = true,
    void Function(String status, double progress)? onProgress,
  }) async {
    onProgress?.call('Collecting data…', 0.05);

    // 1. Read all Hive data
    final notes = HiveService.notesBox.values.toList();
    final folders = HiveService.foldersBox.values.toList();
    final projectDocs = HiveService.projectDocumentsBox.values.toList();
    final imageAttachments = HiveService.imageAttachmentsBox.values.toList();
    final settings = SettingsRepository().getSettings();

    // 2. Build manifest
    final manifest = BackupManifest(
      schemaVersion: _schemaVersion,
      createdAt: DateTime.now(),
      appVersion: _appVersion,
      noteCount: notes.length,
      folderCount: folders.length,
      projectDocumentCount: projectDocs.length,
      imageCount: imageAttachments.length,
      includesAudio: includeAudio,
    );

    onProgress?.call('Serializing data…', 0.15);

    // 3. Serialize data to JSON
    final dataJson = jsonEncode({
      'notes': notes.map((n) => n.toMap()).toList(),
      'folders': folders.map((f) => f.toMap()).toList(),
      'projectDocuments': projectDocs.map((d) => d.toMap()).toList(),
      'imageAttachments': imageAttachments.map((i) => i.toMap()).toList(),
      'settings': settings.toMap(),
    });

    onProgress?.call('Building archive…', 0.25);

    // 4. Build ZIP archive in memory
    final archive = Archive();

    // Add manifest.json
    final manifestBytes = utf8.encode(jsonEncode(manifest.toMap()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // Add data.json
    final dataBytes = utf8.encode(dataJson);
    archive.addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));

    // Add image files
    final appDir = await getApplicationDocumentsDirectory();
    int filesDone = 0;
    final totalImages = imageAttachments.length;

    for (final img in imageAttachments) {
      final file = File(img.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile('images/${img.fileName}', bytes.length, bytes));
      }
      filesDone++;
      onProgress?.call(
        'Adding images… ($filesDone/$totalImages)',
        0.25 + (filesDone / (totalImages + 1)) * 0.25,
      );
    }

    // Add audio files (if requested)
    if (includeAudio) {
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (await recordingsDir.exists()) {
        final audioFiles = await recordingsDir.list().toList();
        int audioDone = 0;
        for (final entity in audioFiles) {
          if (entity is File) {
            final bytes = await entity.readAsBytes();
            final name = entity.path.split(Platform.pathSeparator).last;
            archive.addFile(ArchiveFile('audio/$name', bytes.length, bytes));
          }
          audioDone++;
          onProgress?.call(
            'Adding audio… ($audioDone/${audioFiles.length})',
            0.50 + (audioDone / (audioFiles.length + 1)) * 0.15,
          );
        }
      }
    }

    onProgress?.call('Compressing…', 0.65);

    // 5. Encode ZIP to bytes using ZipEncoder
    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

    onProgress?.call('Encrypting…', 0.75);

    // 6. Generate random salt and IV
    final rng = Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
    final iv = Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));

    // 7. Encrypt ZIP bytes
    final cipherBytes = await compute(_encryptIsolate, _EncryptParams(
      plainBytes: zipBytes,
      passphrase: passphrase,
      salt: salt,
      iv: iv,
    ));

    onProgress?.call('Writing file…', 0.88);

    // 8. Write backup file: magic + version + salt + IV + ciphertext
    final ts = DateTime.now();
    final fileName =
        'vaanix_backup_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}_${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}.vnbak';
    final tempDir = await getTemporaryDirectory();
    final backupFile = File('${tempDir.path}/$fileName');

    final writer = BytesBuilder();
    writer.add(_magic);
    writer.add(_uint32BigEndian(_schemaVersion));
    writer.add(salt);
    writer.add(iv);
    writer.add(cipherBytes);
    await backupFile.writeAsBytes(writer.toBytes());

    onProgress?.call('Sharing…', 0.95);

    // 9. Share the file
    await Share.shareXFiles(
      [XFile(backupFile.path, mimeType: 'application/octet-stream')],
      subject: 'Vaanix Backup',
    );

    onProgress?.call('Done!', 1.0);
    return manifest;
  }

  // ─── Restore Backup ──────────────────────────────────────────────────────

  /// Preview a backup file — verifies passphrase and returns manifest without restoring.
  static Future<BackupManifest> previewBackup({
    required String filePath,
    required String passphrase,
  }) async {
    final archive = await _decryptAndUnzip(filePath: filePath, passphrase: passphrase);
    return _readManifest(archive);
  }

  /// Restore a backup file. Clears all existing data and replaces with backup.
  /// Returns the manifest of the restored backup.
  static Future<BackupManifest> restoreBackup({
    required String filePath,
    required String passphrase,
    void Function(String status, double progress)? onProgress,
  }) async {
    onProgress?.call('Decrypting…', 0.10);
    final archive = await _decryptAndUnzip(filePath: filePath, passphrase: passphrase);

    onProgress?.call('Reading manifest…', 0.20);
    final manifest = _readManifest(archive);

    onProgress?.call('Clearing existing data…', 0.30);
    await HiveService.notesBox.clear();
    await HiveService.foldersBox.clear();
    await HiveService.projectDocumentsBox.clear();
    await HiveService.imageAttachmentsBox.clear();
    await HiveService.settingsBox.clear();

    // Clear image files
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images');
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
    await imagesDir.create(recursive: true);

    onProgress?.call('Restoring data…', 0.40);

    // Parse data.json
    final dataFile = archive.findFile('data.json');
    if (dataFile == null) throw Exception('Backup is corrupt: missing data.json');

    final dataJson = jsonDecode(utf8.decode(dataFile.content as List<int>)) as Map<String, dynamic>;

    // Restore settings
    final settingsMap = dataJson['settings'] as Map<String, dynamic>?;
    if (settingsMap != null) {
      final settings = UserSettings.fromMap(settingsMap);
      await HiveService.settingsBox.put('user_settings', settings);
    }

    // Restore folders
    final foldersData = dataJson['folders'] as List? ?? [];
    for (final f in foldersData) {
      final folder = Folder.fromMap(f as Map<String, dynamic>);
      await HiveService.foldersBox.put(folder.id, folder);
    }

    // Restore project documents
    final docsData = dataJson['projectDocuments'] as List? ?? [];
    for (final d in docsData) {
      final doc = ProjectDocument.fromMap(d as Map<String, dynamic>);
      await HiveService.projectDocumentsBox.put(doc.id, doc);
    }

    onProgress?.call('Restoring images…', 0.55);

    // Restore image files
    final imagesData = dataJson['imageAttachments'] as List? ?? [];
    int imagesDone = 0;
    for (final imgData in imagesData) {
      final attachment = ImageAttachment.fromMap(imgData as Map<String, dynamic>);
      // Extract image file from archive
      final archiveFileName = 'images/${attachment.fileName}';
      final archiveFile = archive.findFile(archiveFileName);
      if (archiveFile != null) {
        final destFile = File('${imagesDir.path}/${attachment.fileName}');
        await destFile.writeAsBytes(archiveFile.content as List<int>);
        // Store the attachment with updated path
        final updatedAttachment = ImageAttachment(
          id: attachment.id,
          filePath: destFile.path,
          fileName: attachment.fileName,
          caption: attachment.caption,
          width: attachment.width,
          height: attachment.height,
          fileSizeBytes: attachment.fileSizeBytes,
          sourceType: attachment.sourceType,
          createdAt: attachment.createdAt,
        );
        await HiveService.imageAttachmentsBox.put(updatedAttachment.id, updatedAttachment);
      } else {
        // File not in archive — store attachment record as-is
        await HiveService.imageAttachmentsBox.put(attachment.id, attachment);
      }
      imagesDone++;
      onProgress?.call(
        'Restoring images… ($imagesDone/${imagesData.length})',
        0.55 + (imagesDone / (imagesData.length + 1)) * 0.15,
      );
    }

    onProgress?.call('Restoring audio…', 0.70);

    // Restore audio files (if included)
    if (manifest.includesAudio) {
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }
      for (final archiveFile in archive.files) {
        if (archiveFile.name.startsWith('audio/') && archiveFile.isFile) {
          final audioName = archiveFile.name.substring('audio/'.length);
          if (audioName.isNotEmpty) {
            final destFile = File('${recordingsDir.path}/$audioName');
            await destFile.writeAsBytes(archiveFile.content as List<int>);
          }
        }
      }
    }

    onProgress?.call('Restoring notes…', 0.80);

    // Restore notes (after images/audio so paths are ready)
    final notesData = dataJson['notes'] as List? ?? [];
    int notesDone = 0;
    for (final n in notesData) {
      final note = Note.fromMap(n as Map<String, dynamic>);
      await HiveService.notesBox.put(note.id, note);
      notesDone++;
      if (notesDone % 20 == 0) {
        onProgress?.call(
          'Restoring notes… ($notesDone/${notesData.length})',
          0.80 + (notesDone / (notesData.length + 1)) * 0.18,
        );
      }
    }

    onProgress?.call('Done!', 1.0);
    return manifest;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  static Future<Archive> _decryptAndUnzip({
    required String filePath,
    required String passphrase,
  }) async {
    final fileBytes = await File(filePath).readAsBytes();

    // Verify magic
    if (fileBytes.length < 40) throw Exception('File is too small to be a valid backup.');
    if (fileBytes[0] != _magic[0] ||
        fileBytes[1] != _magic[1] ||
        fileBytes[2] != _magic[2] ||
        fileBytes[3] != _magic[3]) {
      throw Exception('Not a valid Vaanix backup file.');
    }

    // Parse header
    final salt = fileBytes.sublist(8, 24);
    final iv = fileBytes.sublist(24, 40);
    final cipherBytes = fileBytes.sublist(40);

    // Decrypt
    final zipBytes = await compute(_decryptIsolate, _EncryptParams(
      plainBytes: cipherBytes,
      passphrase: passphrase,
      salt: salt,
      iv: iv,
    ));

    // Unzip
    final archive = ZipDecoder().decodeBytes(zipBytes);
    return archive;
  }

  static BackupManifest _readManifest(Archive archive) {
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) throw Exception('Backup is corrupt: missing manifest.json');
    final manifestJson = jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;
    return BackupManifest.fromMap(manifestJson);
  }

  static List<int> _uint32BigEndian(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  // ─── Auto-Backup ─────────────────────────────────────────────────────────

  static const String _autoBackupPassKey = 'vaanix_auto_backup_passphrase';
  static const String _autoBackupDirName = 'auto_backups';
  static const _secureStorage = FlutterSecureStorage();

  /// Store the auto-backup passphrase securely.
  static Future<void> setAutoBackupPassphrase(String passphrase) async {
    await _secureStorage.write(key: _autoBackupPassKey, value: passphrase);
  }

  /// Retrieve the stored auto-backup passphrase.
  static Future<String?> getAutoBackupPassphrase() async {
    return _secureStorage.read(key: _autoBackupPassKey);
  }

  /// Delete the stored auto-backup passphrase.
  static Future<void> clearAutoBackupPassphrase() async {
    await _secureStorage.delete(key: _autoBackupPassKey);
  }

  /// Check if an auto-backup is due based on frequency and last run time.
  static bool isAutoBackupDue({
    required String frequency,
    required DateTime? lastRun,
  }) {
    if (lastRun == null) return true;
    final now = DateTime.now();
    final diff = now.difference(lastRun);
    switch (frequency) {
      case 'daily':
        return diff.inHours >= 24;
      case 'every3days':
        return diff.inHours >= 72;
      case 'weekly':
        return diff.inDays >= 7;
      default:
        return diff.inDays >= 7;
    }
  }

  /// Get the auto-backup directory (inside app documents).
  static Future<Directory> _getAutoBackupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_autoBackupDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Run auto-backup silently. Saves to app-local directory, rotates old files.
  /// Returns true on success, false on failure.
  static Future<bool> runAutoBackup({
    required int maxCount,
  }) async {
    try {
      final passphrase = await getAutoBackupPassphrase();
      if (passphrase == null || passphrase.isEmpty) {
        debugPrint('AutoBackup: no passphrase stored, skipping.');
        return false;
      }

      debugPrint('AutoBackup: starting…');

      // 1. Read all Hive data
      final notes = HiveService.notesBox.values.toList();
      final folders = HiveService.foldersBox.values.toList();
      final projectDocs = HiveService.projectDocumentsBox.values.toList();
      final imageAttachments = HiveService.imageAttachmentsBox.values.toList();
      final settings = SettingsRepository().getSettings();

      // 2. Build manifest
      final manifest = BackupManifest(
        schemaVersion: _schemaVersion,
        createdAt: DateTime.now(),
        appVersion: _appVersion,
        noteCount: notes.length,
        folderCount: folders.length,
        projectDocumentCount: projectDocs.length,
        imageCount: imageAttachments.length,
        includesAudio: true,
      );

      // 3. Serialize data to JSON
      final dataJson = jsonEncode({
        'notes': notes.map((n) => n.toMap()).toList(),
        'folders': folders.map((f) => f.toMap()).toList(),
        'projectDocuments': projectDocs.map((d) => d.toMap()).toList(),
        'imageAttachments': imageAttachments.map((i) => i.toMap()).toList(),
        'settings': settings.toMap(),
      });

      // 4. Build ZIP archive
      final archive = Archive();
      final manifestBytes = utf8.encode(jsonEncode(manifest.toMap()));
      archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
      final dataBytes = utf8.encode(dataJson);
      archive.addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));

      // Add image files
      final appDir = await getApplicationDocumentsDirectory();
      for (final img in imageAttachments) {
        final file = File(img.filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile('images/${img.fileName}', bytes.length, bytes));
        }
      }

      // Add audio files
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (await recordingsDir.exists()) {
        final audioFiles = await recordingsDir.list().toList();
        for (final entity in audioFiles) {
          if (entity is File) {
            final bytes = await entity.readAsBytes();
            final name = entity.path.split(Platform.pathSeparator).last;
            archive.addFile(ArchiveFile('audio/$name', bytes.length, bytes));
          }
        }
      }

      // 5. Encode ZIP
      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));

      // 6. Encrypt
      final rng = Random.secure();
      final salt = Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));
      final iv = Uint8List.fromList(List<int>.generate(16, (_) => rng.nextInt(256)));

      final cipherBytes = await compute(_encryptIsolate, _EncryptParams(
        plainBytes: zipBytes,
        passphrase: passphrase,
        salt: salt,
        iv: iv,
      ));

      // 7. Write to auto-backup directory
      final ts = DateTime.now();
      final fileName =
          'vaanix_auto_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}_${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}.vnbak';
      final backupDir = await _getAutoBackupDir();
      final backupFile = File('${backupDir.path}/$fileName');

      final writer = BytesBuilder();
      writer.add(_magic);
      writer.add(_uint32BigEndian(_schemaVersion));
      writer.add(salt);
      writer.add(iv);
      writer.add(cipherBytes);
      await backupFile.writeAsBytes(writer.toBytes());

      debugPrint('AutoBackup: saved to ${backupFile.path}');

      // 8. Rotate old backups — keep only maxCount newest files
      await _rotateAutoBackups(maxCount);

      debugPrint('AutoBackup: complete.');
      return true;
    } catch (e) {
      debugPrint('AutoBackup: failed: $e');
      return false;
    }
  }

  /// Delete oldest auto-backup files to keep at most [maxCount].
  static Future<void> _rotateAutoBackups(int maxCount) async {
    final dir = await _getAutoBackupDir();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.vnbak'))
        .cast<File>()
        .toList();

    if (files.length <= maxCount) return;

    // Sort by modified time descending (newest first)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    // Delete oldest files beyond maxCount
    for (int i = maxCount; i < files.length; i++) {
      debugPrint('AutoBackup: rotating old backup ${files[i].path}');
      await files[i].delete();
    }
  }

  /// Get list of existing auto-backup files (newest first).
  static Future<List<File>> getAutoBackupFiles() async {
    final dir = await _getAutoBackupDir();
    if (!await dir.exists()) return [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.vnbak'))
        .cast<File>()
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  // ─── Isolate-safe encrypt/decrypt ─────────────────────────────────────────

  static Uint8List _encryptIsolate(_EncryptParams params) {
    return _encrypt(params.plainBytes, params.passphrase, params.salt, params.iv);
  }

  static Uint8List _decryptIsolate(_EncryptParams params) {
    return _decrypt(params.plainBytes, params.passphrase, params.salt, params.iv);
  }
}

/// Parameters for isolate-based encryption/decryption.
class _EncryptParams {
  final Uint8List plainBytes;
  final String passphrase;
  final Uint8List salt;
  final Uint8List iv;

  const _EncryptParams({
    required this.plainBytes,
    required this.passphrase,
    required this.salt,
    required this.iv,
  });
}
