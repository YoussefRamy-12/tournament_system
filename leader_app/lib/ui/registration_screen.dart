import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:leader_app/network/api_client.dart';
import 'package:leader_app/network/connection_manager.dart';
import 'package:leader_app/ui/feedback_screen.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackScreen(
              success: false,
              title: loc.translate('error'),
              message: displayError,
              primaryButtonLabel: loc.translate('try_again'),
              primaryButtonIcon: Icons.refresh_rounded,
              onPrimaryAction: () => Navigator.pop(context),
              secondaryButtonLabel: loc.translate('cancel'),
              onSecondaryAction: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('leader_registration')),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [AppTheme.darkBg, AppTheme.darkSurface] 
                : [AppTheme.lightBg, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Hero Icon/Illustration
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: const Icon(Icons.emoji_events, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 32),
                
                // Connection Status Indicator
                ValueListenableBuilder<bool>(
                  valueListenable: ApiClient().isOnline,
                  builder: (context, isOnline, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isOnline ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isOnline ? loc.translate('connected_to_server') : loc.translate('searching_for_server'),
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('registration_instruction'),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      PremiumTextField(
                        controller: _nameController,
                        label: loc.translate('full_name'),
                        prefixIcon: Icons.person_outline,
                        hintText: "e.g. John Doe",
                      ),
                      const SizedBox(height: 32),
                      PremiumButton(
                        label: loc.translate('register_and_continue'),
                        onPressed: _isSubmitting ? null : _register,
                        isLoading: _isSubmitting,
                        icon: Icons.arrow_forward,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}