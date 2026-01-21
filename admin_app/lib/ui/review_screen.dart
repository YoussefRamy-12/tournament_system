import 'package:flutter/material.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transaction $status')));
    }
  }

  void _handleMassAction(String status) async {
    final count = (await _dbHelper.getPendingTransactions()).length;
    if (count == 0) return;

    if (!mounted) return;
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('$status All?'),
                content: Text(
                  'Are you sure you want to $status all $count pending requests?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          status == 'APPROVED' ? Colors.green : Colors.red,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('All requests $status')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Score Review'),
        actions: [
          // Bulk Approve Button
          IconButton(
            tooltip: 'Approve All',
            icon: const Icon(Icons.add_circle_outline, color: Colors.green),
            onPressed: () => _handleMassAction('APPROVED'),
          ),
          // Bulk Reject Button
          IconButton(
            tooltip: 'Reject All',
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
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
            return const Center(child: Text('No pending scores to review. ☕'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => _showDetailsDialog(context, item),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          item['points'] > 0 ? Colors.green : Colors.red,
                      child: Text(
                        '${item['points']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(item['memberName'] ?? 'Unknown Member'),
                    subtitle: Text(
                      'By: ${item['leaderName'] ?? "Unknown"} • ${item['tag']}',
                    ), // Added leaderName here
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Transaction Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    'Member Name',
                    item['memberName'] ?? 'Unknown',
                  ),
                  _buildDetailRow('Points', '${item['points']}'),
                  _buildDetailRow('Reason', item['tag'] ?? 'N/A'),
                  const Divider(), // Visual separator
                  // Show the Leader's Name instead of just the ID
                  _buildDetailRow(
                    'Submitted By',
                    item['leaderName'] ?? 'Unknown Leader',
                  ),

                  _buildDetailRow('Leader ID', item['leader_id'].toString()),
                  _buildDetailRow('Time', item['timestamp'].toString()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _handleAction(item['id'], 'REJECTED');
                  Navigator.pop(context);
                },
                child: const Text('Reject'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  _handleAction(item['id'], 'APPROVED');
                  Navigator.pop(context);
                },
                child: const Text('Approve'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
