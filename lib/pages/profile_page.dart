import 'package:flutter/material.dart';
import 'package:my_project/models/access_log.dart';
import 'package:my_project/widgets/log_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const String routeName = '/profile';

  static const String _userName = 'Alex User';
  static const String _role = 'Employee';

  // By user id
  static final List<AccessLog> _recentActivity = [
    AccessLog(
      uid: '4',
      name: 'Alex User',
      direction: 'In',
      timestamp: DateTime(2026, 3, 24, 8, 35),
    ),
    AccessLog(
      uid: '41',
      name: 'Alex User',
      direction: 'Out',
      timestamp: DateTime(2026, 3, 25, 8, 35),
    ),
    AccessLog(
      uid: '423',
      name: 'Alex User',
      direction: 'In',
      timestamp: DateTime(2026, 3, 28, 8, 35),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      child: Icon(Icons.person, size: 34),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(_role),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _recentActivity.length,
                          itemBuilder: (context, index) {
                            return LogCard(log: _recentActivity[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
