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
          )
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
          final approved = allRequests.where((i) => i['status'] == 'APPROVED').toList();
          final rejected = allRequests.where((i) => i['status'] == 'REJECTED').toList();
          final pending = allRequests.where((i) => i['status'] == 'PENDING').toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (pending.isNotEmpty) _buildStatusSection('PENDING APPROVAL', Colors.orange, pending, Icons.hourglass_empty),
              if (pending.isNotEmpty) const SizedBox(height: 24),
              
              if (approved.isNotEmpty) _buildStatusSection('APPROVED', Colors.green, approved, Icons.check_circle),
              if (approved.isNotEmpty) const SizedBox(height: 24),
              
              if (rejected.isNotEmpty) _buildStatusSection('REJECTED', Colors.red, rejected, Icons.cancel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(String status, Color color, List<Map<String, dynamic>> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
            separatorBuilder: (context, index) => Divider(color: color.withOpacity(0.1), height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['memberName'] ?? 'Unknown Member'),
                // Added Leader Name to the subtitle for Admin visibility
                subtitle: Text('By: ${item['leaderName'] ?? "Unknown"} • ${item['tag']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item['points'] > 0 ? "+" : ""}${item['points']} pts', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    Text(item['timestamp'].toString().substring(11, 16), 
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}