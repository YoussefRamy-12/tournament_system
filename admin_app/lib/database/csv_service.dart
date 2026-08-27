import 'dart:io';
import 'package:csv/csv.dart';
import '../database/db_helper.dart';
import '../server/dashboard_notifier.dart';
import '../services/logger_service.dart';

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
    await importCsvFromFile(file);
  }

  Future<void> importCsvFromFile(File file) async {
    final csvString = await file.readAsString();
    await importCsvFromString(csvString);
  }

  Future<void> importCsvFromString(String csvString) async {
    // We use shouldParseNumbers: false to keep everything as strings
    final List<List<dynamic>> fields = const CsvToListConverter().convert(csvString);

    LoggerService.instance.info('CSV', 'CSV Parsing: Found ${fields.length} rows.');

    if (fields.isEmpty) return;

    // Determine if we should skip the first row (header)
    // If the first row contains "Team" or "Member" (case insensitive), we skip it
    int startIndex = 0;
    if (fields.length > 1) {
      final firstRow = fields[0].join().toLowerCase();
      if (firstRow.contains("team") || firstRow.contains("name")) {
        LoggerService.instance.debug('CSV', 'Skipping header row');
        startIndex = 1;
      }
    }

    // Loop through rows
    for (var i = startIndex; i < fields.length; i++) {
      final row = fields[i];
      if (row.length < 2) {
        LoggerService.instance.warning('CSV', 'Skipping invalid row $i: $row');
        continue;
      }

      String teamName = row[0].toString().trim();
      String memberName = row[1].toString().trim();

      await _syncMemberToDb(teamName, memberName);
    }
    
    // Notify the dashboard and other listeners that data has changed
    DashboardNotifier.instance.notifyDashboardUpdate();
    LoggerService.instance.info('CSV', 'CSV Import completed successfully.');
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
      LoggerService.instance.info('CSV', 'Created new team: $teamName (ID: $teamId)');
    } else {
      teamId = teamResult.first['id'] as int;
    }

    // 2. Insert the Member linked to that Team ID
    int memberId = await db.insert('members', {'team_id': teamId, 'name': memberName});
    LoggerService.instance.info('CSV', 'Inserted member: $memberName (ID: $memberId) into Team ID: $teamId');
  }
}
