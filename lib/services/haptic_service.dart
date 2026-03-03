import 'package:flutter/services.dart';

/// Centralized haptic feedback utility.
///
/// Wraps Flutter's [HapticFeedback] with semantic methods so call-sites
/// are not coupled to low-level haptic types.
class HapticService {
  HapticService._();

  /// Light tap — subtle confirmation (e.g. checkbox toggle, selection change).
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Medium impact — noticeable action (e.g. pin note, discard recording).
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Heavy impact — important action (e.g. delete, force-stop recording).
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  /// Selection click — fine-grained selection (e.g. filter chip, mode toggle).
  static Future<void> selection() => HapticFeedback.selectionClick();
}
