import 'dart:async';
import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';

import '../network/api_client.dart';
import '../network/connection_manager.dart';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  State<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends State<WaitingApprovalScreen> {
  Timer? _timer;
  final ApiClient _apiClient = ApiClient();
  final ConnectionManager _connection = ConnectionManager();

  @override
  void initState() {
    super.initState();
    // 1. Ensure we are connected to WebSocket so we show as "Online"
    _apiClient.connectWebSocket();

    // 2. Start checking every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final leaderId = await _connection.getOrGenerateLeaderId();
    final status = await _apiClient.checkLeaderStatus(leaderId);

    if (!mounted) return;

    if (status == 'APPROVED') {
      _timer?.cancel();
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (status == 'REJECTED') {
      _timer?.cancel();
      _showRejectedDialog(); // This breaks the loop and shows the "Try Again" button
    } else if (status == 'NOT_FOUND') {
      _timer?.cancel();
      _showRemovedDialog();
    } else if (status == 'ERROR' || status == 'CONNECTION_ERROR') {
      // Optional: Show a small toast or message that the server is unreachable
      // print("Waiting for server to recover...");
    }
  }

  
  void _showRemovedDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('registration_removed_title')),
        content: Text(loc.translate('registration_removed_message')),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _connection.clearRegistration();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/scanner',
                  (route) => false,
                );
              }
            },
            child: Text(loc.translate('return_to_scan')),
          ),
        ],
      ),
    );
  }

  void _showRejectedDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('access_denied_title')),
        content: Text(loc.translate('access_denied_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/scanner',
              (route) => false,
            ),
            child: Text(loc.translate('return_to_scan')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                loc.translate('waiting_for_approval'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                loc.translate('ask_admin_approval'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _checkStatus, // Manual refresh button
                child: Text(loc.translate('check_status_now')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
