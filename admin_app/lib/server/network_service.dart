import 'dart:io';

// import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  // final _networkInfo = NetworkInfo();

  Future<String?> getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (var interface in interfaces) {
        // Look for common Wi-Fi or LAN interfaces
        for (var address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            // Specifically look for 192.168.x.x, 10.x.x.x, or 172.16.x.x-172.31.x.x
            final addr = address.address;
            if (addr.startsWith('192.168.') || 
                addr.startsWith('10.') || 
                addr.startsWith('172.')) {
              return addr;
            }
          }
        }
      }

      // If no private LAN IP found, return the first non-loopback IPv4
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (e) {
      print("Error getting Local IP: $e");
    }
    return null;
  }
}
