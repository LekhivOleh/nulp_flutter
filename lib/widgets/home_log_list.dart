import 'package:flutter/material.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/services/ws_log_sync_service.dart';
import 'package:my_project/widgets/log_card.dart';

class HomeLogList extends StatelessWidget {
  const HomeLogList({
    required this.service,
    required this.deletedUids,
    required this.onDelete,
    super.key,
  });

  final WsLogSyncService service;
  final Set<String> deletedUids;
  final Future<void> Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.94,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: StreamBuilder<List<AccessLog>>(
            stream: service.logsStream,
            initialData: service.currentLogs,
            builder: (context, snapshot) {
              final logs = (snapshot.data ?? [])
                  .where((l) => !deletedUids.contains(l.uid))
                  .toList();

              if (logs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No access logs yet.'),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Dismissible(
                    key: ValueKey(log.uid),
                    direction: DismissDirection.endToStart,
                    background: const ColoredBox(
                      color: Colors.redAccent,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                    ),
                    confirmDismiss: (_) async {
                      await onDelete(log.uid);
                      return false;
                    },
                    child: LogCard(log: log),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
