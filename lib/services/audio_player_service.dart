import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

const _audioFocusChannel = MethodChannel('com.vaanix.app/audio_focus');

/// Audio playback service using just_audio.
class AudioPlayerService {
  AudioPlayerService._();
  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();
  bool _mediaWasActive = false;

  /// Stream of current playback position.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of total duration.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of player state (playing, paused, etc.).
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Whether the player is currently playing.
  bool get isPlaying => _player.playing;

  /// Current position.
  Duration get position => _player.position;

  /// Total duration of loaded audio.
  Duration? get duration => _player.duration;

  /// Load an audio file for playback. Returns true if successful.
  Future<bool> load(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('AudioPlayerService: file not found: $filePath');
        return false;
      }
      await _player.setFilePath(filePath);
      return true;
    } catch (e) {
      debugPrint('AudioPlayerService.load failed: $e');
      return false;
    }
  }

  Future<void> play() async {
    try {
      // Snapshot whether other media is playing before we grab audio focus
      try {
        final result = await _audioFocusChannel.invokeMethod('checkMediaActive');
        _mediaWasActive = result == true;
      } catch (_) {}
      await _player.play();
    } catch (e) {
      debugPrint('AudioPlayerService.play failed: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('AudioPlayerService.pause failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
      await _resumeMediaIfNeeded();
    } catch (e) {
      debugPrint('AudioPlayerService.stop failed: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('AudioPlayerService.seek failed: $e');
    }
  }

  /// Resume other media apps if they were playing before our playback started.
  Future<void> _resumeMediaIfNeeded() async {
    if (!_mediaWasActive) return;
    _mediaWasActive = false;
    try {
      await _audioFocusChannel.invokeMethod('abandonAudioFocus');
      await _audioFocusChannel.invokeMethod('resumeMedia');
    } catch (e) {
      debugPrint('_resumeMediaIfNeeded failed: $e');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
