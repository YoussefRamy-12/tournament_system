import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../database/db_helper.dart';

class CsvService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> hasExistingData() async {
    final db = await _dbHelper.database;
    final result = await db.query('members', limit: 1);
    return result.isNotEmpty;
  }

  Future<void> clearAllMembers() async {
    final db = await _dbHelper.database;
    await db.delete('members');
  }

  Future<void> importMembersFromCsv(String filePath) async {
    final file = File(filePath);
    final input = file.openRead();

    // Convert CSV rows into a List of Lists
    final fields =
        await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();

    // Loop through rows (Starting at index 1 to skip the header)
    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 2) continue;

      String teamName = row[0].toString().trim();
      String memberName = row[1].toString().trim();

      await _syncMemberToDb(teamName, memberName);
    }
  }

  Future<void> _syncMemberToDb(String teamName, String memberName) async {
    final db = await _dbHelper.database;

    // 1. Check if the team exists, if not, create it
    List<Map<String, dynamic>> teamResult = await db.query(
      'teams',
      where: 'name = ?',
      whereArgs: [teamName],
    );

    int teamId;
    if (teamResult.isEmpty) {
      teamId = await db.insert('teams', {'name': teamName});
    } else {
      teamId = teamResult.first['id'] as int;
    }

    // 2. Insert the Member linked to that Team ID
    await db.insert('members', {'team_id': teamId, 'name': memberName});
  }
}
