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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<Team>? _teams;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadData(isInitial: true);
  }

  Future<void> _loadData({bool isInitial = false}) async {
    if (isInitial) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
    }

    try {
      // 1. Try normal fetch first
      final teams = await _apiClient.fetchTeams().timeout(
        const Duration(seconds: 5),
      );

      if (!mounted) return;
      setState(() {
        _teams = teams;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      // 2. If fetch fails, try to reconnect automatically
      if (!mounted) return;

      // Only show snackbar if we are in the "refreshing" state (not initial full screen load)
      // or if we want to inform user we are trying to fix it.
      if (!isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connection failed. Scanning for Admin laptop..."),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final newIp = await _apiClient.findNewServerIP();

      if (newIp != null) {
        // 3. Retry fetch with new IP
        try {
          final teamsRetry = await _apiClient.fetchTeams().timeout(
            const Duration(seconds: 5),
          );

          if (!mounted) return;
          setState(() {
            _teams = teamsRetry;
            _isLoading = false;
            _error = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Reconnected successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          return;
        } catch (retryError) {
          // Retry failed too
        }
      }

      // If we get here, both initial fetch and recovery failed
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });

      if (!isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not find server. Please check Wi-Fi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Team')),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(isInitial: false),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200), // Push the spinner down a bit
          Center(
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
          ),
        ],
      );
    } else if (_error != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
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
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry Connection"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _refreshIndicatorKey.currentState?.show(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (_teams == null || _teams!.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
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
              ),
            ),
          );
        },
      );
    }

    // Success State
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _teams!.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(child: Text(_teams![index].name[0])),
          title: Text(_teams![index].name),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemberListScreen(team: _teams![index]),
              ),
            );
          },
        );
      },
    );
  }
}
