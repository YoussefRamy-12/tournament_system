import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static const String _urlKey = "server_url";
  static const String _leaderIdKey = 'leader_id';
  static const String _leaderNameKey = "leader_name";
  static const String _isRegisteredKey = 'is_registered';
  static const String _themeModeKey = "theme_mode";
  static const String _languageCodeKey = "language_code";
  static const String _fontSizeFactorKey = "font_size_factor";

  Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }

  Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  Future<String> getOrGenerateLeaderId() async {
    final prefs = await SharedPreferences.getInstance();
    String? leaderId = prefs.getString(_leaderIdKey);

    if (leaderId == null) {
      leaderId = const Uuid().v4();
      await prefs.setString(_leaderIdKey, leaderId);
    }
    return leaderId;
  }

  Future<void> saveLeaderName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_leaderNameKey, name);
  }

  Future<String?> getLeaderName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_leaderNameKey);
  }

  Future<void> setRegistered(bool registered) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isRegisteredKey, registered);
  }

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRegisteredKey) ?? false;
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? "system";
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);
  }

  Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodeKey) ?? "en";
  }

  Future<void> saveFontSizeFactor(double factor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeFactorKey, factor);
  }

  Future<double> getFontSizeFactor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeFactorKey) ?? 1.0;
  }

  Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep leaderId for persistent device identity
    await prefs.remove(_leaderNameKey);
    await prefs.remove(_isRegisteredKey);
  }
}
