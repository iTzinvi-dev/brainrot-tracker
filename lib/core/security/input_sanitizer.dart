/// Input sanitization and validation utilities for Brainrot Tracker Pro.
/// Enforces RFC 5322 email validation, 5-point password complexity checks,
/// and HTML/XSS tag stripping for secure input handling.
class InputSanitizer {
  InputSanitizer._();

  /// RFC 5322 compliant email validation regex pattern.
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static final RegExp _uppercaseRegExp = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegExp = RegExp(r'[a-z]');
  static final RegExp _digitRegExp = RegExp(r'[0-9]');
  static final RegExp _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;`~]');
  static final RegExp _scriptTagRegExp = RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false);
  static final RegExp _htmlTagRegExp = RegExp(r'<[^>]*>');

  /// Validates an email address against the RFC 5322 standard.
  static bool isValidEmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.length > 254) return false;
    return _emailRegExp.hasMatch(trimmed);
  }

  /// Checks if password satisfies minimum length (default 8).
  static bool hasMinLength(String password, [int min = 8]) => password.length >= min;

  /// Checks if password contains at least one uppercase letter.
  static bool hasUppercase(String password) => _uppercaseRegExp.hasMatch(password);

  /// Checks if password contains at least one lowercase letter.
  static bool hasLowercase(String password) => _lowercaseRegExp.hasMatch(password);

  /// Checks if password contains at least one digit.
  static bool hasDigit(String password) => _digitRegExp.hasMatch(password);

  /// Checks if password contains at least one special character.
  static bool hasSpecialChar(String password) => _specialCharRegExp.hasMatch(password);

  /// Computes the 5-point password complexity score (0 to 5).
  static int getPasswordStrengthScore(String? password) {
    if (password == null || password.isEmpty) return 0;
    int score = 0;
    if (hasMinLength(password, 8)) score++;
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasDigit(password)) score++;
    if (hasSpecialChar(password)) score++;
    return score;
  }

  /// 5-point password complexity validation:
  /// 1. >= 8 characters
  /// 2. >= 1 uppercase letter
  /// 3. >= 1 lowercase letter
  /// 4. >= 1 digit
  /// 5. >= 1 special character
  static bool isStrongPassword(String? password) {
    if (password == null) return false;
    return getPasswordStrengthScore(password) == 5;
  }

  /// Strips HTML tags and script elements to prevent XSS.
  static String stripHtml(String? input) {
    if (input == null) return '';
    // First remove scripts and content
    String cleaned = input.replaceAll(_scriptTagRegExp, '');
    // Then remove remaining HTML tags
    cleaned = cleaned.replaceAll(_htmlTagRegExp, '');
    return cleaned.trim();
  }

  /// Sanitizes generic text input by stripping HTML tags and trimming.
  static String sanitizeText(String? input) {
    if (input == null) return '';
    return stripHtml(input);
  }
}
