import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../server/network_service.dart';
import '../theme/app_theme.dart';

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
        if (ips.isNotEmpty) _selectedIp = ips.first;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("QR Connection")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableIps.isEmpty
              ? _buildErrorState(isDark)
              : _buildContent(isDark),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: AppTheme.errorColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  "No Network Found",
                  style: AppTheme.headline24.copyWith(
                    color:
                        isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Could not find a local IP address.\nPlease check your Wi-Fi connection.",
                  textAlign: TextAlign.center,
                  style: AppTheme.caption14.copyWith(
                    color:
                        isDark
                            ? AppTheme.darkMutedTextColor
                            : AppTheme.lightMutedTextColor,
                  ),
                ),
              ],
            ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final String laptopIp = _selectedIp ?? _availableIps.first;
    final String connectionUrl = "http://$laptopIp:8080";

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLg,
            vertical: AppTheme.spaceXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ─── Title ───────────────────────────────────────────────
              Text(
                "Connect Leader Devices",
                style: AppTheme.headline24.copyWith(
                  color:
                      isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                ),
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                "Scan the QR code from the Leader App",
                style: AppTheme.caption14.copyWith(
                  color:
                      isDark
                          ? AppTheme.darkMutedTextColor
                          : AppTheme.lightMutedTextColor,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: AppTheme.spaceXl),

              // ─── IP Selector ─────────────────────────────────────────
              if (_availableIps.length > 1)
                Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spaceLg),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.router_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedIp,
                            isExpanded: true,
                            items:
                                _availableIps.map((ip) {
                                  return DropdownMenuItem(
                                    value: ip,
                                    child: Text(
                                      ip,
                                      style: AppTheme.body16.copyWith(
                                        color:
                                            isDark
                                                ? AppTheme.darkTextColor
                                                : AppTheme.lightTextColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (val) => setState(() => _selectedIp = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms),

              // ─── QR Card ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: connectionUrl,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMd,
                        vertical: AppTheme.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Text(
                        laptopIp,
                        style: AppTheme.title18.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: AppTheme.spaceXl),

              // ─── Quick-step instructions ──────────────────────────────
              _buildInstructionCard(
                icon: Icons.wifi_rounded,
                color: AppTheme.infoColor,
                title: "Same Wi-Fi",
                subtitle: "Ensure all devices are on the same network",
                isDark: isDark,
                delay: 300,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              _buildInstructionCard(
                icon: Icons.qr_code_scanner_rounded,
                color: AppTheme.successColor,
                title: "Scan & Connect",
                subtitle: "Open the Leader App and scan this QR code",
                isDark: isDark,
                delay: 350,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              _buildInstructionCard(
                icon: Icons.verified_user_rounded,
                color: AppTheme.warningColor,
                title: "Approve Registration",
                subtitle: "Approve the leader request in Leader Management",
                isDark: isDark,
                delay: 400,
              ),

              const SizedBox(height: AppTheme.spaceXl),

              // ─── Troubleshooting ─────────────────────────────────────
              _buildTroubleshootingSection(laptopIp, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body16.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.caption14.copyWith(
                    color:
                        isDark
                            ? AppTheme.darkMutedTextColor
                            : AppTheme.lightMutedTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildTroubleshootingSection(String ip, bool isDark) {
    return ExpansionTile(
      leading: Icon(Icons.build_circle_rounded, color: AppTheme.warningColor),
      title: Text(
        "Troubleshooting",
        style: AppTheme.body16.copyWith(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
      collapsedBackgroundColor:
          isDark
              ? AppTheme.darkCardColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.05),
      children: [
        _buildTip(
          Icons.security_rounded,
          "Windows Firewall: Allow port 8080 for incoming traffic.",
        ),
        _buildTip(
          Icons.network_wifi_rounded,
          "Network Type: Set your Wi-Fi to 'Private' (not Public).",
        ),
        _buildTip(
          Icons.open_in_browser_rounded,
          "Test in Browser: Open http://$ip:8080/ping on your phone.",
        ),
        _buildTip(
          Icons.swap_horiz_rounded,
          "IP Mismatch: Try selecting a different IP from the dropdown.",
        ),
        const SizedBox(height: AppTheme.spaceSm),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.warningColor),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              text,
              style: AppTheme.caption14.copyWith(
                color: AppTheme.darkMutedTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
