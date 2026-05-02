import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:admin_app/server/online_leader_tracker.dart';
import 'package:admin_app/server/dashboard_notifier.dart';

class DatabaseHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    // 1. Initialize FFI for Desktop
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    // 2. Define a stable path in the user's AppData
    final appSupportDir = await getApplicationSupportDirectory();
    final dbPath = appSupportDir.path;
    
    // Ensure the directory exists
    if (!await Directory(dbPath).exists()) {
      await Directory(dbPath).create(recursive: true);
    }
    
    final path = join(dbPath, "tournament.db");
    print("📂 Database located at: $path");

    // 3. Open/Create the database
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Create Teams Table
          await db.execute('''
            CREATE TABLE Teams (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');

          // Create Members Table
          await db.execute('''
            CREATE TABLE Members (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              team_id INTEGER,
              name TEXT NOT NULL,
              FOREIGN KEY (team_id) REFERENCES teams (id)
            )
          ''');

          // Create Transactions Table
          await db.execute('''
              CREATE TABLE Transactions (
              id TEXT PRIMARY KEY,
              leader_id TEXT,
              target_id INTEGER,
              target_type TEXT DEFAULT 'MEMBER', -- 'MEMBER' or 'TEAM'
              points INTEGER,
              tag TEXT,
              status TEXT,
              description TEXT,
              timestamp TEXT
            )
        ''');

          await db.execute('''
          CREATE TABLE leaders (
            id TEXT PRIMARY KEY,
            name TEXT,
            status TEXT, -- 'PENDING' or 'APPROVED'
            device_info TEXT
          )
        ''');
        },
      ),
    );

    // 4. Migration: Add target_type if it doesn't exist
    try {
      await db.execute("ALTER TABLE Transactions ADD COLUMN target_type TEXT DEFAULT 'MEMBER'");
      print("🚀 Migration: Added target_type to Transactions");
    } catch (e) {
      // Column already exists, ignore
    }

    return db;
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      transactions.*, 
      CASE 
        WHEN transactions.target_type = 'TEAM' THEN teams.name 
        ELSE members.name 
      END as targetName,
      leaders.name as leaderName 
    FROM transactions 
    LEFT JOIN members ON transactions.target_id = members.id AND (transactions.target_type = 'MEMBER' OR transactions.target_type IS NULL)
    LEFT JOIN teams ON transactions.target_id = teams.id AND transactions.target_type = 'TEAM'
    LEFT JOIN leaders ON transactions.leader_id = leaders.id 
    ORDER BY timestamp DESC
  ''');
  }

  // Fetch pending transactions with Member/Team Names
  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      transactions.*, 
      CASE 
        WHEN transactions.target_type = 'TEAM' THEN teams.name 
        ELSE members.name 
      END as targetName,
      leaders.name as leaderName 
    FROM transactions 
    LEFT JOIN members ON transactions.target_id = members.id AND (transactions.target_type = 'MEMBER' OR transactions.target_type IS NULL)
    LEFT JOIN teams ON transactions.target_id = teams.id AND transactions.target_type = 'TEAM'
    LEFT JOIN leaders ON transactions.leader_id = leaders.id 
    WHERE transactions.status = 'PENDING'
    ORDER BY timestamp DESC
  ''');
  }

  // Update transaction status
  Future<void> updateTransactionStatus(String id, String newStatus) async {
    final db = await database;
    await db.update(
      'transactions',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      teams.name, 
      teams.id,
      (
        SELECT IFNULL(SUM(points), 0) FROM transactions 
        WHERE (
          (target_id = teams.id AND target_type = 'TEAM') 
          OR 
          (target_id IN (SELECT id FROM members WHERE team_id = teams.id) AND (target_type = 'MEMBER' OR target_type IS NULL))
        )
        AND status = 'APPROVED'
      ) as totalScore
    FROM teams
    ORDER BY totalScore DESC
  ''');
  }

  Future<void> updateAllPendingStatus(String newStatus) async {
    final db = await database;
    await db.update(
      'transactions',
      {'status': newStatus},
      where: 'status = ?',
      whereArgs: ['PENDING'],
    );
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  // Fetch all leaders waiting for approval
  Future<List<Map<String, dynamic>>> getPendingLeaders() async {
    final db = await database;
    return await db.query(
      'leaders',
      where: 'status = ?',
      whereArgs: ['PENDING'],
    );
  }

  Future<List<Map<String, dynamic>>> getAllLeaders() async {
    final db = await database;
    return await db.query('leaders');
  }

  // Approve or Reject a leader
  Future<void> updateLeaderStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'leaders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  // Delete a team and its associated members and transactions
  Future<void> deleteTeam(int teamId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('members', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('teams', where: 'id = ?', whereArgs: [teamId]);
    });
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  // Delete a member and their transactions
  Future<void> deleteMember(int memberId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'transactions',
        where: 'target_id = ?',
        whereArgs: [memberId],
      );
      await txn.delete('members', where: 'id = ?', whereArgs: [memberId]);
    });
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  // Delete a leader
  Future<void> deleteLeader(String leaderId) async {
    final db = await database;
    await db.delete('leaders', where: 'id = ?', whereArgs: [leaderId]);
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  // Gets team totals for the leaderboard
  Future<List<Map<String, dynamic>>> getTeamStats() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      T.name AS team_name, 
      (
        SELECT IFNULL(SUM(points), 0) FROM transactions 
        WHERE (
          (target_id = T.id AND target_type = 'TEAM') 
          OR 
          (target_id IN (SELECT id FROM members WHERE team_id = T.id) AND (target_type = 'MEMBER' OR target_type IS NULL))
        )
        AND status = 'APPROVED'
      ) AS total_points
    FROM Teams T
    ORDER BY total_points DESC
  ''');
  }

  // Gets top N individual players
  Future<List<Map<String, dynamic>>> getTop10Players() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      Members.id, 
      Members.name, 
      Teams.name AS teamName, 
      SUM(CASE WHEN (Transactions.target_type = 'MEMBER' OR Transactions.target_type IS NULL) THEN Transactions.points ELSE 0 END) as totalScore
    FROM Members
    JOIN Teams ON Members.team_id = Teams.id
    LEFT JOIN Transactions ON Members.id = Transactions.target_id
    WHERE Transactions.status = 'APPROVED'
    GROUP BY Members.id
    ORDER BY totalScore DESC
    LIMIT 10
  ''');
  }

  Future<List<Map<String, dynamic>>> getAllPlayersWithScores() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      Members.id, 
      Members.name, 
      Teams.name AS teamName, 
      IFNULL(SUM(CASE WHEN (Transactions.target_type = 'MEMBER' OR Transactions.target_type IS NULL) THEN Transactions.points ELSE 0 END), 0) as totalScore
    FROM Members
    JOIN Teams ON Members.team_id = Teams.id
    LEFT JOIN Transactions ON Members.id = Transactions.target_id AND Transactions.status = 'APPROVED'
    GROUP BY Members.id
    ORDER BY totalScore DESC, Members.name ASC
  ''');
  }

  Future<List<Map<String, dynamic>>> getTeamPlayers(int teamId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      M.id, 
      M.name, 
      (SELECT IFNULL(SUM(points), 0) 
       FROM Transactions 
       WHERE target_id = M.id AND status = 'APPROVED') as memberTotal
    FROM Members M
    WHERE M.team_id = ?
    ORDER BY M.name ASC
  ''',
      [teamId],
    );
  }

  Future<Map<String, dynamic>> getTeamSummary(int teamId) async {
    final db = await database;
    
    // 1. Member Count
    final membersCountResult = await db.rawQuery(
      "SELECT COUNT(*) as total FROM Members WHERE team_id = ?",
      [teamId]
    );
    final int memberCount = (membersCountResult.first['total'] as int?) ?? 0;

    // 2. Direct Team Points
    final teamPointsResult = await db.rawQuery(
      "SELECT SUM(points) as total FROM Transactions WHERE target_id = ? AND target_type = 'TEAM' AND status = 'APPROVED'",
      [teamId]
    );
    final int teamPoints = (teamPointsResult.first['total'] as int?) ?? 0;

    // 3. Individual Points Sum
    final memberPointsResult = await db.rawQuery(
      "SELECT SUM(points) as total FROM Transactions WHERE target_id IN (SELECT id FROM Members WHERE team_id = ?) AND (target_type = 'MEMBER' OR target_type IS NULL) AND status = 'APPROVED'",
      [teamId]
    );
    final int memberPoints = (memberPointsResult.first['total'] as int?) ?? 0;

    // 4. Top Player
    final topPlayerResult = await db.rawQuery(
      '''
      SELECT M.name, SUM(T.points) as total 
      FROM Members M 
      JOIN Transactions T ON M.id = T.target_id 
      WHERE M.team_id = ? AND (T.target_type = 'MEMBER' OR T.target_type IS NULL) AND T.status = 'APPROVED'
      GROUP BY M.id 
      ORDER BY total DESC LIMIT 1
      ''',
      [teamId]
    );
    
    String topPlayerName = "N/A";
    int topPlayerScore = 0;
    if (topPlayerResult.isNotEmpty) {
      topPlayerName = topPlayerResult.first['name'] as String;
      topPlayerScore = (topPlayerResult.first['total'] as int?) ?? 0;
    }

    return {
      'memberCount': memberCount,
      'teamPoints': teamPoints,
      'memberPoints': memberPoints,
      'totalPoints': teamPoints + memberPoints,
      'topPlayerName': topPlayerName,
      'topPlayerScore': topPlayerScore,
    };
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    final db = await database;
    // We fetch only the ID and Name to keep the dropdown lightweight
    return await db.query(
      'Teams',
      columns: ['id', 'name'],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final db = await database;

    // 1. Pending Transactions
    final txCount = (await db.rawQuery(
      '''SELECT COUNT(*) as total FROM Transactions WHERE status = 'PENDING' ''',
    ));
    final pendingTransactionsCount = (txCount.first['total'] as int?) ?? 0;

    // 2. Pending Leader Approvals
    final leaderPendingCount = (await db.rawQuery(
      "SELECT COUNT(*) as total FROM Leaders WHERE status = 'PENDING'",
    ));
    final pendingLeaderCount = (leaderPendingCount.first['total'] as int?) ?? 0;

    // 2.5 Approved Leaders
    final leaderApprovedCount = (await db.rawQuery(
      "SELECT COUNT(*) as total FROM Leaders WHERE status = 'APPROVED'",
    ));
    final approvedLeaderCount = (leaderApprovedCount.first['total'] as int?) ?? 0;

    // 3. Total Members/Teams
    final memberResult = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM Members",
    );
    final totalMemberCount = memberResult.first['total'] as int;
    // 4. Online Leaders
    final onlineCount = OnlineLeaderTracker.instance.onlineCount;
    final onlineIds = OnlineLeaderTracker.instance.onlineLeaderIds;
    List<Map<String, dynamic>> onlineLeadersList = [];
    if (onlineIds.isNotEmpty) {
      final placeholders = List.filled(onlineIds.length, '?').join(',');
      onlineLeadersList = await db.query(
        'leaders',
        where: 'id IN ($placeholders)',
        whereArgs: onlineIds,
      );
    }

    return {
      'pendingTx': pendingTransactionsCount,
      'pendingLeaders': pendingLeaderCount,
      'approvedLeaders': approvedLeaderCount,
      'totalMembers': totalMemberCount,
      'onlineLeaders': onlineCount,
      'onlineLeadersList': onlineLeadersList,
    };
  }

  // Clear selected tables to start fresh
  Future<void> clearSelectedData(List<String> tables) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var table in tables) {
        await txn.delete(table);
      }
    });
    DashboardNotifier.instance.notifyDashboardUpdate();
  }

  Future<void> submitBulkScore({
    required int teamId,
    required int totalPoints,
    required String leaderId,
    required String tag,
    required String description,
    required String timestamp,
  }) async {
    final db = await database;
    
    await db.insert('transactions', {
      'id': "${timestamp}_team_$teamId",
      'leader_id': leaderId,
      'target_id': teamId,
      'target_type': 'TEAM',
      'points': totalPoints,
      'tag': tag,
      'description': description,
      'status': 'PENDING',
      'timestamp': timestamp,
    });

    DashboardNotifier.instance.notifyDashboardUpdate();
  }
}
