import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../network/api_client.dart';
import '../network/connection_manager.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _hasScanned = false;
  late bool _hasRegistered;

  @override
  void initState() {
    super.initState();
    _initializeRegistration();
  }

  Future<void> _initializeRegistration() async {
    _hasRegistered = await ConnectionManager().isRegistered();
    // Ensure we are connected if we already have a URL
    if (await ConnectionManager().getUrl() != null) {
      ApiClient().connectWebSocket();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Admin QR Code")),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_hasRegistered) {
                // If already registered, do nothing on scan
                MobileScannerController().stop();
                dispose();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
                return;
              } else {
                if (_hasScanned) {
                  MobileScannerController().stop();

                  return;
                } else {
                  _hasScanned = true;

                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? scannedUrl = barcodes.first.rawValue;
                    _processUrl(scannedUrl);
                  }
                }
              }
            },
          ),
          // --- MANUAL IP BUTTON ---
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  "Trouble scanning?",
                  style: TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: _showManualIpDialog,
                  style: TextButton.styleFrom(backgroundColor: Colors.black45),
                  child: const Text("Enter Server IP Manually",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showManualIpDialog() {
    final TextEditingController _ipController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manual Server Connect"),
        content: TextField(
          controller: _ipController,
          decoration: const InputDecoration(
            hintText: "e.g., 192.168.1.15",
            labelText: "Server IP",
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              String ip = _ipController.text.trim();
              if (ip.isNotEmpty) {
                // Ensure it has http:// and :8080 if missing
                if (!ip.startsWith('http')) ip = 'http://$ip';
                if (!ip.contains(':8080')) ip = '$ip:8080';
                _processUrl(ip);
              }
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  Future<void> _processUrl(String? url) async {
    if (url != null && url.startsWith('http') && url.isNotEmpty) {
      final conn = ConnectionManager();

      // 1. Save the URL
      await conn.saveUrl(url);

      // 2. Generate the ID immediately
      await conn.getOrGenerateLeaderId();

      // 3. TRIGGER WEBSOCKET IMMEDIATELY
      // This is crucial for showing up as "Online" to the admin
      ApiClient().connectWebSocket();

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to server successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // 2. Go to the Registration Screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/registration',
          (route) => false,
        );
      }
    }
  }
}
