import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('my_scoring_requests')),
        backgroundColor: Colors.transparent,
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
            key: _refreshIndicatorKey,
            onRefresh: () => context.read<TournamentProvider>().fetchHistory(),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final loc = AppLocalizations.of(context);
    final tournament = context.watch<TournamentProvider>();

    if (tournament.isLoading && tournament.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(loc.translate('loading')),
          ],
        ),
      );
    } else if (tournament.errorMessage != null && tournament.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: PremiumCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  loc.translate('oops_something_wrong'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tournament.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                PremiumButton(
                  label: loc.translate('try_again'),
                  onPressed: () => _refreshIndicatorKey.currentState?.show(),
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allRequests = tournament.history;

    if (allRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80,
              color: AppTheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              loc.translate('no_scores_yet'),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Filter data into groups
    final approved = allRequests
        .where((i) => i['status'] == 'APPROVED')
        .toList();
    final rejected = allRequests
        .where((i) => i['status'] == 'REJECTED')
        .toList();
    final pending = allRequests.where((i) => i['status'] == 'PENDING').toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        if (pending.isNotEmpty)
          _buildStatusSection(
            loc.translate('pending_requests'),
            Colors.orange,
            pending,
            Icons.hourglass_empty,
          ),
        if (pending.isNotEmpty) const SizedBox(height: 24),
        if (approved.isNotEmpty)
          _buildStatusSection(
            loc.translate('approved'),
            Colors.green,
            approved,
            Icons.check_circle,
          ),
        if (approved.isNotEmpty) const SizedBox(height: 24),
        if (rejected.isNotEmpty)
          _buildStatusSection(
            loc.translate('rejected'),
            Colors.red,
            rejected,
            Icons.cancel,
          ),
      ],
    );
  }

  Widget _buildStatusSection(
    String status,
    Color color,
    List<Map<String, dynamic>> items,
    IconData icon,
  ) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ...items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: PremiumCard(
                  onTap: () => _showTransactionDetails(context, item),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${item['points'] > 0 ? "+" : ""}${item['points']}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item['targetName'] ??
                                      item['memberName'] ??
                                      loc.translate('unknown'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (item['target_type'] == 'TEAM') ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.group_rounded,
                                    size: 14,
                                    color: AppTheme.primary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['tag']}',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                            if (item['description'] != null &&
                                item['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black45,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        item['timestamp'].toString().length >= 16
                            ? item['timestamp'].toString().substring(11, 16)
                            : "",
                        style: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ],
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.05, end: 0);
  }
}

void _showTransactionDetails(BuildContext context, Map<String, dynamic> t) {
  final points = t['points'] ?? 0;
  final isPositive = points >= 0;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Transaction Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailTile(
            t['target_type'] == 'TEAM' ? Icons.groups : Icons.person,
            t['target_type'] == 'TEAM' ? 'Team' : 'Member',
            t['targetName'] ?? t['memberName'] ?? 'Unknown',
          ),
          _buildDetailTile(
            Icons.stars_rounded,
            'Points',
            '${isPositive ? "+" : ""}$points',
            valueColor: isPositive ? Colors.greenAccent : Colors.redAccent,
          ),
          _buildDetailTile(Icons.label_outline, 'Category', t['tag'] ?? 'N/A'),
          _buildDetailTile(
            Icons.badge_outlined,
            'Submitted By',
            t['leaderName'] ?? 'Unknown Leader',
          ),
          _buildDetailTile(
            Icons.access_time,
            'Timestamp',
            t['timestamp'].toString(),
          ),
          _buildDetailTile(
            Icons.info_outline,
            'Status',
            t['status'] ?? 'N/A',
            valueColor: t['status'] == 'APPROVED'
                ? Colors.greenAccent
                : t['status'] == 'REJECTED'
                ? Colors.redAccent
                : Colors.orange,
          ),
          if (t['description'] != null &&
              t['description'].toString().isNotEmpty) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Note: ${t['description']}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildDetailTile(
  IconData icon,
  String label,
  String value, {
  Color? valueColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, size: 20, color: Colors.indigoAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
