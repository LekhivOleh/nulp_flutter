class InputValidators {
  const InputValidators._();

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Name is required';
    }

    final containsDigit = RegExp(r'\d').hasMatch(name);
    if (containsDigit) {
      return 'Name must not contain digits';
    }

    if (name.length < 2) {
      return 'Name is too short';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 6) {
      return 'Minimum 6 characters';
    }

    return null;
  }

  static String? validateConfirmPassword({
    required String? value,
    required String original,
  }) {
    final confirm = value ?? '';
    if (confirm.isEmpty) {
      return 'Confirm password is required';
    }

    if (confirm != original) {
      return 'Passwords do not match';
    }

    return null;
  }
}
