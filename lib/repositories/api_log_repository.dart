import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:my_project/data/local/key_value_storage.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/repositories/log_repository.dart';
import 'package:my_project/services/api_endpoints.dart';
import 'package:my_project/services/secure_token_storage.dart';

class ApiLogRepository implements LogRepository {
  ApiLogRepository(
    this._tokenStorage,
    this._storage,
  );

  static String get baseUrl => ApiEndpoints.apiBaseUrl;
  final SecureTokenStorage _tokenStorage;
  final KeyValueStorage _storage;

  static const String _cachedLogsKey = 'cached_logs';

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<AccessLog>> _readCachedLogs() async {
    final raw = await _storage.readString(key: _cachedLogsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AccessLog.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _writeCachedLogs(List<AccessLog> logs) async {
    final logsJson =
        jsonEncode(logs.map((e) => e.toJson()).toList());
    await _storage.writeString(key: _cachedLogsKey, value: logsJson);
  }

  @override
  Future<List<AccessLog>> getLogs() async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        return _readCachedLogs();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/logs'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final logs = (jsonDecode(response.body) as List)
            .map((item) => AccessLog.fromJson(item as Map<String, dynamic>))
            .toList();
        await _writeCachedLogs(logs);
        return logs;
      }
    } catch (_) {
      return _readCachedLogs();
    }

    return _readCachedLogs();
  }

  @override
  Future<void> saveLogs({required List<AccessLog> logs}) async {
    await _writeCachedLogs(logs);
  }
}
