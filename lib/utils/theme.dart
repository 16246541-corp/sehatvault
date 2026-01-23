import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme following Apple's Human Interface Guidelines
/// Emphasizes content-first design with judicious use of color
class AppTheme {
  // MARK: - Color Palette (Judicious Use of Color)
  
  /// Primary color - used sparingly for emphasis
  static const Color primaryColor = Color(0xFF5B21B6); // Deep purple/indigo
  
  /// Accent color - used for CTAs and important actions
  static const Color accentTeal = Color(0xFF14B8A6); // Teal
  
  /// Health accent - for health-related highlights
  static const Color healthGreen = Color(0xFF10B981); // Emerald green
  
  /// Warning color
  static const Color warningOrange = Color(0xFFD97706); // Warm orange
  
  // MARK: - Light Mode Colors
  
  /// Light background - allows content to shine
  static const Color lightBackground = Color(0xFFFAFAF9); // Soft cream/white
  
  /// Light surface - for cards and elevated content
  static const Color lightSurface = Colors.white;
  
  /// Light text primary - high contrast for readability
  static const Color lightTextPrimary = Color(0xFF1F2937);
  
  /// Light text secondary - for less important text
  static const Color lightTextSecondary = Color(0xFF6B7280);
  
  // MARK: - Dark Mode Colors
  
  /// Dark background - deep, immersive
  static const Color darkBackground = Color(0xFF0F172A); // Deep blue-black
  
  /// Dark surface - for cards and elevated content
  static const Color darkSurface = Color(0xFF1E293B);
  
  /// Dark text primary - high contrast for readability
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  
  /// Dark text secondary - for less important text
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentTeal,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: lightSurface,
        margin: EdgeInsets.zero,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: 0.37,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: 0.36,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: 0.35,
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: 0.38,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.41,
          height: 1.4,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
          letterSpacing: -0.41,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
          letterSpacing: -0.32,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
          letterSpacing: -0.24,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
          letterSpacing: -0.08,
          height: 1.4,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
          letterSpacing: 0,
          height: 1.3,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
          letterSpacing: 0.07,
          height: 1.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentTeal,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: darkSurface,
        margin: EdgeInsets.zero,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: 0.37,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: 0.36,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          letterSpacing: 0.35,
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: 0.38,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          letterSpacing: -0.41,
          height: 1.4,
        ),
        bodyLarge: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: darkTextPrimary,
          letterSpacing: -0.41,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
          letterSpacing: -0.32,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
          letterSpacing: -0.24,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
          letterSpacing: -0.08,
          height: 1.4,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
          letterSpacing: 0,
          height: 1.3,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: darkTextSecondary,
          letterSpacing: 0.07,
          height: 1.2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
      ),
    );
  }
}
