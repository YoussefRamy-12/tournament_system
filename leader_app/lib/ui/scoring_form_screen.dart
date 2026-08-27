import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/ui/feedback_screen.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:shared_models/models.dart';
import 'package:shared_models/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tournament_provider.dart';
import '../services/storage_service.dart';

enum ScoringMode { individual, team }

class ScoringFormScreen extends StatefulWidget {
  final Team team;
  final Member? initialMember;

  const ScoringFormScreen({
    super.key,
    required this.team,
    this.initialMember,
  });

  @override
  State<ScoringFormScreen> createState() => _ScoringFormScreenState();
}

class _ScoringFormScreenState extends State<ScoringFormScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  int _points = 0;
  String? _selectedTag;
  Member? _selectedMember;
  ScoringMode _mode = ScoringMode.team;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.initialMember;
    if (_selectedMember != null) {
      _mode = ScoringMode.individual;
    }
    
    // Ensure members are loaded for the dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchMembers(widget.team.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tournament = context.watch<TournamentProvider>();
    final members = tournament.getMembersForTeam(widget.team.id);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _mode == ScoringMode.team
              ? loc.translateWithParam('score_team', 'name', widget.team.name)
              : (_selectedMember != null
                  ? loc.translateWithParam('score_member', 'name', _selectedMember!.name)
                  : loc.translate('select_member')),
        ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Mode Toggle Slider
                _buildModeToggle(loc, isDark),
                const SizedBox(height: 24),

                if (_mode == ScoringMode.individual) ...[
                  _buildMemberDropdown(loc, isDark, members),
                  const SizedBox(height: 24),
                ],

                // Points Display Card
                PremiumCard(
                  child: Column(
                    children: [
                      Text(
                        loc.translate('points_to_award'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                            '$_points',
                            key: ValueKey(_points),
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: _points > 0
                                  ? AppTheme.primary
                                  : (_points < 0
                                        ? Colors.redAccent
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black87)),
                            ),
                          )
                          .animate()
                          .scale(duration: 200.ms, curve: Curves.easeOutBack)
                          .fadeIn(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Point Adjusters
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _pointButton(-10, Colors.redAccent),
                        _pointButton(-5, Colors.redAccent),
                        _pointButton(-1, Colors.redAccent),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _pointButton(1, Colors.greenAccent),
                        _pointButton(5, Colors.greenAccent),
                        _pointButton(10, Colors.greenAccent),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => setState(() => _points = 0),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(loc.translate('reset_points')),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Reason & Description
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: loc.translate('reason_tag'),
                          prefixIcon: const Icon(
                            Icons.label_outline,
                            color: AppTheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBg.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.05),
                        ),
                        hint: Text(loc.translate('select_tag')),
                        initialValue: _selectedTag,
                        items: TournamentConstants.scoreTags.map((tag) {
                          // Map raw tag names to localized names
                          String localizedTag = tag;
                          if (tag == 'Technical Skill') localizedTag = loc.translate('tag_technical');
                          if (tag == 'Sportsmanship') localizedTag = loc.translate('tag_sportsmanship');
                          if (tag == 'Teamwork') localizedTag = loc.translate('tag_teamwork');
                          if (tag == 'Goal/Objective') localizedTag = loc.translate('tag_goal');
                          if (tag == 'Arrival Bonus') localizedTag = loc.translate('tag_arrival');
                          if (tag == 'Rule Violation (-)') localizedTag = loc.translate('tag_violation');
                          
                          return DropdownMenuItem(value: tag, child: Text(localizedTag));
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedTag = value),
                      ),
                      const SizedBox(height: 24),
                      PremiumTextField(
                        controller: _descriptionController,
                        label: loc.translate('description_optional'),
                        prefixIcon: Icons.description_outlined,
                        hintText: loc.translate('add_details_hint'),
                      ),
                      if (_mode == ScoringMode.team) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.translate('balancing_note'),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                PremiumButton(
                  label: loc.translate('submit_score'),
                  onPressed: _canSubmit() ? _submitScore : null,
                  isLoading: _isSubmitting,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle(AppLocalizations loc, bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _modeButton(ScoringMode.team, loc.translate('team_mode')),
          _modeButton(ScoringMode.individual, loc.translate('individual_mode')),
        ],
      ),
    );
  }

  Widget _modeButton(ScoringMode mode, String label) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            boxShadow: isSelected
                ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberDropdown(AppLocalizations loc, bool isDark, List<Member> members) {
    // Match selected member by ID to prevent DropdownMenuItem assertion crash
    Member? selectedMemberInList;
    if (_selectedMember != null) {
      try {
        selectedMemberInList = members.firstWhere((m) => m.id == _selectedMember!.id);
      } catch (_) {
        selectedMemberInList = null;
      }
    }

    return PremiumCard(
      child: DropdownButtonFormField<Member>(
        decoration: InputDecoration(
          labelText: loc.translate('select_member'),
          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? AppTheme.darkBg.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.05),
        ),
        initialValue: selectedMemberInList,
        hint: Text(members.isEmpty ? 'Loading members...' : loc.translate('select_member')),
        items: members.map((member) {
          return DropdownMenuItem(value: member, child: Text(member.name));
        }).toList(),
        onChanged: (value) => setState(() => _selectedMember = value),
      ),
    );
  }

  bool _canSubmit() {
    if (_points == 0 || _selectedTag == null || _isSubmitting) return false;
    if (_mode == ScoringMode.individual && _selectedMember == null) return false;
    return true;
  }

  Widget _pointButton(int value, Color color) {
    final label = value > 0 ? '+$value' : '$value';
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _points += value),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitScore() async {
    final auth = context.read<AuthProvider>();
    final tournament = context.read<TournamentProvider>();
    final storage = context.read<StorageService>();
    final loc = AppLocalizations.of(context);

    setState(() => _isSubmitting = true);

    await auth.checkApproval();
    if (auth.status != AuthStatus.approved) {
      if (mounted) {
        String message = loc.translate('access_revoked_message');
        if (auth.status == AuthStatus.scanning) {
          message = loc.translate('registration_not_found_message');
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    final leaderId = await storage.getOrGenerateLeaderId();
    String status = 'ERROR';

    if (_mode == ScoringMode.individual) {
      final transaction = ScoreTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        targetId: _selectedMember!.id,
        targetType: 'MEMBER',
        leaderId: leaderId,
        points: _points,
        tag: _selectedTag!,
        status: 'PENDING',
        timestamp: DateTime.now(),
        description: _descriptionController.text.trim(),
      );
      status = await tournament.submitScore(transaction);
    } else {
      status = await tournament.submitBulkScore(
        teamId: widget.team.id,
        points: _points,
        tag: _selectedTag!,
        description: _descriptionController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      
      bool isSuccess = status == 'SUCCESS';
      bool isOffline = status == 'OFFLINE_SAVED';
      
      String title = isSuccess ? loc.translate('success') : (isOffline ? loc.translate('offline_success') : loc.translate('error'));
      String message;
      if (isSuccess) {
        message = _mode == ScoringMode.individual ? loc.translate('score_submitted_success') : loc.translate('score_submitted_bulk');
      } else if (isOffline) {
        message = loc.translate('score_saved_offline');
      } else {
        message = loc.translate('score_submit_failed');
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackScreen(
            success: isSuccess || isOffline,
            isOffline: isOffline,
            title: title,
            message: message,
            primaryButtonLabel: loc.translate('score_another'),
            primaryButtonIcon: Icons.person_add_rounded,
            onPrimaryAction: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.pushNamed(context, '/member_selector');
            },
            secondaryButtonLabel: loc.translate('back_to_home'),
            onSecondaryAction: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }
}
