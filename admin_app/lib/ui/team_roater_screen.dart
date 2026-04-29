import 'package:admin_app/database/db_helper.dart';
import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

class TeamRosterScreen extends StatelessWidget {
  final int teamId;
  final String teamName;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  TeamRosterScreen({super.key, required this.teamId, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text("$teamName ${loc.translate('roster')}"),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getTeamPlayers(teamId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final members = snapshot.data!;

          return Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.translate("member_name"),
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                    ),
                    Text(
                      loc.translate("total_points"),
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
              
              FutureBuilder<Map<String, dynamic>>(
                future: _dbHelper.getTeamSummary(teamId),
                builder: (context, summarySnapshot) {
                  if (!summarySnapshot.hasData) return const SizedBox();
                  final summary = summarySnapshot.data!;

                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          loc.translate("average"),
                          "${summary['teamAverage'].toStringAsFixed(1)}",
                          isDark,
                        ),
                        _buildStatItem(
                          loc.translate("top_player"),
                          "${summary['topPlayerName'] ?? 'N/A'}",
                          isDark,
                        ),
                        _buildStatItem(loc.translate("members"), "${summary['memberCount']}", isDark),
                      ],
                    ),
                  );
                },
              ),
              // List of Members
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder:
                      (context, index) => Divider(color: isDark ? Colors.white10 : Colors.black12),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final int score = m['memberTotal'] ?? 0;

                    return ListTile(
                      onTap: () {
                        _showPlayerDetails(context, m, teamName, loc);
                      },
                      title: Text(
                        m['name'],
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                        ),
                      ),
                      trailing: Text(
                        "$score ${loc.translate('pts')}",
                        style: TextStyle(
                          color:
                              score >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                          fontSize: 18,
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

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPlayerDetails(
    BuildContext context,
    Map<String, dynamic> member,
    String tName,
    AppLocalizations loc,
  ) async {
    final player = {
      'id': member['id'],
      'name': member['name'],
      'teamName': tName,
      'totalScore': member['memberTotal'] ?? 0,
    };

    final allTransactions = await _dbHelper.getAllTransactions();
    final playerHistory =
        allTransactions.where((t) => t['target_id'] == player['id']).toList();

    if (!context.mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              player['name'],
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${loc.translate('team')}: ${player['teamName']}",
                    style: const TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  Text(
                    "ID: ${player['id']}",
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  const Divider(height: 30),

                  Text(
                    loc.translate("total_points").toUpperCase(),
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12),
                  ),
                  Text(
                    "${player['totalScore'] ?? 0} ${loc.translate('pts')}",
                    style: TextStyle(
                      color:
                          player['totalScore'] >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    loc.translate("recent_transactions"),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

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
                                  "${t['tag'] ?? loc.translate('points')}",
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              Text(
                                "${t['timestamp']?.toString().split(' ')[0]}",
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  loc.translate("close").toUpperCase(),
                  style: const TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
    );
  }
}
