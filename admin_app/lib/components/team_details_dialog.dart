import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'player_details_dialog.dart';
import '../utils/app_localizations.dart';

class TeamDetailsDialog {
  static void show(BuildContext context, Map<String, dynamic> team) async {
    final dbHelper = DatabaseHelper();
    final teamId = team['id'];
    final loc = AppLocalizations.of(context);

    if (teamId == null) return;

    final summary = await dbHelper.getTeamSummary(teamId);
    final players = await dbHelper.getTeamPlayers(teamId);

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Summary Data
    final int memberCount = summary['memberCount'] ?? 0;
    final int teamPoints = summary['teamPoints'] ?? 0;
    final int memberPoints = summary['memberPoints'] ?? 0;
    final int totalScore = summary['totalPoints'] ?? 0;
    final String mvpName = summary['topPlayerName'] ?? 'N/A';
    final int mvpScore = summary['topPlayerScore'] ?? 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    team['name'] ?? loc.translate('unknown_team'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (totalScore >= 0 ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$totalScore ${loc.translate('pts')}",
                    style: TextStyle(
                      color: totalScore >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.group_rounded,
                            label: loc.translate("members"),
                            value: "$memberCount",
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.emoji_events_outlined,
                            label: "Team Awards",
                            value: "$teamPoints",
                            isDark: isDark,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.person_add_alt_1_rounded,
                            label: "Member Points",
                            value: "$memberPoints",
                            isDark: isDark,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_rounded,
                            label: loc.translate("team_mvp"),
                            value: "$mvpName ($mvpScore)",
                            isDark: isDark,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        loc.translate("team_roster").toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          loc.translate("no_players_yet"),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ...players.map((p) {
                      final int pScore = p['memberTotal'] ?? 0;
                      final bool isPositive = pScore >= 0;

                      return InkWell(
                        onTap: () {
                          final playerMap = {
                            'id': p['id'],
                            'name': p['name'],
                            'teamName': team['name'],
                            'totalScore': pScore,
                          };
                          PlayerDetailsDialog.show(context, playerMap);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.indigo.withValues(
                                  alpha: 0.1,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "${p['name'] ?? loc.translate('unknown')}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (isPositive
                                          ? Colors.green
                                          : Colors.red)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${isPositive ? '+' : ''}$pScore",
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.translate('close')),
              ),
            ],
          ),
    );
  }

  static Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color color = Colors.indigoAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
