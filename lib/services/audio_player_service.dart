import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Audio playback service using just_audio.
class AudioPlayerService {
  AudioPlayerService._();
  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

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

  Future<void> dispose() async {
    await _player.dispose();
  }
}
