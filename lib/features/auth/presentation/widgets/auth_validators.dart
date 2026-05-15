class AuthValidators {
  const AuthValidators._();

  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Email is required.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedValue)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? lnuEmail(String? value) {
    final emailError = email(value);
    if (emailError != null) {
      return emailError;
    }

    if (!value!.trim().toLowerCase().endsWith('@lnu.edu.ph')) {
      return 'Use your LNU email ending in @lnu.edu.ph.';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? username(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return 'Username is required.';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(trimmedValue)) {
      return 'Use 3-24 letters, numbers, or underscores.';
    }
    return null;
  }
}
