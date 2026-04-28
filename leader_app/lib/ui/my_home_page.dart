import 'dart:async';

import 'package:flutter/material.dart';
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/ui/history_screen.dart';
import 'package:leader_app/ui/member_selector.dart';
import 'package:leader_app/ui/scanner_screen.dart';
import 'package:leader_app/ui/settings_screen.dart';
import 'package:leader_app/ui/app_localizations.dart';

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
  bool _isManualChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure we attempt to connect if not already
    _apiClient.connectWebSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is back! Check immediately
      _apiClient.connectWebSocket();
    }
  }

  Future<void> _manualReconnect() async {
    setState(() => _isManualChecking = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Re-scanning network for Admin laptop...")),
    );
    
    String? found = await _apiClient.findNewServerIP();
    
    if (mounted) {
      setState(() => _isManualChecking = false);
      if (found != null) {
        _apiClient.connectWebSocket();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connected!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laptop not found. Check Wi-Fi."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Text(loc.translate('test')),
            const SizedBox(width: 16),
            // --- Unified Connection Status Indicator ---
            ValueListenableBuilder<bool>(
              valueListenable: _apiClient.isOnline,
              builder: (context, isOnline, _) {
                return Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green
                        : _isManualChecking
                            ? Colors.yellow
                            : Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_problem),
            tooltip: loc.translate('reconnect'),
            onPressed: _isManualChecking ? null : _manualReconnect,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(loc.translate('scan_qr')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(loc.translate('select_member')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MemberSelector()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(loc.translate('history')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
