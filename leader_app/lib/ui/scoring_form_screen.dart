import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/network/connection_manager.dart';
import 'package:leader_app/ui/widgets/premium_widgets.dart';
import 'package:leader_app/ui/theme/app_theme.dart';
import 'package:shared_models/models.dart';
import 'package:shared_models/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../network/api_client.dart';

class ScoringFormScreen extends StatefulWidget {
  final Member member;
  const ScoringFormScreen({super.key, required this.member});

  @override
  State<ScoringFormScreen> createState() => _ScoringFormScreenState();
}

class _ScoringFormScreenState extends State<ScoringFormScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _descriptionController = TextEditingController();
  int _points = 0;
  String? _selectedTag;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeLeaderId();
  }

  Future<void> _initializeLeaderId() async {}

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.translateWithParam('score_member', 'name', widget.member.name),
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
                      label: Text(
                        loc.translate('reset_points'),
                      ), // Ensure this key exists or use a default
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
                              ? AppTheme.darkBg.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.05),
                        ),
                        hint: Text(loc.translate('select_tag')),
                        initialValue: _selectedTag,
                        items: TournamentConstants.scoreTags.map((tag) {
                          return DropdownMenuItem(value: tag, child: Text(tag));
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
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                PremiumButton(
                  label: loc.translate('submit_score'),
                  onPressed:
                      (_points != 0 && _selectedTag != null && !_isSubmitting)
                      ? _submitScore
                      : null,
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

  Widget _pointButton(int value, Color color) {
    final label = value > 0 ? '+$value' : '$value';
    return Container(
      width: 80,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _points += value);
            // Add haptic-like effect or animation here if needed
          },
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
    final conn = ConnectionManager();
    final leaderId = await conn.getOrGenerateLeaderId();

    // 1. Ask the server: "Am I still allowed to do this?"
    String status = 'UNKNOWN';
    try {
      status = await _apiClient
          .checkLeaderStatus(leaderId)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('connection_lost_message')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    if (status != 'APPROVED') {
      // 2. If rejected or blocked, kick them back to the waiting screen
      if (mounted) {
        final loc = AppLocalizations.of(context);
        String message = loc.translate('access_revoked_message');
        if (status == 'NOT_FOUND') {
          message = loc.translate('registration_not_found_message');
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/waiting_approval',
          (route) => false,
        );
      }
      return;
    }

    // 3. Only if APPROVED, proceed with the actual submission

    final transaction = ScoreTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: widget.member.id,
      leaderId: leaderId,
      points:
          _points, // Fixed: your code used _selectedPoints which didn't exist
      tag: _selectedTag!,
      status: 'PENDING',
      timestamp: DateTime.now(),
      description: _descriptionController.text.trim(),
    );

    final success = await _apiClient.submitScore(transaction);

    if (mounted) {
      final loc = AppLocalizations.of(context);
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('score_submitted_success'))),
        );
        Navigator.pop(context); // Go back to member list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('score_submit_failed'))),
        );
      }
    }
  }
}
