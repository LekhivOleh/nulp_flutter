import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_project/app_dependencies.dart';
import 'package:my_project/pages/home_page.dart';
import 'package:my_project/pages/login_page.dart';
import 'package:my_project/pages/profile_page.dart';
import 'package:my_project/pages/register_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = AppDependencies.instance.authService.isLoggedIn();
    unawaited(AppDependencies.instance.wsLogSyncService.start());
  }

  @override
  void dispose() {
    unawaited(AppDependencies.instance.wsLogSyncService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Project',
      home: FutureBuilder<bool>(
        future: _isLoggedInFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isLoggedIn = snapshot.data ?? false;
          return isLoggedIn ? const HomePage() : const LoginPage();
        },
      ),
      routes: {
        HomePage.routeName: (context) => const HomePage(),
        LoginPage.routeName: (context) => const LoginPage(),
        ProfilePage.routeName: (context) => const ProfilePage(),
        RegisterPage.routeName: (context) => const RegisterPage(),
      },
    );
  }
}
