import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/online_leader_tracker.dart';

class LeaderApprovalScreen extends StatefulWidget {
  const LeaderApprovalScreen({super.key});

  @override
  State<LeaderApprovalScreen> createState() => _LeaderApprovalScreenState();
}

class _LeaderApprovalScreenState extends State<LeaderApprovalScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _handleAction(String id, String status) async {
    await _dbHelper.updateLeaderStatus(id, status);
    
    if (status == 'APPROVED') {
      OnlineLeaderTracker.instance.sendToLeader(id, '{"type": "status_update", "status": "APPROVED"}');
    } else if (status == 'REJECTED') {
      OnlineLeaderTracker.instance.sendToLeader(id, '{"type": "status_update", "status": "REJECTED"}');
    }

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leader status updated to $status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leader Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Blocked'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllLeaders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final all = snapshot.data!;
          final pending = all.where((l) => l['status'] == 'PENDING').toList();
          final approved = all.where((l) => l['status'] == 'APPROVED').toList();
          final rejected = all.where((l) => l['status'] == 'REJECTED').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderList(pending, Colors.orange, isDark),
              _buildLeaderList(approved, Colors.green, isDark),
              _buildLeaderList(rejected, Colors.red, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderList(List<Map<String, dynamic>> items, Color color, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: color.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No leaders in this category', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final leader = items[index];
        return _buildLeaderCard(leader, color, isDark)
          .animate()
          .fadeIn(delay: (index * 50).ms)
          .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildLeaderCard(Map<String, dynamic> leader, Color color, bool isDark) {
    final String currentStatus = leader['status'];
    final String leaderId = leader['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: StreamBuilder<void>(
          stream: OnlineLeaderTracker.instance.onStatusChange,
          builder: (context, _) {
            bool isOnline = OnlineLeaderTracker.instance.onlineLeaderIds.contains(leaderId);
            return Stack(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(Icons.person_rounded, color: color),
                ),
                if (isOnline && currentStatus == 'APPROVED')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                  ),
              ],
            );
          },
        ),
        title: Text(
          leader['name'] ?? 'Unknown Name',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'ID: ${leaderId.length > 8 ? leaderId.substring(0, 8) : leaderId}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentStatus != 'APPROVED')
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                onPressed: () => _handleAction(leaderId, 'APPROVED'),
              ),
            if (currentStatus != 'REJECTED')
              IconButton(
                icon: const Icon(Icons.block_rounded, color: Colors.red),
                onPressed: () => _handleAction(leaderId, 'REJECTED'),
              ),
          ],
        ),
      ),
    );
  }
}
