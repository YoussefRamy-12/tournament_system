import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class LeaderApprovalScreen extends StatefulWidget {
  const LeaderApprovalScreen({super.key});

  @override
  State<LeaderApprovalScreen> createState() => _LeaderApprovalScreenState();
}

class _LeaderApprovalScreenState extends State<LeaderApprovalScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _handleAction(String id, String status) async {
    await _dbHelper.updateLeaderStatus(id, status);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leader status updated to $status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leader Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllLeaders(), // Fetch everyone
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLeaders = snapshot.data!;
          if (allLeaders.isEmpty) {
            return const Center(child: Text('No leaders registered yet.'));
          }

          // Filter into groups
          final pending =
              allLeaders.where((l) => l['status'] == 'PENDING').toList();
          final approved =
              allLeaders.where((l) => l['status'] == 'APPROVED').toList();
          final rejected =
              allLeaders.where((l) => l['status'] == 'REJECTED').toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (pending.isNotEmpty)
                _buildStatusSection(
                  'PENDING REGISTRATIONS',
                  Colors.orange,
                  pending,
                  Icons.person_add,
                ),
              if (pending.isNotEmpty) const SizedBox(height: 24),

              if (approved.isNotEmpty)
                _buildStatusSection(
                  'APPROVED LEADERS',
                  Colors.green,
                  approved,
                  Icons.verified_user,
                ),
              if (approved.isNotEmpty) const SizedBox(height: 24),

              if (rejected.isNotEmpty)
                _buildStatusSection(
                  'REJECTED / BLOCKED',
                  Colors.red,
                  rejected,
                  Icons.block,
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.02),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder:
                (context, index) =>
                    Divider(color: color.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final leader = items[index];
              final String currentStatus = leader['status'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: color),
                ),
                title: Text(
                  leader['name'] ?? 'Unknown Name',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'ID: ${leader['id'].toString().substring(0, 8)}...',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only show Approve button if not already approved
                    if (currentStatus != 'APPROVED')
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        onPressed:
                            () => _handleAction(leader['id'], 'APPROVED'),
                      ),
                    // Only show Reject button if not already rejected
                    if (currentStatus != 'REJECTED')
                      IconButton(
                        icon: const Icon(
                          Icons.block_flipped,
                          color: Colors.red,
                        ),
                        onPressed:
                            () => _handleAction(leader['id'], 'REJECTED'),
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
}
