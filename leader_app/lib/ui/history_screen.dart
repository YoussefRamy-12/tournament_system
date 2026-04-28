import 'package:flutter/material.dart';
import 'package:leader_app/ui/app_localizations.dart';
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
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.translate('connection_failed')),
            duration: const Duration(seconds: 2),
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
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).translate('reconnected_successfully'),
              ),
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('could_not_find_server'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('my_scoring_requests'))),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () => _loadData(isInitial: false),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final loc = AppLocalizations.of(context);
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
                      Text(
                        loc.translate('oops_something_wrong'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.translate('could_not_load_members'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(loc.translate('try_again')),
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
              child: Center(child: Text(loc.translate('no_scores_yet'))),
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
            loc.translate('pending_requests'),
            Colors.orange,
            pending,
            Icons.hourglass_empty,
          ),
        if (pending.isNotEmpty) const SizedBox(height: 24),
        if (approved.isNotEmpty)
          _buildStatusSection(
            loc.translate('approved'),
            Colors.green,
            approved,
            Icons.check_circle,
          ),
        if (approved.isNotEmpty) const SizedBox(height: 24),
        if (rejected.isNotEmpty)
          _buildStatusSection(
            loc.translate('rejected'),
            Colors.red,
            rejected,
            Icons.cancel,
          ),
      ],
    );
  }

  Widget _buildStatusSection(
    String status,
    Color color,
    List<Map<String, dynamic>> items,
    IconData icon,
  ) {
    final loc = AppLocalizations.of(context);
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
                isThreeLine:
                    item['description'] != null &&
                    item['description'].toString().isNotEmpty,
                title: Text(
                  item['memberName'] ?? loc.translate('unknown_member'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['tag']} • ${item['points'] > 0 ? "+" : ""}${item['points']} pts',
                    ),
                    if (item['description'] != null &&
                        item['description'].toString().isNotEmpty)
                      Text(
                        item['description'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
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
