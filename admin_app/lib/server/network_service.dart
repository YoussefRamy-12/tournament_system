import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  final _networkInfo = NetworkInfo();

  Future<String?> getLocalIP() async {
    // This fetches the IP assigned by the Wi-Fi router
    String? ip = await _networkInfo.getWifiIP();
    return ip;
  }
}