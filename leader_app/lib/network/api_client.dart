import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'connection_manager.dart';
import 'package:shared_models/models.dart';

class ApiClient {
  // Singleton Pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final ConnectionManager _connection = ConnectionManager();
  WebSocketChannel? _channel;
  bool _isConnected = false;

  void connectWebSocket() async {
    if (_isConnected) return;

    final baseUrl = await _connection.getUrl();
    final leaderId = await _connection.getOrGenerateLeaderId();

    if (baseUrl == null || leaderId == null) {
      print("⚠️ WS: Cannot connect, baseUrl or leaderId is null");
      return;
    }

    // Convert http://ip:port to ws://ip:port/ws
    // Ensure we don't end up with double slashes
    String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final wsUrl = cleanBase.replaceFirst('http', 'ws') + '/ws';

    try {
      print("🔌 WS: Connecting to $wsUrl...");
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          // print("WS Message: $message");
        },
        onDone: () {
          print("🔌 WS: Connection closed");
          _isConnected = false;
          _stopHeartbeat();
          _reconnect();
        },
        onError: (error) {
          print("🔌 WS: Connection error: $error");
          _isConnected = false;
          _stopHeartbeat();
          _reconnect();
        },
      );

      // Send leaderId as first message
      _channel!.sink.add(leaderId);
      _isConnected = true;
      print("🔌 WS: Connected and sent leaderId: $leaderId");

      // Start a heartbeat to keep connection alive
      _startHeartbeat();
    } catch (e) {
      print("🔌 WS: Connection failed: $e");
      _isConnected = false;
      _reconnect();
    }
  }

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add("ping");
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connectWebSocket();
      }
    });
  }

  // Fetch all teams from the Admin Laptop

  // Fetch all teams from the Admin Laptop
  Future<List<Team>> fetchTeams() async {
    final baseUrl = await _connection.getUrl();
    final response = await http.get(Uri.parse('$baseUrl/teams'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Team> team = body.map((json) => Team.fromJson(json)).toList();
      return team;
    } else {
      throw Exception('Failed to load teams');
    }
  }

  // Fetch members for a specific team
  Future<List<Member>> fetchMembers(int teamId) async {
    final baseUrl = await _connection.getUrl();
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

  Future<bool> submitScore(ScoreTransaction transaction) async {
    try {
      // 1. Get the laptop URL we saved during the QR scan
      final baseUrl = await _connection.getUrl();
      if (baseUrl == null) return false;

      // 2. Send the POST request
      final response = await http
          .post(
            Uri.parse('$baseUrl/submit-score'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(transaction.toJson()),
          )
          .timeout(
            const Duration(seconds: 5),
          ); // Don't wait forever if Wi-Fi is weak

      // 3. Return true if the laptop says "OK" (200)
      return response.statusCode == 200;
    } catch (e) {
      // print("Error submitting score: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyHistory() async {
    final leaderId = await _connection.getOrGenerateLeaderId();
    final baseUrl = await _connection.getUrl();

    final response = await http.get(Uri.parse('$baseUrl/history/$leaderId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(body);
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<String> checkLeaderStatus(String leaderId) async {
    try {
      final baseUrl = await _connection.getUrl();
      // Use Uri.parse to combine them safely
      final url = Uri.parse('$baseUrl/check-approval/$leaderId');

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status']; // 'PENDING', 'APPROVED', 'REJECTED'
      } else {
        // print("Server returned status: ${response.statusCode}");
        return 'ERROR';
      }
    } catch (e) {
      // print("Network error checking status: $e");
      return 'CONNECTION_ERROR';
    }
  }

  Future<bool> isServerAvailable() async {
    try {
      final baseUrl = await _connection.getUrl();
      if (baseUrl == null) return false;

      final leaderId = await _connection.getOrGenerateLeaderId();
      final response = await http
          .get(Uri.parse('$baseUrl/ping?leaderId=$leaderId'))
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200 && response.body == 'pong';
    } catch (e) {
      return false;
    }
  }

  Future<String?> findNewServerIP() async {
    final String? currentUrl = await _connection.getUrl();
    if (currentUrl == null) return null;

    // Get the subnet (e.g., "http://192.168.1")
    final uri = Uri.parse(currentUrl);
    final parts = uri.host.split('.');
    if (parts.length < 4) return null;
    final String subnet = "${parts[0]}.${parts[1]}.${parts[2]}";
    // print("Scanning subnet: $subnet.XXX");

    // Scan all IPs on the subnet (1 to 254)
    // We use a list of futures to scan many IPs at once (much faster)
    List<Future<String?>> scans = [];

    for (int i = 1; i < 255; i++) {
      final String testIp = 'http://$subnet.$i:8080';
      // print(  "Checking $testIp");
      scans.add(_checkIp(testIp));
    }

    // Return the first IP that responds with 'pong'
    final results = await Future.wait(scans);
    for (var result in results) {
      if (result != null) {
        await _connection.saveUrl(result); // Auto-save the new IP
        // print("New server found at $result");
        return result;
      }
    }
    return null;
  }

  Future<String?> _checkIp(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$url/ping'))
          .timeout(const Duration(milliseconds: 500)); // Very fast timeout
      if (response.statusCode == 200 && response.body == 'pong') {
        // print("Found server at $url");
        return url;
      }
    } catch (_) {}
    return null;
  }
}
