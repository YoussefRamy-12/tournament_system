import 'package:flutter/material.dart';
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
  TextEditingController _descriptionController = TextEditingController();
  int _points = 0;
  String? _selectedTag;
  String _description = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeLeaderId();
  }

  Future<void> _initializeLeaderId() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Score ${widget.member.name}')),
      body: Padding(
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
                    const Text(
                      'Points to Award',
                      style: TextStyle(fontSize: 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pointButton(
                  -1,
                  Colors.red,
                ), // Added a minus button for mistakes
                _pointButton(1, Colors.green),
                _pointButton(5, Colors.green),
                _pointButton(10, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            // Tag Dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Reason / Tag",
              ),
              hint: const Text('Select a tag'),
              initialValue: _selectedTag,
              items: TournamentConstants.scoreTags.map((tag) {
                return DropdownMenuItem(value: tag, child: Text(tag));
              }).toList(),
              onChanged: (value) => setState(() => _selectedTag = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description (Optional)',
                hintText: 'Add any additional details...',
              
              ),
              maxLines: 3,
              // onChanged: (value) => setState(() => _description = value),
            ),
            const Spacer(),
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
                    : const Text(
                        'Submit Score',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pointButton(int value, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
      ),
      onPressed: () => setState(() => _points += value),
      child: Text(value > 0 ? '+$value' : '$value'),
    );
  }

  Future<void> _submitScore() async {
  final conn = ConnectionManager();
  final leader_id = await conn.getOrGenerateLeaderId();

  // 1. Ask the server: "Am I still allowed to do this?"
  final status = await _apiClient.checkLeaderStatus(leader_id);

  if (status != 'APPROVED') {
    // 2. If rejected or blocked, kick them back to the waiting screen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access Revoked: Your account is no longer approved."))
      );
      Navigator.pushNamedAndRemoveUntil(context, '/waiting_approval', (route) => false);
    }
    return;
  }

  // 3. Only if APPROVED, proceed with the actual submission
      print("leader id is $leader_id");

    final transaction = ScoreTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: widget.member.id,
      leaderId: leader_id,
      points:
          _points, // Fixed: your code used _selectedPoints which didn't exist
      tag: _selectedTag!,
      status: 'PENDING',
      timestamp: DateTime.now(),
      description: _descriptionController.text.trim(),
    );

    final success = await _apiClient.submitScore(transaction);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Score submitted for approval!')),
        );
        Navigator.pop(context); // Go back to member list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to connect to Admin Laptop.')),
        );
      }
    }
  }
}
