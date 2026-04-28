import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/network/connection_manager.dart';

class RegistrationScreen extends StatefulWidget {
  // final String serverUrl;
  const RegistrationScreen({super.key,/* required this.serverUrl*/});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure we are connected to WebSocket so we show as "Online" to the admin
    ApiClient().connectWebSocket();
  }
  
void _register() async {
    // 1. Validation: Don't submit if name is empty
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('please_enter_name'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    String? serverUrl;
    try {
      final conn = ConnectionManager();
      
      // 2. Properly AWAIT the URL retrieval
      serverUrl = await conn.getUrl();
      
      if (serverUrl == null) {
        throw Exception(AppLocalizations.of(context).translate('server_url_not_found'));
      }

      final leaderId = await conn.getOrGenerateLeaderId();
      await conn.saveLeaderName(_nameController.text.trim());

      // 3. Make the Network Request
      final response = await http.post(
        Uri.parse('$serverUrl/register-leader'),
        body: jsonEncode({
          'id': leaderId,
          'name': /*_nameController.text.trim()*/ await conn.getLeaderName(),
          'deviceInfo': 'Mobile Device', 
        }),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10)); // Add a timeout so it doesn't spin forever

      if (response.statusCode == 200) {
        // 4. Save registration status locally
        await conn.setRegistered();
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/waiting_approval');
        }
      } else {
        // throw Exception("Server returned ${response.statusCode}");
        throw Exception("Server Error 500: ${response.body}");
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      print("❌ Registration failed to $serverUrl: $e");
      
      String displayError = e.toString();
      if (e is http.ClientException || e.toString().contains("SocketException")) {
        displayError = "Connection Failed. Ensure you are on the same Wi-Fi as the Admin Laptop at $serverUrl";
      }

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('error')}: $displayError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: loc.translate('details'),
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc.translate('detailed_error')),
                    content: Text("Target: $serverUrl\n\nError: $e"),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('ok')))],
                  )
                );
              },
            ),
          ),
        );
      }
    }
  }
  // void _register() async {
  //   setState(() => _isSubmitting = true);
    
  //   final conn = ConnectionManager();
  //   final leaderId = await conn.getOrGenerateLeaderId();
  //   final serverUrl = await conn.getUrl();
    
  //   // Save the URL first so we can talk to the server
  //   // await conn.saveUrl(serverUrl as String);

  //   final response = await http.post(
  //     Uri.parse('$serverUrl/register-leader'),
  //     body: jsonEncode({
  //       'id': leaderId,
  //       'name': _nameController.text,
  //       'deviceInfo': 'Android/iOS Device', // Optional: capture device model
  //     }),
  //     headers: {'Content-Type': 'application/json'},
  //   );

  //   if (response.statusCode == 200) {
  //     // Save registration status locally
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool('is_registered', true);
      
  //     // Go to a "Waiting" screen or Home
  //     if (mounted) {
  //       Navigator.pushReplacementNamed(context, '/waiting_approval');
  //     }
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('leader_registration'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Connection Status Indicator
            ValueListenableBuilder<bool>(
              valueListenable: ApiClient().isOnline,
              builder: (context, isOnline, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isOnline ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.check_circle : Icons.error,
                        color: isOnline ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? loc.translate('connected_to_server') : loc.translate('searching_for_server'),
                        style: TextStyle(
                          color: isOnline ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Text(loc.translate('registration_instruction'), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: loc.translate('full_name'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(loc.translate('register_and_continue'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}