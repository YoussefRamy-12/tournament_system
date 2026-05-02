import 'package:flutter/material.dart';
import 'package:leader_app/providers/auth_provider.dart';
import 'package:leader_app/providers/connectivity_provider.dart';
import 'package:leader_app/providers/settings_provider.dart';
import 'package:leader_app/providers/tournament_provider.dart';
import 'package:leader_app/ui/connection_failed_screen.dart';
import 'package:leader_app/ui/history_screen.dart';
import 'package:leader_app/ui/member_selector.dart';
import 'package:leader_app/ui/scanner_screen.dart';
import 'package:leader_app/ui/settings_screen.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:leader_app/ui/widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isManualChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure we attempt to connect if not already
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connectivity = context.read<ConnectivityProvider>();
      connectivity.onStatusUpdate = (status) {
        if (mounted) {
          context.read<AuthProvider>().checkApproval();
        }
      };
      connectivity.connect();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is back! Check immediately
      context.read<ConnectivityProvider>().connect();
    }
  }

  Future<void> _manualReconnect() async {
    final loc = AppLocalizations.of(context);
    final auth = context.read<AuthProvider>();
    final connectivity = context.read<ConnectivityProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isManualChecking = true);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(loc.translate('reconnecting'))),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // duration: const Duration(seconds: 3),
      ),
    );

    await auth.checkApproval();
    await connectivity.connect();

    if (mounted) {
      setState(() => _isManualChecking = false);
      messenger.clearSnackBars();
      if (connectivity.isOnline) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.translate('connected'))),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.translate('laptop_not_found'))),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivity = context.watch<ConnectivityProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('dashboard')),
        backgroundColor: Colors.transparent,
        actions: [
          // Connection Status Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: connectivity.isOnline
                      ? Colors.green[700]
                      : (_isManualChecking ? Colors.yellow : Colors.red),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (connectivity.isOnline ? Colors.green : Colors.red)
                          .withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Offline Data Ready Indicator
          Consumer<TournamentProvider>(
            builder: (context, tournament, child) {
              if (tournament.isOfflineDataReady) {
                return Tooltip(
                  message: loc.translate('offline_data_ready'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.cloud_done_rounded,
                      color: Colors.green[700],
                      size: 22,
                    ),
                  ),
                );
              } else if (connectivity.isOnline &&
                  !tournament.isOfflineDataReady) {
                return Tooltip(
                  message: loc.translate('syncing_data'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                );
              }
              return Tooltip(
                message: loc.translate('no_internet_connection'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isManualChecking
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: loc.translate('retry'),
                    splashRadius: 24,
                    onPressed: _manualReconnect,
                  ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppTheme.darkBg, AppTheme.darkSurface]
                : [AppTheme.lightBg, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: _manualReconnect,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('app_title'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<SettingsProvider>(
                        builder: (context, settings, _) {
                          return Text(
                            loc.translateWithParam(
                              'welcome_back',
                              'name',
                              settings.leaderName,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(24),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMenuCard(
                      context,
                      loc.translate('scan_qr'),
                      Icons.qr_code_scanner_rounded,
                      AppTheme.primaryGradient,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      loc.translate('add_score'),
                      Icons.add_circle_outline_rounded,
                      AppTheme.accentGradient,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemberSelector(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      loc.translate('history'),
                      Icons.history_rounded,
                      const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      context,
                      loc.translate('settings'),
                      Icons.settings_rounded,
                      const LinearGradient(
                        colors: [Color(0xFF64748B), Color(0xFF475569)],
                      ),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return PremiumCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: gradient.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
