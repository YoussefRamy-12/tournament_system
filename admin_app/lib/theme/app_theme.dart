import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==================== SPACING (8-Point Grid) ====================
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 40.0;
  static const double space48 = 48.0;

  // ==================== BORDER RADIUS ====================
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;

  // ==================== COLORS ====================
  // Common Colors
  static const primaryColor = Color(0xFF6366F1); // Indigo
  static const secondaryColor = Color(0xFF06B6D4); // Cyan
  static const accentColor = Color(0xFFF43F5E); // Rose

  // Semantic Colors
  static const successColor = Color(0xFF10B981); // Green
  static const warningColor = Color(0xFFF59E0B); // Amber
  static const errorColor = Color(0xFFEF4444); // Red
  static const infoColor = Color(0xFF3B82F6); // Blue

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

  // ==================== GLASSMORPHISM HELPERS ====================
  static Color glassLight(Color base) => base.withValues(alpha: 0.05);
  static Color glassMedium(Color base) => base.withValues(alpha: 0.1);
  static Color glassDark(Color base) => base.withValues(alpha: 0.15);

  // ==================== STATUS COLOR HELPERS ====================
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return successColor;
      case 'PENDING':
        return warningColor;
      case 'REJECTED':
        return errorColor;
      default:
        return primaryColor;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle_rounded;
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'REJECTED':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  // ==================== TYPOGRAPHY SCALE ====================
  static TextStyle get display32 => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static TextStyle get headline24 => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static TextStyle get title18 => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle get body16 => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static TextStyle get caption14 => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static TextStyle get label12 => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );

  // ==================== THEME DATA ====================
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
        borderRadius: BorderRadius.circular(radiusLg),
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
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        elevation: 0,
      ),
    );
  }
}
