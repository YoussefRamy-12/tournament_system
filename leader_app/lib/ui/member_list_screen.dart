import 'package:flutter/material.dart';
import 'package:leader_app/ui/scoring_form_screen.dart';
import 'package:shared_models/models.dart';
import '../network/api_client.dart';
// import 'scoring_form_screen.dart'; // We will build this next

class MemberListScreen extends StatelessWidget {
  final Team team;
  final ApiClient _apiClient = ApiClient();

  MemberListScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${team.name} Members')),
      body: FutureBuilder<List<Member>>(
        future: _apiClient.fetchMembers(team.id), // Use the ID from Phase 1
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final members = snapshot.data ?? [];
          if (members.isEmpty) {
            return const Center(child: Text("No members found in this team."));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(members[index].name),
                onTap: () {
                  // Navigate to the form to actually give points
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ScoringFormScreen(member: members[index]),
                    ),
                  );

                  print('Selected ${members[index].name}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
