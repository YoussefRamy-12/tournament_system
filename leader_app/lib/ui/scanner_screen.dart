import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:leader_app/ui/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('scan_admin_qr'))),
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
                Text(
                  loc.translate('trouble_scanning'),
                  style: const TextStyle(color: Colors.white70),
                ),
                TextButton(
                  onPressed: _showManualIpDialog,
                  style: TextButton.styleFrom(backgroundColor: Colors.black45),
                  child: Text(loc.translate('enter_ip_manually'),
                      style: const TextStyle(color: Colors.white)),
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
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('manual_server_connect')),
        content: TextField(
          controller: _ipController,
          decoration: InputDecoration(
            hintText: "e.g., 192.168.1.15",
            labelText: loc.translate('server_ip'),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.translate('cancel')),
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
            child: Text(loc.translate('ok')),
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
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('connected_successfully')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/registration', (route) => false);
      }
    } else {
      // Revert if failed
      if (oldUrl != null) await conn.saveUrl(oldUrl);
      
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translateWithParam('connection_failed_details', 'url', url)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: loc.translate('details'),
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc.translate('connection_failed_title')),
                    content: Text(loc.translateWithParam('connection_failed_message', 'url', url)),
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
}
