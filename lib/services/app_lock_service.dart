import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;

  /// Check if currently in lockout period.
  Duration? get lockoutRemaining {
    if (_lockoutUntil == null) return null;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
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

  /// Get or create a per-device salt for PIN hashing.
  static Future<String> _getOrCreateSalt() async {
    var salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) {
      // Generate a random salt from current time + hash
      final raw = '${DateTime.now().microsecondsSinceEpoch}';
      salt = sha256.convert(utf8.encode(raw)).toString().substring(0, 32);
      await _secureStorage.write(key: _saltKey, value: salt);
    }
    return salt;
  }
}
