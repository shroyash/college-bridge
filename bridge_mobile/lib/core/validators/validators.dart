abstract class Validators {
  static const int minNameLength = 3;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minNameLength) {
      return 'Full Name must be at least $minNameLength characters';
    }
    if (trimmed.length > maxNameLength) {
      return 'Full Name cannot exceed $maxNameLength characters';
    }
    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'Full Name cannot contain numbers';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    // RFC-compliant email regex
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid RFC-compliant email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    if (value.length > maxPasswordLength) {
      return 'Password cannot exceed $maxPasswordLength characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? validateConfirmPassword(String? confirmValue, String passwordValue) {
    if (confirmValue == null || confirmValue.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmValue != passwordValue) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateFaculty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a faculty';
    }
    return null;
  }

  static String? validateSemester(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a semester';
    }
    return null;
  }
}
