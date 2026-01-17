import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ConnectionManager {
  static const String _urlKey = "server_url";

  // Save the URL from the QR code (e.g., http://192.168.1.15:8080)
  Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url);
  }

  // Get the saved URL
  Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  // Get or generate a unique Leader ID
  Future<String> getOrGenerateLeaderId() async {
    final prefs = await SharedPreferences.getInstance();
    String? leaderId = prefs.getString('leader_id');

    if (leaderId == null) {
      leaderId = const Uuid()
          .v4(); // Generates a unique string like '550e8400-e29b...'
      await prefs.setString('leader_id', leaderId);
    }
    return leaderId;
  }

  Future<void> saveLeaderName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("leader_name", name);
  }

  Future<String?> getLeaderName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("leader_name");
  }

  Future<void> setRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_registered', true);
  }

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_registered') ?? false;
  }
}
