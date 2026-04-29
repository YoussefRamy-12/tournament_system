import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:admin_app/database/db_helper.dart';
import 'package:admin_app/server/online_leader_tracker.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';
import '../utils/app_localizations.dart';

class LeaderApprovalScreen extends StatefulWidget {
  const LeaderApprovalScreen({super.key});

  @override
  State<LeaderApprovalScreen> createState() => _LeaderApprovalScreenState();
}

class _LeaderApprovalScreenState extends State<LeaderApprovalScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _handleAction(BuildContext context, String id, String status, AppLocalizations loc) async {
    await _dbHelper.updateLeaderStatus(id, status);

    if (status == 'APPROVED') {
      OnlineLeaderTracker.instance.sendToLeader(
          id, '{"type": "status_update", "status": "APPROVED"}');
    } else if (status == 'REJECTED') {
      OnlineLeaderTracker.instance.sendToLeader(
          id, '{"type": "status_update", "status": "REJECTED"}');
    }

    if (!context.mounted) return;
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${loc.translate('status_updated')} ${loc.translate(status.toLowerCase())}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        backgroundColor: AppTheme.getStatusColor(status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('leader_management')),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark
              ? AppTheme.darkMutedTextColor
              : AppTheme.lightMutedTextColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: [
            Tab(text: loc.translate('pending')),
            Tab(text: loc.translate('approved')),
            Tab(text: loc.translate('blocked')),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllLeaders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          final pending = all.where((l) => l['status'] == 'PENDING').toList();
          final approved = all.where((l) => l['status'] == 'APPROVED').toList();
          final rejected = all.where((l) => l['status'] == 'REJECTED').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderList(pending, 'PENDING', isDark, loc),
              _buildLeaderList(approved, 'APPROVED', isDark, loc),
              _buildLeaderList(rejected, 'REJECTED', isDark, loc),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderList(
      List<Map<String, dynamic>> items, String status, bool isDark, AppLocalizations loc) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        message: loc.translate('no_leaders_here'),
        subtitle: '${loc.translate('no_transactions_subtitle')}', // Reusing subtitle key
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceMd),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final leader = items[index];
            return _buildLeaderCard(leader, isDark, loc)
                .animate()
                .fadeIn(delay: (index * 40).ms)
                .slideY(begin: 0.05, end: 0);
          },
        ),
      ),
    );
  }

  Widget _buildLeaderCard(Map<String, dynamic> leader, bool isDark, AppLocalizations loc) {
    final String currentStatus = leader['status'];
    final String leaderId = leader['id'];
    final color = AppTheme.getStatusColor(currentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: AppCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            // Avatar with online indicator
            StreamBuilder<void>(
              stream: OnlineLeaderTracker.instance.onStatusChange,
              builder: (context, _) {
                bool isOnline = OnlineLeaderTracker.instance.onlineLeaderIds
                    .contains(leaderId);
                return Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(Icons.person_rounded, color: color),
                    ),
                    if (isOnline && currentStatus == 'APPROVED')
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isDark
                                    ? AppTheme.darkCardColor
                                    : Colors.white,
                                width: 2),
                          ),
                        ).animate(onPlay: (c) => c.repeat()).shimmer(
                            duration: 2.seconds,
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: AppTheme.spaceMd),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leader['name'] ?? loc.translate('unknown_name'),
                    style: AppTheme.body16.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextColor
                          : AppTheme.lightTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'ID: ${leaderId.length > 8 ? leaderId.substring(0, 8) : leaderId}',
                        style: AppTheme.caption14.copyWith(
                            color: isDark
                                ? AppTheme.darkMutedTextColor
                                : AppTheme.lightMutedTextColor),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      StatusBadge(status: currentStatus),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentStatus != 'APPROVED')
                  IconButton(
                    icon: Icon(Icons.check_circle_rounded,
                        color: AppTheme.successColor),
                    tooltip: loc.translate('approve'),
                    onPressed: () => _handleAction(context, leaderId, 'APPROVED', loc),
                  ),
                if (currentStatus != 'REJECTED')
                  IconButton(
                    icon: Icon(Icons.block_rounded,
                        color: AppTheme.errorColor),
                    tooltip: loc.translate('block'),
                    onPressed: () => _handleAction(context, leaderId, 'REJECTED', loc),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
