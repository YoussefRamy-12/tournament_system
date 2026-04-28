import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../server/network_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final NetworkService _networkService = NetworkService();
  String? _selectedIp;
  List<String> _availableIps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIps();
  }

  Future<void> _loadIps() async {
    final ips = await _networkService.getAllLocalIPs();
    if (mounted) {
      setState(() {
        _availableIps = ips;
        if (ips.isNotEmpty) {
          _selectedIp = ips.first;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connect Leader Devices")),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _availableIps.isEmpty
                ? const Text("Error: Could not find Local IP. Check Wi-Fi.")
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final String laptopIp = _selectedIp ?? _availableIps.first;
    final String connectionUrl = "http://$laptopIp:8080";

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Leader Connection QR",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_availableIps.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  const Text("Multiple IPs detected. Try another if one fails:",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  DropdownButton<String>(
                    value: _selectedIp,
                    items: _availableIps.map((ip) {
                      return DropdownMenuItem(value: ip, child: Text(ip));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedIp = val),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Ensure phones are on the same Wi-Fi",
              style: TextStyle(color: Colors.blueAccent)),
          const SizedBox(height: 40),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("⚠️ Troubleshooting:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTip("1. Check Windows Firewall: Ensure port 8080 allows incoming traffic."),
                _buildTip("2. Network Type: Make sure your Wi-Fi is set to 'Private', not 'Public'."),
                _buildTip("3. Test in Browser: Open http://$laptopIp:8080/ping on your PHONE."),
                _buildTip("4. IP Mismatch: If one IP doesn't work, select another from the dropdown above."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }
}