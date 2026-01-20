// import 'dart:io';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:path/path.dart';

// class DbHelper {
//   static Database? _database;

//   static Future<void> initializeSqfliteFfi() async {
//     sqfliteFfiInit();
//     databaseFactory = databaseFactoryFfi;
//   }

//   static Future<Database> getDatabase() async {
//     _database ??= await _initDatabase();
//     return _database!;
//   }

//   static Future<Database> _initDatabase() async {
//     final dbPath = await getDatabasesPath();
//     final path = '$dbPath/tournament.db';

//     return await openDatabase(path, version: 1, onCreate: _createTables);
//   }

//   static Future<void> _createTables(Database db, int version) async {
//     await db.execute('''
//       CREATE TABLE users (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         name TEXT NOT NULL,
//         created_at DATETIME DEFAULT CURRENT_TIMESTAMP
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE teams (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         tournament_id INTEGER NOT NULL,
//         name TEXT NOT NULL,
//         created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
//         FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
//       )
//     ''');

//     // Create Transactions Table
//     await db.execute('''
//             CREATE TABLE transactions (
//               id TEXT PRIMARY KEY,
//               target_id INTEGER,
//               points INTEGER,
//               tag TEXT,
//               status TEXT,
//               timestamp TEXT
//             )
//           ''');
//   }
// }
// import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

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

    // 2. Define the path (saves a file named 'tournament.db' on your laptop)
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = join(dbPath, "tournament.db");

    // 3. Open/Create the database
    return await databaseFactory.openDatabase(
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
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      transactions.*, 
      members.name as memberName, 
      leaders.name as leaderName 
    FROM transactions 
    JOIN members ON transactions.target_id = members.id
    LEFT JOIN leaders ON transactions.leader_id = leaders.id 
    ORDER BY timestamp DESC
  ''');
  }

  // Fetch pending transactions with Member Names
  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      transactions.*, 
      members.name as memberName, 
      leaders.name as leaderName -- We add this line
    FROM transactions 
    JOIN members ON transactions.target_id = members.id
    LEFT JOIN leaders ON transactions.leader_id = leaders.id -- Join with leaders
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
  }

  Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      teams.name, 
      teams.id,
      SUM(transactions.points) as totalScore
    FROM teams
    LEFT JOIN members ON teams.id = members.team_id
    LEFT JOIN transactions ON members.id = transactions.target_id
    WHERE transactions.status = 'APPROVED' OR transactions.status IS NULL
    GROUP BY teams.id
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
  }

  // Delete a team and its associated members and transactions
  Future<void> deleteTeam(int teamId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('members', where: 'team_id = ?', whereArgs: [teamId]);
      await txn.delete('teams', where: 'id = ?', whereArgs: [teamId]);
    });
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
  }

  // Delete a leader
  Future<void> deleteLeader(String leaderId) async {
    final db = await database;
    await db.delete('leaders', where: 'id = ?', whereArgs: [leaderId]);
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Gets team totals for the leaderboard
  Future<List<Map<String, dynamic>>> getTeamStats() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      T.name AS team_name, 
      SUM(CASE WHEN TR.status = 'approved' THEN TR.points ELSE 0 END) AS total_points
    FROM Teams T
    LEFT JOIN Members M ON T.id = M.team_id
    LEFT JOIN Transactions TR ON M.id = TR.target_id
    GROUP BY T.id, T.name
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
      SUM(Transactions.points) as totalScore
    FROM Members
    JOIN Teams ON Members.team_id = Teams.id
    LEFT JOIN Transactions ON Members.id = Transactions.target_id
    WHERE Transactions.status = 'APPROVED'
    GROUP BY Members.id
    ORDER BY totalScore DESC
    LIMIT 10
  ''');
}
  Future<List<Map<String, dynamic>>> getTeamPlayers(int teamId) async {
  final db = await database;
  return await db.rawQuery('''
    SELECT 
      M.id, 
      M.name, 
      (SELECT IFNULL(SUM(points), 0) 
       FROM Transactions 
       WHERE target_id = M.id AND status = 'APPROVED') as memberTotal
    FROM Members M
    WHERE M.team_id = ?
    ORDER BY M.name ASC
  ''', [teamId]);
}

Future<Map<String, dynamic>> getTeamSummary(int teamId) async {
  final db = await database;
  final result = await db.rawQuery('''
    SELECT 
      COUNT(M.id) as memberCount,
      IFNULL(AVG(member_scores.total), 0) as teamAverage,
      (SELECT name FROM Members WHERE id = member_scores.id) as topPlayerName,
      MAX(IFNULL(member_scores.total, 0)) as topPlayerScore
    FROM Members M
    LEFT JOIN (
      SELECT target_id as id, SUM(points) as total 
      FROM Transactions 
      WHERE status = 'APPROVED' 
      GROUP BY target_id
    ) member_scores ON M.id = member_scores.id
    WHERE M.team_id = ?
  ''', [teamId]);
  
  return result.first;
}


}
