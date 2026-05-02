import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class StorageService {
  static const String _urlKey = "server_url";
  static const String _leaderIdKey = 'leader_id';
  static const String _leaderNameKey = "leader_name";
  static const String _isRegisteredKey = 'is_registered';
  static const String _themeModeKey = "theme_mode";
  static const String _languageCodeKey = "language_code";
  static const String _fontSizeFactorKey = "font_size_factor";
  static const String _pendingTransactionsKey = "pending_transactions";

  Future<void> savePendingTransaction(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingTransactionsKey) ?? [];
    pending.add(jsonEncode(data));
    await prefs.setStringList(_pendingTransactionsKey, pending);
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingTransactionsKey) ?? [];
    return pending.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearPendingTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingTransactionsKey);
  }

  static const String _cachedTeamsKey = "cached_teams";

  Future<void> saveCachedTeams(List<Map<String, dynamic>> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedTeamsKey, jsonEncode(teams));
  }

  Future<List<Map<String, dynamic>>?> getCachedTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_cachedTeamsKey);
    if (str != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(str));
    }
    return null;
  }

  Future<void> saveCachedMembers(int teamId, List<Map<String, dynamic>> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_members_$teamId', jsonEncode(members));
  }

  Future<List<Map<String, dynamic>>?> getCachedMembers(int teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('cached_members_$teamId');
    if (str != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(str));
    }
    return null;
  }

  static const String _cachedHistoryKey = "cached_history";

  Future<void> saveCachedHistory(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedHistoryKey, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>?> getCachedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_cachedHistoryKey);
    if (str != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(str));
    }
    return null;
  }

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
