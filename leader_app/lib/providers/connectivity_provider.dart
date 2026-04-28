import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/storage_service.dart';

class ConnectivityProvider with ChangeNotifier {
  final StorageService _storage;
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  
  bool _isOnline = false;
  bool _isConnecting = false;
  void Function(String)? onStatusUpdate;

  bool get isOnline => _isOnline;
  bool get isConnecting => _isConnecting;

  ConnectivityProvider({required StorageService storage}) : _storage = storage;

  Future<void> connect() async {
    if (_isOnline || _isConnecting) return;
    
    final baseUrl = await _storage.getUrl();
    final leaderId = await _storage.getOrGenerateLeaderId();

    if (baseUrl == null) return;

    _isConnecting = true;
    notifyListeners();

    // Ensure any old connection is closed
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;

    String cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final wsUrl = '${cleanBase.replaceFirst('http', 'ws')}/ws';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            if (data['status'] == 'connected') {
              _channel?.sink.add(leaderId);
              _isConnecting = false;
              _setOnline(true);
            } else if (data['type'] == 'status_update') {
              onStatusUpdate?.call(data['status']);
            }
          } catch (e) {
            // Non-JSON message, treat as online if we already sent ID
            if (!_isConnecting) _setOnline(true);
          }
        },
        onDone: () {
          _isConnecting = false;
          _setOnline(false);
          _reconnect();
        },
        onError: (error) {
          _isConnecting = false;
          _setOnline(false);
          _reconnect();
        },
      );

      _startHeartbeat();
    } catch (e) {
      _isConnecting = false;
      _setOnline(false);
      _reconnect();
    }
  }

  void _setOnline(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
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
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isOnline) {
        connect();
      }
    });
  }

  void disconnect() {
    _stopHeartbeat();
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
