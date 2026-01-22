import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:admin_app/server/dashboard_notifier.dart';

class OnlineLeaderTracker {
  static final OnlineLeaderTracker _instance = OnlineLeaderTracker._internal();
  static OnlineLeaderTracker get instance => _instance;

  OnlineLeaderTracker._internal();

  // Map of LeaderID -> WebSocket Connection
  final Map<String, WebSocketSink> _connections = {};

  // Stream to notify UI of updates
  final _statusController = StreamController<void>.broadcast();
  Stream<void> get onStatusChange => _statusController.stream;

  void addConnection(String leaderId, WebSocketSink sink) {
    _connections[leaderId] = sink;
    _notify();
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
    _notify();
  }

  void _notify() {
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
