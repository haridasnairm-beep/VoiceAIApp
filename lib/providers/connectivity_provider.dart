import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple connectivity state.
/// Will integrate with connectivity_plus package in Step 5.
class ConnectivityState {
  final bool isOnline;
  final int pendingProcessingCount;

  const ConnectivityState({
    this.isOnline = true,
    this.pendingProcessingCount = 0,
  });

  ConnectivityState copyWith({
    bool? isOnline,
    int? pendingProcessingCount,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      pendingProcessingCount:
          pendingProcessingCount ?? this.pendingProcessingCount,
    );
  }
}

/// Notifier for connectivity and offline queue status.
class ConnectivityNotifier extends Notifier<ConnectivityState> {
  @override
  ConnectivityState build() => const ConnectivityState();

  void setOnline(bool isOnline) {
    state = state.copyWith(isOnline: isOnline);
  }

  void setPendingCount(int count) {
    state = state.copyWith(pendingProcessingCount: count);
  }

  void incrementPending() {
    state = state.copyWith(
      pendingProcessingCount: state.pendingProcessingCount + 1,
    );
  }

  void decrementPending() {
    final newCount = state.pendingProcessingCount - 1;
    state = state.copyWith(
      pendingProcessingCount: newCount < 0 ? 0 : newCount,
    );
  }
}

/// Provider for connectivity state.
final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityState>(
        ConnectivityNotifier.new);
