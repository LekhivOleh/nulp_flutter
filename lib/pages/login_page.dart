import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_project/app_dependencies.dart';
import 'package:my_project/cubits/auth_cubit.dart';
import 'package:my_project/pages/home_page.dart';
import 'package:my_project/pages/register_page.dart';
import 'package:my_project/widgets/login_form.dart';
import 'package:my_project/widgets/offline_banner.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthCubit>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Login successful'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          ).then((_) {
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                HomePage.routeName,
              );
            }
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Login Page')),
          body: SafeArea(
            child: Column(
              children: [
                OfflineBanner(
                  service:
                      AppDependencies.instance.connectivityService,
                ),
                Expanded(
                  child: Center(
                    child: LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      isLoading: state is AuthLoading,
                      onSubmit: _submit,
                      onGoToRegister: () =>
                          Navigator.pushReplacementNamed(
                        context,
                        RegisterPage.routeName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
