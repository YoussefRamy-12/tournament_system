import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_app/database/db_helper.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _selectedLevel = 'ALL';
  String _selectedCategory = 'ALL';

  final List<String> _levels = ['ALL', 'INFO', 'WARNING', 'ERROR', 'SUCCESS'];
  final List<String> _categories = ['ALL', 'SERVER', 'LEADER', 'SCORES', 'SYSTEM'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _dbHelper.getSystemLogs(
      level: _selectedLevel,
      category: _selectedCategory,
    );
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Future<void> _clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('Are you sure you want to permanently delete all stored system logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Logs', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.clearSystemLogs();
      _loadLogs();
    }
  }

  Color _getLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'SUCCESS':
        return Colors.green;
      case 'INFO':
      default:
        return Colors.blue;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return Icons.error_outline_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'SUCCESS':
        return Icons.check_circle_outline_rounded;
      case 'INFO':
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System & Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Logs',
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 20),
                const SizedBox(width: 8),
                const Text('Filters:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                
                // Level Dropdown
                DropdownButton<String>(
                  value: _selectedLevel,
                  underline: const SizedBox(),
                  items: _levels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text('Level: $level'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedLevel = val);
                      _loadLogs();
                    }
                  },
                ),
                const SizedBox(width: 20),

                // Category Dropdown
                DropdownButton<String>(
                  value: _selectedCategory,
                  underline: const SizedBox(),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text('Category: $cat'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                      _loadLogs();
                    }
                  },
                ),
                const Spacer(),
                Text(
                  'Total Entries: ${_logs.length}',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Logs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No logs found matching selected filters.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _logs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final level = log['level'] as String? ?? 'INFO';
                          final category = log['category'] as String? ?? 'SYSTEM';
                          final message = log['message'] as String? ?? '';
                          final details = log['details'] as String?;
                          final timestamp = log['timestamp'] as String? ?? '';

                          DateTime? parsedDate = DateTime.tryParse(timestamp);
                          String formattedTime = parsedDate != null
                              ? "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')} (${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')})"
                              : timestamp;

                          final color = _getLevelColor(level);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(_getLevelIcon(level), color: color, size: 22),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    level,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (details != null && details.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        details,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.textTheme.bodySmall?.color,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: "[$level] [$category] $message ${details ?? ''} ($formattedTime)",
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Log copied to clipboard!')),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
