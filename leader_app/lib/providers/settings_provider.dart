import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;
  final ApiService _api;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  double _fontSizeFactor = 1.0;
  String _leaderName = "";

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get fontSizeFactor => _fontSizeFactor;
  String get leaderName => _leaderName;

  SettingsProvider({required StorageService storage, required ApiService api})
      : _storage = storage,
        _api = api {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _storage.getThemeMode();
    final lang = await _storage.getLanguageCode();
    final font = await _storage.getFontSizeFactor();
    final name = await _storage.getLeaderName() ?? "";

    _themeMode = _parseThemeMode(theme);
    _locale = Locale(lang);
    _fontSizeFactor = font;
    _leaderName = name;

    notifyListeners();
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(_themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _storage.saveLanguageCode(locale.languageCode);
    notifyListeners();
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    await _storage.saveFontSizeFactor(factor);
    notifyListeners();
  }

  Future<void> setLeaderName(String name) async {
    _leaderName = name;
    await _storage.saveLeaderName(name);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final leaderId = await _storage.getOrGenerateLeaderId();
    final baseUrl = await _storage.getUrl();
    
    if (baseUrl != null) {
      await _api.deleteLeader(baseUrl, leaderId);
    }

    await _storage.clearRegistration();
    _leaderName = "";
    notifyListeners();
  }
}
