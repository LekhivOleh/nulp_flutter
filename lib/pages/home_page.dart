import 'package:flutter/material.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/pages/profile_page.dart';
import 'package:my_project/widgets/log_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  static final List<AccessLog> _logs = [
    AccessLog(
      uid: '1',
      name: 'Alice',
      direction: 'In',
      timestamp: DateTime(2026, 3, 21, 8, 10),
    ),
    AccessLog(
      uid: '2',
      name: 'Chains',
      direction: 'Out',
      timestamp: DateTime(2026, 3, 21, 8, 18),
    ),
    AccessLog(
      uid: '3',
      name: 'Charlie',
      direction: 'In',
      timestamp: DateTime(2026, 3, 21, 8, 27),
    ),
    AccessLog(
      uid: '4',
      name: 'Donald',
      direction: 'Out',
      timestamp: DateTime(2026, 3, 21, 8, 35),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () =>
              Navigator.pushNamed(context, ProfilePage.routeName),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text('Logs:'),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return LogCard(log: _logs[index]);
                      },
                    ),
                  ),
                ),
              )
            ),
            const SizedBox(height: 12),
          ],
        ),
      )
    );
  }
}
