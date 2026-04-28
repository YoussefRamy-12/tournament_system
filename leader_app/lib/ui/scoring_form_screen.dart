import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
import 'package:leader_app/network/connection_manager.dart';
import 'package:shared_models/models.dart';
import 'package:shared_models/constants.dart';
import '../network/api_client.dart'; // Ensure this import exists

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
    return Scaffold(
      appBar: AppBar(title: Text(loc.translateWithParam('score_member', 'name', widget.member.name))),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Points Display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        loc.translate('points_to_award'),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        '$_points',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Points Buttons
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _pointButton(
                        -1,
                        Colors.red,
                      ), // Added a minus button for mistakes
                      _pointButton(
                        -5,
                        Colors.red,
                      ), // Added a minus button for mistakes
                      _pointButton(-10, Colors.red),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Added a minus button for mistakes
                      _pointButton(1, Colors.green),
                      _pointButton(5, Colors.green),
                      _pointButton(10, Colors.green),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Tag Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: loc.translate('reason_tag'),
                ),
                hint: Text(loc.translate('select_tag')),
                initialValue: _selectedTag,
                items: TournamentConstants.scoreTags.map((tag) {
                  return DropdownMenuItem(value: tag, child: Text(tag));
                }).toList(),
                onChanged: (value) => setState(() => _selectedTag = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: loc.translate('description_optional'),
                  hintText: loc.translate('add_details_hint'),
                ),
                maxLines: 3,
                // onChanged: (value) => setState(() => _description = value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      (_points != 0 && _selectedTag != null && !_isSubmitting)
                      ? _submitScore
                      : null,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          loc.translate('submit_score'),
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pointButton(int value, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(foregroundColor: color),
      onPressed: () => setState(() => _points += value),
      child: Text(value > 0 ? '+$value' : '$value'),
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
            content: Text(
              loc.translate('connection_lost_message'),
            ),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
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
