import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Opt-in anonymous crash reporting via Sentry.
///
/// No personal data, no note content, no audio — only stack traces and device metadata.
/// Initialized only when the user explicitly opts in.
class CrashReportingService {
  CrashReportingService._();
  static final CrashReportingService instance = CrashReportingService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Sentry DSN — replace with real DSN before production.
  /// Use empty string or placeholder while DSN is not configured.
  static const _dsn = '';

  /// Initialize Sentry. No-op if already initialized or DSN is empty.
  Future<void> initialize() async {
    if (_initialized || _dsn.isEmpty) {
      debugPrint('CrashReporting: skipped (${_dsn.isEmpty ? 'no DSN' : 'already init'})');
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.tracesSampleRate = 0.2;
        options.attachStacktrace = true;
        // Privacy: never send PII
        options.sendDefaultPii = false;
        // Only capture crashes + errors, not breadcrumbs with user data
        options.maxBreadcrumbs = 50;
      },
    );
    _initialized = true;
    debugPrint('CrashReporting: initialized');
  }

  /// Capture an exception manually (e.g. from a try-catch).
  Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
  }) async {
    if (!_initialized) return;
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
    );
  }

  /// Capture a message (non-exception event).
  Future<void> captureMessage(String message, {SentryLevel? level}) async {
    if (!_initialized) return;
    await Sentry.captureMessage(message, level: level);
  }

  /// Wrap the app's main function to capture unhandled Flutter errors.
  /// Call this in main() when crash reporting is enabled.
  static void setupFlutterErrorHandler() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
      original?.call(details);
    };
  }
}
