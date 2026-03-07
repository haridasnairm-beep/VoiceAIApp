import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// On-device speech-to-text service using the speech_to_text package.
/// Uses Google STT on Android, Apple Speech on iOS — fully on-device, no API key.
class TranscriptionService {
  TranscriptionService._();
  static final TranscriptionService instance = TranscriptionService._();

  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;

  /// Accumulated final transcription text from completed sessions.
  String _finalizedText = '';

  /// Current partial/interim text from the active session.
  String _currentSessionText = '';

  /// Detected language from recognition.
  String _detectedLanguage = '';

  /// Whether the service should auto-restart after a session ends.
  bool _shouldAutoRestart = false;

  /// Locale ID for speech recognition (BCP-47 format, e.g. 'hi-IN').
  String? _localeId;

  /// Callback for transcription updates (finalText, interimText).
  void Function(String finalText, String interimText)? onTranscriptionUpdate;

  /// Callback for detected language changes.
  void Function(String language)? onLanguageDetected;

  /// Callback for status changes.
  void Function(String status)? onStatusChanged;

  /// Optional text filter applied to transcription output (e.g., profanity filter).
  String Function(String text)? textFilter;

  /// Current sound level from STT (for waveform visualization).
  /// Normalized to 0.0–1.0 range.
  final ValueNotifier<double> soundLevel = ValueNotifier<double>(0.0);

  bool get isAvailable => _isInitialized;
  bool get isListening => _isListening;

  /// Full transcription text so far (finalized + current session).
  String get fullTranscription {
    if (_currentSessionText.isEmpty) return _finalizedText;
    if (_finalizedText.isEmpty) return _currentSessionText;
    return '$_finalizedText $_currentSessionText';
  }

  String get detectedLanguage => _detectedLanguage;

  /// Initialize the speech recognizer. Call once before starting.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      debugPrint('TranscriptionService initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('TranscriptionService init failed: $e');
      return false;
    }
  }

  /// Start listening for speech. Audio recording should already be active.
  Future<void> startListening({String? localeId}) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    _shouldAutoRestart = true;
    _localeId = localeId;
    _finalizedText = '';
    _currentSessionText = '';
    _detectedLanguage = '';
    await _beginSession();
  }

  /// Stop listening and finalize all text.
  Future<String> stopListening() async {
    _shouldAutoRestart = false;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    // Commit any remaining session text
    _commitCurrentSession();
    final raw = _finalizedText.trim();
    final result = textFilter?.call(raw) ?? raw;
    onStatusChanged?.call('done');
    return result;
  }

  /// Pause transcription (stop listening without clearing state).
  Future<void> pauseListening() async {
    _shouldAutoRestart = false;
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
    soundLevel.value = 0.0;
    // Commit current session text so it's not lost
    _commitCurrentSession();
    onStatusChanged?.call('paused');
  }

  /// Resume transcription after a pause.
  Future<void> resumeListening() async {
    _shouldAutoRestart = true;
    await _beginSession();
  }

  /// Reset all state (for discard).
  void reset() {
    _shouldAutoRestart = false;
    _finalizedText = '';
    _currentSessionText = '';
    _detectedLanguage = '';
    soundLevel.value = 0.0;
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  Future<void> _beginSession() async {
    if (_isListening) return;
    try {
      _currentSessionText = '';
      _isListening = true;
      await _speech.listen(
        onResult: _handleResult,
        onSoundLevelChange: _handleSoundLevel,
        localeId: _localeId,
        listenFor: const Duration(seconds: 59),
        pauseFor: const Duration(seconds: 10),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
      debugPrint('TranscriptionService: session started (locale: ${_localeId ?? "system default"})');
    } catch (e) {
      debugPrint('TranscriptionService: listen failed: $e');
      _isListening = false;
    }
  }

  void _handleSoundLevel(double level) {
    // speech_to_text reports dB values roughly -2 to 10+.
    // Normalize to 0.0–1.0 for waveform visualization.
    soundLevel.value = ((level + 2) / 12).clamp(0.0, 1.0);
  }

  void _handleResult(SpeechRecognitionResult result) {
    debugPrint('TranscriptionService result: "${result.recognizedWords}" '
        'final=${result.finalResult} confidence=${result.confidence}');
    _currentSessionText = result.recognizedWords;

    if (result.finalResult) {
      _commitCurrentSession();
      final filtered = textFilter?.call(_finalizedText) ?? _finalizedText;
      onTranscriptionUpdate?.call(filtered, '');
    } else {
      final filteredInterim = textFilter?.call(_currentSessionText) ?? _currentSessionText;
      final filteredFinal = textFilter?.call(_finalizedText) ?? _finalizedText;
      onTranscriptionUpdate?.call(filteredFinal, filteredInterim);
    }
  }

  void _handleStatus(String status) {
    debugPrint('TranscriptionService status: $status');

    if (status == 'notListening' || status == 'done') {
      _isListening = false;
      // Do NOT commit here — _handleResult(final=true) commits the
      // authoritative text. notListening fires BEFORE the final result
      // on Android, so committing here would double-commit partial text.
      // For edge cases (timeout with no final result), stopListening()
      // and pauseListening() handle the commit.

      // Auto-restart for long recordings
      if (_shouldAutoRestart) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_shouldAutoRestart) {
            debugPrint('TranscriptionService: auto-restarting session');
            _beginSession();
          }
        });
      }
    }

    onStatusChanged?.call(status);
  }

  void _handleError(dynamic error) {
    debugPrint('TranscriptionService error: $error (type: ${error.runtimeType})');
    _isListening = false;

    // Auto-restart on non-fatal errors if we should still be listening
    if (_shouldAutoRestart) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_shouldAutoRestart) {
          _beginSession();
        }
      });
    }
  }

  void _commitCurrentSession() {
    if (_currentSessionText.isNotEmpty) {
      if (_finalizedText.isEmpty) {
        _finalizedText = _currentSessionText;
      } else {
        _finalizedText = '$_finalizedText $_currentSessionText';
      }
      _currentSessionText = '';
    }
  }

  /// Get available locales for speech recognition.
  Future<List<String>> getAvailableLocales() async {
    if (!_isInitialized) return [];
    final locales = await _speech.locales();
    return locales.map((l) => l.localeId).toList();
  }
}
