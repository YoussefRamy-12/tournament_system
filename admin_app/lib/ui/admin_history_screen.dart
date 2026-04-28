import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark
              ? AppTheme.darkMutedTextColor
              : AppTheme.lightMutedTextColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Approved'),
            Tab(text: 'Pending'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          final approved = all.where((i) => i['status'] == 'APPROVED').toList();
          final pending = all.where((i) => i['status'] == 'PENDING').toList();
          final rejected = all.where((i) => i['status'] == 'REJECTED').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(approved, 'APPROVED', isDark),
              _buildHistoryList(pending, 'PENDING', isDark),
              _buildHistoryList(rejected, 'REJECTED', isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(
      List<Map<String, dynamic>> items, String status, bool isDark) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        message: 'No Transactions',
        subtitle: 'There are no transactions with $status status',
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
            return _buildHistoryCard(item, isDark)
                .animate()
                .fadeIn(delay: (index * 30).ms)
                .slideY(begin: 0.05, end: 0);
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, bool isDark) {
    final points = item['points'] ?? 0;
    final isPositive = points >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: AppCard(
        onTap: () => _showStatusPicker(context, item),
        padding: const EdgeInsets.all(AppTheme.spaceSm),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Center(
              child: Text(
                '${isPositive ? "+" : ""}$points',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          title: Text(
            item['memberName'] ?? 'Unknown Member',
            style: AppTheme.body16.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
            ),
          ),
          subtitle: Text(
            '${item['tag']} • ${item['leaderName']}',
            style: AppTheme.caption14.copyWith(
                color: isDark
                    ? AppTheme.darkMutedTextColor
                    : AppTheme.lightMutedTextColor),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['timestamp'].toString().substring(11, 16),
                style: AppTheme.label12.copyWith(
                    color: isDark
                        ? AppTheme.darkMutedTextColor
                        : AppTheme.lightMutedTextColor),
              ),
              const SizedBox(height: 4),
              Icon(Icons.more_horiz_rounded,
                  color: isDark
                      ? AppTheme.darkMutedTextColor
                      : AppTheme.lightMutedTextColor,
                  size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppTheme.spaceLg),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Manage Transaction",
                  style: AppTheme.title18.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextColor
                        : AppTheme.lightTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                _buildStatusBtn(context, item['id'], 'APPROVED',
                    AppTheme.successColor, isDark),
                const SizedBox(height: AppTheme.spaceSm),
                _buildStatusBtn(context, item['id'], 'PENDING',
                    AppTheme.warningColor, isDark),
                const SizedBox(height: AppTheme.spaceSm),
                _buildStatusBtn(context, item['id'], 'REJECTED',
                    AppTheme.errorColor, isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                  child: Divider(),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSm),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(Icons.delete_forever_rounded,
                        color: AppTheme.errorColor),
                  ),
                  title: Text(
                    "Delete Permanently",
                    style: AppTheme.body16.copyWith(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, item['id']);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBtn(BuildContext context, String id, String status,
      Color color, bool isDark) {
    return InkWell(
      onTap: () async {
        await _dbHelper.updateTransactionStatus(id, status);
        if (!context.mounted) return;
        Navigator.pop(context);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spaceMd, horizontal: AppTheme.spaceMd),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: AppTheme.spaceMd),
            Text(
              "Mark as $status",
              style: AppTheme.body16.copyWith(
                  color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
        title: const Text("Delete Transaction?"),
        content: const Text(
            "This action cannot be undone and will update the leaderboard immediately."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              minimumSize: const Size(80, 44),
            ),
            onPressed: () async {
              await _dbHelper.deleteTransaction(id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
