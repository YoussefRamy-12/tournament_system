import 'dart:async';
import 'package:admin_app/ui/team_roater_screen.dart';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';

class ProjectorStatsScreen extends StatefulWidget {
  const ProjectorStatsScreen({super.key});

  @override
  State<ProjectorStatsScreen> createState() => _ProjectorStatsScreenState();
}

class _ProjectorStatsScreenState extends State<ProjectorStatsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _top10Players = [];
  List<Map<String, dynamic>> _allPlayers = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
    // Auto-refresh every 30 seconds to show live updates from Leaders
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (t) => _refreshData(),
    );
    _loadPlayerStats();
  }

  void _refreshData() async {
    final teamsData = await _dbHelper.getLeaderboardData();
    setState(() {
      _teams = teamsData;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14), // Ultra dark background
      appBar: AppBar(
        title: const Text("Projector: Live Tournament Standings"),
        // backgroundColor: const Color(0xFF1F2330),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Text(
              "TOURNAMENT LIVE STANDINGS",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 48,
                letterSpacing: 4,
              ),
            ),
            const Divider(
              color: Colors.amber,
              thickness: 3,
              indent: 100,
              endIndent: 100,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Row(
                children: [
                  // Team Standings Section
                  Expanded(
                    flex: 1,
                    child: _buildPanel("TEAM SCORES", _buildTeamTable()),
                  ),
                  const SizedBox(width: 20),
                  // Top Players Section
                  Expanded(
                    flex: 1,
                    child: _buildPanel("TOP PLAYERS", _buildPlayerList()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildTeamTable() {
    if (_teams.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    return ListView.builder(
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            // Triggers the member list dialog we created
            onTap: () {
              final teamId = team['id'];
              print("Tapped on team: $teamId");
              final teamName = team['name'] ?? 'Unknown Team';
              print("Team Name: $teamName");

              if (teamId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TeamRosterScreen(
                          teamId: team['id'],
                          teamName: team['name'],
                        ),
                  ),
                );
              } else {
                debugPrint("Error: Team ID is null for $teamName");
                // Optional: Show a snackbar so you know why it didn't open
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cannot open team: Missing ID")),
                );
              }
            },
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                "#${index + 1}",
                style: TextStyle(
                  color:
                      index == 0
                          ? Colors.amber
                          : index == 1
                          ? Colors.grey
                          : index == 2
                          ? Colors.brown
                          : Colors.white38,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              team['name'] ?? 'Unknown Team',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              "Tap to view members",
              style: TextStyle(color: Colors.white24, fontSize: 14),
            ),
            trailing: Text(
              "${team['totalScore'] ?? 0}",
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerList() {
    if (_top10Players.isEmpty) {
      return const Center(
        child: Text(
          "No approved points yet...",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _top10Players.length,
      itemBuilder: (context, index) {
        final player = _top10Players[index];

        return ListTile(
          shape: ShapeBorder.lerp(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
              side: BorderSide(color: Colors.white, width: 1),
            ),
            null,
            5.0,
          ),
          // Use your logic: Tapping opens the specific details dialog
          onTap: () => _showPlayerDetails(player),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Text(
            "#${index + 1}",
            style: TextStyle(
              fontSize: 28,
              color: index < 3 ? Colors.amber : const Color.fromARGB(208, 211, 211, 211),
              fontWeight: FontWeight.bold,
            ),
          ),
          title: Text(
            player['name'] ?? 'Unknown Member',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          subtitle: Text(
            player['teamName'] ?? 'No Team',
            style: const TextStyle(color: Colors.white54, fontSize: 18),
          ),
          trailing: Text(
            "${player['totalScore'] ?? 0}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadPlayerStats() async {
    final top10Data = await _dbHelper.getTop10Players();
    if (mounted) {
      setState(() {
        _top10Players = top10Data;
        // _allPlayers = data;
      });
    }
  }

  // void _showTeamDetails(int teamId, String teamName) async {
  //   final members = await _dbHelper.getTeamPlayers(teamId);

  //   showDialog(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           backgroundColor: const Color(0xFF0F172A),
  //           title: Text(
  //             "$teamName Roster",
  //             style: const TextStyle(color: Colors.amber, fontSize: 28),
  //           ),
  //           content: SizedBox(
  //             width: 450,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 const Divider(color: Colors.white24),
  //                 const SizedBox(height: 10),
  //                 // Header for the list
  //                 const Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       "Member Name",
  //                       style: TextStyle(color: Colors.white54),
  //                     ),
  //                     Text(
  //                       "Total Points",
  //                       style: TextStyle(color: Colors.white54),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 10),
  //                 // List of members
  //                 Flexible(
  //                   child: ListView.builder(
  //                     shrinkWrap: true,
  //                     itemCount: members.length,
  //                     itemBuilder: (context, index) {
  //                       final m = members[index];
  //                       return Padding(
  //                         padding: const EdgeInsets.symmetric(vertical: 8.0),
  //                         child: Row(
  //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                           children: [
  //                             Text(
  //                               m['name'],
  //                               style: const TextStyle(
  //                                 color: Colors.white,
  //                                 fontSize: 20,
  //                               ),
  //                             ),
  //                             Text(
  //                               m['memberTotal'] != null ? "${m['memberTotal']} pts": "0 pts",
  //                               style: TextStyle(
  //                                 color: m['memberTotal']  != null && m['memberTotal'] >=0 ? Colors.greenAccent : Colors.redAccent,
  //                                 fontSize: 20,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text(
  //                 "CLOSE",
  //                 style: TextStyle(color: Colors.white38),
  //               ),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  void _showPlayerDetails(Map<String, dynamic> player) async {
    // Reuse your existing getAllTransactions() function
    final allTransactions = await _dbHelper.getAllTransactions();

    // Filter for only this player's transactions
    final playerHistory =
        allTransactions.where((t) => t['target_id'] == player['id']).toList();

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
                    style:  TextStyle(
                      color: player['totalScore'] >= 0? Colors.greenAccent : Colors.redAccent,
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
