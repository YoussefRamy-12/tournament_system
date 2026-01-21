import 'dart:async';

import 'package:flutter/material.dart';
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/ui/history_screen.dart';
import 'package:leader_app/ui/member_selector.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final _apiClient = ApiClient();
  Timer? _heartbeatTimer;
  int _failureCount = 0;
  bool _isOnline = true;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    // Check connection every 10 seconds
    // _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    WidgetsBinding.instance.addObserver(this);
    _startPulse();
    // });
  }

  void _startPulse() {
    _heartbeatTimer?.cancel();

    // Determine wait time based on failure count
    int secondsToWait;
    if (_failureCount == 0) {
      secondsToWait = 15; // Healthy: Check every 15s
    } else if (_failureCount == 1) {
      secondsToWait = 5; // First fail: Check again quickly
    } else if (_failureCount == 2) {
      secondsToWait = 10;
    } else if (_failureCount == 3) {
      secondsToWait = 30;
    } else {
      secondsToWait = 60; // Major issue: Check once a minute
    }

    _heartbeatTimer = Timer(Duration(seconds: secondsToWait), () {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    bool available = await _apiClient.isServerAvailable();

    if (available) {
      // SUCCESS
      if (!_isOnline) {
        setState(() {
          _isOnline = true;
          _isReconnecting = false;
        });
      }
      _failureCount = 0; // Reset failures
    } else {
      // FAILURE
      _failureCount++;

      if (_isOnline) {
        setState(() {
          _isOnline = false;
          _isReconnecting = true;
        });

        // Try to find the new IP only on the first few failures
        if (_failureCount <= 2) {
          _attemptReconnection();
        } else {
          setState(() => _isReconnecting = false);
        }
      }
    }

    // Schedule the next pulse regardless of outcome
    if (mounted) _startPulse();
  }

  Future<void> _attemptReconnection() async {
    String? newIp = await _apiClient.findNewServerIP();
    if (newIp != null) {
      _failureCount = 0;
      setState(() {
        _isOnline = true;
        _isReconnecting = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is back! Check immediately and restart pulse
      _checkConnection();
    } else if (state == AppLifecycleState.paused) {
      // App is paused, stop heartbeat
      _heartbeatTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Text(widget.title),
            const SizedBox(width: 16),
            // Connection Status Indicator
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: _isOnline
                    ? Colors.green
                    : _isReconnecting
                    ? Colors.yellow
                    : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_problem),
            tooltip: 'Reconnect to Laptop',
            onPressed: () async {
              setState(() {
                _isReconnecting = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Re-scanning network for Admin laptop..."),
                ),
              );
              String? found = await _apiClient.findNewServerIP();
              if (!context.mounted) return;
              if (found != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Connected!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                setState(() {
                  _isReconnecting = false;
                  _isOnline = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Laptop not found. Check Wi-Fi."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('select member screen'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MemberSelector()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('history screen'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
