import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

/// On-device Whisper transcription service.
/// Transcribes WAV audio files via whisper.cpp (on-device, no cloud API).
class WhisperService {
  WhisperService._();
  static final WhisperService instance = WhisperService._();

  static const _downloadUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main';

  /// Current model selection
  String _currentModelName = 'base';
  WhisperModel _currentModel = WhisperModel.base;

  Whisper? _whisper;
  bool _isReady = false;

  bool get isReady => _isReady;
  String get currentModelName => _currentModelName;

  /// Map model name string to WhisperModel enum.
  static WhisperModel _modelFromName(String name) {
    switch (name) {
      case 'small':
        return WhisperModel.small;
      case 'medium':
        return WhisperModel.medium;
      default:
        return WhisperModel.base;
    }
  }

  /// Model file name for a given model.
  static String modelFileName(String modelName) => 'ggml-$modelName.bin';

  /// Switch to a different model. Requires re-initialization.
  void switchModel(String modelName) {
    if (modelName == _currentModelName && _isReady) return;
    _currentModelName = modelName;
    _currentModel = _modelFromName(modelName);
    _isReady = false;
    _whisper = null;
    debugPrint('WhisperService: switched to model "$modelName"');
  }

  /// Returns the directory where models are stored.
  Future<String> _getModelDir() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  /// Check if the current model file exists on disk.
  Future<bool> isModelDownloaded() async {
    return isSpecificModelDownloaded(_currentModelName);
  }

