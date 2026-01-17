import 'dart:async';
import 'package:flutter/material.dart';
import 'package:leader_app/ui/scanner_screen.dart';
import '../network/api_client.dart';
import '../network/connection_manager.dart';

class WaitingApprovalScreen extends StatefulWidget {
  const WaitingApprovalScreen({Key? key}) : super(key: key);

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
    // Start checking every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final leaderId = await _connection.getOrGenerateLeaderId();
    final status = await _apiClient.checkLeaderStatus(leaderId);
    print( "Leader status: $status" );
    if (!mounted) return;

    if (status == 'APPROVED') {
      _timer?.cancel();
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (status == 'REJECTED') {
      _timer?.cancel();
      _showRejectedDialog(); // This breaks the loop and shows the "Try Again" button
    } else if (status == 'ERROR' || status == 'CONNECTION_ERROR') {
      // Optional: Show a small toast or message that the server is unreachable
      print("Waiting for server to recover...");
    }
  }

  void _showRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text('Your registration was not approved by the Admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/scanner', (route) => false),
            child: const Text('Return to Scan'),
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Waiting for Admin Approval...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please ask the Admin to approve your device on the laptop.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: _checkStatus, // Manual refresh button
                child: const Text('Check Status Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
