import 'package:flutter/material.dart';

/// Responsive layout utilities for phone / tablet / landscape support.
///
/// Design principles:
/// - On phones (< 600dp width) everything stays exactly the same.
/// - On wider screens, content is centered with a max width and padding scales.
/// - Grid column counts adapt to available width.
class Responsive {
  Responsive._();

  // ── Breakpoints ──────────────────────────────────────────────────────────
  static const double mobileMax = 600;
  static const double tabletMax = 1200;

  /// True when the screen is wider than a typical phone portrait.
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMax;

  /// True on large tablets / desktop width.
  static bool isExtraWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMax;

  // ── Content width ────────────────────────────────────────────────────────

  /// Maximum content width for scrollable page bodies.
  /// On phones this returns null (no constraint = full width).
  /// On tablets it caps at 720dp so text stays readable.
  static double? maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return null; // phone — no constraint
    if (w < tabletMax) return 720;
    return 840;
  }

  // ── Adaptive grid columns ────────────────────────────────────────────────

  /// Note/project cards in lists (home, folder detail, search results).
  static int noteGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return 1;
    if (w < tabletMax) return 2;
    return 3;
  }

  /// Folder cards on the library page.
  static int folderGridColumns(BuildContext context) =>
      noteGridColumns(context);

  /// Image attachment grid in note detail.
  static int imageGridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return 2;
    if (w < tabletMax) return 3;
    return 4;
  }

  /// Calendar month-picker grid.
  static int monthPickerColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return 3;
    return 4;
  }

  // ── Horizontal padding ───────────────────────────────────────────────────

  /// Standard horizontal padding that scales with width.
  /// Phone: 20, tablet: 32, large: 48.
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileMax) return 20;
    if (w < tabletMax) return 32;
    return 48;
  }
}

/// A wrapper widget that constrains its child to [Responsive.maxContentWidth]
/// and centers it horizontally. On phones this is a no-op pass-through.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.maxContentWidth(context);

    // Phone — no wrapping needed, just apply optional padding.
    if (maxWidth == null) {
      return padding != null ? Padding(padding: padding!, child: child) : child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
