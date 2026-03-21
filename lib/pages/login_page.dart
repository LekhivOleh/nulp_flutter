import 'package:flutter/material.dart';
import 'package:my_project/pages/home_page.dart';
import 'package:my_project/pages/register_page.dart';

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
    if (_formKey.currentState?.validate() ?? false) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Login form is valid'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invalid'),
          content: const Text('Check inputs'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Email is required';
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(email)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration:
                          const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) return 'Password is required';
                          if (password.length < 6) {
                            return 'Minimum 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                  Navigator.pushReplacementNamed(
                    context,
                    RegisterPage.routeName
                  ),
                child: const Text(
                  'No account yet?\nGo to Register',
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () =>
                  Navigator.pushReplacementNamed(
                    context,
                    HomePage.routeName
                  ),
                child:
                const Text(
                  'Continue to Home\n(only for demo, later only if logged in)',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
