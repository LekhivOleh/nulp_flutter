import 'package:flutter/material.dart';
import 'package:my_project/services/validators/input_validators.dart';

class RegisterForm extends StatelessWidget {
  const RegisterForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoToLogin,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: InputValidators.validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: InputValidators.validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: InputValidators.validatePassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                  validator: (value) =>
                      InputValidators.validateConfirmPassword(
                        value: value,
                        original: passwordController.text,
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onGoToLogin,
          child: const Text(
            'Already have an account?\n Go to Login',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
