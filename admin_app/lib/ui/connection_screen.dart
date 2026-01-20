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

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Leader Connection QR", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                // The QR Code Widget
                QrImageView(
                  data: connectionUrl,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 20),
                Text("IP Address: $laptopIp", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Ensure phones are on the same Wi-Fi"),
              ],
            );
          },
        ),
      ),
    );
  }
}