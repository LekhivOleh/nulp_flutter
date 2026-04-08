import 'dart:convert';

import 'package:my_project/data/local/key_value_storage.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/repositories/log_repository.dart';

class LocalLogRepository implements LogRepository {
  LocalLogRepository(this._storage);

  final KeyValueStorage _storage;

  static const String _logsKey = 'access_logs';

  @override
  Future<List<AccessLog>> getLogs() async {
    final raw = await _storage.readString(key: _logsKey);
    if (raw == null || raw.isEmpty) {
      return <AccessLog>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => AccessLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveLogs({required List<AccessLog> logs}) async {
    final payload = jsonEncode(logs.map((e) => e.toJson()).toList());
    await _storage.writeString(key: _logsKey, value: payload);
  }
}
