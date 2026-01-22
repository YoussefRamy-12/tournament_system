import 'dart:async';

/// Singleton that notifies listeners when dashboard stats should be refreshed
/// This is triggered by database changes like new transactions, leader approvals, etc.
class DashboardNotifier {
  static final DashboardNotifier _instance = DashboardNotifier._internal();
  static DashboardNotifier get instance => _instance;

  DashboardNotifier._internal();

  // Stream to notify UI of updates
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onUpdate => _updateController.stream;

  /// Call this whenever a database operation occurs that affects dashboard stats
  void notifyDashboardUpdate() {
    print('📣 DashboardNotifier: Broadcasting update event');
    _updateController.add(null);
  }

  void dispose() {
    _updateController.close();
  }
}
