import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'settings_repository.dart';

/// Manages app lock state, PIN hashing, and auto-lock timeout tracking.
class AppLockService {
  AppLockService._();
  static final instance = AppLockService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _saltKey = 'app_lock_pin_salt';

  bool _isLocked = true;
  DateTime? _lastBackgroundedAt;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  bool _widgetRecordingSession = false;

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;

  /// True when the user is recording via widget without authentication.
  /// The recording page is accessible but no other pages are.
  bool get isInWidgetRecordingSession => _widgetRecordingSession;

  void startWidgetRecordingSession() => _widgetRecordingSession = true;
  void endWidgetRecordingSession() => _widgetRecordingSession = false;

  /// Check if currently in lockout period.
  Duration? get lockoutRemaining {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Restore persisted lockout state on app startup.
  void initFromSettings(int failedAttempts, DateTime? lockoutUntil) {
    _failedAttempts = failedAttempts;
    // Only restore lockout if it's still in the future
    if (lockoutUntil != null && lockoutUntil.isAfter(DateTime.now())) {
      _lockoutUntil = lockoutUntil;
    } else {
      _lockoutUntil = null;
    }
  }

  void lock() => _isLocked = true;
  void unlock() {
    _isLocked = false;
    _failedAttempts = 0;
    _lockoutUntil = null;
    _lastBackgroundedAt = null; // Prevent re-lock from stale timestamp
  }

  /// Called when app goes to background.
  void onAppPaused() {
    _lastBackgroundedAt = DateTime.now();
  }

  /// Called when app returns to foreground. Returns true if lock should trigger.
  /// Returns false if app was never backgrounded (cold start lock is handled
  /// by the splash page directly).
  bool shouldLockOnResume(int timeoutSeconds) {
    if (_lastBackgroundedAt == null) return false;
    final elapsed = DateTime.now().difference(_lastBackgroundedAt!).inSeconds;
    return elapsed >= timeoutSeconds;
  }

  /// Record a failed PIN attempt. Returns lockout duration if lockout triggered.
  Duration? recordFailedAttempt() {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      final lockoutSeconds = _failedAttempts >= 10
          ? 300 // 5 min after 10+ attempts
          : _failedAttempts >= 7
              ? 60 // 1 min after 7+ attempts
              : 30; // 30s after 5+ attempts
      _lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));
      return Duration(seconds: lockoutSeconds);
    }
    return null;
  }

  /// Hash a PIN with a device-specific salt. Returns hex digest.
  static Future<String> hashPin(String pin) async {
    final salt = await _getOrCreateSalt();
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Verify a PIN against a stored hash.
  static Future<bool> verifyPin(String input, String storedHash) async {
    final inputHash = await hashPin(input);
    return inputHash == storedHash;
  }

  /// Read the stored PIN hash directly from the settings repository.
  /// This avoids exposing the hash through Riverpod state.
  static String? getStoredPinHash() {
    return SettingsRepository().getSettings().appLockPinHash;
  }

  /// Write the PIN hash directly to the settings repository.
  static Future<void> setStoredPinHash(String? hash) async {
    await SettingsRepository().setAppLockPinHash(hash);
  }

  /// Get or create a per-device salt for PIN hashing.
  static Future<String> _getOrCreateSalt() async {
    var salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) {
      // Generate cryptographically secure random salt
      final random = Random.secure();
      final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
      salt = base64Encode(saltBytes);
      await _secureStorage.write(key: _saltKey, value: salt);
    }
    return salt;
  }
}
