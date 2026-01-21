import 'package:flutter/material.dart';
import '../network/api_client.dart'; // Ensure this points to your client

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Map<String, dynamic>>? _historyRequests;
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
      final data = await _apiClient.fetchMyHistory().timeout(
        const Duration(seconds: 5),
      );
      if (!mounted) return;
      setState(() {
        _historyRequests = data;
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
          final retryData = await _apiClient.fetchMyHistory().timeout(
            const Duration(seconds: 5),
          );
          if (!mounted) return;
          setState(() {
            _historyRequests = retryData;
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
      appBar: AppBar(title: const Text('My Scoring Requests')),
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
          Center(child: CircularProgressIndicator()),
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
                        "We couldn't load the history right now. Please try again.",
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
            ),
          );
        },
      );
    }

    final allRequests = _historyRequests ?? [];

    if (allRequests.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Text('You haven\'t submitted any scores yet.'),
              ),
            ),
          );
        },
      );
    }

    // Filter data into groups
    final approved = allRequests
        .where((i) => i['status'] == 'APPROVED')
        .toList();
    final rejected = allRequests
        .where((i) => i['status'] == 'REJECTED')
        .toList();
    final pending = allRequests.where((i) => i['status'] == 'PENDING').toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        if (pending.isNotEmpty)
          _buildStatusSection(
            'PENDING REQUESTS',
            Colors.orange,
            pending,
            Icons.hourglass_empty,
          ),
        if (pending.isNotEmpty) const SizedBox(height: 24),
        if (approved.isNotEmpty)
          _buildStatusSection(
            'APPROVED',
            Colors.green,
            approved,
            Icons.check_circle,
          ),
        if (approved.isNotEmpty) const SizedBox(height: 24),
        if (rejected.isNotEmpty)
          _buildStatusSection('REJECTED', Colors.red, rejected, Icons.cancel),
      ],
    );
  }

  Widget _buildStatusSection(
    String status,
    Color color,
    List<Map<String, dynamic>> items,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.02),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(color: color.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  item['memberName'] ?? 'Unknown Member',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${item['tag']} • ${item['points'] > 0 ? "+" : ""}${item['points']} pts',
                ),
                trailing: Text(
                  item['timestamp'].toString().substring(
                    11,
                    16,
                  ), // Shows "HH:mm"
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
