import 'package:flutter/material.dart';

abstract final class AppColors {
  // NPP රූපයට අදාළ ප්‍රධාන වර්ණය (Magenta/Dark Pink)
  static const primary = Color(0xFFB30059); 
  static const fieldFill = Color(0xFFF3F4F6);
  static const danger = Color(0xFFC62828);
  static const success = Color(0xFF2E7D32);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansSinhala',
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
}