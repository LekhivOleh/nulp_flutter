import 'package:flutter/material.dart';
import 'package:my_project/app_dependencies.dart';
import 'package:my_project/pages/login_page.dart';
import 'package:my_project/widgets/register_form.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      await AppDependencies.instance.authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Registration successful. Please log in.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, LoginPage.routeName);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Page')),
      body: SafeArea(
        child: Center(
          child: RegisterForm(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            confirmPasswordController: _confirmPasswordController,
            isLoading: _isLoading,
            onSubmit: _submit,
            onGoToLogin: () => Navigator.pushReplacementNamed(
              context,
              LoginPage.routeName,
            ),
          ),
        ),
      ),
    );
  }
}
