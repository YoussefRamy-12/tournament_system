import 'dart:io';
import '../services/logger_service.dart';

// import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  // final _networkInfo = NetworkInfo();

  Future<List<String>> getAllLocalIPs() async {
    List<String> foundIps = [];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          if (!address.isLoopback && address.type == InternetAddressType.IPv4) {
            final addr = address.address;
            // Prioritize common private LAN IPs
            if (addr.startsWith('192.168.') || 
                addr.startsWith('10.') || 
                addr.startsWith('172.')) {
              foundIps.add(addr);
            }
          }
        }
      }
      
      // If no private LAN IP found but we have other IPv4, add them
      if (foundIps.isEmpty && interfaces.isNotEmpty) {
        for (var interface in interfaces) {
          for (var address in interface.addresses) {
             if (address.type == InternetAddressType.IPv4) {
               foundIps.add(address.address);
             }
          }
        }
      }
    } catch (e) {
      LoggerService.instance.error('NETWORK', 'Error getting Local IPs: $e');
    }
    return foundIps.toSet().toList(); // Return unique IPs
  }

  // Keep the old one for compatibility temporarily, or just migrate it
  Future<String?> getLocalIP() async {
    final ips = await getAllLocalIPs();
    return ips.isNotEmpty ? ips.first : null;
  }
}
