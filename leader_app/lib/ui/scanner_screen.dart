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
    if (url == null || !url.startsWith('http') || url.isEmpty) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final conn = ConnectionManager();
    final apiClient = ApiClient();

    // 1. TEMPORARILY save for testing
    final oldUrl = await conn.getUrl();
    await conn.saveUrl(url);

    // 2. Validate connection
    bool isAvailable = await apiClient.isServerAvailable();

    if (mounted) {
      Navigator.pop(context); // Close loading indicator
    }

    if (isAvailable) {
      // 3. Generate the ID immediately
      await conn.getOrGenerateLeaderId();

      // 4. TRIGGER WEBSOCKET IMMEDIATELY
      apiClient.connectWebSocket();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to server successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/registration', (route) => false);
      }
    } else {
      // Revert if failed
      if (oldUrl != null) await conn.saveUrl(oldUrl);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reach server at $url. Check Wi-Fi/Firewall.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Connection Failed"),
                    content: Text(
                      "The app tried to reach $url but got no response.\n\n"
                      "Possible causes:\n"
                      "1. Phone and Laptop are on DIFFERENT Wi-Fi.\n"
                      "2. Windows Firewall is blocking Port 8080.\n"
                      "3. The IP address has changed on the laptop."
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                  )
                );
              },
            ),
          ),
        );
      }
    }
  }
}
