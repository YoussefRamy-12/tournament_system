import 'package:admin_app/database/db_helper.dart';

class LoggerService {
  static final LoggerService instance = LoggerService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  LoggerService._internal();

  Future<void> debug(String category, String message, {String? details}) async {
    await _log('DEBUG', category, message, details: details);
  }

  Future<void> info(String category, String message, {String? details}) async {
    await _log('INFO', category, message, details: details);
  }

  Future<void> warning(String category, String message, {String? details}) async {
    await _log('WARNING', category, message, details: details);
  }

  Future<void> error(String category, String message, {String? details}) async {
    await _log('ERROR', category, message, details: details);
  }

  Future<void> success(String category, String message, {String? details}) async {
    await _log('SUCCESS', category, message, details: details);
  }

  Future<void> _log(String level, String category, String message, {String? details}) async {
    try {
      // ignore: avoid_print
      print('[$level] [$category] $message');
      await _dbHelper.insertLog(
        level: level,
        category: category,
        message: message,
        details: details,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Failed to write log: $e');
    }
  }
}
