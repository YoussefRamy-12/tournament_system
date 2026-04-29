import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');
  double _fontSizeFactor = 1.0;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get fontSizeFactor => _fontSizeFactor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  SettingsProvider({required StorageService storage}) : _storage = storage {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _storage.getThemeMode();
    final lang = await _storage.getLanguageCode();
    final font = await _storage.getFontSizeFactor();

    if (theme != null) {
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }
    if (lang != null) {
      _locale = Locale(lang);
    }
    _fontSizeFactor = font;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _storage.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggleTheme() async {
    await setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    await _storage.saveLanguageCode(locale.languageCode);
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    notifyListeners();
    await _storage.saveFontSizeFactor(factor);
  }
}
