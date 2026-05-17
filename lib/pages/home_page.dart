import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_project/app_dependencies.dart';
import 'package:my_project/cubits/auth_cubit.dart';
import 'package:my_project/pages/login_page.dart';
import 'package:my_project/pages/profile_page.dart';
import 'package:my_project/widgets/connectivity_banner.dart';
import 'package:my_project/widgets/home_log_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  Future<void> _confirmLogout(BuildContext context) async {
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
    if (confirmed && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginPage.routeName,
            (_) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
          actions: [
            IconButton(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(
                context,
                ProfilePage.routeName,
              ),
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
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final email = state is AuthAuthenticated
                      ? state.user.email
                      : '';
                  return Text('Logged in as: $email');
                },
              ),
              const SizedBox(height: 12),
              const Expanded(child: HomeLogList()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
