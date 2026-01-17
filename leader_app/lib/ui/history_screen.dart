import 'package:flutter/material.dart';
import '../network/api_client.dart'; // Ensure this points to your client

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiClient _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Scoring Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}), // Simple refresh
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _apiClient.fetchMyHistory(), // The new filtered function
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Connection Error: ${snapshot.error}'));
          }

          final allRequests = snapshot.data ?? [];

          if (allRequests.isEmpty) {
            return const Center(
              child: Text('You haven\'t submitted any scores yet.'),
            );
          }

          // Filter data into groups
          final approved = allRequests.where((i) => i['status'] == 'APPROVED').toList();
          final rejected = allRequests.where((i) => i['status'] == 'REJECTED').toList();
          final pending = allRequests.where((i) => i['status'] == 'PENDING').toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (pending.isNotEmpty) _buildStatusSection('PENDING REQUESTS', Colors.orange, pending, Icons.hourglass_empty),
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
            Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.02),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(color: color.withOpacity(0.1), height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item['memberName'] ?? 'Unknown Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item['tag']} • ${item['points'] > 0 ? "+" : ""}${item['points']} pts'),
                trailing: Text(
                  item['timestamp'].toString().substring(11, 16), // Shows "HH:mm"
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}