import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recording session state.
enum RecordingStatus { idle, recording, paused }

class RecordingState {
  final RecordingStatus status;
  final String? currentFilePath;
  final Duration elapsed;
  final double amplitude; // 0.0 to 1.0

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.currentFilePath,
    this.elapsed = Duration.zero,
    this.amplitude = 0.0,
  });

  RecordingState copyWith({
    RecordingStatus? status,
    String? Function()? currentFilePath,
    Duration? elapsed,
    double? amplitude,
  }) {
    return RecordingState(
      status: status ?? this.status,
      currentFilePath: currentFilePath != null
          ? currentFilePath()
          : this.currentFilePath,
      elapsed: elapsed ?? this.elapsed,
      amplitude: amplitude ?? this.amplitude,
    );
  }

  bool get isRecording => status == RecordingStatus.recording;
  bool get isPaused => status == RecordingStatus.paused;
  bool get isIdle => status == RecordingStatus.idle;
}

/// Notifier for the current recording session.
class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() => const RecordingState();

  void startRecording(String filePath) {
    state = RecordingState(
      status: RecordingStatus.recording,
      currentFilePath: filePath,
    );
  }

  void pauseRecording() {
    state = state.copyWith(status: RecordingStatus.paused);
  }

  void resumeRecording() {
    state = state.copyWith(status: RecordingStatus.recording);
  }

  void updateElapsed(Duration elapsed) {
    state = state.copyWith(elapsed: elapsed);
  }

  void updateAmplitude(double amplitude) {
    state = state.copyWith(amplitude: amplitude);
  }

  void stopRecording() {
    state = state.copyWith(status: RecordingStatus.idle);
  }

  void cancelRecording() {
    state = const RecordingState();
  }
}

/// Provider for the recording session state.
final recordingProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);
