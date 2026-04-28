import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = "theme_mode";
  static const String _langKey = "language_code";
  static const String _fontSizeKey = "font_size_factor";

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');
  double _fontSizeFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get fontSizeFactor => _fontSizeFactor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeStr = prefs.getString(_themeKey);
    if (themeStr != null) {
      _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }

    final langStr = prefs.getString(_langKey);
    if (langStr != null) {
      _locale = Locale(langStr);
    }

    _fontSizeFactor = prefs.getDouble(_fontSizeKey) ?? 1.0;
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, factor);
  }
}
