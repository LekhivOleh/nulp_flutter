import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:my_project/models/access_log.dart';
import 'package:my_project/services/api_endpoints.dart';

class WsLogSyncService {
  final _controller = StreamController<List<AccessLog>>.broadcast();
  final _logs = <AccessLog>[];
  final _seenUids = <String>{};

  WebSocket? _ws;
  Timer? _reconnectTimer;
  bool _started = false;

  Stream<List<AccessLog>> get logsStream => _controller.stream;
  List<AccessLog> get currentLogs => List.unmodifiable(_logs);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _connect();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_started && _ws == null) unawaited(_connect());
    });
  }

  Future<void> dispose() async {
    _started = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final ws = _ws;
    _ws = null;
    await ws?.close();
    await _controller.close();
  }

  Future<void> _connect() async {
    if (!_started) return;
    try {
      final ws = await WebSocket.connect(ApiEndpoints.wsLogsUrl);
      if (!_started) {
        await ws.close();
        return;
      }
      _ws = ws;
      ws.listen(
        _handleMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (_) {
      _ws = null;
    }
  }

  void _onDisconnected() {
    _ws = null;
  }

  void _handleMessage(dynamic data) {
    if (data is! String) return;
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = msg['type'] as String?;

    if (type == 'history') {
      final rawList = msg['logs'] as List?;
      if (rawList == null) return;
      _logs.clear();
      _seenUids.clear();
      for (final item in rawList) {
        final log = AccessLog.fromJson(item as Map<String, dynamic>);
        if (_seenUids.add(log.uid)) {
          _logs.add(log);
        }
      }
      if (!_controller.isClosed) _controller.add(List.unmodifiable(_logs));
    } else if (type == 'new') {
      final rawLog = msg['log'] as Map<String, dynamic>?;
      if (rawLog == null) return;
      final log = AccessLog.fromJson(rawLog);
      if (_seenUids.add(log.uid)) {
        _logs.add(log);
        if (!_controller.isClosed) _controller.add(List.unmodifiable(_logs));
      }
    }
  }
}
