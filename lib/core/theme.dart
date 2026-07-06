import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LoveSnaps Kawaii Connection Palette (from Stitch design system)
class LoveSnapsColors {
  // Primary (Rich, vibrant soft purple)
  static const primary = Color(0xFF8B5CF6);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFEDE9FE);
  static const onPrimaryContainer = Color(0xFF5B21B6);

  // Secondary (Vivid cute pink)
  static const secondary = Color(0xFFF472B6);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFCE7F3);
  static const onSecondaryContainer = Color(0xFF9D174D);

  // Tertiary (Fresh mint green)
  static const tertiary = Color(0xFF34D399);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFD1FAE5);
  static const onTertiaryContainer = Color(0xFF065F46);

  // Custom Accents
  static const pinkAccent = Color(0xFFFB7185);
  static const pinkAccentDark = Color(0xFFE11D48);
  static const peachAccent = Color(0xFFFDA4AF);

  // Background / Surface (Soft milky white)
  static const background = Color(0xFFFDFBFF); 
  static const onBackground = Color(0xFF1E1B4B);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1E1B4B);
  static const surfaceVariant = Color(0xFFF5F3FF);
  static const onSurfaceVariant = Color(0xFF6D28D9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);

  // Error
  static const error = Color(0xFFE11D48);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFE4E6);
  static const onErrorContainer = Color(0xFF9F1239);

  // Outline
  static const outline = Color(0xFFA78BFA);
  static const outlineVariant = Color(0xFFDDD6FE);
}

class LoveSnapsTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme(
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
        color: LoveSnapsColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LoveSnapsColors.pinkAccent,
          foregroundColor: LoveSnapsColors.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999), // full
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 20, // title-md
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: LoveSnapsColors.secondary,
          textStyle: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LoveSnapsColors.surface,
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
        hintStyle: GoogleFonts.beVietnamPro(
          color: LoveSnapsColors.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.quicksand(
          color: LoveSnapsColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return light(); // Future feature
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.quicksand(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 40,
        color: LoveSnapsColors.primary,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: LoveSnapsColors.primary,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: LoveSnapsColors.primary,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: LoveSnapsColors.primary,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: LoveSnapsColors.primary,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: LoveSnapsColors.primary,
      ),
      bodyLarge: GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: LoveSnapsColors.onSurfaceVariant,
      ),
      bodyMedium: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: LoveSnapsColors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05 * 14,
        color: LoveSnapsColors.primary,
      ),
      labelSmall: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05 * 12,
        color: LoveSnapsColors.primary,
      ),
    );
  }
}

/// Custom shadows defined in the Stitch design system
class LoveSnapsShadows {
  // Ultra-soft plush shadow for cards
  static final marshmallowShadowCard = [
    BoxShadow(
      color: const Color(0xFF8B5CF6).withOpacity(0.08),
      blurRadius: 32,
      spreadRadius: 4,
      offset: const Offset(0, 12),
    ),
  ];

  // Bright pink glowing shadow for buttons
  static final marshmallowShadowBtn = [
    BoxShadow(
      color: const Color(0xFFF472B6).withOpacity(0.3),
      blurRadius: 24,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];

  // Tertiary glow for milestones
  static final marshmallowGlow = [
    BoxShadow(
      color: const Color(0xFF34D399).withOpacity(0.25),
      blurRadius: 28,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ];
}
