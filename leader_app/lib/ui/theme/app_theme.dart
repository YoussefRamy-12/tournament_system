import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors ---
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Violet
  static const Color accent = Color(0xFF06B6D4); // Cyan
  
  static const Color darkBg = Color(0xFF0F172A); // Deep Navy
  static const Color darkSurface = Color(0xFF1E293B); // Navy Slate
  
  static const Color lightBg = Color(0xFFF8FAFC); // Soft Gray
  static const Color lightSurface = Colors.white;

  // --- Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Theme Data ---
  static ThemeData lightTheme(Locale? locale) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: _getTextTheme(locale, Brightness.light),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _getHeadingStyle(locale, Brightness.light),
      ),
    );
  }

  static ThemeData darkTheme(Locale? locale) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: _getTextTheme(locale, Brightness.dark),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _getHeadingStyle(locale, Brightness.dark),
      ),
    );
  }

  // --- Typography ---
  static TextTheme _getTextTheme(Locale? locale, Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    // Check locale for font switching (simplified here, will be used in main)
    bool isArabic = locale?.languageCode == 'ar';

    if (isArabic) {
      return GoogleFonts.tajawalTextTheme(baseTextTheme);
    } else {
      return GoogleFonts.outfitTextTheme(baseTextTheme);
    }
  }

  static TextStyle _getHeadingStyle(Locale? locale, Brightness brightness) {
    bool isArabic = locale?.languageCode == 'ar';
    return (isArabic ? GoogleFonts.tajawal() : GoogleFonts.outfit()).copyWith(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: brightness == Brightness.light ? Colors.black87 : Colors.white,
    );
  }

  // --- Decorative ---
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
}
