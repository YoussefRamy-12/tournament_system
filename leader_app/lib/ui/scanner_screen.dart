import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../network/connection_manager.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Admin QR Code")),
      body: MobileScanner(
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

                if (scannedUrl != null &&
                    scannedUrl.startsWith('http') &&
                    scannedUrl.isNotEmpty) {
                  final conn = ConnectionManager();

                  // 1. Save the URL
                  await conn.saveUrl(scannedUrl);

                  // 2. Generate the ID immediately
                  await conn.getOrGenerateLeaderId();

                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('qr scanned successfully!'),
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
          }
        },
      ),
    );
  }
}
