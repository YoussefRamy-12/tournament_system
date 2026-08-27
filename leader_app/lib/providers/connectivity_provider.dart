import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/storage_service.dart';

class ConnectivityProvider with ChangeNotifier {
  final StorageService _storage;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  // A single, cancellable reconnect timer. Using Timer instead of
  // Future.delayed prevents unbounded timer pile-up when _reconnect() is
  // called many times in quick succession (e.g., 50 channels closing at once).
  Timer? _reconnectTimer;

  bool _isOnline = false;
  bool _isConnecting = false;
  bool _connectionFailed = false;
  Timer? _connectionTimeoutTimer;
  void Function(String)? onStatusUpdate;
  void Function(String)? onProfileUpdate;
  VoidCallback? onReconnect;

  bool get isOnline => _isOnline;
  bool get isConnecting => _isConnecting;
  bool get connectionFailed => _connectionFailed;

  ConnectivityProvider({required StorageService storage}) : _storage = storage;

  Future<void> connect() async {
    // Cancel any pending reconnect — this call IS the reconnect.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // BUG-A FIX: Set _isConnecting = true BEFORE the first await.
    // Without this, multiple concurrent connect() calls all pass the guard
    // during the event-loop yield of the storage reads, creating a WS storm.
    if (_isOnline || _isConnecting || _channel != null) return;
    _isConnecting = true;
    _connectionFailed = false;
    notifyListeners();

    final baseUrl = await _storage.getUrl();
    final leaderId = await _storage.getOrGenerateLeaderId();

    if (baseUrl == null) {
      _isConnecting = false;
      notifyListeners();
      return;
    }

    // Set timeout for initial connection
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!_isOnline && _isConnecting) {
        _isConnecting = false;
        _connectionFailed = true;
        notifyListeners();
      }
    });

    // Ensure any old connection is closed
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;

    String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final wsUrl = '${cleanBase.replaceFirst('http', 'ws')}/ws';

    try {
      // BUG-C FIX: Capture the channel in a LOCAL variable and use that in
      // all closures. _channel (the field) can be reassigned by the time
      // onDone fires, so reading _channel?.closeCode gives the wrong value.
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = channel;

      channel.ready.catchError((_) {}); // Suppress unhandled package exception

      channel.stream.listen(
        (message) {
          // Ignore messages from a stale channel that was already replaced.
          if (_channel != channel) return;
          try {
            final data = jsonDecode(message);
            if (data['status'] == 'connected') {
              channel.sink.add(leaderId);
              _isConnecting = false;
              _connectionTimeoutTimer?.cancel();
              _connectionFailed = false;
              _setOnline(true);
            } else if (data['type'] == 'status_update') {
              onStatusUpdate?.call(data['status']);
            } else if (data['type'] == 'profile_update') {
              onProfileUpdate?.call(data['name']);
            }
          } catch (e) {
            // Non-JSON message, treat as online if we already sent ID
            if (!_isConnecting) _setOnline(true);
          }
        },
        onDone: () {
          // Ignore events from a stale channel that was already replaced.
          if (_channel != channel) return;

          _isConnecting = false;

          // BUG-C FIX: Read closeCode from the LOCAL 'channel' capture, NOT
          // from _channel (the field). The field may already point to a newer
          // channel by the time this fires. Close code 4001 means the server
          // displaced this connection because a newer one arrived — in that
          // case, don't reconnect, the new channel is already taking over.
          final code = channel.closeCode;
          _channel = null;
          _setOnline(false);
          if (code != 4001) {
            _reconnect();
          }
        },
        onError: (error) {
          if (_channel != channel) return;
          _isConnecting = false;
          _channel = null;
          _setOnline(false);
          _reconnect();
        },
      );

      _startHeartbeat();
    } catch (e) {
      _isConnecting = false;
      _channel = null;
      _setOnline(false);
      _reconnect();
    }
  }

  void _setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
      if (online && onReconnect != null) {
        onReconnect!();
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isOnline && _channel != null) {
        try {
          _channel!.sink.add("ping");
        } catch (e) {
          _setOnline(false);
          _stopHeartbeat();
          _reconnect();
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _reconnect() {
    _stopHeartbeat();
    // BUG-B FIX: Use a single cancellable Timer instead of Future.delayed.
    // Future.delayed creates a new, untracked timer on every call. If
    // _reconnect() is called 50 times rapidly (50 channels closing at once),
    // you get 50 delayed timers all firing simultaneously 5s later, creating
    // 50 new channels. With a cancellable Timer, each new call replaces the
    // previous one — only ONE reconnect attempt ever fires.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      if (!_isOnline) {
        connect();
      }
    });
  }

  void resetFailure() {
    _connectionFailed = false;
    _isConnecting = false;
    _connectionTimeoutTimer?.cancel();
    notifyListeners();
  }

  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectionTimeoutTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setOnline(false);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
