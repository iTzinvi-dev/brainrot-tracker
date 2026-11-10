import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/core/security/input_sanitizer.dart';

void main() {
  group('InputSanitizer Security Tests', () {
    group('Email Validation (RFC 5322)', () {
      test('accepts valid email addresses', () {
        expect(InputSanitizer.isValidEmail('user@brainrot.app'), isTrue);
        expect(InputSanitizer.isValidEmail('operative.007@cyber.agency.io'), isTrue);
        expect(InputSanitizer.isValidEmail('user+filter@subdomain.example.com'), isTrue);
        expect(InputSanitizer.isValidEmail('test_dev-123@domain.org'), isTrue);
      });

      test('rejects invalid email addresses', () {
        expect(InputSanitizer.isValidEmail(null), isFalse);
        expect(InputSanitizer.isValidEmail(''), isFalse);
        expect(InputSanitizer.isValidEmail('   '), isFalse);
        expect(InputSanitizer.isValidEmail('plainaddress'), isFalse);
        expect(InputSanitizer.isValidEmail('@missingusername.com'), isFalse);
        expect(InputSanitizer.isValidEmail('username@.com'), isFalse);
        expect(InputSanitizer.isValidEmail('username@domain'), isFalse);
        expect(InputSanitizer.isValidEmail('user name@domain.com'), isFalse);
        expect(InputSanitizer.isValidEmail('user@domain..com'), isFalse);
      });
    });

    group('5-Point Password Complexity Verification', () {
      test('accepts passwords satisfying all 5 criteria', () {
        expect(InputSanitizer.isStrongPassword('P@ssword123!'), isTrue);
        expect(InputSanitizer.isStrongPassword('Cyber#Operative2026'), isTrue);
        expect(InputSanitizer.isStrongPassword('Str0ng_P@ss!'), isTrue);
        expect(InputSanitizer.getPasswordStrengthScore('P@ssword123!'), 5);
      });

      test('rejects passwords failing individual criteria', () {
        // Less than 8 characters (score 4)
        expect(InputSanitizer.isStrongPassword('P@1a!'), isFalse);
        expect(InputSanitizer.hasMinLength('P@1a!'), isFalse);

        // Missing uppercase letter
        expect(InputSanitizer.isStrongPassword('p@ssword123!'), isFalse);
        expect(InputSanitizer.hasUppercase('p@ssword123!'), isFalse);

        // Missing lowercase letter
        expect(InputSanitizer.isStrongPassword('P@SSWORD123!'), isFalse);
        expect(InputSanitizer.hasLowercase('P@SSWORD123!'), isFalse);

        // Missing numeric digit
        expect(InputSanitizer.isStrongPassword('P@ssword!'), isFalse);
        expect(InputSanitizer.hasDigit('P@ssword!'), isFalse);

        // Missing special character
        expect(InputSanitizer.isStrongPassword('Password123'), isFalse);
        expect(InputSanitizer.hasSpecialChar('Password123'), isFalse);
      });

      test('handles null or empty passwords safely', () {
        expect(InputSanitizer.isStrongPassword(null), isFalse);
        expect(InputSanitizer.isStrongPassword(''), isFalse);
        expect(InputSanitizer.getPasswordStrengthScore(null), 0);
        expect(InputSanitizer.getPasswordStrengthScore(''), 0);
      });
    });

    group('HTML and XSS Sanitization', () {
      test('strips script tags and executable contents', () {
        const malicious = "Hello <script>alert('xss');</script>Operative";
        expect(InputSanitizer.stripHtml(malicious), 'Hello Operative');
      });

      test('strips general HTML tags and elements', () {
        const input = "<h1>Alert</h1><p>Doomscroll detected: <b class='red'>Level 7</b></p>";
        expect(InputSanitizer.stripHtml(input), 'AlertDoomscroll detected: Level 7');
      });

      test('sanitizeText trims whitespace and eliminates tags', () {
        const dirty = "   <div><script src='evil.js'></script>  Clean Text  </div>  ";
        expect(InputSanitizer.sanitizeText(dirty), 'Clean Text');
      });

      test('handles null safely', () {
        expect(InputSanitizer.stripHtml(null), '');
        expect(InputSanitizer.sanitizeText(null), '');
      });
    });
  });
}
