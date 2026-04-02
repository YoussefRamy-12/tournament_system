import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../server/network_service.dart';

class ConnectionScreen extends StatelessWidget {
  final NetworkService _networkService = NetworkService();

  ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect Leader Devices")),
      body: Center(
        child: FutureBuilder<String?>(
          future: _networkService.getLocalIP(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Text("Error: Could not find Local IP. Check Wi-Fi.");
            }

            final String laptopIp = snapshot.data!;
            // The data inside the QR code
            final String connectionUrl = "http://$laptopIp:8080";

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Leader Connection QR",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // The QR Code Widget
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: connectionUrl,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("IP Address: $laptopIp",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text("Ensure phones are on the same Wi-Fi",
                      style: TextStyle(color: Colors.blueAccent)),
                  const SizedBox(height: 40),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("⚠️ Troubleshooting:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildTip("1. Check Windows Firewall: Ensure port 8080 allows incoming traffic."),
                        _buildTip("2. Network Type: Make sure your Wi-Fi is set to 'Private', not 'Public'."),
                        _buildTip("3. Test in Browser: Open http://$laptopIp:8080/ping on your PHONE."),
                        _buildTip("4. IP Mismatch: If $laptopIp is not your actual IP, check your network settings."),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }
}