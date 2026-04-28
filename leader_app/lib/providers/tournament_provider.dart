import 'package:flutter/material.dart';
import 'package:shared_models/models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class TournamentProvider with ChangeNotifier {
  final ApiService _api;
  final StorageService _storage;

  List<Team> _teams = [];
  final Map<int, List<Member>> _membersMap = {};
  List<Map<String, dynamic>> _history = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  List<Team> get teams => _teams;
  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  TournamentProvider({required ApiService api, required StorageService storage})
      : _api = api,
        _storage = storage;

  List<Member> getMembersForTeam(int teamId) {
    return _membersMap[teamId] ?? [];
  }

  Future<void> fetchTeams() async {
    _setLoading(true);
    try {
      final url = await _storage.getUrl();
      if (url == null) throw Exception("Server URL not found");
      _teams = await _api.fetchTeams(url);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMembers(int teamId) async {
    _setLoading(true);
    try {
      final url = await _storage.getUrl();
      if (url == null) throw Exception("Server URL not found");
      final members = await _api.fetchMembers(url, teamId);
      _membersMap[teamId] = members;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchHistory() async {
    _setLoading(true);
    try {
      final url = await _storage.getUrl();
      final leaderId = await _storage.getOrGenerateLeaderId();
      if (url == null) throw Exception("Server URL not found");
      _history = await _api.fetchHistory(url, leaderId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitScore(ScoreTransaction transaction) async {
    _setLoading(true);
    try {
      final url = await _storage.getUrl();
      if (url == null) throw Exception("Server URL not found");
      final success = await _api.submitScore(url, transaction);
      if (success) {
        await fetchHistory(); // Refresh history after submission
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

