import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leader_app/network/connection_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  // final String serverUrl;
  const RegistrationScreen({super.key,/* required this.serverUrl*/});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  
void _register() async {
    // 1. Validation: Don't submit if name is empty
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final conn = ConnectionManager();
      
      // 2. Properly AWAIT the URL retrieval
      final String? serverUrl = await conn.getUrl();
      
      if (serverUrl == null) {
        throw Exception("Server URL not found. Please scan again.");
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Leader Registration')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Enter your name to join the tournament as a Leader.'),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _register,
              child: const Text('Register and Continue'),
            )
          ],
        ),
      ),
    );
  }
}