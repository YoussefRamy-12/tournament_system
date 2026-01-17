import 'package:flutter/material.dart';
import 'package:shared_models/models.dart'; // Use the shared model!
import '../network/api_client.dart';
import 'member_list_screen.dart'; // Move the second screen to its own file

class MemberSelector extends StatefulWidget {
  const MemberSelector({Key? key}) : super(key: key);

  @override
  State<MemberSelector> createState() => _MemberSelectorState();
}

class _MemberSelectorState extends State<MemberSelector> {
  final ApiClient _apiClient = ApiClient();
  late Future<List<Team>> _teamsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the teams from the laptop immediately
    _teamsFuture = _apiClient.fetchTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Team')),
      body: FutureBuilder<List<Team>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}\nMake sure you scanned the QR code!'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No teams found in database.'));
          }

          final teams = snapshot.data!;

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text(teams[index].name[0])),
                title: Text(teams[index].name),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberListScreen(team: teams[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}