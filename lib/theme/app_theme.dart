import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF00327D);
  static const Color primaryContainer = Color(0xFF0047AB);
  static const Color background = Color(0xFFF5FAFC);
  static const Color surface = Color(0xFFF5FAFC);
  static const Color secondary = Color(0xFF4D6265);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF171C1E);
  static const Color surfaceContainerLow = Color(0xFFEFF4F6);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        background: background,
        surface: surface,
        onPrimary: onPrimary,
        onBackground: onBackground,
        onSurface: onBackground,
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lexend(
            color: onBackground, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.lexend(
            color: onBackground, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.lexend(
            color: onBackground, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.lexend(
            color: onBackground, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(
            color: onBackground, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: onBackground),
        bodyMedium: GoogleFonts.inter(color: onBackground),
        labelLarge: GoogleFonts.inter(color: secondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
