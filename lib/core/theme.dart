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
  static const secondary = Color(0xFF31647d);
  static const onSecondary = Color(0xFFffffff);
  static const secondaryContainer = Color(0xFFAFE1FE);
  static const onSecondaryContainer = Color(0xFF32657e);

  // Tertiary
  static const tertiary = Color(0xFF306a42);
  static const onTertiary = Color(0xFFffffff);
  static const tertiaryContainer = Color(0xFFb7f6c4);
  static const onTertiaryContainer = Color(0xFF39734b);

  // Custom Accents
  static const pinkAccent = Color(0xFFffb6c1);
  static const pinkAccentDark = Color(0xFFff9a9e);

  // Background / Surface
  static const background = Color(0xFFf8f9fe); // Very soft lilac/white
  static const onBackground = Color(0xFF191c1f);
  static const surface = Color(0xFFffffff); // True white for cards
  static const onSurface = Color(0xFF191c1f);
  static const surfaceVariant = Color(0xFFf2f3f8);
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
  // 0px 8px 24px rgba(204, 204, 255, 0.2)
  static final marshmallowShadowCard = [
    BoxShadow(
      color: const Color(0x33CCCCFF),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // 0px 12px 32px rgba(255, 182, 193, 0.3)
  static final marshmallowShadowBtn = [
    BoxShadow(
      color: const Color(0x4DFFB6C1),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];

  // Tertiary glow for milestones
  static final marshmallowGlow = [
    BoxShadow(
      color: const Color(0x4Db7f6c4),
      blurRadius: 28,
      offset: const Offset(0, 8),
    ),
  ];
}
