import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of an update check against GitHub Releases.
class UpdateCheckResult {
  final bool isForceUpdate;
  final String latestVersion;
  final String? releaseNotes;
  final String downloadUrl;

  const UpdateCheckResult({
    required this.isForceUpdate,
    required this.latestVersion,
    this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateCheckService {
  static const _repoApiUrl =
      'https://api.github.com/repos/haridasnairm-beep/VoiceAIApp/releases/latest';

  // Store URLs — platform-aware
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.hdmpixels.vaanix';
  static const _appStoreUrl =
      'https://apps.apple.com/app/vaanix/id0'; // Update with real App Store ID when published

  static String get _storeUrl =>
      Platform.isIOS ? _appStoreUrl : _playStoreUrl;

  /// Check for updates. Returns null if no update needed, check skipped, or error.
  static Future<UpdateCheckResult?> checkForUpdate({
    required String currentVersion,
    DateTime? lastCheckDate,
    String? dismissedVersion,
  }) async {
    // Throttle: skip if checked within last 24 hours
    if (lastCheckDate != null &&
        DateTime.now().difference(lastCheckDate).inHours < 24) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse(_repoApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final releaseName = data['name'] as String? ?? '';
      final body = data['body'] as String?;

      // Strip leading 'v' from tag
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (latestVersion.isEmpty) return null;

      // Compare versions
      if (!_isNewer(latestVersion, currentVersion)) return null;

      // Detect force update from tag or release name
      final combined = '$tagName $releaseName'.toLowerCase();
      final isForce =
          combined.contains('[force]') || combined.contains('[critical]');

      // Skip if optional and user already dismissed this version
      if (!isForce && dismissedVersion == latestVersion) return null;

      return UpdateCheckResult(
        isForceUpdate: isForce,
        latestVersion: latestVersion,
        releaseNotes: body,
        downloadUrl: _storeUrl,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Returns true if [latest] is newer than [current] (semantic version).
  static bool _isNewer(String latest, String current) {
    final latestParts = _parseVersion(latest);
    final currentParts = _parseVersion(current);

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false; // equal
  }

  /// Parse version string like "1.0.0" into [major, minor, patch].
  static List<int> _parseVersion(String version) {
    // Remove any build metadata or pre-release suffix
    final clean = version.split('+').first.split('-').first;
    final parts = clean.split('.');
    return [
      parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    ];
  }
}
