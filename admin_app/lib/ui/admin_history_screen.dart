import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/db_helper.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> with SingleTickerProviderStateMixin {
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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final all = snapshot.data!;
          final approved = all.where((i) => i['status'] == 'APPROVED').toList();
          final pending = all.where((i) => i['status'] == 'PENDING').toList();
          final rejected = all.where((i) => i['status'] == 'REJECTED').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(approved, Colors.green, isDark),
              _buildHistoryList(pending, Colors.orange, isDark),
              _buildHistoryList(rejected, Colors.red, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> items, Color color, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: color.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No transactions found', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildHistoryCard(item, color, isDark)
          .animate()
          .fadeIn(delay: (index * 30).ms)
          .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, Color color, bool isDark) {
    final points = item['points'] ?? 0;
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
        onTap: () => _showStatusPicker(context, item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${points > 0 ? "+" : ""}$points',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        title: Text(item['memberName'] ?? 'Unknown Member', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item['tag']} • ${item['leaderName']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Text(
          item['timestamp'].toString().substring(11, 16),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Manage Transaction", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildStatusBtn(context, item['id'], 'APPROVED', Colors.green),
              const SizedBox(height: 12),
              _buildStatusBtn(context, item['id'], 'PENDING', Colors.orange),
              const SizedBox(height: 12),
              _buildStatusBtn(context, item['id'], 'REJECTED', Colors.red),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text("Delete Permanently", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, item['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBtn(BuildContext context, String id, String status, Color color) {
    return InkWell(
      onTap: () async {
        await _dbHelper.updateTransactionStatus(id, status);
        if (!context.mounted) return;
        Navigator.pop(context);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(width: 12),
            Text("Mark as $status", style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: const Text("This action cannot be undone and will update the leaderboard immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _dbHelper.deleteTransaction(id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
