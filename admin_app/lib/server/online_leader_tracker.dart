import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:admin_app/server/dashboard_notifier.dart';

class OnlineLeaderTracker {
  static final OnlineLeaderTracker _instance = OnlineLeaderTracker._internal();
  static OnlineLeaderTracker get instance => _instance;

  OnlineLeaderTracker._internal();

  // Map of LeaderID -> WebSocketChannel
  final Map<String, WebSocketChannel> _connections = {};
  // Map of LeaderID -> Last Seen Time
  final Map<String, DateTime> _lastSeen = {};
  // Set of unauthenticated channels to track for cleanup
  final Map<WebSocketChannel, DateTime> _unauthenticatedChannels = {};

  Timer? _cleanupTimer;

  // Stream to notify UI of updates
  final _statusController = StreamController<void>.broadcast();
  Stream<void> get onStatusChange => _statusController.stream;

  void addConnection(String leaderId, WebSocketChannel channel) {
    // 1. If this leader already has a connection, close the old one
    if (_connections.containsKey(leaderId)) {
      print('🔄 OnlineLeaderTracker: Closing existing connection for $leaderId');
      final oldChannel = _connections.remove(leaderId);
      _lastSeen.remove(leaderId);
      try {
        oldChannel?.sink.close();
      } catch (_) {}
    }

    // 2. Remove from unauthenticated list if it was there
    _unauthenticatedChannels.remove(channel);

    // 3. Add to active connections
    _connections[leaderId] = channel;
    _lastSeen[leaderId] = DateTime.now();
    
    _startCleanupTimer();
    _notify();
  }

  void trackUnauthenticated(WebSocketChannel channel) {
    _unauthenticatedChannels[channel] = DateTime.now();
    _startCleanupTimer();
  }

  void recordPing(String? leaderId, WebSocketChannel channel) {
    if (leaderId != null) {
      _lastSeen[leaderId] = DateTime.now();
    } else {
      _unauthenticatedChannels[channel] = DateTime.now();
    }
  }

  void removeConnection(String leaderId) {
    if (_connections.containsKey(leaderId)) {
      final channel = _connections.remove(leaderId);
      _lastSeen.remove(leaderId);
      try {
        channel?.sink.close();
      } catch (_) {}
      _notify();
    }
  }

  void removeChannel(WebSocketChannel channel, String? leaderId) {
    if (leaderId != null) {
      if (_connections[leaderId] == channel) {
        _connections.remove(leaderId);
        _lastSeen.remove(leaderId);
        _notify();
      }
    }
    _unauthenticatedChannels.remove(channel);
  }

  void _startCleanupTimer() {
    _cleanupTimer ??= Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();
      
      // Cleanup authenticated leaders
      final staleLeaderIds = _lastSeen.entries
          .where((e) => now.difference(e.value).inSeconds > 30)
          .map((e) => e.key)
          .toList();

      for (var id in staleLeaderIds) {
        print('🧹 Cleaning up stale authenticated leader: $id');
        final channel = _connections.remove(id);
        _lastSeen.remove(id);
        try {
          channel?.sink.close();
        } catch (_) {}
      }

      // Cleanup unauthenticated channels
      final staleUnauth = _unauthenticatedChannels.entries
          .where((e) => now.difference(e.value).inSeconds > 30)
          .map((e) => e.key)
          .toList();

      if (staleUnauth.isNotEmpty) {
        print('🧹 Cleaning up ${staleUnauth.length} stale unauthenticated connections');
        for (var channel in staleUnauth) {
          _unauthenticatedChannels.remove(channel);
          try {
            channel.sink.close();
          } catch (_) {}
        }
      }

      if (staleLeaderIds.isNotEmpty) {
        _notify();
      }
    });
  }

  void _notify() {
    print('🔄 OnlineLeaderTracker: Notifying (Total Online: $onlineCount)');
    _statusController.add(null);
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  int get onlineCount => _connections.length;
  List<String> get onlineLeaderIds => _connections.keys.toList();

  void broadcast(String message) {
    for (var channel in _connections.values) {
      try {
        channel.sink.add(message);
      } catch (_) {}
    }
  }

  void sendToLeader(String leaderId, String message) {
    final channel = _connections[leaderId];
    if (channel != null) {
      try {
        channel.sink.add(message);
      } catch (_) {}
    }
  }
}
