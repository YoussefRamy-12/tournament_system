import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:shared_models/models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/tournament_provider.dart';
import 'member_list_screen.dart';

class MemberSelector extends StatefulWidget {
  const MemberSelector({super.key});

  @override
  State<MemberSelector> createState() => _MemberSelectorState();
}

class _MemberSelectorState extends State<MemberSelector> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(loc.translate('select_team')),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [AppTheme.darkBg, AppTheme.darkSurface] 
                : [AppTheme.lightBg, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: () => context.read<TournamentProvider>().fetchTeams(),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final loc = AppLocalizations.of(context);
    final tournament = context.watch<TournamentProvider>();

    if (tournament.isLoading && tournament.teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary)),
            const SizedBox(height: 24),
            Text(loc.translate('loading_tournament_data')),
          ],
        ),
      );
    } else if (tournament.errorMessage != null && tournament.teams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: PremiumCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 64),
                const SizedBox(height: 24),
                Text(
                  loc.translate('connection_not_found'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  tournament.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                PremiumButton(
                  label: loc.translate('retry_connection'),
                  onPressed: () => _refreshIndicatorKey.currentState?.show(),
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        ),
      );
    } else if (tournament.teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 80, color: AppTheme.primary.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(loc.translate('no_teams_registered'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final teams = tournament.teams;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: PremiumCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MemberListScreen(team: team)),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      team.name.isNotEmpty ? team.name[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to view members",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}

