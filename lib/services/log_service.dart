import 'package:my_project/models/access_log.dart';
import 'package:my_project/repositories/log_repository.dart';

class LogService {
  LogService(this._logRepository);

  final LogRepository _logRepository;

  Future<List<AccessLog>> getLogs() async {
    final logs = await _logRepository.getLogs();
    return logs;
  }

  Future<void> saveLogs(List<AccessLog> logs) {
    return _logRepository.saveLogs(logs: logs);
  }

  Future<void> addLog({
      required AccessLog log,
      required String userId
    }) async {
    final logs = await _logRepository.getLogs();
    final updated = <AccessLog>[...logs, log];
    await _logRepository.saveLogs(logs: updated);
  }

  Future<void> deleteLog({required int index}) async {
    final logs = await _logRepository.getLogs();
    if (index < 0 || index >= logs.length) {
      return;
    }

    final updated = <AccessLog>[...logs]..removeAt(index);
    await _logRepository.saveLogs(logs: updated);
  }
}
