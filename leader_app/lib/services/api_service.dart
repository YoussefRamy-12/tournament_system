import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_models/models.dart';

class ApiService {
  // Pure network methods. No state management here.

  Future<bool> isServerAvailable(String baseUrl, String leaderId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ping?leaderId=$leaderId'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200 && response.body == 'pong';
    } catch (e) {
      return false;
    }
  }

  Future<List<Team>> fetchTeams(String baseUrl) async {
    final response = await http.get(Uri.parse('$baseUrl/teams'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Team.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<List<Member>> fetchMembers(String baseUrl, int teamId) async {
    final response = await http.get(Uri.parse('$baseUrl/members/$teamId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Member> members = body.map((json) => Member.fromJson(json)).toList();
      members.sort((a, b) => a.name.compareTo(b.name));
      return members;
    } else {
      throw Exception('Failed to load members');
    }
  }

  Future<bool> submitScore(String baseUrl, ScoreTransaction transaction) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/submit-score'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(transaction.toJson()),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitBulkScore(
    String baseUrl, {
    required int teamId,
    required int points,
    required String tag,
    required String description,
    required String leaderId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/submit-bulk-score'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'teamId': teamId,
              'points': points,
              'tag': tag,
              'description': description,
              'leaderId': leaderId,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistory(String baseUrl, String leaderId) async {
    final response = await http.get(Uri.parse('$baseUrl/history/$leaderId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(body);
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<Map<String, dynamic>?> checkLeaderStatus(String baseUrl, String leaderId) async {
    try {
      final url = Uri.parse('$baseUrl/check-approval/$leaderId');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return {'status': 'NOT_FOUND'};
      }
      return {'status': 'ERROR'};
    } catch (e) {
      return {'status': 'CONNECTION_ERROR'};
    }
  }

  Future<bool> registerLeader(String baseUrl, String leaderId, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register-leader'),
        body: jsonEncode({
          'id': leaderId,
          'name': name,
          'deviceInfo': 'Mobile Device', 
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLeader(String baseUrl, String leaderId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/delete-leader'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': leaderId}),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> findNewServerIP(String currentUrl) async {
    try {
      final uri = Uri.parse(currentUrl);
      final parts = uri.host.split('.');
      if (parts.length < 4) return null;
      final String subnet = "${parts[0]}.${parts[1]}.${parts[2]}";

      List<Future<String?>> scans = [];
      for (int i = 1; i < 255; i++) {
        final String testIp = 'http://$subnet.$i:8080';
        scans.add(_checkIp(testIp));
      }

      final results = await Future.wait(scans);
      for (var result in results) {
        if (result != null) return result;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _checkIp(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/ping'))
          .timeout(const Duration(milliseconds: 500));
      if (response.statusCode == 200 && response.body == 'pong') {
        return url;
      }
    } catch (_) {}
    return null;
  }
}
