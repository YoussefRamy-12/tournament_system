import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _handleAction(String id, String status) async {
    await _dbHelper.updateTransactionStatus(id, status);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction $status'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.getStatusColor(status),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        ),
      );
    }
  }

  void _handleMassAction(String status) async {
    final count = (await _dbHelper.getPendingTransactions()).length;
    if (count == 0) return;

    if (!mounted) return;
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
            title: Text('$status All?'),
            content: Text(
                'Are you sure you want to $status all $count pending requests?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'APPROVED'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
                child: Text('Yes, $status All'),
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
            content: Text('All requests $status'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.getStatusColor(status),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Scores'),
        actions: [
          IconButton(
            tooltip: 'Approve All',
            icon: Icon(Icons.done_all_rounded, color: AppTheme.successColor),
            onPressed: () => _handleMassAction('APPROVED'),
          ),
          IconButton(
            tooltip: 'Reject All',
            icon: Icon(Icons.remove_done_rounded, color: AppTheme.errorColor),
            onPressed: () => _handleMassAction('REJECTED'),
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
              message: 'All Caught Up!',
              subtitle: 'No pending scores to review.',
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
                  final item = items[index];
                  return _buildReviewCard(item, isDark)
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

  Widget _buildReviewCard(Map<String, dynamic> item, bool isDark) {
    final points = item['points'] ?? 0;
    final isPositive = points >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: AppCard(
        onTap: () => _showDetailsDialog(context, item),
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
                  Text(
                    item['memberName'] ?? 'Unknown Member',
                    style: AppTheme.title18.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(
                    '${item['tag']} • ${item['leaderName'] ?? "Unknown"}',
                    style: AppTheme.caption14.copyWith(
                      color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                    ),
                  ),
                  if (item['description'] != null &&
                      item['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spaceXs),
                      child: Text(
                        item['description'],
                        style: AppTheme.label12.copyWith(
                          color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor,
                size: 20),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
          title: const Text('Review Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailTile(
                  Icons.person_outline, 'Member', item['memberName'] ?? 'Unknown', isDark),
              _buildDetailTile(Icons.stars_rounded, 'Points', '${item['points']}', isDark),
              _buildDetailTile(Icons.label_outline, 'Category', item['tag'] ?? 'N/A', isDark),
              _buildDetailTile(Icons.badge_outlined, 'Submitted By',
                  item['leaderName'] ?? 'Unknown Leader', isDark),
              _buildDetailTile(Icons.access_time, 'Timestamp',
                  item['timestamp'].toString(), isDark),
              if (item['description'] != null &&
                  item['description'].toString().isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  'Note: ${item['description']}',
                  style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor),
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
                      _handleAction(item['id'], 'REJECTED');
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: BorderSide(color: AppTheme.errorColor),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: ActionButton(
                    label: 'Approve',
                    onPressed: () {
                      _handleAction(item['id'], 'APPROVED');
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

  Widget _buildDetailTile(IconData icon, String label, String value, bool isDark) {
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
                Text(label,
                    style: AppTheme.caption14.copyWith(
                        color: isDark ? AppTheme.darkMutedTextColor : AppTheme.lightMutedTextColor)),
                Text(value,
                    style: AppTheme.body16.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
