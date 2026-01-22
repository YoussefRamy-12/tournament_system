import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/dashboard_notifier.dart';
import 'package:flutter/material.dart';

import 'package:admin_app/ui/projector_screen.dart';
import 'package:admin_app/ui/review_screen.dart';
import 'package:admin_app/ui/setup_screen.dart';

import 'package:admin_app/ui/admin_history_screen.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light professional grey
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<void>(
        stream: DashboardNotifier.instance.onUpdate,
        builder: (context, _) {
          print('📥 MyHomePage: StreamBuilder detected an update event');
          return FutureBuilder<Map<String, dynamic>>(
            future: _dbHelper.getAdminDashboardStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                print('📊 MyHomePage: Dashboard stats fetched');
              }
              final stats =
                  snapshot.data ??
                  {
                    'pendingTx': 0,
                    'onlineLeaders': 0,
                    'pendingLeaders': 0,
                    'totalMembers': 0,
                  };

              return RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLiveStats(stats),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Active Operations"),
                      _buildGrid([
                        _DashCard(
                          "Review\nScores",
                          Icons.rate_review,
                          Colors.blue,
                          () => const ReviewScreen(),
                        ),
                        _DashCard(
                          "Leader\nApproval",
                          Icons.verified_user,
                          Colors.orange,
                          () => const LeaderApprovalScreen(),
                        ),
                        _DashCard(
                          "Full\nControl",
                          Icons.settings_input_component,
                          Colors.redAccent,
                          () => const FullControlScreen(),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Monitoring & Data"),
                      _buildGrid([
                        _DashCard(
                          "Leaderboard",
                          Icons.leaderboard,
                          Colors.purple,
                          () => LeaderboardScreen(),
                        ),
                        _DashCard(
                          "Transactions",
                          Icons.history,
                          Colors.teal,
                          () => const AdminHistoryScreen(),
                        ),
                        _DashCard(
                          "Projector\nView",
                          Icons.cast,
                          Colors.indigo,
                          () => const ProjectorStatsScreen(),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionTitle("System Setup"),
                      _buildGrid([
                        _DashCard(
                          "QR Link",
                          Icons.qr_code_scanner,
                          Colors.blueGrey,
                          () => ConnectionScreen(),
                        ),
                        _DashCard(
                          "Initial\nSetup",
                          Icons.settings,
                          Colors.grey,
                          () => const SetupScreen(),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLiveStats(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Primary Row: Critical Approvals
        Row(
          children: [
            _buildStatItem(
              "Pending Points",
              stats['pendingTx'].toString(),
              Icons.pending_actions,
              Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReviewScreen()),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildStatItem(
              "New Leaders",
              stats['pendingLeaders'].toString(),
              Icons.person_add_alt_1,
              Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Secondary Row: System Status
        Row(
          children: [
            _buildStatItem(
              "Online Leaders",
              stats['onlineLeaders'].toString(),
              Icons.sensors,
              Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderApprovalScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildStatItem(
              "Total Players",
              stats['totalMembers'].toString(),
              Icons.groups,
              Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: children,
    );
  }
}

// Interactive Dashboard Card
class _DashCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget Function() destination;

  const _DashCard(this.title, this.icon, this.color, this.destination);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination()),
          ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
