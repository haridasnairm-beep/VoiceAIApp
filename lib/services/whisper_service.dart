import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

/// On-device Whisper transcription service.
/// Transcribes WAV audio files via whisper.cpp (on-device, no cloud API).
class WhisperService {
  WhisperService._();
  static final WhisperService instance = WhisperService._();

  static const _modelName = 'ggml-base.bin';
  static const _downloadUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main';

  Whisper? _whisper;
  bool _isReady = false;

  bool get isReady => _isReady;

  /// Returns the directory where the model is stored.
  Future<String> _getModelDir() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  /// Check if the Whisper model file exists on disk.
  Future<bool> isModelDownloaded() async {
    try {
      final modelDir = await _getModelDir();
      final modelFile = File('$modelDir/$_modelName');
      final exists = modelFile.existsSync();
      if (exists) {
        final size = await modelFile.length();
        debugPrint('WhisperService: model found (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
      }
      return exists;
    } catch (e) {
      debugPrint('WhisperService: isModelDownloaded check failed: $e');
      return false;
    }
  }

  /// Download the Whisper model with a progress callback.
  /// [onProgress] receives values from 0.0 to 1.0.
  /// Returns true on success, false on failure.
  Future<bool> downloadModel({void Function(double)? onProgress}) async {
    try {
      final modelDir = await _getModelDir();
      final modelFile = File('$modelDir/$_modelName');

      // Already downloaded
      if (modelFile.existsSync()) {
        debugPrint('WhisperService: model already exists');
        onProgress?.call(1.0);
        return true;
      }

      debugPrint('WhisperService: downloading model from $_downloadUrl/$_modelName');
      final uri = Uri.parse('$_downloadUrl/$_modelName');
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        debugPrint('WhisperService: download failed with status ${response.statusCode}');
        httpClient.close();
        return false;
      }

      final contentLength = response.contentLength;
      int received = 0;

      // Ensure directory exists
      final dir = Directory(modelDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      // Write to a temp file first, then rename on success
      final tempFile = File('$modelDir/$_modelName.tmp');
      final sink = tempFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }

      await sink.flush();
      await sink.close();
      httpClient.close();

      // Rename temp to final
      await tempFile.rename(modelFile.path);
      debugPrint('WhisperService: model downloaded (${(received / 1024 / 1024).toStringAsFixed(1)} MB)');
      return true;
    } catch (e, stackTrace) {
      debugPrint('WhisperService: download failed: $e');
      debugPrint('WhisperService: stack trace: $stackTrace');

      // Clean up partial download
      try {
        final modelDir = await _getModelDir();
        final tempFile = File('$modelDir/$_modelName.tmp');
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}

      return false;
    }
  }

  /// Initialize with the base model. Assumes model is already downloaded.
  Future<void> ensureModelReady() async {
    if (_isReady && _whisper != null) return;
    try {
      debugPrint('WhisperService: initializing model...');
      _whisper = Whisper(
        model: WhisperModel.base,
        downloadHost: _downloadUrl,
      );
      _isReady = true;
      debugPrint('WhisperService: model ready');
    } catch (e, stackTrace) {
      debugPrint('WhisperService: model init failed: $e');
      debugPrint('WhisperService: stack trace: $stackTrace');
      _isReady = false;
    }
  }

  /// Transcribe a WAV audio file and return the text.
  /// Returns empty string on failure.
  Future<String> transcribe(String wavPath) async {
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
      debugPrint('WhisperService: model not downloaded, cannot transcribe');
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
      debugPrint('WhisperService: transcribing $wavPath');
      final result = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: wavPath,
          isTranslate: false,
          isNoTimestamps: true,
          splitOnWord: true,
        ),
      );
      final text = result.text.trim();
      debugPrint('WhisperService: transcription result (${text.length} chars): "$text"');
      return text;
    } catch (e, stackTrace) {
      debugPrint('WhisperService: transcription failed: $e');
      debugPrint('WhisperService: stack trace: $stackTrace');
      return '';
    }
  }
}
