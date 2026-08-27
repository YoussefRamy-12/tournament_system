import 'package:admin_app/providers/dashboard_provider.dart';
import 'package:admin_app/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:admin_app/ui/projector_screen.dart';
import 'package:admin_app/ui/review_screen.dart';
import 'package:admin_app/ui/settings_screen.dart';
import 'package:admin_app/ui/admin_history_screen.dart';
import 'package:admin_app/ui/all_players_screen.dart';
import 'package:admin_app/ui/connection_screen.dart';
import 'package:admin_app/ui/full_control_screen.dart';
import 'package:admin_app/ui/leader_approval_screen.dart';
import 'package:admin_app/ui/leaderboard_screen.dart';
import 'package:admin_app/ui/logs_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    // Watch the DashboardProvider for real-time updates
    final dashboard = context.watch<DashboardProvider>();
    final stats = dashboard.stats;

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate("tournament_admin"))),
      body: RefreshIndicator(
        onRefresh: dashboard.refreshStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark, loc),
                  const SizedBox(height: 32),
                  _buildLiveStats(stats, isDark, loc),
                  const SizedBox(height: 32),
                  _buildOnlineLeadersSection(
                    (stats['onlineLeadersList'] as List?)
                        ?.cast<Map<String, dynamic>>(),
                    isDark,
                    loc,
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle(loc.translate("active_operations")),
                  const SizedBox(height: 16),
                  _buildGrid([
                    _DashCard(
                      loc.translate("review_scores"),
                      Icons.rate_review_rounded,
                      Colors.blue,
                      () => const ReviewScreen(),
                    ),
                    _DashCard(
                      loc.translate("leader_approval"),
                      Icons.verified_user_rounded,
                      Colors.orange,
                      () => const LeaderApprovalScreen(),
                    ),
                    _DashCard(
                      loc.translate("full_control"),
                      Icons.terminal_rounded,
                      Colors.blueGrey,
                      () => const FullControlScreen(),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle(loc.translate("monitoring_data")),
                  const SizedBox(height: 16),
                  _buildGrid([
                    _DashCard(
                      loc.translate("leaderboard"),
                      Icons.leaderboard_rounded,
                      Colors.purple,
                      () => LeaderboardScreen(),
                    ),
                    _DashCard(
                      loc.translate("transactions"),
                      Icons.receipt_long_rounded,
                      Colors.teal,
                      () => const AdminHistoryScreen(),
                    ),
                    _DashCard(
                      loc.translate("projector_view"),
                      Icons.monitor_rounded,
                      Colors.indigo,
                      () => const ProjectorStatsScreen(),
                    ),
                    _DashCard(
                      "System Logs",
                      Icons.article_rounded,
                      Colors.blueGrey,
                      () => const LogsScreen(),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle(loc.translate("system_setup")),
                  const SizedBox(height: 16),
                  _buildGrid([
                    _DashCard(
                      loc.translate("qr_connection"),
                      Icons.qr_code_2_rounded,
                      Colors.blueGrey,
                      () => ConnectionScreen(),
                    ),
                    _DashCard(
                      loc.translate("settings"),
                      Icons.settings_suggest_rounded,
                      Colors.blueGrey,
                      () => const SettingsScreen(),
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate("welcome_back"),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        Text(
          loc.translate("dashboard_overview"),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLiveStats(
    Map<String, dynamic> stats,
    bool isDark,
    AppLocalizations loc,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final pendingCard = _buildStatItem(
          loc.translate("pending_points"),
          stats['pendingTx'].toString(),
          Icons.auto_graph_rounded,
          Colors.orange,
          () => const ReviewScreen(),
        );

        final totalCard = _buildStatItem(
          loc.translate("total_players"),
          stats['totalMembers'].toString(),
          Icons.people_alt_rounded,
          Colors.blue,
          () => const AllPlayersScreen(),
        );

        final onlineCard = _buildStatItem(
          loc.translate("online_leaders"),
          stats['onlineLeaders'].toString(),
          Icons.wifi_tethering_rounded,
          Colors.teal,
          () => const LeaderApprovalScreen(),
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
                    const SizedBox(width: 16),
                    Expanded(child: onlineCard),
                  ],
                ))
            .animate()
            .scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildOnlineLeadersSection(
    List<Map<String, dynamic>>? leaders,
    bool isDark,
    AppLocalizations loc,
  ) {
    if (leaders == null || leaders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_tethering_rounded,
                color: Colors.teal,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            _buildSectionTitle(loc.translate("online_leaders")),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${leaders.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: leaders.length,
            itemBuilder: (context, index) {
              final leader = leaders[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: isDark ? 0.3 : 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          leader['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.tealAccent,
                              size: 8,
                            ),
                            SizedBox(width: 4),
                            Text(
                              loc.translate("active_now"),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
            },
          ),
        ),
      ],
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
