import 'package:flutter/material.dart';
import 'package:leader_app/ui/scoring_form_screen.dart';
import 'package:shared_models/models.dart';
import '../network/api_client.dart';
// import 'scoring_form_screen.dart'; // We will build this next

class MemberListScreen extends StatefulWidget {
  final Team team;

  const MemberListScreen({super.key, required this.team});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Member>? _members;
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
      final members = await _apiClient
          .fetchMembers(widget.team.id)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

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
        try {
          final membersRetry = await _apiClient
              .fetchMembers(widget.team.id)
              .timeout(const Duration(seconds: 5));
          if (!mounted) return;
          setState(() {
            _members = membersRetry;
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
        } catch (_) {}
      }

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
      appBar: AppBar(title: Text('${widget.team.name} Members')),
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
          SizedBox(height: 200),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(height: 16),
                Text(
                  "Loading members...",
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
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Oops! Something went wrong",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We couldn't load the members right now. Please try again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text("Try Again"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        // Identical UX: Trigger the refresh indicator
                        onPressed: () =>
                            _refreshIndicatorKey.currentState?.show(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    final members = _members ?? [];

    if (members.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                alignment: Alignment.center,
                child: const Text("No members found in this team."),
              ),
            ],
          );
        },
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
                builder: (context) => ScoringFormScreen(member: members[index]),
              ),
            );
          },
        );
      },
    );
  }
}
