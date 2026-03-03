import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  AudioRecorderService._();

  static final AudioRecorderService instance = AudioRecorderService._();

  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Amplitude>? _amplitudeSub;
  final ValueNotifier<double> level = ValueNotifier<double>(0);

  String? _activePath;

  Future<bool> ensurePermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('AudioRecorderService.ensurePermission failed: $e');
      return false;
    }
  }

  Future<String> _buildPath({String extension = 'm4a'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${recordingsDir.path}/voicenote_$ts.$extension';
  }

  /// Start recording with voiceRecognition audio source (compatible with STT).
  Future<String?> startWithSource() async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;

      final path = await _buildPath();
      _activePath = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voiceRecognition,
            manageBluetooth: false,
          ),
        ),
        path: path,
      );

      _listenAmplitude();
      return path;
    } catch (e) {
      debugPrint('AudioRecorderService.startWithSource failed: $e');
      return null;
    }
  }

  Future<String?> start() async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;

      final path = await _buildPath();
      _activePath = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _listenAmplitude();
      return path;
    } catch (e) {
      debugPrint('AudioRecorderService.start failed: $e');
      return null;
    }
  }

  /// Start recording in 16kHz mono WAV format (for Whisper transcription).
  ///
  /// IMPORTANT: Do not play audio (just_audio, SoundService, etc.) while
  /// this recorder is active — it will steal audio focus on some Android
  /// devices and produce an empty file. Play cues BEFORE calling this.
  Future<String?> startWav() async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;

      final path = await _buildPath(extension: 'wav');
      _activePath = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      _listenAmplitude();
      return path;
    } catch (e) {
      debugPrint('AudioRecorderService.startWav failed: $e');
      return null;
    }
  }

  void _listenAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
      final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      level.value = normalized;
    }, onError: (e) {
      debugPrint('Amplitude stream error: $e');
    });
  }

  Future<void> pause() async {
    try {
      await _recorder.pause();
    } catch (e) {
      debugPrint('AudioRecorderService.pause failed: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _recorder.resume();
    } catch (e) {
      debugPrint('AudioRecorderService.resume failed: $e');
    }
  }

  Future<String?> stop() async {
    try {
      final path = await _recorder.stop();
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
      level.value = 0;
      return path ?? _activePath;
    } catch (e) {
      debugPrint('AudioRecorderService.stop failed: $e');
      return null;
    } finally {
      _activePath = null;
    }
  }

  Future<void> cancelAndDelete() async {
    try {
      final path = await stop();
      if (path == null) return;
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('AudioRecorderService.cancelAndDelete failed: $e');
    }
  }

  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPaused() async {
    try {
      return await _recorder.isPaused();
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
      await _recorder.dispose();
    } catch (e) {
      debugPrint('AudioRecorderService.dispose failed: $e');
    }
  }
}
