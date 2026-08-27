import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _themeKey = "theme_mode";
  static const String _langKey = "language_code";
  static const String _fontSizeKey = "font_size_factor";

  Future<String?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode);
    } catch (_) {}
  }

  Future<String?> getLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_langKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLanguageCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langKey, code);
    } catch (_) {}
  }

  Future<double> getFontSizeFactor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_fontSizeKey) ?? 1.0;
    } catch (_) {
      return 1.0;
    }
  }

  Future<void> saveFontSizeFactor(double factor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontSizeKey, factor);
    } catch (_) {}
  }
}
