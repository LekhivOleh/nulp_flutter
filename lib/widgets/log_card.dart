import 'package:flutter/material.dart';
import 'package:my_project/models/access_log.dart';

class LogCard extends StatelessWidget {
  final AccessLog log;
  const LogCard({required this.log, super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${log.name.isNotEmpty ? log.name : 'Unknown'}'
          ' | ${log.direction}'
          ' | ${log.timestamp.toLocal()}',
        ),
        const SizedBox(height: 5),
        const Divider(height: 1, thickness: 1),
      ],
    ),
  );
}
