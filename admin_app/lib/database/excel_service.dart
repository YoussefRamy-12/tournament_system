import 'dart:io';
import 'package:excel/excel.dart';
import '../database/db_helper.dart';
import '../services/logger_service.dart';

class ExcelExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<bool> exportTournamentData(String filePath) async {
    try {
      final db = await _dbHelper.database;
      final excel = Excel.createExcel();

      // 1. Teams & Members Sheet (Matches CSV import format)
      final membersSheetName = 'Teams & Members';
      final membersSheet = excel[membersSheetName];
      excel.setDefaultSheet(membersSheetName);
      if (excel.sheets.containsKey('Sheet1') && 'Sheet1' != membersSheetName) {
        excel.delete('Sheet1');
      }

      // Header styling
      final headerCellStyle = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Calibri),
      );

      membersSheet.appendRow([
        TextCellValue('Team Name'),
        TextCellValue('Member Name'),
      ]);
      _applyHeaderStyle(membersSheet, 0, 2, headerCellStyle);

      final membersData = await db.rawQuery('''
        SELECT teams.name AS team_name, members.name AS member_name
        FROM members
        JOIN teams ON members.team_id = teams.id
        ORDER BY teams.name ASC, members.name ASC
      ''');

      for (var row in membersData) {
        membersSheet.appendRow([
          TextCellValue(row['team_name']?.toString() ?? ''),
          TextCellValue(row['member_name']?.toString() ?? ''),
        ]);
      }

      // If there are teams without members, include them too
      final emptyTeams = await db.rawQuery('''
        SELECT name FROM teams 
        WHERE id NOT IN (SELECT DISTINCT team_id FROM members WHERE team_id IS NOT NULL)
      ''');
      for (var row in emptyTeams) {
        membersSheet.appendRow([
          TextCellValue(row['name']?.toString() ?? ''),
          TextCellValue(''),
        ]);
      }

      // 2. Team Standings Sheet
      final standingsSheet = excel['Team Standings'];
      standingsSheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Team Name'),
        TextCellValue('Total Points'),
      ]);
      _applyHeaderStyle(standingsSheet, 0, 3, headerCellStyle);

      final teamStats = await _dbHelper.getTeamStats();
      for (int i = 0; i < teamStats.length; i++) {
        final stat = teamStats[i];
        standingsSheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(stat['team_name']?.toString() ?? ''),
          IntCellValue((stat['total_points'] as num?)?.toInt() ?? 0),
        ]);
      }

      // 3. Player Rankings Sheet
      final playerSheet = excel['Player Rankings'];
      playerSheet.appendRow([
        TextCellValue('Rank'),
        TextCellValue('Player Name'),
        TextCellValue('Team Name'),
        TextCellValue('Total Points'),
      ]);
      _applyHeaderStyle(playerSheet, 0, 4, headerCellStyle);

      final playersWithScores = await _dbHelper.getAllPlayersWithScores();
      for (int i = 0; i < playersWithScores.length; i++) {
        final player = playersWithScores[i];
        playerSheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(player['name']?.toString() ?? ''),
          TextCellValue(player['teamName']?.toString() ?? ''),
          IntCellValue((player['totalScore'] as num?)?.toInt() ?? 0),
        ]);
      }

      // 4. Transactions Sheet
      final txSheet = excel['Transactions'];
      txSheet.appendRow([
        TextCellValue('Transaction ID'),
        TextCellValue('Timestamp'),
        TextCellValue('Leader'),
        TextCellValue('Target'),
        TextCellValue('Target Type'),
        TextCellValue('Points'),
        TextCellValue('Category / Tag'),
        TextCellValue('Description'),
        TextCellValue('Status'),
      ]);
      _applyHeaderStyle(txSheet, 0, 9, headerCellStyle);

      final transactions = await _dbHelper.getAllTransactions();
      for (var tx in transactions) {
        txSheet.appendRow([
          TextCellValue(tx['id']?.toString() ?? ''),
          TextCellValue(tx['timestamp']?.toString() ?? ''),
          TextCellValue(tx['leaderName']?.toString() ?? tx['leader_id']?.toString() ?? ''),
          TextCellValue(tx['targetName']?.toString() ?? ''),
          TextCellValue(tx['target_type']?.toString() ?? 'MEMBER'),
          IntCellValue((tx['points'] as num?)?.toInt() ?? 0),
          TextCellValue(tx['tag']?.toString() ?? ''),
          TextCellValue(tx['description']?.toString() ?? ''),
          TextCellValue(tx['status']?.toString() ?? ''),
        ]);
      }

      // 5. Leaders Sheet
      final leadersSheet = excel['Leaders'];
      leadersSheet.appendRow([
        TextCellValue('Leader ID'),
        TextCellValue('Name'),
        TextCellValue('Status'),
        TextCellValue('Device Info'),
      ]);
      _applyHeaderStyle(leadersSheet, 0, 4, headerCellStyle);

      final leaders = await _dbHelper.getAllLeaders();
      for (var leader in leaders) {
        leadersSheet.appendRow([
          TextCellValue(leader['id']?.toString() ?? ''),
          TextCellValue(leader['name']?.toString() ?? ''),
          TextCellValue(leader['status']?.toString() ?? ''),
          TextCellValue(leader['device_info']?.toString() ?? ''),
        ]);
      }

      // Encode and Save file
      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);
        LoggerService.instance.info('EXCEL', 'Tournament data successfully exported to $filePath');
        return true;
      }
      return false;
    } catch (e, stack) {
      LoggerService.instance.error('EXCEL', 'Failed to export Excel: $e', details: stack.toString());
      rethrow;
    }
  }

  void _applyHeaderStyle(Sheet sheet, int rowIndex, int colCount, CellStyle style) {
    for (int col = 0; col < colCount; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
      cell.cellStyle = style;
    }
  }
}
