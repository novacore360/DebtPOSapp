// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background    = Color(0xFF0F0F1A);
  static const surface       = Color(0xFF1A1A2E);
  static const card          = Color(0xFF14142A);
  static const border        = Color(0x12FFFFFF);
  static const primary       = Color(0xFF4E73DF);
  static const green         = Color(0xFF1CC88A);
  static const yellow        = Color(0xFFF6C23E);
  static const red           = Color(0xFFE74A3B);
  static const cyan          = Color(0xFF36B9CC);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x99FFFFFF);
  static const textMuted     = Color(0x55FFFFFF);
}

ThemeData buildAppTheme() {
  final base = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.green,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0FFFFFFF),
      hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
      labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0x0AFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xF71A1A2E),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.dmSans(
        color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
      contentTextStyle: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
