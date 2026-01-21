import 'package:flutter/material.dart';
import 'package:shared_models/models.dart'; // Use the shared model!
import '../network/api_client.dart';
import 'member_list_screen.dart'; // Move the second screen to its own file

class MemberSelector extends StatefulWidget {
  const MemberSelector({super.key});

  @override
  State<MemberSelector> createState() => _MemberSelectorState();
}

class _MemberSelectorState extends State<MemberSelector> {
  final ApiClient _apiClient = ApiClient();
  late Future<List<Team>> _teamsFuture;
  bool _isOnline = true;
  bool _isReconnecting = false;

  void _refreshData() {
    setState(() {
      _teamsFuture = _apiClient.fetchTeams();
    });
  }

  @override
  void initState() {
    super.initState();
    // Fetch the teams from the laptop immediately
    _teamsFuture = _apiClient.fetchTeams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_problem),
            tooltip: 'Reconnect to Laptop',
            onPressed: () async {
              setState(() {
                _isReconnecting = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Re-scanning network for Admin laptop..."),
                ),
              );
              String? found = await _apiClient.findNewServerIP();
              if (found != null) {
                _refreshData();
                setState(() {
                  _isReconnecting = false;
                  _isOnline = true;
                });
              } else {
                setState(() {
                  _isReconnecting = false;
                  _isOnline = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Laptop not found. Check Wi-Fi."),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Team>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 16),
                  Text(
                    "Loading tournament data...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.orangeAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Connection Not Found",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "It looks like we can't find the team data. Did you scan the correct QR code for this event?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isReconnecting = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Re-scanning network for Admin laptop...",
                            ),
                          ),
                        );
                        String? found = await _apiClient.findNewServerIP();
                        if (found != null) {
                          _refreshData();
                          setState(() {
                            _isReconnecting = false;
                            _isOnline = true;
                          });
                        } else {
                          setState(() {
                            _isReconnecting = false;
                            _isOnline = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Laptop not found. Check Wi-Fi."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, color: Colors.white24, size: 60),
                  SizedBox(height: 16),
                  Text(
                    "No Teams Registered",
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                  Text(
                    "Once teams are added, they will appear here.",
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            );
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
                      builder: (context) =>
                          MemberListScreen(team: teams[index]),
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
