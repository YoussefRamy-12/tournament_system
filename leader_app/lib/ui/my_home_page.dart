import 'package:flutter/material.dart';
import 'package:leader_app/providers/auth_provider.dart';
import 'package:leader_app/providers/connectivity_provider.dart';
import 'package:leader_app/providers/settings_provider.dart';
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

    setState(() => _isManualChecking = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.translate('reconnecting'))));

    // For manual reconnect, we can try to find the server again if URL is lost or IP changed
    // but here we just trigger a refresh and check approval
    await auth.checkApproval();
    await connectivity.connect();

    if (mounted) {
      setState(() => _isManualChecking = false);
      if (connectivity.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('connected')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('laptop_not_found')),
            backgroundColor: Colors.red,
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
                      ? Colors.green
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
          IconButton(
            icon: const Icon(Icons.sync_problem),
            onPressed: _isManualChecking ? null : _manualReconnect,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(24),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
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
                      loc.translate('select_member'),
                      Icons.people_alt_rounded,
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
              ),
            ],
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

