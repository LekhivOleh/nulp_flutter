import 'package:flutter/material.dart';
import 'package:my_project/app_dependencies.dart';
import 'package:my_project/pages/login_page.dart';
import 'package:my_project/pages/profile_page.dart';
import 'package:my_project/widgets/connectivity_banner.dart';
import 'package:my_project/widgets/home_log_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _wsService = AppDependencies.instance.wsLogSyncService;
  final _authService = AppDependencies.instance.authService;
  final _deletedUids = <String>{};
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() => _userEmail = user?.email ?? 'unknown');
  }

  Future<void> _deleteLog(String uid) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete log'),
            content: const Text('Are you sure you want to delete this item?'),
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

    if (!confirmed || !mounted) return;
    setState(() => _deletedUids.add(uid));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
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
            ConnectivityBanner(
              service: AppDependencies.instance.connectivityService,
            ),
            const SizedBox(height: 12),
            Text('Logged in as: $_userEmail'),
            const SizedBox(height: 12),
            Expanded(
              child: HomeLogList(
                service: _wsService,
                deletedUids: _deletedUids,
                onDelete: _deleteLog,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
