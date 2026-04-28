import 'package:flutter/material.dart';
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/network/connection_manager.dart';

class SettingsProvider with ChangeNotifier {
  final _connectionManager = ConnectionManager();

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  double _fontSizeFactor = 1.0;
  String _leaderName = "";

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get fontSizeFactor => _fontSizeFactor;
  String get leaderName => _leaderName;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await _connectionManager.getThemeMode();
    final lang = await _connectionManager.getLanguageCode();
    final font = await _connectionManager.getFontSizeFactor();
    final name = await _connectionManager.getLeaderName() ?? "";

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
    await _connectionManager.saveThemeMode(_themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _connectionManager.saveLanguageCode(locale.languageCode);
    notifyListeners();
  }

  Future<void> setFontSizeFactor(double factor) async {
    _fontSizeFactor = factor;
    await _connectionManager.saveFontSizeFactor(factor);
    notifyListeners();
  }

  Future<void> setLeaderName(String name) async {
    _leaderName = name;
    await _connectionManager.saveLeaderName(name);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final leaderId = await _connectionManager.getOrGenerateLeaderId();
    // Notify server first
    await ApiClient().deleteLeader(leaderId);
    
    // Then clear locally
    await _connectionManager.clearRegistration();
    _leaderName = "";
    notifyListeners();
  }
}
