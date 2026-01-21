import 'package:flutter/material.dart';
import '../database/db_helper.dart'; // Import your local DB helper

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllTransactions(), // Local DB call
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRequests = snapshot.data ?? [];

          if (allRequests.isEmpty) {
            return const Center(child: Text('No transactions recorded yet.'));
          }

          // Grouping logic remains the same
          final approved =
              allRequests.where((i) => i['status'] == 'APPROVED').toList();
          final rejected =
              allRequests.where((i) => i['status'] == 'REJECTED').toList();
          final pending =
              allRequests.where((i) => i['status'] == 'PENDING').toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (pending.isNotEmpty)
                _buildStatusSection(
                  'PENDING APPROVAL',
                  Colors.orange,
                  pending,
                  Icons.hourglass_empty,
                ),
              if (pending.isNotEmpty) const SizedBox(height: 24),

              if (approved.isNotEmpty)
                _buildStatusSection(
                  'APPROVED',
                  Colors.green,
                  approved,
                  Icons.check_circle,
                ),
              if (approved.isNotEmpty) const SizedBox(height: 24),

              if (rejected.isNotEmpty)
                _buildStatusSection(
                  'REJECTED',
                  Colors.red,
                  rejected,
                  Icons.cancel,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(
    String status,
    Color color,
    List<Map<String, dynamic>> items,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder:
                (context, index) =>
                    Divider(color: color.withOpacity(0.1), height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                onTap: () => _showStatusPicker(context, item),
                title: Text(item['memberName'] ?? 'Unknown Member'),
                // Added Leader Name to the subtitle for Admin visibility
                subtitle: Text(
                  'By: ${item['leaderName'] ?? "Unknown"} • ${item['tag']}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item['points'] > 0 ? "+" : ""}${item['points']} pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            item['points'] < 0
                                ? Colors.redAccent
                                : Colors.green,
                      ),
                    ),
                    Text(
                      item['timestamp'].toString().substring(11, 16),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showStatusPicker(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Change Transaction Status",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildStatusOption(context, item['id'], 'PENDING', Colors.orange),
              _buildStatusOption(context, item['id'], 'APPROVED', Colors.green),
              _buildStatusOption(context, item['id'], 'REJECTED', Colors.red),
              const SizedBox(height: 10),
              const Divider(),
            // --- NEW DELETE OPTION ---
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Delete Permanently", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _confirmDelete(context, item['id']); // Open confirmation
              },
            ),
            const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Delete Transaction?"),
      content: const Text("This action cannot be undone. The points will be removed from the leaderboard immediately."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await _dbHelper.deleteTransaction(id);
            Navigator.pop(ctx);
            setState(() {}); // Refresh the history list
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Transaction deleted")),
            );
          },
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  Widget _buildStatusOption(
    BuildContext context,
    String id,
    String status,
    Color color,
  ) {
    return ListTile(
      leading: Icon(Icons.circle, color: color),
      title: Text("Mark as $status"),
      onTap: () async {
        await _dbHelper.updateTransactionStatus(id, status);
        Navigator.pop(context); // Close sheet
        setState(
          () {},
        ); // Refresh the screen to move the item to the new section

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Transaction moved to $status")));
      },
    );
  }
}
