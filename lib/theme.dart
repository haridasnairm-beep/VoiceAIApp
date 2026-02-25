import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

// =============================================================================
// COLORS
// =============================================================================

class AppColors {
  // Light Mode
  static const lightPrimary = Color(0xFF4A90E2);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFF56C596);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFFF6AD55);
  static const lightBackground = Color(0xFFFDFCFB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF2D3748);
  static const lightPrimaryText = Color(0xFF1A202C);
  static const lightSecondaryText = Color(0xFF718096);
  static const lightHint = Color(0xFFA0AEC0);
  static const lightError = Color(0xFFE53E3E);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightSuccess = Color(0xFF38A169);
  static const lightDivider = Color(0xFFEDF2F7);

  // Dark Mode
  static const darkPrimary = Color(0xFF63B3ED);
  static const darkOnPrimary = Color(0xFF0A2540);
  static const darkSecondary = Color(0xFF68D391);
  static const darkOnSecondary = Color(0xFF092618);
  static const darkAccent = Color(0xFFFBD38D);
  static const darkBackground = Color(0xFF171923);
  static const darkSurface = Color(0xFF2D3748);
  static const darkOnSurface = Color(0xFFF7FAFC);
  static const darkPrimaryText = Color(0xFFF7FAFC);
  static const darkSecondaryText = Color(0xFFA0AEC0);
  static const darkHint = Color(0xFF4A5568);
  static const darkError = Color(0xFFFC8181);
  static const darkOnError = Color(0xFF63171B);
  static const darkSuccess = Color(0xFF48BB78);
  static const darkDivider = Color(0xFF4A5568);
}

// =============================================================================
// THEMES
// =============================================================================

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightOnPrimary,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightOnSecondary,
        tertiary: AppColors.lightAccent,
        error: AppColors.lightError,
        onError: AppColors.lightOnError,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        outline: AppColors.lightDivider,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      dividerColor: AppColors.lightDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightPrimaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.lightDivider, width: 1),
        ),
      ),
      textTheme: _buildTextTheme(
        primaryColor: AppColors.lightPrimaryText,
        secondaryColor: AppColors.lightSecondaryText,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkOnPrimary,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkOnSecondary,
        tertiary: AppColors.darkAccent,
        error: AppColors.darkError,
        onError: AppColors.darkOnError,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        outline: AppColors.darkDivider,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      dividerColor: AppColors.darkDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkPrimaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.darkDivider, width: 1),
        ),
      ),
      textTheme: _buildTextTheme(
        primaryColor: AppColors.darkPrimaryText,
        secondaryColor: AppColors.darkSecondaryText,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkPrimaryText),
    );

TextTheme _buildTextTheme(
    {required Color primaryColor, required Color secondaryColor}) {
  return TextTheme(
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: primaryColor,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: primaryColor,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: primaryColor,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: primaryColor,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w500, // Adjusted from default
      height: 1.4,
      color: primaryColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: secondaryColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: secondaryColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: secondaryColor,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: primaryColor,
    ),
    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: primaryColor,
    ),
    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: primaryColor,
    ),
  );
}
