import 'package:flutter/material.dart';
import 'package:leader_app/providers/auth_provider.dart';
import 'package:leader_app/providers/connectivity_provider.dart';
import 'package:leader_app/providers/settings_provider.dart';
import 'package:leader_app/providers/tournament_provider.dart';
import 'package:leader_app/ui/history_screen.dart';
import 'package:leader_app/ui/member_selector.dart';
import 'package:leader_app/ui/scanner_screen.dart';
import 'package:leader_app/ui/settings_screen.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final connectivity = context.read<ConnectivityProvider>();
      connectivity.onStatusUpdate = (status) {
        if (mounted) {
          context.read<AuthProvider>().checkApproval();
        }
      };
      connectivity.connect();

      // FIX: When a leader is approved for the first time, the WS is already
      // online (connected from WaitingApprovalScreen), so onReconnect never
      // fires again. Trigger the full data fetch explicitly here.
      if (connectivity.isOnline && mounted) {
        final tournament = context.read<TournamentProvider>();
        await tournament.syncPendingTransactions();
        await tournament.fetchTeams();
        await tournament.prefetchOfflineData();
        await tournament.fetchHistory();
      }
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
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: connectivity.isOnline
                      ? Colors.green[700]
                      : (_isManualChecking ? Colors.yellow : Colors.red),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (connectivity.isOnline ? Colors.green : Colors.red)
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  connectivity.isOnline
                      ? Icons.check_circle_outline_rounded
                      : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
          // Offline Data Ready Indicator
          Consumer<TournamentProvider>(
            builder: (context, tournament, child) {
              if (tournament.isOfflineDataReady) {
                return Tooltip(
                  triggerMode: TooltipTriggerMode.tap,
                  waitDuration: Duration(seconds: 5),
                  showDuration: Duration(seconds: 3),
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
              } else if (tournament.isSyncing) {
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
                triggerMode: TooltipTriggerMode.tap,
                waitDuration: Duration(seconds: 10),
                showDuration: Duration(seconds: 5),
                onTriggered: () async {
                  await tournament.syncPendingTransactions();
                  await tournament.fetchTeams();
                  await tournament.prefetchOfflineData();
                  await tournament.fetchHistory();
                },
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
                // Manual offline sync card
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Consumer2<TournamentProvider, ConnectivityProvider>(
                    builder: (context, tournament, connectivity, _) {
                      final isSyncing = tournament.isSyncing;
                      final isReady = tournament.isOfflineDataReady;
                      final isOnline = connectivity.isOnline;

                      final gradient = isSyncing
                          ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)])
                          : isReady
                              ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                              : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]);

                      return PremiumCard(
                        onTap: (!isOnline || isSyncing)
                            ? null
                            : () async {
                                final t = context.read<TournamentProvider>();
                                await t.fetchTeams();
                                await t.prefetchOfflineData();
                              },
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: gradient.withOpacity(0.08),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: gradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: gradient.colors.first.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: isSyncing
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        isReady
                                            ? Icons.cloud_done_rounded
                                            : Icons.cloud_download_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSyncing
                                          ? loc.translate('syncing_data')
                                          : isReady
                                              ? loc.translate('offline_data_ready')
                                              : loc.translate('sync_offline_data'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isSyncing
                                          ? loc.translate('downloading_members')
                                          : isReady
                                              ? loc.translate('tap_to_refresh_offline')
                                              : isOnline
                                                  ? loc.translate('tap_to_download_offline')
                                                  : loc.translate('go_online_to_sync'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white54 : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isSyncing)
                                Icon(
                                  isOnline ? Icons.chevron_right_rounded : Icons.wifi_off_rounded,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
                    color: gradient.colors.first.withValues(alpha: 0.3),
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
