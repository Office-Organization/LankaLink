import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFFC2185B);
  static const primaryDark = Color(0xFF6A0A3D);
  static const fieldFill = Color(0xFFF3F4F6);
  static const danger = Color(0xFFC62828);
  static const success = Color(0xFF2E7D32);
  static const lightBlue = Color(0xFF03A9F4);
  static const navy = Color(0xFF0B1E3D);
  static const gold = Color(0xFFC6A962);
  static const cardBg = Color(0xFFF4F7FC);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'UN-Imanee', // Sinhala font set once
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      );
}