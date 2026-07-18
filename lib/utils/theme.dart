import 'package:flutter/material.dart';

/// Dark theme with gold and black color scheme — Material Design 3
class AppTheme {
  AppTheme._();

  // Core colors
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFFFF3B0);
  static const Color black = Color(0xFF0A0A0A);
  static const Color blackLight = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceVariant = Color(0xFF1E1E1E);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFEF5350);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: black,
        secondary: goldDark,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: Colors.white,
        error: red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: black,
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: gold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: gold,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        labelLarge: TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF333333), thickness: 1),
    );
  }
}
