import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:admin_app/server/dashboard_notifier.dart';

class OnlineLeaderTracker {
  static final OnlineLeaderTracker _instance = OnlineLeaderTracker._internal();
  static OnlineLeaderTracker get instance => _instance;

  OnlineLeaderTracker._internal();

  // Map of LeaderID -> WebSocket Connection
  final Map<String, WebSocketSink> _connections = {};
  // Map of Sink -> Last Seen Time
  final Map<WebSocketSink, DateTime> _lastSeen = {};
  Timer? _cleanupTimer;

  // Stream to notify UI of updates
  final _statusController = StreamController<void>.broadcast();
  Stream<void> get onStatusChange => _statusController.stream;

  void addConnection(String leaderId, WebSocketSink sink) {
    _connections[leaderId] = sink;
    _lastSeen[sink] = DateTime.now();
    _startCleanupTimer();
    _notify();
  }

  void recordPing(WebSocketSink sink) {
    if (_lastSeen.containsKey(sink)) {
      _lastSeen[sink] = DateTime.now();
      // print('💓 OnlineLeaderTracker: Received heartbeat'); 
    } else {
      // print('⚠️ OnlineLeaderTracker: Received ping for unknown sink');
    }
  }

  void removeConnection(String leaderId) {
    if (_connections.containsKey(leaderId)) {
      _connections.remove(leaderId);
      _notify(); // Notify only if actually removed
    }
  }

  void removeConnectionBySink(WebSocketSink sink) {
    // Find the entry associated with this sink
    MapEntry<String, WebSocketSink>? entry;
    try {
      entry = _connections.entries.firstWhere((e) => e.value == sink);
    } catch (_) {
      // No matching entry found
      return;
    }

    _connections.remove(entry.key);
    _lastSeen.remove(sink);
    _notify();
  }

  void _startCleanupTimer() {
    _cleanupTimer ??= Timer.periodic(const Duration(seconds: 8), (timer) {
      final now = DateTime.now();
      final staleSinks =
          _lastSeen.entries
              .where(
                (e) => now.difference(e.value).inSeconds > 30,
              ) // 30s timeout is safer than 12s
              .map((e) => e.key)
              .toList();

      if (staleSinks.isNotEmpty) {
        print('🧹 Cleaning up ${staleSinks.length} stale connections');
        for (var sink in staleSinks) {
          removeConnectionBySink(sink);
          try {
            sink.close();
          } catch (_) {}
        }
      }
    });
  }

  void _notify() {
    print(
      '🔄 OnlineLeaderTracker: Notifying listeners (Total Online: $onlineCount)',
    );
    _statusController.add(null);
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  int get onlineCount {
    return _connections.length;
  }

  List<String> get onlineLeaderIds {
    return _connections.keys.toList();
  }

  void broadcast(String message) {
    for (var sink in _connections.values) {
      sink.add(message);
    }
  }
}
