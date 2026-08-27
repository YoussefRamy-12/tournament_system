import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:admin_app/components/player_details_dialog.dart';
import 'package:admin_app/components/team_details_dialog.dart';
import 'package:admin_app/services/projector_window_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../utils/app_localizations.dart';

class ProjectorStatsScreen extends StatefulWidget {
  final bool isSubWindow;

  const ProjectorStatsScreen({super.key, this.isSubWindow = false});

  @override
  State<ProjectorStatsScreen> createState() => _ProjectorStatsScreenState();
}

class _ProjectorStatsScreenState extends State<ProjectorStatsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Timer? _refreshTimer;
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: Standings, 1: Top Performers (used in compact mode)
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _top10Players = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (t) => _refreshData(),
    );
  }

  void _refreshData() async {
    try {
      if (widget.isSubWindow) {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 2);
        final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:8080/projector-stats'),
        );
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _teams = List<Map<String, dynamic>>.from(data['teams'] ?? []);
              _top10Players = List<Map<String, dynamic>>.from(
                data['top10Players'] ?? [],
              );
              _isLoading = false;
            });
          }
        }
        client.close();
      } else {
        final teamsData = await _dbHelper.getLeaderboardData();
        final top10Data = await _dbHelper.getTop10Players();
        if (mounted) {
          setState(() {
            _teams = teamsData;
            _top10Players = top10Data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching projector stats: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                loc.translate("tournament_arena"),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.orbitron(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "LIVE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
                  duration: 1.seconds,
                  begin: 0.4,
                  end: 1.0,
                ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.translate("refresh"),
            onPressed: _refreshData,
          ),
          if (!widget.isSubWindow)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: loc.translate("open_in_new_window"),
              onPressed: () async {
                try {
                  await ProjectorWindowService.openProjectorWindow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.translate("open_in_new_window")),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error opening window: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          const SizedBox(width: 12),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;
          final isMedium = constraints.maxWidth < 1150;
          final horizontalPad = isCompact ? 16.0 : (isMedium ? 24.0 : 40.0);
          final verticalPad = isCompact ? 12.0 : 20.0;

          final standingsPanel = _buildGlassPanel(
            title: loc.translate("team_standings"),
            icon: Icons.groups_rounded,
            child: _buildTeamList(loc, isCompact),
            isCompact: isCompact,
          );

          final performersPanel = _buildGlassPanel(
            title: loc.translate("top_performers"),
            icon: Icons.emoji_events_rounded,
            child: _buildPlayerList(loc, isCompact),
            isCompact: isCompact,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.indigo.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: verticalPad,
              ),
              child: Column(
                children: [
                  _buildMainTitle(loc, isCompact, isMedium),
                  SizedBox(height: isCompact ? 12 : 24),
                  if (isCompact) ...[
                    _buildSegmentedTabToggle(loc, isDark),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: isCompact
                        ? (_selectedTabIndex == 0
                            ? standingsPanel
                            : performersPanel)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: isMedium ? 5 : 6,
                                child: standingsPanel,
                              ),
                              SizedBox(width: isMedium ? 20 : 32),
                              Expanded(
                                flex: isMedium ? 5 : 4,
                                child: performersPanel,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSegmentedTabToggle(AppLocalizations loc, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: loc.translate("team_standings"),
              icon: Icons.groups_rounded,
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: loc.translate("top_performers"),
              icon: Icons.emoji_events_rounded,
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.indigo.shade700 : Colors.indigo)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTitle(
    AppLocalizations loc,
    bool isCompact,
    bool isMedium,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fontSize = isCompact ? 28.0 : (isMedium ? 40.0 : 52.0);

    return Column(
      children: [
        Text(
          loc.translate("leaderboard"),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white70 : Colors.black54,
            letterSpacing: isCompact ? -0.5 : -1.5,
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
        Container(
          width: isCompact ? 100 : 160,
          height: isCompact ? 4 : 5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.indigo, Colors.cyan],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ).animate().scaleX(delay: 400.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildGlassPanel({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isCompact,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigoAccent, size: isCompact ? 22 : 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 20),
          Expanded(child: child),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTeamList(AppLocalizations loc, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_teams.isEmpty) {
      return Center(
        child: Text(
          loc.translate("no_teams_yet"),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final isTop3 = index < 3;
        final score = team['totalScore'] ?? 0;

        return InkWell(
          onTap: () => TeamDetailsDialog.show(context, team),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: EdgeInsets.only(bottom: isCompact ? 10 : 14),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14 : 20,
              vertical: isCompact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: isTop3
                  ? Colors.indigo.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isTop3
                    ? Colors.indigo.withValues(alpha: 0.2)
                    : (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.05,
                      ),
              ),
            ),
            child: Row(
              children: [
                _buildRankBadge(index + 1, isDark, isCompact),
                SizedBox(width: isCompact ? 12 : 18),
                Expanded(
                  child: Text(
                    team['name'] ?? loc.translate('unknown_team'),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isCompact ? 18 : 24,
                      fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "$score",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isCompact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    color: score < 0 ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: -0.05, end: 0);
      },
    );
  }

  Widget _buildRankBadge(int rank, bool isDark, bool isCompact) {
    Color color = isDark ? Colors.white24 : Colors.black26;
    if (rank == 1) color = const Color(0xFFFFD700); // Gold
    if (rank == 2) color = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) color = const Color(0xFFCD7F32); // Bronze
    final size = isCompact ? 36.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          "$rank",
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isCompact ? 15 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerList(AppLocalizations loc, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_top10Players.isEmpty) {
      return Center(
        child: Text(
          loc.translate("no_scores_yet"),
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _top10Players.length,
      itemBuilder: (context, index) {
        final player = _top10Players[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isCompact ? 12.0 : 18.0),
          child: InkWell(
            onTap: () => PlayerDetailsDialog.show(context, player),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: isCompact ? 28 : 34,
                    child: Text(
                      "#${index + 1}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompact ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: index < 3
                            ? Colors.indigoAccent
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player['name'] ?? loc.translate('unknown'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isCompact ? 15 : 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          player['teamName'] ?? loc.translate('no_team'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isCompact ? 11 : 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${player['totalScore'] ?? 0}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (300 + index * 40).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}
