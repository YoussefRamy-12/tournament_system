import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/db_helper.dart';

class ApiRouter {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Router get router {
    final router = Router();

    // 1. GET all teams
    router.get('/teams', (Request request) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> teams = await db.query('teams');
      return Response.ok(
        jsonEncode(teams),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 2. GET members by team ID
    router.get('/members/<teamId>', (Request request, String teamId) async {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> members = await db.query(
        'members',
        where: 'team_id = ?',
        whereArgs: [int.parse(teamId)],
      );
      return Response.ok(
        jsonEncode(members),
        headers: {'Content-Type': 'application/json'},
      );
    });

    router.post('/submit-score', (Request request) async {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final db = await _dbHelper.database;

      await db.insert('transactions', {
        'id': data['id'],
        'leader_id':
            data['leaderId'], // Matches the 'leaderId' in Model.toJson()
        'target_id': data['targetId'],
        'points': data['points'],
        'tag': data['tag'],
        'status': 'PENDING',
        'timestamp': data['timestamp'],
      });

      // print(
      //   '📥 Received Score for Member ID: ${data['targetId']} the leader ID: ${data['leaderId']}',
      // );
      return Response.ok(jsonEncode({'status': 'success'}));
    });

    router.get('/history/<leaderId>', (Request request, String leaderId) async {
      final db = await _dbHelper.database;

      final List<Map<String, dynamic>> history = await db.rawQuery(
        '''
    SELECT transactions.*, members.name as memberName 
    FROM transactions 
    JOIN members ON transactions.target_id = members.id
    WHERE transactions.leader_id = ?
    ORDER BY timestamp DESC
  ''',
        [leaderId],
      );

      return Response.ok(jsonEncode(history));
    });

    // 1. Receive Registration
    router.post('/register-leader', (Request request) async {
      final data = jsonDecode(await request.readAsString());
      final db = await _dbHelper.database;

      // Check if leader already exists
      final existing = await db.query(
        'leaders',
        where: 'id = ?',
        whereArgs: [data['id']],
      );

      if (existing.isNotEmpty) {
        // If they exist, RESET their status to PENDING so the admin sees them again
        await db.update(
          'leaders',
          {
            'name': data['name'],
            'status': 'PENDING',
            'device_info': data['deviceInfo'],
          },
          where: 'id = ?',
          whereArgs: [data['id']],
        );
      } else {
        // New registration
        await db.insert('leaders', {
          'id': data['id'],
          'name': data['name'],
          'status': 'PENDING',
          'device_info': data['deviceInfo'],
        });
      }

      return Response.ok('Registered');
    });

    // 2. Check Approval Status (Used by phone to see if they can start scoring)
    // Ensure there is a <leaderId> parameter defined in the path
    router.get('/check-approval/<leaderId>', (
      Request request,
      String leaderId,
    ) async {
      try {
        final db = await _dbHelper.database;
        final List<Map<String, dynamic>> result = await db.query(
          'leaders',
          where: 'id = ?',
          whereArgs: [leaderId],
        );

        if (result.isNotEmpty) {
          final String status = result.first['status'];
          return Response.ok(
            jsonEncode({'status': status}),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          // If the ID isn't found at all, we return PENDING so the app keeps waiting
          return Response.ok(
            jsonEncode({'status': 'NOT_FOUND'}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } catch (e) {
        // print("Server Error in check-approval: $e");
        return Response.internalServerError();
      }
    });

    router.get('/ping', (Request request) {
      return Response.ok('pong');
    });

    return router;
  }
}
