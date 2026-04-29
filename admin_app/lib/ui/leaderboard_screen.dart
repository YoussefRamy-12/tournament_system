import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../components/app_components.dart';
import '../components/team_details_dialog.dart';
import '../utils/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('team_leaderboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
          const SizedBox(width: AppTheme.spaceSm),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getLeaderboardData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final leaderboard = snapshot.data!;

          if (leaderboard.isEmpty) {
            return EmptyState(
              icon: Icons.leaderboard_rounded,
              message: loc.translate("no_teams_yet"),
              subtitle: loc.translate("no_teams_subtitle"),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceXl,
                ),
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final team = leaderboard[index];
                  final int score = team['totalScore'] ?? 0;
                  return _buildTeamCard(team, score, index, isDark, loc)
                      .animate()
                      .fadeIn(delay: (index * 60).ms)
                      .slideX(begin: 0.06, end: 0);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(
    Map<String, dynamic> team,
    int score,
    int index,
    bool isDark,
    AppLocalizations loc,
  ) {
    final isTop3 = index < 3;
    final rankColor = _getRankColor(index);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      decoration: BoxDecoration(
        color:
            isTop3
                ? rankColor.withValues(alpha: isDark ? 0.08 : 0.05)
                : (isDark ? AppTheme.darkCardColor : Colors.white),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color:
              isTop3
                  ? rankColor.withValues(alpha: isDark ? 0.25 : 0.2)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow:
            isTop3
                ? [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: InkWell(
        onTap: () => TeamDetailsDialog.show(context, team),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceMd,
          ),
          child: Row(
            children: [
              // Rank badge
              RankBadge(rank: index + 1, size: 48),
              const SizedBox(width: AppTheme.spaceMd),

              // Team info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['name'] ?? loc.translate('unknown'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body16.copyWith(
                        fontWeight: isTop3 ? FontWeight.bold : FontWeight.w600,
                        color:
                            isDark
                                ? AppTheme.darkTextColor
                                : AppTheme.lightTextColor,
                      ),
                    ),
                    if (team['memberCount'] != null)
                      Text(
                        "${team['memberCount']} ${loc.translate('members')}",
                        style: AppTheme.label12.copyWith(
                          color:
                              isDark
                                  ? AppTheme.darkMutedTextColor
                                  : AppTheme.lightMutedTextColor,
                        ),
                      ),
                  ],
                ),
              ),

              // Score
              ScoreIndicator(score: score),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.primaryColor;
    }
  }
}
