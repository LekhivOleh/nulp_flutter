import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/services/ws_log_sync_service.dart';

part 'log_state.dart';

class LogCubit extends Cubit<LogState> {
  LogCubit(this._wsService) : super(LogInitial()) {
    _subscription = _wsService.logsStream.listen(_onLogs);
    final current = _wsService.currentLogs;
    if (current.isNotEmpty) _onLogs(current);
  }

  final WsLogSyncService _wsService;
  StreamSubscription<List<AccessLog>>? _subscription;
  final _deletedUids = <String>{};

  void _onLogs(List<AccessLog> logs) {
    if (isClosed) return;
    final visible = logs
        .where((l) => !_deletedUids.contains(l.uid))
        .toList();
    emit(LogLoaded(visible));
  }

  void deleteLog(String uid) {
    _deletedUids.add(uid);
    if (state is LogLoaded) {
      final updated = (state as LogLoaded)
          .logs
          .where((l) => l.uid != uid)
          .toList();
      if (!isClosed) emit(LogLoaded(updated));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
