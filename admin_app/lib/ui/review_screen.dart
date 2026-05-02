import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';
import '../utils/app_localizations.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _handleAction(
    BuildContext context,
    String id,
    String status,
    AppLocalizations loc,
  ) async {
    await _dbHelper.updateTransactionStatus(id, status);
    if (!context.mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${loc.translate('transaction')} ${loc.translate(status.toLowerCase())}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.getStatusColor(status),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  void _handleMassAction(AppLocalizations loc, String status) async {
    final count = (await _dbHelper.getPendingTransactions()).length;
    if (count == 0) return;

    if (!mounted) return;
    String statusText = loc.translate(status.toLowerCase());

    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                title: Text('$statusText ${loc.translate('all')}?'),
                content: Text(
                  loc
                      .translate('mass_action_confirm')
                      .replaceAll('{status}', statusText)
                      .replaceAll('{count}', count.toString()),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(loc.translate('cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          status == 'APPROVED'
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                    ),
                    child: Text(
                      '${loc.translate('yes')}, $statusText ${loc.translate('all')}',
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      await _dbHelper.updateAllPendingStatus(status);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.translate('all')} ${loc.translate('requests')} $statusText',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.getStatusColor(status),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('pending_scores')),
        actions: [
          IconButton(
            tooltip: loc.translate('approve_all'),
            icon: Icon(Icons.done_all_rounded, color: AppTheme.successColor),
            onPressed: () => _handleMassAction(loc, 'APPROVED'),
          ),
          IconButton(
            tooltip: loc.translate('reject_all'),
            icon: Icon(Icons.remove_done_rounded, color: AppTheme.errorColor),
            onPressed: () => _handleMassAction(loc, 'REJECTED'),
          ),
          const SizedBox(width: AppTheme.spaceSm),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getPendingTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_outline_rounded,
              message: loc.translate('all_caught_up'),
              subtitle: loc.translate('no_pending_scores'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                  vertical: AppTheme.spaceMd,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildReviewCard(item, isDark, loc)
                      .animate()
                      .fadeIn(delay: (index * 40).ms)
                      .slideX(begin: 0.05, end: 0);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> item,
    bool isDark,
    AppLocalizations loc,
  ) {
    final points = item['points'] ?? 0;
    final isPositive = points >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: AppCard(
        onTap: () => _showDetailsDialog(context, item, loc),
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Center(
                child: Text(
                  '${isPositive ? "+" : ""}$points',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['targetName'] ?? loc.translate('unknown'),
                        style: AppTheme.title18.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppTheme.darkTextColor
                                  : AppTheme.lightTextColor,
                        ),
                      ),
                      if (item['target_type'] == 'TEAM') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            "TEAM",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(
                    '${item['tag']} • ${item['leaderName'] ?? loc.translate("unknown")}',
                    style: AppTheme.caption14.copyWith(
                      color:
                          isDark
                              ? AppTheme.darkMutedTextColor
                              : AppTheme.lightMutedTextColor,
                    ),
                  ),
                  if (item['description'] != null &&
                      item['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spaceXs),
                      child: Text(
                        item['description'],
                        style: AppTheme.label12.copyWith(
                          color:
                              isDark
                                  ? AppTheme.darkMutedTextColor
                                  : AppTheme.lightMutedTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color:
                  isDark
                      ? AppTheme.darkMutedTextColor
                      : AppTheme.lightMutedTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    Map<String, dynamic> item,
    AppLocalizations loc,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          title: Text(loc.translate('review_transaction')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailTile(
                item['target_type'] == 'TEAM'
                    ? Icons.groups_2_rounded
                    : Icons.person,
                item['target_type'] == 'TEAM'
                    ? 'Team'
                    : loc.translate('member'),
                item['targetName'] ?? loc.translate('unknown'),
                isDark,
              ),
              _buildDetailTile(
                Icons.stars_rounded,
                loc.translate('points'),
                '${item['points']}',
                isDark,
              ),
              _buildDetailTile(
                Icons.label_outline,
                loc.translate('category'),
                item['tag'] ?? 'N/A',
                isDark,
              ),
              _buildDetailTile(
                Icons.badge_outlined,
                loc.translate('submitted_by'),
                item['leaderName'] ?? loc.translate('unknown_leader'),
                isDark,
              ),
              _buildDetailTile(
                Icons.access_time,
                loc.translate('timestamp'),
                item['timestamp'].toString(),
                isDark,
              ),
              if (item['description'] != null &&
                  item['description'].toString().isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  '${loc.translate('note')}: ${item['description']}',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color:
                        isDark
                            ? AppTheme.darkMutedTextColor
                            : AppTheme.lightMutedTextColor,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _handleAction(context, item['id'], 'REJECTED', loc);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                    ),
                    child: Text(loc.translate('reject')),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: ActionButton(
                    label: loc.translate('approve'),
                    onPressed: () {
                      _handleAction(context, item['id'], 'APPROVED', loc);
                      Navigator.pop(context);
                    },
                    type: ActionButtonType.primary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.caption14.copyWith(
                    color:
                        isDark
                            ? AppTheme.darkMutedTextColor
                            : AppTheme.lightMutedTextColor,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.body16.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppTheme.darkTextColor
                            : AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
