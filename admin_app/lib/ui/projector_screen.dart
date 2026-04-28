import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (t) => _refreshData());
  }

  void _refreshData() async {
    final teamsData = await _dbHelper.getLeaderboardData();
    final top10Data = await _dbHelper.getTop10Players();
    if (mounted) {
      setState(() {
        _teams = teamsData;
        _top10Players = top10Data;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deepest Navy
      appBar: AppBar(
        title: Text(
          "TOURNAMENT ARENA",
          style: GoogleFonts.orbitron(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24),
          child: Column(
            children: [
              _buildMainTitle(),
              const SizedBox(height: 48),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildGlassPanel(
                        title: "TEAM STANDINGS",
                        icon: Icons.groups_rounded,
                        child: _buildTeamList(),
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 4,
                      child: _buildGlassPanel(
                        title: "TOP PERFORMERS",
                        icon: Icons.emoji_events_rounded,
                        child: _buildPlayerList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTitle() {
    return Column(
      children: [
        Text(
          "LEADERBOARD",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -2,
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
        Container(
          width: 200,
          height: 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.indigo, Colors.cyan]),
            borderRadius: BorderRadius.circular(3),
          ),
        ).animate().scaleX(delay: 400.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildGlassPanel({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigoAccent, size: 28),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    ).animate().fadeIn(duration: 1.seconds).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTeamList() {
    if (_teams.isEmpty) return const Center(child: CircularProgressIndicator());

    return ListView.builder(
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final isTop3 = index < 3;
        final score = team['totalScore'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isTop3 ? Colors.indigo.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTop3 ? Colors.indigo.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              _buildRankBadge(index + 1),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  team['name'] ?? 'Unknown Team',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                "$score",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: score < 0 ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.05, end: 0);
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color = Colors.white24;
    if (rank == 1) color = const Color(0xFFFFD700); // Gold
    if (rank == 2) color = const Color(0xFFC0C0C0); // Silver
    if (rank == 3) color = const Color(0xFFCD7F32); // Bronze

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Center(
        child: Text(
          "$rank",
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerList() {
    if (_top10Players.isEmpty) return const Center(child: Text("No scores yet", style: TextStyle(color: Colors.white30)));

    return ListView.builder(
      itemCount: _top10Players.length,
      itemBuilder: (context, index) {
        final player = _top10Players[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            children: [
              Text(
                "#${index + 1}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: index < 3 ? Colors.indigoAccent : Colors.white24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['name'] ?? 'Unknown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      player['teamName'] ?? 'No Team',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${player['totalScore'] ?? 0}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (400 + index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}
