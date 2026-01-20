import 'package:admin_app/database/db_helper.dart';
import 'package:flutter/material.dart';

class TeamRosterScreen extends StatelessWidget {
  final int teamId;
  final String teamName;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  TeamRosterScreen({super.key, required this.teamId, required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("$teamName Roster"),
        // backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getTeamPlayers(teamId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          final members = snapshot.data!;

          return Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Member Name", style: TextStyle(color: Colors.white54, fontSize: 16)),
                    Text("Total Points", style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              
              // List of Members
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final int score = m['memberTotal'] ?? 0;

                    return ListTile(
                      onTap: () {
                        // REUSE your existing player details dialog here
                        _showPlayerDetails(context, m, teamName);
                      },
                      title: Text(
                        m['name'],
                        style: const TextStyle(color: Colors.white, fontSize: 22),
                      ),
                      trailing: Text(
                        "$score pts",
                        style: TextStyle(
                          color: score >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper to trigger the dialog you want
  void _showPlayerDetails(BuildContext context, Map<String, dynamic> member, String tName) async {
     // Prepare the data map to match what your Player Details dialog expects
     final player = {
       'id': member['id'],
       'name': member['name'],
       'teamName': tName,
       'totalScore': member['memberTotal'] ?? 0,

     };

    final allTransactions = await _dbHelper.getAllTransactions();


     final playerHistory =
        allTransactions.where((t) => t['target_id'] == player['id']).toList();
     
     // Call your existing dialog function here
     // showDialog(context: context, builder: (...) => ...) 
     showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(
              0xFF1E293B,
            ), // Dark theme for projector
            title: Text(
              player['name'],
              style: const TextStyle(color: Colors.white, fontSize: 28),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Team: ${player['teamName']}",
                    style: const TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                  Text(
                    "Member ID: ${player['id']}",
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const Divider(color: Colors.white24, height: 30),

                  const Text(
                    "TOTAL POINTS",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "${player['totalScore'] ?? 0} pts",
                    style: TextStyle(
                      color:  player['totalScore'] >= 0? Colors.greenAccent : Colors.redAccent,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "RECENT TRANSACTIONS",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Show recent history using your existing transaction data
                  ...playerHistory
                      .take(5)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Text(
                                "${t['points']}",
                                style: TextStyle(
                                  color:
                                      t['points'] < 0
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
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
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "CLOSE",
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
    );
  }
}