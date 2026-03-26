import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color background = Color(0xFF0B0F19);
  static const Color card = Color(0xFF111827);
  static const Color accent = Color(0xFF22C55E);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);
  static const Color lightBorder = Color(0xFFE5E7EB);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.lightCard,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.lightTextPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: _buttonTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.lightTextSecondary),
      ),
    );
  }

  static ElevatedButtonThemeData get _buttonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.card,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: _buttonTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
      ),
    );
  }
}
