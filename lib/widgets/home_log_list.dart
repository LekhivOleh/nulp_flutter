import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_project/cubits/log_cubit.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/widgets/log_card.dart';

class HomeLogList extends StatelessWidget {
  const HomeLogList({super.key});

  Future<bool> _confirmDelete(
    BuildContext context,
    String uid,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete log'),
            content: const Text(
              'Are you sure you want to delete this item?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      context.read<LogCubit>().deleteLog(uid);
    }
    return confirmed;
  }

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
          child: BlocBuilder<LogCubit, LogState>(
            builder: (context, state) {
              final logs =
                  state is LogLoaded ? state.logs : <AccessLog>[];
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    confirmDismiss: (_) =>
                        _confirmDelete(context, log.uid),
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
