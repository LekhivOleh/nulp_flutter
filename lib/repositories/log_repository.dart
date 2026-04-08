import 'package:my_project/models/access_log.dart';

abstract class LogRepository {
  Future<List<AccessLog>> getLogs();

  Future<void> saveLogs({required List<AccessLog> logs});
}
