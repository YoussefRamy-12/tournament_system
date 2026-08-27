import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/feedback_screen.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _hasScanned = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('scan_admin_qr'), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (auth.status == AuthStatus.approved) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                return;
              } else {
                if (_hasScanned) return;
                
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? scannedUrl = barcodes.first.rawValue;
                  if (scannedUrl != null) {
                    _hasScanned = true;
                    _processUrl(scannedUrl);
                  }
                }
              }
            },
          ),
          
          // Futuristic Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                backgroundBlendMode: BlendMode.dstOut,
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Scanner Line Animation
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [AppTheme.primary.withValues(alpha: 0), AppTheme.primary, AppTheme.primary.withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                       .moveY(begin: 0, end: 250, duration: 2.seconds, curve: Curves.easeInOut),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  loc.translate('registration_instruction'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
          
          // Manual IP Button at bottom
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Text(
                  loc.translate('trouble_scanning'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                PremiumButton(
                  label: loc.translate('enter_ip_manually'),
                  onPressed: _showManualIpDialog,
                  gradient: AppTheme.accentGradient,
                  icon: Icons.keyboard_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualIpDialog() {
    final TextEditingController ipController = TextEditingController();
    final loc = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.translate('manual_server_connect')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PremiumTextField(
              controller: ipController,
              label: loc.translate('server_ip'),
              prefixIcon: Icons.lan_outlined,
              hintText: "192.168.1.15",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
          ),
          PremiumButton(
            label: loc.translate('ok'),
            onPressed: () {
              Navigator.pop(context);
              String ip = ipController.text.trim();
              if (ip.isNotEmpty) {
                if (!ip.startsWith('http')) ip = 'http://$ip';
                if (!ip.contains(':8080')) ip = '$ip:8080';
                _processUrl(ip);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _processUrl(String url) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final auth = context.read<AuthProvider>();
    final success = await auth.processScannedUrl(url);

    if (mounted) {
      Navigator.pop(context); // Close loading indicator
    }

    if (success) {
      // Start WebSocket connection
      if (mounted) {
        context.read<ConnectivityProvider>().connect();
        
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('connected_successfully')),
            backgroundColor: Colors.green,
          ),
        );
        // Navigation is handled by main.dart listener
      }
    } else {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackScreen(
              success: false,
              title: loc.translate('connection_failed_title'),
              message: auth.errorMessage ?? loc.translateWithParam('connection_failed_message', 'url', url),
              primaryButtonLabel: loc.translate('try_again'),
              primaryButtonIcon: Icons.refresh_rounded,
              onPrimaryAction: () {
                Navigator.pop(context);
                setState(() => _hasScanned = false);
              },
            ),
          ),
        );
      }
    }
  }
}

