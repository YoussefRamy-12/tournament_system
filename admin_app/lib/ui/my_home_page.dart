import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/dashboard_notifier.dart';
import 'package:admin_app/theme/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:admin_app/ui/projector_screen.dart';
import 'package:admin_app/ui/review_screen.dart';
import 'package:admin_app/ui/setup_screen.dart';
import 'package:admin_app/ui/admin_history_screen.dart';
import 'package:admin_app/ui/all_players_screen.dart';
import 'package:admin_app/ui/connection_screen.dart';
import 'package:admin_app/ui/full_control_screen.dart';
import 'package:admin_app/ui/leader_approval_screen.dart';
import 'package:admin_app/ui/leaderboard_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _dbHelper = DatabaseHelper();
  Future<Map<String, dynamic>>? _dashboardStatsFuture;

  Future<Map<String, dynamic>> get _dashboardStats {
    _dashboardStatsFuture ??= _dbHelper.getAdminDashboardStats();
    return _dashboardStatsFuture!;
  }

  void _loadStats() {
    setState(() {
      _dashboardStatsFuture = _dbHelper.getAdminDashboardStats();
    });
  }

  Future<void> _handleRefresh() async {
    _loadStats();
    await _dashboardStats;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tournament Admin"),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => ThemeService.instance.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<void>(
        stream: DashboardNotifier.instance.onUpdate,
        builder: (context, _) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _dbHelper.getAdminDashboardStats(),
            builder: (context, snapshot) {
              final stats =
                  snapshot.data ??
                  {
                    'pendingTx': 0,
                    'onlineLeaders': 0,
                    'pendingLeaders': 0,
                    'approvedLeaders': 0,
                    'totalMembers': 0,
                  };

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isDark),
                          const SizedBox(height: 32),
                          _buildLiveStats(stats, isDark),
                          const SizedBox(height: 40),
                          _buildSectionTitle("Active Operations"),
                          const SizedBox(height: 16),
                          _buildGrid([
                            _DashCard(
                              "Review Scores",
                              Icons.rate_review_rounded,
                              Colors.blue,
                              () => const ReviewScreen(),
                            ),
                            _DashCard(
                              "Leader Approval",
                              Icons.verified_user_rounded,
                              Colors.orange,
                              () => const LeaderApprovalScreen(),
                            ),
                            _DashCard(
                              "Full Control",
                              Icons.terminal_rounded,
                              Colors.blueGrey,
                              () => const FullControlScreen(),
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSectionTitle("Monitoring & Data"),
                          const SizedBox(height: 16),
                          _buildGrid([
                            _DashCard(
                              "Leaderboard",
                              Icons.leaderboard_rounded,
                              Colors.purple,
                              () => LeaderboardScreen(),
                            ),
                            _DashCard(
                              "Transactions",
                              Icons.receipt_long_rounded,
                              Colors.teal,
                              () => const AdminHistoryScreen(),
                            ),
                            _DashCard(
                              "Projector View",
                              Icons.monitor_rounded,
                              Colors.indigo,
                              () => const ProjectorStatsScreen(),
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSectionTitle("System Setup"),
                          const SizedBox(height: 16),
                          _buildGrid([
                            _DashCard(
                              "QR Connection",
                              Icons.qr_code_2_rounded,
                              Colors.blueGrey,
                              () => ConnectionScreen(),
                            ),
                            _DashCard(
                              "Settings",
                              Icons.settings_suggest_rounded,
                              Colors.blueGrey,
                              () => const SetupScreen(),
                            ),
                          ]),
                          const SizedBox(height: 40),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.05, end: 0),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back,",
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const Text(
          "Dashboard Overview",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLiveStats(Map<String, dynamic> stats, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final pendingCard = _buildStatItem(
          "Pending Points",
          stats['pendingTx'].toString(),
          Icons.auto_graph_rounded,
          Colors.orange,
          () => const ReviewScreen(),
        );

        final totalCard = _buildStatItem(
          "Total Players",
          stats['totalMembers'].toString(),
          Icons.people_alt_rounded,
          Colors.blue,
          () => const AllPlayersScreen(),
        );

        return (isNarrow
            ? Column(
                children: [
                  pendingCard,
                  const SizedBox(height: 16),
                  totalCard,
                ],
              )
            : Row(
                children: [
                  Expanded(child: pendingCard),
                  const SizedBox(width: 16),
                  Expanded(child: totalCard),
                ],
              )).animate().scale(
          delay: 200.ms,
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Widget Function() destination,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination()),
          ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: children,
        );
      },
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function() destination;

  const _DashCard(this.title, this.icon, this.color, this.destination);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destination()),
              ),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(
          delay: 2000.ms,
          duration: 1500.ms,
          color: color.withValues(alpha: 0.1),
        );
  }
}
