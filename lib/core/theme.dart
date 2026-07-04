import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LoveSnaps Kawaii Connection Palette (from Stitch design system)
class LoveSnapsColors {
  // Primary
  static const primary = Color(0xFF5c5d6e);
  static const onPrimary = Color(0xFFffffff);
  static const primaryContainer = Color(0xFFe6e6fa);
  static const onPrimaryContainer = Color(0xFF656677);

  // Secondary
  static const secondary = Color(0xFF37656b);
  static const onSecondary = Color(0xFFffffff);
  static const secondaryContainer = Color(0xFFb8e8ee);
  static const onSecondaryContainer = Color(0xFF3b6a6f);

  // Tertiary
  static const tertiary = Color(0xFF874e58);
  static const onTertiary = Color(0xFFffffff);
  static const tertiaryContainer = Color(0xFFffe0e3);
  static const onTertiaryContainer = Color(0xFF915761);
  static const tertiaryFixedDim = Color(0xFFfcb3be);

  // Background / Surface
  static const background = Color(0xFFf9f9ff);
  static const onBackground = Color(0xFF191c20);
  static const surface = Color(0xFFf9f9ff);
  static const onSurface = Color(0xFF191c20);
  static const surfaceVariant = Color(0xFFe2e2e9);
  static const onSurfaceVariant = Color(0xFF46464c);
  static const surfaceContainerLowest = Color(0xFFffffff);

  // Error
  static const error = Color(0xFFba1a1a);
  static const onError = Color(0xFFffffff);
  static const errorContainer = Color(0xFFffdad6);
  static const onErrorContainer = Color(0xFF93000a);

  // Outline
  static const outline = Color(0xFF77767d);
  static const outlineVariant = Color(0xFFc7c5cc);
}

class LoveSnapsTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: LoveSnapsColors.primary,
      onPrimary: LoveSnapsColors.onPrimary,
      primaryContainer: LoveSnapsColors.primaryContainer,
      onPrimaryContainer: LoveSnapsColors.onPrimaryContainer,
      secondary: LoveSnapsColors.secondary,
      onSecondary: LoveSnapsColors.onSecondary,
      secondaryContainer: LoveSnapsColors.secondaryContainer,
      onSecondaryContainer: LoveSnapsColors.onSecondaryContainer,
      tertiary: LoveSnapsColors.tertiary,
      onTertiary: LoveSnapsColors.onTertiary,
      tertiaryContainer: LoveSnapsColors.tertiaryContainer,
      onTertiaryContainer: LoveSnapsColors.onTertiaryContainer,
      error: LoveSnapsColors.error,
      onError: LoveSnapsColors.onError,
      errorContainer: LoveSnapsColors.errorContainer,
      onErrorContainer: LoveSnapsColors.onErrorContainer,
      background: LoveSnapsColors.background,
      onBackground: LoveSnapsColors.onBackground,
      surface: LoveSnapsColors.surface,
      onSurface: LoveSnapsColors.onSurface,
      surfaceVariant: LoveSnapsColors.surfaceVariant,
      onSurfaceVariant: LoveSnapsColors.onSurfaceVariant,
      outline: LoveSnapsColors.outline,
      outlineVariant: LoveSnapsColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LoveSnapsColors.background,
      textTheme: _buildTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 28, // headline-lg-mobile
          fontWeight: FontWeight.w700,
          color: LoveSnapsColors.primary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: LoveSnapsColors.primary),
      ),
      cardTheme: CardThemeData(
        color: LoveSnapsColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), // 2rem
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LoveSnapsColors.tertiaryContainer,
          foregroundColor: LoveSnapsColors.onTertiaryContainer,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // full
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 24, // headline-md
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LoveSnapsColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: LoveSnapsColors.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: LoveSnapsColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: LoveSnapsColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: LoveSnapsColors.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: LoveSnapsColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData dark() {
    // For this design system, dark mode is not fully defined, but we'll adapt the light colors
    // safely for now. Production would require a dedicated dark palette.
    return light();
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.quicksand(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 48,
        color: LoveSnapsColors.onBackground,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: LoveSnapsColors.onBackground,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: LoveSnapsColors.onBackground,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: LoveSnapsColors.onBackground,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: LoveSnapsColors.onBackground,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01 * 14,
        color: LoveSnapsColors.onBackground,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: LoveSnapsColors.onBackground,
      ),
    );
  }
}

/// Custom shadows defined in the Stitch design system
class LoveSnapsShadows {
  static final marshmallowShadowLarge = [
    BoxShadow(
      color: const Color(0xFFE6E6FA).withOpacity(0.4),
      blurRadius: 64,
      offset: const Offset(0, 32),
      spreadRadius: -12,
    ),
    BoxShadow(
      color: const Color(0xFFFFFFFF).withOpacity(0.5),
      blurRadius: 0,
      offset: const Offset(0, 0),
      spreadRadius: 1, // simulates the `inset 0 0 0 1px` to some extent by extending outwards
    ),
  ];

  static final marshmallowShadowMedium = [
    BoxShadow(
      color: const Color(0xFFE6E6FA).withOpacity(0.4),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    ),
    BoxShadow(
      color: const Color(0xFFE6E6FA).withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static final marshmallowGlow = [
    BoxShadow(
      color: const Color(0xFFFCB3BE).withOpacity(0.4), // tertiary-fixed-dim
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
