import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark; // Default to dark

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

class AppTheme {
  // Anti-Gravity Color Palette
  static const Color background = Color(0xFF0B0C10);
  static const Color surface = Color(0xFF15181F);
  static const Color accentCyan = Color(0xFF00FFCC);
  static const Color accentMagenta = Color(0xFFFF00FF);
  static const Color accentPurple = Color(0xFF8A2BE2);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0AAB2);
  static const Color glowingRed = Color(0xFFFF3366);

  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentMagenta,
        surface: surface,
        error: glowingRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        bodyLarge: GoogleFonts.outfit(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: accentCyan,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00B894),
        secondary: Color(0xFFE84393),
        surface: lightSurface,
        error: glowingRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        bodyLarge: GoogleFonts.outfit(color: lightTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.outfit(color: lightTextSecondary, fontSize: 14),
      ),
      useMaterial3: true,
    );
  }

  // Helper for generating glowing box shadows
  static List<BoxShadow> getNeonGlow({Color color = accentCyan, double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3 * intensity),
        blurRadius: 15 * intensity,
        spreadRadius: 2 * intensity,
        offset: const Offset(0, 0),
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.1 * intensity),
        blurRadius: 30 * intensity,
        spreadRadius: 5 * intensity,
        offset: const Offset(0, 0),
      )
    ];
  }
}
