class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    // Minimum 8 characters, at least one letter, one number, and optionally special characters
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!*@#\$%^&+=]{8,}$');
    return regex.hasMatch(password);
  }
}