import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Plays subtle UI sound cues (recording start / stop).
///
/// Sounds are generated programmatically as PCM WAV data — no binary
/// asset files are required. The generated files are cached to a temp
/// directory after the first call.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();

  String? _startPath;
  String? _stopPath;

  /// Play the recording-start cue (rising tone at 523 Hz / C5, 80 ms).
  Future<void> playStart() => _play(523, 80, isStart: true);

  /// Play the recording-stop cue (falling tone at 392 Hz / G4, 100 ms).
  Future<void> playStop() => _play(392, 100, isStart: false);

  Future<void> _play(int frequency, int durationMs, {required bool isStart}) async {
    try {
      final path = isStart
          ? (_startPath ??= await _writeWav('ui_start.wav', frequency, durationMs))
          : (_stopPath ??= await _writeWav('ui_stop.wav', frequency, durationMs));

      await _player.stop();
      await _player.setFilePath(path);
      await _player.seek(Duration.zero);
      _player.play(); // fire-and-forget — don't await so it never blocks UI
    } catch (_) {
      // Sound cues are non-critical — swallow errors silently.
    }
  }

  /// Writes a mono 16-bit PCM WAV file to the temp directory and returns its path.
  Future<String> _writeWav(String filename, int frequency, int durationMs) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    final bytes = _generateWav(frequency: frequency, durationMs: durationMs);
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Generates a mono 16-bit 44100 Hz PCM WAV as a [Uint8List].
  ///
  /// Applies a short linear fade-in and fade-out (10 ms each) to avoid clicks.
  static Uint8List _generateWav({
    required int frequency,
    required int durationMs,
    double volume = 0.35,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final buffer = ByteData(44 + dataSize);

    // ---- RIFF header ----
    _writeAscii(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(buffer, 8, 'WAVE');

    // ---- fmt subchunk ----
    _writeAscii(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);      // subchunk size
    buffer.setUint16(20, 1, Endian.little);       // PCM format
    buffer.setUint16(22, 1, Endian.little);       // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little);       // block align
    buffer.setUint16(34, 16, Endian.little);      // bits per sample

    // ---- data subchunk ----
    _writeAscii(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    // ---- PCM samples ----
    final fadeSamples = (sampleRate * 10 / 1000).round(); // 10 ms fade
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      double envelope = 1.0;
      if (i < fadeSamples) {
        envelope = i / fadeSamples;
      } else if (i > numSamples - fadeSamples) {
        envelope = (numSamples - i) / fadeSamples;
      }
      final raw = sin(2 * pi * frequency * t) * volume * envelope;
      final sample = (raw * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static void _writeAscii(ByteData buf, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  void dispose() {
    _player.dispose();
  }
}
