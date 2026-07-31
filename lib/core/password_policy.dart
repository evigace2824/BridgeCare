/// Single source of truth for password rules (signup UI + [AuthService]).
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static bool hasMinLength(String s) => s.length >= minLength;

  static bool hasUppercase(String s) => RegExp(r'[A-Z]').hasMatch(s);

  static bool hasDigit(String s) => RegExp(r'\d').hasMatch(s);

  /// Non-alphanumeric (symbol / punctuation), excluding whitespace.
  static bool hasSymbol(String s) => RegExp(r'[^a-zA-Z0-9\s]').hasMatch(s);

  /// `null` if valid; otherwise a short message for form validators.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!hasMinLength(value)) {
      return 'Use at least $minLength characters';
    }
    if (!hasUppercase(value)) {
      return 'Add at least one uppercase letter (A–Z)';
    }
    if (!hasDigit(value)) {
      return 'Add at least one number (0–9)';
    }
    if (!hasSymbol(value)) {
      return 'Add at least one symbol (e.g. ! @ # \$ %)';
    }
    return null;
  }

  static bool isValid(String s) => validate(s) == null;
}
