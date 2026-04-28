import 'package:admin_app/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AllPlayersScreen extends StatefulWidget {
  const AllPlayersScreen({super.key});

  @override
  State<AllPlayersScreen> createState() => _AllPlayersScreenState();
}

class _AllPlayersScreenState extends State<AllPlayersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _searchQuery = "";
  List<Map<String, dynamic>>? _allPlayers;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tournament Players"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search by name or team...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbHelper.getAllPlayersWithScores(),
              builder: (context, snapshot) {
                if (!snapshot.hasData && _allPlayers == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) _allPlayers = snapshot.data;
                if (_allPlayers == null || _allPlayers!.isEmpty) {
                  return const Center(child: Text("No players found"));
                }

                final filtered = _allPlayers!.where((p) {
                  final name = p['name'].toString().toLowerCase();
                  final team = p['teamName'].toString().toLowerCase();
                  final q = _searchQuery.toLowerCase();
                  return name.contains(q) || team.contains(q);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final player = filtered[index];
                    final int score = player['totalScore'] ?? 0;
                    return _buildPlayerTile(player, score, isDark)
                      .animate()
                      .fadeIn(delay: (index * 20).ms)
                      .slideX(begin: 0.05, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Map<String, dynamic> player, int score, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: () => _showPlayerDetails(context, player),
        title: Text(player['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(player['teamName'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (score >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$score pts",
            style: TextStyle(
              color: score >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, Map<String, dynamic> player) async {
    final all = await _dbHelper.getAllTransactions();
    final history = all.where((t) => t['target_id'] == player['id']).toList();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(player['name']),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Team: ${player['teamName']}", style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
              const Divider(height: 32),
              Text("${player['totalScore'] ?? 0} pts", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
              const Text("Total Score", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              const Align(alignment: Alignment.centerLeft, child: Text("RECENT HISTORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              const SizedBox(height: 8),
              if (history.isEmpty) const Text("No transactions yet"),
              ...history.take(5).map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text("${t['points']}", style: TextStyle(color: t['points'] < 0 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(child: Text("${t['tag']}", style: const TextStyle(fontSize: 14))),
                    Text("${t['timestamp']?.toString().split(' ')[0]}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