  /// Check if a specific model file exists on disk.
  Future<bool> isSpecificModelDownloaded(String modelName) async {
    try {
      final modelDir = await _getModelDir();
      final fileName = modelFileName(modelName);
      final modelFile = File('$modelDir/$fileName');
      final exists = modelFile.existsSync();
      if (exists) {
        final size = await modelFile.length();
        debugPrint('WhisperService: $fileName found (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
      }
      return exists;
    } catch (e) {
      debugPrint('WhisperService: isModelDownloaded check failed: $e');
      return false;
    }
  }

  /// Get the current model file size in bytes (0 if not downloaded).
  Future<int> getModelSizeBytes() async {
    return getSpecificModelSizeBytes(_currentModelName);
  }

  /// Get a specific model file size in bytes (0 if not downloaded).
  Future<int> getSpecificModelSizeBytes(String modelName) async {
    try {
      final modelDir = await _getModelDir();
      final fileName = modelFileName(modelName);
      final modelFile = File('$modelDir/$fileName');
      if (modelFile.existsSync()) return await modelFile.length();
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Delete the current model.
  Future<bool> deleteModel() async {
    return deleteSpecificModel(_currentModelName);
  }

  /// Delete a specific model.
  Future<bool> deleteSpecificModel(String modelName) async {
    try {
      final modelDir = await _getModelDir();
      final fileName = modelFileName(modelName);
      final modelFile = File('$modelDir/$fileName');
      if (modelFile.existsSync()) {
        await modelFile.delete();
        if (modelName == _currentModelName) {
          _isReady = false;
          _whisper = null;
        }
        debugPrint('WhisperService: $fileName deleted');
      }
      return true;
    } catch (e) {
      debugPrint('WhisperService: deleteModel failed: $e');
      return false;
    }
  }

  /// Active HTTP client for the current download (allows cancellation).
  HttpClient? _activeHttpClient;

  /// Cancel any in-progress download (partial file kept for resume).
  void cancelDownload() {
    _activeHttpClient?.close(force: true);
    _activeHttpClient = null;
    debugPrint('WhisperService: download cancelled (partial file kept)');
  }

  /// Delete partial download (.tmp file) for a model.
  /// Use after cancel to fully remove progress so next download starts fresh.
  Future<void> deletePartialDownload(String modelName) async {
    try {
      final modelDir = await _getModelDir();
      final tempFile = File('$modelDir/${modelFileName(modelName)}.tmp');
      if (tempFile.existsSync()) {
        await tempFile.delete();
        debugPrint('WhisperService: partial download deleted for $modelName');
      }
    } catch (e) {
      debugPrint('WhisperService: deletePartialDownload failed: $e');
    }
  }

  /// Download a specific model with a progress callback.
  /// [onProgress] receives values from 0.0 to 1.0.
  /// Supports resuming interrupted downloads via HTTP Range header.
  /// Keeps the screen awake during download to prevent OS from killing the connection.
  /// Returns true on success, false on failure.
  Future<bool> downloadModel({
    String? modelName,
    void Function(double)? onProgress,
  }) async {
    final targetModel = modelName ?? _currentModelName;
    final fileName = modelFileName(targetModel);
    try {
      final modelDir = await _getModelDir();
      final modelFile = File('$modelDir/$fileName');

      // Already downloaded
      if (modelFile.existsSync()) {
        debugPrint('WhisperService: $fileName already exists');
        onProgress?.call(1.0);
        return true;
      }

      // Keep screen awake during download
      await WakelockPlus.enable();

      // Ensure directory exists
      final dir = Directory(modelDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Check for partial download to resume
      final tempFile = File('$modelDir/$fileName.tmp');
      int existingBytes = 0;
      if (tempFile.existsSync()) {
        existingBytes = await tempFile.length();
        debugPrint('WhisperService: resuming download from ${(existingBytes / 1024 / 1024).toStringAsFixed(1)} MB');
      }

      debugPrint('WhisperService: downloading $fileName from $_downloadUrl/$fileName');
      final uri = Uri.parse('$_downloadUrl/$fileName');
      final httpClient = HttpClient();
      _activeHttpClient = httpClient;
      final request = await httpClient.getUrl(uri);

      // Add Range header for resume support
      if (existingBytes > 0) {
        request.headers.set('Range', 'bytes=$existingBytes-');
      }

      final response = await request.close();

      // 206 = Partial Content (resume), 200 = full download
      if (response.statusCode != 200 && response.statusCode != 206) {
        debugPrint('WhisperService: download failed with status ${response.statusCode}');
        httpClient.close();
        _activeHttpClient = null;
        await WakelockPlus.disable();
        return false;
      }

      // If server doesn't support Range (returns 200 instead of 206), start fresh
      if (existingBytes > 0 && response.statusCode == 200) {
        debugPrint('WhisperService: server does not support resume, starting fresh');
        existingBytes = 0;
        if (tempFile.existsSync()) tempFile.deleteSync();
      }

      final contentLength = response.contentLength;
      final totalSize = contentLength > 0 ? contentLength + existingBytes : 0;
      int received = existingBytes;

      // Open file in append mode for resume, or write mode for fresh download
      final sink = tempFile.openWrite(mode: existingBytes > 0 ? FileMode.append : FileMode.write);

      // Report initial progress if resuming
      if (totalSize > 0 && existingBytes > 0) {
        onProgress?.call(received / totalSize);
      }

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (totalSize > 0) {
          onProgress?.call(received / totalSize);
        }
      }

      await sink.flush();
      await sink.close();
      httpClient.close();
      _activeHttpClient = null;
      await WakelockPlus.disable();

      // Rename temp to final
      await tempFile.rename(modelFile.path);
      debugPrint('WhisperService: $fileName downloaded (${(received / 1024 / 1024).toStringAsFixed(1)} MB)');
      return true;
    } catch (e, stackTrace) {
      debugPrint('WhisperService: download failed: $e');
      debugPrint('WhisperService: stack trace: $stackTrace');
      _activeHttpClient = null;
      await WakelockPlus.disable();

      // Keep partial download for resume — do NOT delete temp file
      debugPrint('WhisperService: partial download kept for resume');

      return false;
    }
  }

  /// Initialize with the selected model. Assumes model is already downloaded.
  Future<void> ensureModelReady() async {
    if (_isReady && _whisper != null) return;
    try {
      debugPrint('WhisperService: initializing model "$_currentModelName"...');
      _whisper = Whisper(
        model: _currentModel,
        downloadHost: _downloadUrl,
      );
      _isReady = true;
      debugPrint('WhisperService: model "$_currentModelName" ready');
    } catch (e, stackTrace) {
      debugPrint('WhisperService: model init failed: $e');
      debugPrint('WhisperService: stack trace: $stackTrace');
      _isReady = false;
    }
  }

  /// Transcribe a WAV audio file and return the text.
  /// Returns empty string on failure.
  Future<String> transcribe(String wavPath, {String language = 'en', bool isTranslate = false}) async {
    // Validate input file
    final file = File(wavPath);
    if (!await file.exists()) {
      debugPrint('WhisperService: file does not exist: $wavPath');
      return '';
    }
    final fileSize = await file.length();
    debugPrint('WhisperService: file size: ${(fileSize / 1024).toStringAsFixed(1)} KB');

    if (fileSize < 1024) {
      debugPrint('WhisperService: file too small ($fileSize bytes), likely empty recording');
      return '';
    }

    // Check model exists
    if (!await isModelDownloaded()) {
      debugPrint('WhisperService: model "$_currentModelName" not downloaded, cannot transcribe');
      return '';
    }

    if (!_isReady || _whisper == null) {
      debugPrint('WhisperService: model not ready, initializing...');
      await ensureModelReady();
    }
    if (_whisper == null) {
      debugPrint('WhisperService: model failed to initialize');
      return '';
    }

    try {
      debugPrint('WhisperService: transcribing $wavPath (model: $_currentModelName, language: $language, translate: $isTranslate)');
      // Timeout: 3 minutes max — prevents hanging when app is backgrounded
      final result = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: wavPath,
          language: language,
          isTranslate: isTranslate,
          isNoTimestamps: true,
          splitOnWord: true,
        ),
      ).timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          debugPrint('WhisperService: transcription timed out after 3 minutes');
          throw TimeoutException('Whisper transcription timed out');
        },
      );
      // Strip Whisper hallucination artifacts and noise markers.
      var text = result.text;

      // Remove bracketed noise markers: [BLANK_AUDIO], [inaudible], [MUSIC], etc.
      text = text.replaceAll(
        RegExp(
          r'\[(?:'
          r'BLANK[_ ]AUDIO'
          r'|inaudible'
          r'|INAUDIBLE'
          r'|MUSIC'
          r'|music'
          r'|Music'
          r'|SOUND'
          r'|NOISE'
          r'|SILENCE'
          r'|APPLAUSE'
          r'|LAUGHTER'
          r'|COUGH(?:ING)?'
          r'|SIGH'
          r'|CLICK(?:ING)?'
          r'|STATIC'
          r'|BEEP(?:ING)?'
          r'|RINGING'
          r'|BUZZING'
          r')\]',
          caseSensitive: false,
        ),
        '',
      );

      // Remove parenthesized noise/hallucination markers:
      // (speaking in foreign language), (soft music), (inaudible), etc.
      text = text.replaceAll(
        RegExp(
          r'\('
          r'(?:speaking in (?:foreign |other |another )?language)'
          r'|(?:(?:soft |loud |faint )?music(?: playing)?)'
          r'|(?:inaudible)'
          r'|(?:silence)'
          r'|(?:laughter)'
          r'|(?:applause)'
          r'|(?:cough(?:ing)?)'
          r'|(?:sigh(?:ing)?)'
          r'|(?:background (?:noise|music|chatter))'
          r'|(?:unintelligible)'
          r'|(?:crosstalk)'
          r'|(?:phone ringing)'
          r'|(?:static)'
          r'\)',
          caseSensitive: false,
        ),
        '',
      );

      // Remove Whisper hallucination patterns (repeated phrases, filler)
      // e.g. "Thank you." repeated, "Bye." repeated, common Whisper loops
      text = text.replaceAll(
        RegExp(r'(?:\b(?:Thank you|Thanks for watching|Please subscribe|Like and subscribe)\.?\s*){3,}',
            caseSensitive: false),
        '',
      );

      // Collapse multiple spaces/dashes and trim
      text = text
          .replaceAll(RegExp(r'\s*-\s*-\s*'), ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
      debugPrint('WhisperService: transcription result (${text.length} chars): "$text"');
      return text;
    } catch (e, stackTrace) {
      debugPrint('WhisperService: transcription failed: $e');
      debugPrint('WhisperService: stack trace: $stackTrace');
      return '';
    }
  }
}
