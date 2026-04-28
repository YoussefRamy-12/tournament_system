import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/db_helper.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: Text('$status All?'),
        content: Text('Are you sure you want to $status all $count pending requests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red,
            ),
            child: Text('Yes, $status All'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _dbHelper.updateAllPendingStatus(status);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All requests $status'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Scores'),
        actions: [
          IconButton(
            tooltip: 'Approve All',
            icon: const Icon(Icons.done_all_rounded, color: Colors.green),
            onPressed: () => _handleMassAction('APPROVED'),
          ),
          IconButton(
            tooltip: 'Reject All',
            icon: const Icon(Icons.remove_done_rounded, color: Colors.red),
            onPressed: () => _handleMassAction('REJECTED'),
          ),
          const SizedBox(width: 8),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                  const SizedBox(height: 16),
                  Text(
                    'No pending scores to review.',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ).animate().fadeIn().scale(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildReviewCard(item, isDark, theme)
                .animate()
                .fadeIn(delay: (index * 50).ms)
                .slideX(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> item, bool isDark, ThemeData theme) {
    final points = item['points'] ?? 0;
    final isPositive = points >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetailsDialog(context, item),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${isPositive ? "+" : ""}$points',
                        style: TextStyle(
                          color: isPositive ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['memberName'] ?? 'Unknown Member',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['tag']} • ${item['leaderName'] ?? "Unknown"}',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        if (item['description'] != null && item['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item['description'],
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailTile(Icons.person_outline, 'Member', item['memberName'] ?? 'Unknown'),
            _buildDetailTile(Icons.stars_rounded, 'Points', '${item['points']}'),
            _buildDetailTile(Icons.label_outline, 'Category', item['tag'] ?? 'N/A'),
            _buildDetailTile(Icons.badge_outlined, 'Submitted By', item['leaderName'] ?? 'Unknown Leader'),
            _buildDetailTile(Icons.access_time, 'Timestamp', item['timestamp'].toString()),
            if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Note: ${item['description']}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _handleAction(item['id'], 'REJECTED');
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _handleAction(item['id'], 'APPROVED');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigoAccent),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
