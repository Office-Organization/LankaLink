import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFFFF5722); // පටන් ගන්න බොත්තමේ තැඹිලි වර්ණය
  static const fieldFill = Color(0xFFF3F4F6); // අළු පැහැති පසුබිම් වර්ණය
  static const danger = Color(0xFFC62828);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSinhala', // මුළු App එකටම සිංහල අකුරු
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

    // App එකේ සෑම TextField එකකම හැඩය මෙතැනින් ස්වයංක්‍රීයව සැකසේ
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}
