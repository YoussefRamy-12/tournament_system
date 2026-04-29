import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../server/dashboard_notifier.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Map<String, dynamic> _stats = {
    'pendingTx': 0,
    'onlineLeaders': 0,
    'pendingLeaders': 0,
    'approvedLeaders': 0,
    'totalMembers': 0,
    'onlineLeadersList': [],
  };

  bool _isLoading = false;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  DashboardProvider() {
    refreshStats();
    // Listen for real-time updates from the server/database
    DashboardNotifier.instance.onUpdate.listen((_) {
      refreshStats();
    });
  }

  Future<void> refreshStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await _dbHelper.getAdminDashboardStats();
    } catch (e) {
      debugPrint('❌ Error refreshing dashboard stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
