import 'package:flutter/material.dart';

abstract final class AppColors {
  // Lanka Link logo primary color (Deep Magenta)
  static const primary = Color.fromARGB(199, 16, 1, 226);
  static const secondary = Color(0xFF56B4F8);
  static const accent = Color(0xFFFF5722);

  static const fieldFill = Color(0xFFF3F4F6);
  static const danger = Color(0xFFC62828);
  static final dangerBackground = Colors.red.shade100;
  static const success = Color(0xFF2E7D32);
  static const info = Colors.blue;

  static const white = Colors.white;
  static const black = Colors.black;
  static const transparent = Colors.transparent;

  static const textPrimary = Colors.black87;
  static const textSecondary = Colors.black;
  static const textDisabled = Colors.grey;

  static final borderColor = Colors.grey.shade400;
  static const lightBlue = Colors.lightBlue;
  static final lightBlue200 = Colors.lightBlue.shade200;

  static Color? get error => null;
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

    // Define the default font family for the app
    fontFamily: 'UNGanganee',

    // Define a custom text theme using your project's fonts
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'UNGanganee',
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'UNGanganee',
        fontSize: 45,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        fontFamily: 'UNSamantha',
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'UNSamantha',
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'UNSamantha',
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'UNSamantha',
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontFamily: 'UNSamantha',
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
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
