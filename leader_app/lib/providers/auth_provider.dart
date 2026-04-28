import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unauthenticated, scanning, registering, waitingApproval, approved, error }

class AuthProvider with ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;
  bool _isInitializing = true;
  Timer? _pollingTimer;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isInitializing => _isInitializing;

  AuthProvider({required ApiService api, required StorageService storage})
      : _api = api,
        _storage = storage {
    initialize();
  }

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final url = await _storage.getUrl();
    final registered = await _storage.isRegistered();

    if (url == null) {
      _status = AuthStatus.scanning;
    } else if (!registered) {
      _status = AuthStatus.registering;
    } else {
      await checkApproval();
    }

    _isInitializing = false;
    notifyListeners();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_status == AuthStatus.waitingApproval) {
        checkApproval();
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> processScannedUrl(String url) async {
    if (!url.startsWith('http')) return false;

    final leaderId = await _storage.getOrGenerateLeaderId();
    final isAvailable = await _api.isServerAvailable(url, leaderId);

    if (isAvailable) {
      await _storage.saveUrl(url);
      _status = AuthStatus.registering;
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Server not available at $url";
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name) async {
    _status = AuthStatus.registering;
    notifyListeners();

    final url = await _storage.getUrl();
    final leaderId = await _storage.getOrGenerateLeaderId();

    if (url == null) return false;

    final success = await _api.registerLeader(url, leaderId, name);
    if (success) {
      await _storage.saveLeaderName(name);
      await _storage.setRegistered(true);
      _status = AuthStatus.waitingApproval;
      _startPolling();
      notifyListeners();
      return true;
    } else {
      _errorMessage = "Registration failed";
      notifyListeners();
      return false;
    }
  }

  Future<void> checkApproval() async {
    final url = await _storage.getUrl();
    final leaderId = await _storage.getOrGenerateLeaderId();

    if (url == null) return;

    final result = await _api.checkLeaderStatus(url, leaderId);
    
    AuthStatus oldStatus = _status;
    if (result == 'APPROVED') {
      _status = AuthStatus.approved;
      _pollingTimer?.cancel();
    } else if (result == 'PENDING') {
      _status = AuthStatus.waitingApproval;
      if (_pollingTimer == null || !_pollingTimer!.isActive) {
        _startPolling();
      }
    } else if (result == 'NOT_FOUND') {
      await _storage.clearRegistration();
      _status = AuthStatus.scanning;
      _pollingTimer?.cancel();
    } else {
      _status = AuthStatus.waitingApproval;
    }
    
    if (oldStatus != _status) {
      notifyListeners();
    }
  }

  void logout() async {
    _pollingTimer?.cancel();
    await _storage.clearRegistration();
    _status = AuthStatus.scanning;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
