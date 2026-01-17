import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class LeaderboardScreen extends StatelessWidget {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Leaderboard 🏆')),
      body: StreamBuilder( // We use a Stream or Future to refresh data
        stream: _dbHelper.getLeaderboardData().asStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final leaderboard = snapshot.data as List<Map<String, dynamic>>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final team = leaderboard[index];
                final score = team['totalScore'] ?? 0;

                return Card(
                  elevation: index == 0 ? 8 : 2, // Highlight the leader
                  color: index == 0 ? Colors.amber[50] : Colors.white,
                  child: ListTile(
                    leading: Text('#${index + 1}', 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    title: Text(team['name'], 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                    trailing: Text('$score pts', 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}