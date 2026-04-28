import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Common Colors
  static const primaryColor = Color(0xFF6366F1); // Indigo
  static const secondaryColor = Color(0xFF06B6D4); // Cyan
  static const accentColor = Color(0xFFF43F5E); // Rose

  // Dark Theme Colors
  static const darkBackgroundColor = Color(0xFF0F172A); // Slate 900
  static const darkCardColor = Color(0xFF1E293B); // Slate 800
  static const darkTextColor = Color(0xFFF8FAFC); // Slate 50
  static const darkMutedTextColor = Color(0xFF94A3B8); // Slate 400

  // Light Theme Colors
  static const lightBackgroundColor = Color(0xFFF8FAFC); // Slate 50
  static const lightCardColor = Colors.white;
  static const lightTextColor = Color(0xFF0F172A); // Slate 900
  static const lightMutedTextColor = Color(0xFF64748B); // Slate 500

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: darkCardColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      cardTheme: _cardTheme(darkCardColor, Colors.white.withValues(alpha: 0.05)),
      appBarTheme: _appBarTheme(darkBackgroundColor, darkTextColor),
      textTheme: _textTheme(darkTextColor),
      elevatedButtonTheme: _buttonTheme(),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: lightCardColor,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      cardTheme: _cardTheme(lightCardColor, Colors.black.withValues(alpha: 0.05)),
      appBarTheme: _appBarTheme(lightBackgroundColor, lightTextColor),
      textTheme: _textTheme(lightTextColor),
      elevatedButtonTheme: _buttonTheme(),
    );
  }

  static CardThemeData _cardTheme(Color color, Color borderColor) {
    return CardThemeData(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1),
      ),
    );
  }

  static AppBarTheme _appBarTheme(Color bgColor, Color txtColor) {
    return AppBarTheme(
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: txtColor,
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    return GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  static ElevatedButtonThemeData _buttonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }
}
