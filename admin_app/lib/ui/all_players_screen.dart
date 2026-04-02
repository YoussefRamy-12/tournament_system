import 'package:admin_app/database/db_helper.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("All Players"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search players...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbHelper.getAllPlayersWithScores(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allPlayers == null) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                if (snapshot.hasData) {
                  _allPlayers = snapshot.data;
                }

                if (_allPlayers == null || _allPlayers!.isEmpty) {
                  return const Center(child: Text("No players found", style: TextStyle(color: Colors.white54)));
                }

                final filteredPlayers = _allPlayers!.where((player) {
                  final name = player['name'].toString().toLowerCase();
                  final team = player['teamName'].toString().toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || team.contains(query);
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredPlayers.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    final int score = player['totalScore'] ?? 0;

                    return ListTile(
                      onTap: () => _showPlayerDetails(context, player),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Text(
                        player['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        player['teamName'],
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: score >= 0 
                              ? Colors.greenAccent.withValues(alpha: 0.1)
                              : Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$score pts",
                          style: TextStyle(
                            color: score >= 0 ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(BuildContext context, Map<String, dynamic> player) async {
    final allTransactions = await _dbHelper.getAllTransactions();
    final playerHistory = allTransactions.where((t) => t['target_id'] == player['id']).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          player['name'],
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Team: ${player['teamName']}",
                style: const TextStyle(color: Colors.amber, fontSize: 16),
              ),
              const Divider(color: Colors.white24, height: 30),
              const Text(
                "TOTAL POINTS",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "${player['totalScore'] ?? 0} pts",
                style: TextStyle(
                  color: (player['totalScore'] ?? 0) >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "RECENT TRANSACTIONS",
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (playerHistory.isEmpty)
                const Text("No transactions yet", style: TextStyle(color: Colors.white38)),
              ...playerHistory.take(5).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Text(
                      "${t['points']}",
                      style: TextStyle(
                        color: t['points'] < 0 ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${t['tag'] ?? 'Points'}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Text(
                      "${t['timestamp']?.toString().split(' ')[0]}",
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
