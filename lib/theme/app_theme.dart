import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color cream = Color(0xFFF8F2E8);
  static const Color warmPaper = Color(0xFFF1E6D6);
  static const Color paper = Color(0xFFFFFCF7);
  static const Color sand = Color(0xFFE8DCC2);
  static const Color caramel = Color(0xFFD9B89D);
  static const Color rust = Color(0xFFC67D6B);
  static const Color terracotta = Color(0xFFB85B47);
  static const Color olive = Color(0xFF5B6B4A);
  static const Color lavender = Color(0xFFA78AA7);
  static const Color ink = Color(0xFF4A3D36);
  static const Color softInk = Color(0xFF766A63);
  static const Color softGrey = Color(0xFF8D837D);
  static const Color border = Color(0xFFE2D3C3);
  static const Color shadow = Color(0x14000000);
  static const Color white = Color(0xFFFFFFFF);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      brightness: Brightness.light,
      primary: AppColors.terracotta,
      secondary: AppColors.olive,
      surface: AppColors.paper,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 48,
          fontWeight: FontWeight.w500,
          height: 1.05,
          color: AppColors.ink,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 34,
          fontWeight: FontWeight.w600,
          height: 1.08,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'serif',
          fontSize: 29,
          fontWeight: FontWeight.w600,
          height: 1.10,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.softInk,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.softGrey,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.terracotta,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: AppColors.terracotta),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        hintStyle: const TextStyle(color: AppColors.softGrey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.terracotta,
            width: 1.4,
          ),
        ),
      ),
      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.ink),
    );
  }
}
