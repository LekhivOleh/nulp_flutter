import 'package:flutter/material.dart';
import 'package:my_project/pages/home_page.dart';
import 'package:my_project/pages/login_page.dart';
import 'package:my_project/pages/profile_page.dart';
import 'package:my_project/pages/register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const bool isRegistered = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Project',
      initialRoute: isRegistered ? HomePage.routeName : LoginPage.routeName,
      routes: {
        HomePage.routeName: (context) => const HomePage(),
        LoginPage.routeName: (context) => const LoginPage(),
        ProfilePage.routeName: (context) => const ProfilePage(),
        RegisterPage.routeName: (context) => const RegisterPage(),
      },
    );
  }
}
