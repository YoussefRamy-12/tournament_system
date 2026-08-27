import 'package:admin_app/database/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../components/player_details_dialog.dart';
import '../utils/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate("tournament_players"))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: loc.translate("search_hint"),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor:
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
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
                      return Center(
                        child: Text(loc.translate("no_players_found")),
                      );
                    }

                    final filtered =
                        _allPlayers!.where((p) {
                          final name = p['name'].toString().toLowerCase();
                          final team = p['teamName'].toString().toLowerCase();
                          final id = p['id'].toString().toLowerCase();
                          final q = _searchQuery.toLowerCase();
                          return name.contains(q) ||
                              team.contains(q) ||
                              id.contains(q);
                        }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final player = filtered[index];
                        final int score = player['totalScore'] ?? 0;
                        return _buildPlayerTile(player, score, isDark, loc)
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
        ),
      ),
    );
  }

  Widget _buildPlayerTile(
    Map<String, dynamic> player,
    int score,
    bool isDark,
    AppLocalizations loc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        onTap: () => PlayerDetailsDialog.show(context, player),
        title: Text(
          player['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          player['teamName'],
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (score >= 0 ? Colors.green : Colors.red).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$score ${loc.translate("pts")}",
            style: TextStyle(
              color: score >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
