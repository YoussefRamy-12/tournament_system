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
  bool isServerOnline = false; // Tracks websocket status
  bool _isOfflineDataReady = false;

  List<Team> get teams => _teams;
  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOfflineDataReady => _isOfflineDataReady;

  TournamentProvider({required ApiService api, required StorageService storage})
      : _api = api,
        _storage = storage;

  List<Member> getMembersForTeam(int teamId) {
    return _membersMap[teamId] ?? [];
  }

  Future<void> fetchTeams() async {
    _setLoading(true);
    try {
      if (!isServerOnline) throw Exception("Server is offline");
      final url = await _storage.getUrl();
      if (url == null) throw Exception("Server URL not found");
      _teams = await _api.fetchTeams(url);
      await _storage.saveCachedTeams(_teams.map((t) => t.toJson()).toList());
      _errorMessage = null;
    } catch (e) {
      final cached = await _storage.getCachedTeams();
      if (cached != null) {
        _teams = cached.map((json) => Team.fromJson(json)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = e.toString();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMembers(int teamId) async {
    _setLoading(true);
    try {
      if (!isServerOnline) throw Exception("Server is offline");
      final url = await _storage.getUrl();
      if (url == null) throw Exception("Server URL not found");
      final members = await _api.fetchMembers(url, teamId);
      _membersMap[teamId] = members;
      await _storage.saveCachedMembers(teamId, members.map((m) => m.toJson()).toList());
      _errorMessage = null;
    } catch (e) {
      final cached = await _storage.getCachedMembers(teamId);
      if (cached != null) {
        _membersMap[teamId] = cached.map((json) => Member.fromJson(json)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = e.toString();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> prefetchOfflineData() async {
    if (!isServerOnline) return;
    _isOfflineDataReady = false;
    notifyListeners();
    try {
      final url = await _storage.getUrl();
      if (url == null) return;
      
      // Fetch all members in parallel for maximum speed
      final futures = _teams.map((team) async {
        try {
          final members = await _api.fetchMembers(url, team.id);
          _membersMap[team.id] = members;
          await _storage.saveCachedMembers(team.id, members.map((m) => m.toJson()).toList());
        } catch (_) {
          // Fallback to cache if possible
          final cached = await _storage.getCachedMembers(team.id);
          if (cached != null) {
            _membersMap[team.id] = cached.map((json) => Member.fromJson(json)).toList();
          }
        }
      }).toList();
      
      await Future.wait(futures);
    } catch (_) {
    } finally {
      _isOfflineDataReady = true;
      notifyListeners();
    }
  }

  Future<void> fetchHistory() async {
    _setLoading(true);
    try {
      if (!isServerOnline) throw Exception("Server is offline");
      final url = await _storage.getUrl();
      final leaderId = await _storage.getOrGenerateLeaderId();
      if (url == null) throw Exception("Server URL not found");
      _history = await _api.fetchHistory(url, leaderId);
      await _storage.saveCachedHistory(_history);
      _errorMessage = null;
    } catch (e) {
      final cached = await _storage.getCachedHistory();
      if (cached != null) {
        _history = cached;
        _errorMessage = null;
      } else {
        _errorMessage = e.toString();
      }
    } finally {
      // Inject pending transactions into history
      final pending = await _storage.getPendingTransactions();
      for (var p in pending) {
        if (p['type'] == 'single') {
          final tx = p['data'];
          _history.insert(0, {
             'id': tx['id'],
             'points': tx['points'],
             'tag': tx['tag'],
             'description': tx['description'],
             'timestamp': tx['timestamp'],
             'status': 'PENDING (OFFLINE)',
             'target_type': 'MEMBER',
             'memberName': _getMemberName(tx['targetId'] ?? tx['target_id']) ?? 'Offline Member',
          });
        } else if (p['type'] == 'bulk') {
          final tx = p['data'];
          _history.insert(0, {
             'id': p['id'],
             'points': tx['points'],
             'tag': tx['tag'],
             'description': tx['description'],
             'timestamp': tx['timestamp'] ?? DateTime.now().toIso8601String(),
             'status': 'PENDING (OFFLINE)',
             'target_type': 'TEAM',
             'targetName': _getTeamName(tx['teamId'] ?? tx['team_id']) ?? 'Offline Team',
          });
        }
      }
      _setLoading(false);
    }
  }

  String? _getMemberName(int? memberId) {
    if (memberId == null) return null;
    for (var members in _membersMap.values) {
      for (var m in members) {
        if (m.id == memberId) return m.name;
      }
    }
    return null;
  }

  String? _getTeamName(int? teamId) {
    if (teamId == null) return null;
    for (var t in _teams) {
      if (t.id == teamId) return t.name;
    }
    return null;
  }

  Future<String> submitScore(ScoreTransaction transaction) async {
    _setLoading(true);
    try {
      if (!isServerOnline) {
        await _saveOffline('single', transaction.toJson());
        await fetchHistory(); // Refresh to show pending score
        return 'OFFLINE_SAVED';
      }
      
      final url = await _storage.getUrl();
      if (url == null) throw Exception("Server URL not found");
      final success = await _api.submitScore(url, transaction);
      if (success) {
        await fetchHistory(); // Refresh history after submission
        return 'SUCCESS';
      } else {
        await _saveOffline('single', transaction.toJson());
        await fetchHistory(); // Refresh to show pending score
        return 'OFFLINE_SAVED';
      }
    } catch (e) {
      await _saveOffline('single', transaction.toJson());
      await fetchHistory(); // Refresh to show pending score
      return 'OFFLINE_SAVED';
    } finally {
      _setLoading(false);
    }
  }

  Future<String> submitBulkScore({
    required int teamId,
    required int points,
    required String tag,
    required String description,
  }) async {
    _setLoading(true);
    try {
      if (!isServerOnline) {
        final leaderId = await _storage.getOrGenerateLeaderId();
        await _saveOffline('bulk', {
          'teamId': teamId,
          'points': points,
          'tag': tag,
          'description': description,
          'leaderId': leaderId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return 'OFFLINE_SAVED';
      }

      final url = await _storage.getUrl();
      final leaderId = await _storage.getOrGenerateLeaderId();
      if (url == null) throw Exception("Server URL not found");
      
      final success = await _api.submitBulkScore(
        url,
        teamId: teamId,
        points: points,
        tag: tag,
        description: description,
        leaderId: leaderId,
      );
      
      if (success) {
        await fetchHistory(); // Refresh history after submission
        return 'SUCCESS';
      } else {
        await _saveOffline('bulk', {
          'teamId': teamId,
          'points': points,
          'tag': tag,
          'description': description,
          'leaderId': leaderId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        await fetchHistory(); // Refresh to show pending score
        return 'OFFLINE_SAVED';
      }
    } catch (e) {
      await _saveOffline('bulk', {
        'teamId': teamId,
        'points': points,
        'tag': tag,
        'description': description,
        'leaderId': await _storage.getOrGenerateLeaderId(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      await fetchHistory(); // Refresh to show pending score
      return 'OFFLINE_SAVED';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveOffline(String type, Map<String, dynamic> data) async {
    await _storage.savePendingTransaction({
      'type': type,
      'data': data,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  Future<void> syncPendingTransactions() async {
    final pending = await _storage.getPendingTransactions();
    if (pending.isEmpty) return;

    final url = await _storage.getUrl();
    if (url == null) return;

    List<String> toRemove = [];
    
    for (var p in pending) {
      bool success = false;
      try {
        if (p['type'] == 'single') {
          final tx = ScoreTransaction.fromJson(p['data']);
          success = await _api.submitScore(url, tx);
        } else if (p['type'] == 'bulk') {
          final data = p['data'];
          success = await _api.submitBulkScore(
            url,
            teamId: data['teamId'],
            points: data['points'],
            tag: data['tag'],
            description: data['description'],
            leaderId: data['leaderId'],
          );
        }
      } catch (_) {}

      if (success) {
        toRemove.add(p['id']);
      }
    }

    if (toRemove.isNotEmpty) {
      final currentPending = await _storage.getPendingTransactions();
      currentPending.removeWhere((element) => toRemove.contains(element['id']));
      
      await _storage.clearPendingTransactions();
      for (var p in currentPending) {
        await _storage.savePendingTransaction(p);
      }
      await fetchHistory(); // Refresh history with synced items
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}

