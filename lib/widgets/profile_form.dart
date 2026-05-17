import 'package:flutter/material.dart';
import 'package:my_project/services/validators/input_validators.dart';

class ProfileForm extends StatelessWidget {
  const ProfileForm({
    required this.nameController,
    required this.emailController,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            child: Icon(Icons.person, size: 34),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              child: const Text('Save changes'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onDelete,
              child: const Text('Delete account'),
            ),
          ),
        ],
      ),
    );
  }
}
