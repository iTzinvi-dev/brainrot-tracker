/**
 * Adversarial Verification Suite for SafeLogger
 * Brainrot Tracker Pro - Milestone Hardening Iteration 2
 * Evaluates SafeLogger using ECMAScript RegExp (exact semantic match to Dart RegExp)
 */

const fs = require('fs');
const path = require('path');

const LOGGER_FILE = '/data/data/com.termux/files/home/brainrot-tracker-pro/lib/core/logging/safe_logger.dart';

class SafeLoggerSimulator {
  constructor(tag = 'BrainrotTracker', isReleaseMode = false) {
    this.tag = tag;
    this.isReleaseMode = isReleaseMode;
    this.logs = [];

    // Exact regexes from safe_logger.dart
    this.passwordRegex = /(password["\s:=]+)(["']?)([^"'\s,;&]+)\2/gi;
    this.tokenRegex = /((?:bearer|token|secret|apiKey|idToken|refreshToken)["\s:=]+)(["']?)([^"'\s,;&]+)\2/gi;
  }

  debugPrint(msg) {
    this.logs.push(msg);
  }

  redact(message) {
    let sanitized = message.replace(this.passwordRegex, (match, g1) => {
      return g1 + '[REDACTED]';
    });
    sanitized = sanitized.replace(this.tokenRegex, (match, g1) => {
      return g1 + '[REDACTED]';
    });
    return sanitized;
  }

  debug(message) {
    if (!this.isReleaseMode) {
      this.debugPrint(`[${this.tag}][DEBUG] ${this.redact(message)}`);
    }
  }

  info(message) {
    if (!this.isReleaseMode) {
      this.debugPrint(`[${this.tag}][INFO] ${this.redact(message)}`);
    }
  }

  warning(message, error = null, stackTrace = null) {
    this.debugPrint(`[${this.tag}][WARN] ${this.redact(message)}`);
    if (error !== null && error !== undefined) {
      this.debugPrint(`[${this.tag}][WARN ERROR] ${this.redact(String(error))}`);
    }
    if (stackTrace !== null && stackTrace !== undefined && !this.isReleaseMode) {
      this.debugPrint(`[${this.tag}][WARN STACK] ${stackTrace}`);
    }
  }

  error(message, error = null, stackTrace = null) {
    this.debugPrint(`[${this.tag}][ERROR] ${this.redact(message)}`);
    if (error !== null && error !== undefined) {
      this.debugPrint(`[${this.tag}][ERROR DETAILS] ${this.redact(String(error))}`);
    }
    if (stackTrace !== null && stackTrace !== undefined && !this.isReleaseMode) {
      this.debugPrint(`[${this.tag}][ERROR STACK] ${stackTrace}`);
    }
  }
}

function runTests() {
  console.log('='.repeat(60));
  console.log('RUNNING ADVERSARIAL SAFE_LOGGER TESTS');
  console.log('='.repeat(60));

  let passed = 0;
  let failed = 0;

  // 1. Read actual safe_logger.dart source and verify critical structures
  const src = fs.readFileSync(LOGGER_FILE, 'utf8');
  if (src.includes('redact(error.toString())') && src.includes('!kReleaseMode')) {
    passed++;
    console.log('  [PASS] Source code contains redact(error.toString()) and !kReleaseMode checks.');
  } else {
    failed++;
    console.log('  [FAIL] Source code missing error redaction or release mode guards!');
  }

  const loggerDebug = new SafeLoggerSimulator('BrainrotTracker', false);
  const loggerRelease = new SafeLoggerSimulator('BrainrotTracker', true);

  // 2. Test warning() and error() with sensitive exception objects / strings
  const adversarialExceptions = [
    {
      name: 'AuthException with cleartext password',
      msg: 'Login attempt failed',
      err: 'AuthException: Invalid credentials for password: SuperSecretPassword123!',
      secret: 'SuperSecretPassword123!',
    },
    {
      name: 'Network error with Bearer token header',
      msg: 'Failed to sync event log',
      err: 'DioError [401]: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_token_value',
      secret: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_token_value',
    },
    {
      name: 'FirebaseException with apiKey leak',
      msg: 'Remote Config fetch error',
      err: 'FirebaseException: Invalid request with apiKey: AIzaSyC_AdversarialSecretKey999',
      secret: 'AIzaSyC_AdversarialSecretKey999',
    },
    {
      name: 'Custom AuthError with idToken',
      msg: 'Token validation exception',
      err: { toString: () => 'CustomAuthError: idToken="secret_id_token_xyz888"' },
      secret: 'secret_id_token_xyz888',
    },
    {
      name: 'OAuth refresh failure with refreshToken',
      msg: 'Token refresh failed',
      err: 'OAuthException: refreshToken: 1//04adversarial_refresh_token_99999',
      secret: '1//04adversarial_refresh_token_99999',
    },
    {
      name: 'Database secret leak in error',
      msg: 'Database connection failed',
      err: 'SqliteError: encryption failed with secret: db_master_encryption_key_444',
      secret: 'db_master_encryption_key_444',
    },
  ];

  console.log('\n--- 2. Testing warning() and error() exception redaction ---');
  for (const tc of adversarialExceptions) {
    // Test in warning()
    loggerDebug.logs = [];
    loggerDebug.warning(tc.msg, tc.err);
    const warnOutput = loggerDebug.logs.join('\n');
    if (!warnOutput.includes(tc.secret) && warnOutput.includes('[REDACTED]')) {
      passed++;
      console.log(`  [PASS] warning() redacted secret in: ${tc.name}`);
    } else {
      failed++;
      console.log(`  [FAIL] warning() LEAKED SECRET in: ${tc.name}`);
      console.log(`    Log Output: ${warnOutput}`);
    }

    // Test in error()
    loggerDebug.logs = [];
    loggerDebug.error(tc.msg, tc.err);
    const errOutput = loggerDebug.logs.join('\n');
    if (!errOutput.includes(tc.secret) && errOutput.includes('[REDACTED]')) {
      passed++;
      console.log(`  [PASS] error() redacted secret in: ${tc.name}`);
    } else {
      failed++;
      console.log(`  [FAIL] error() LEAKED SECRET in: ${tc.name}`);
      console.log(`    Log Output: ${errOutput}`);
    }
  }

  // 3. Test sensitive strings embedded directly in message parameter
  console.log('\n--- 3. Testing message string redaction ---');
  const messageTestCases = [
    {
      input: 'Attempted login with password=ClearTextPassword999',
      secret: 'ClearTextPassword999',
    },
    {
      input: 'Session initialized with token: sec_tok_8888888',
      secret: 'sec_tok_8888888',
    },
    {
      input: 'Header Bearer abcdef123456789 sent to server',
      secret: 'abcdef123456789',
    },
  ];

  for (const tc of messageTestCases) {
    loggerDebug.logs = [];
    loggerDebug.warning(tc.input);
    const out = loggerDebug.logs.join('\n');
    if (!out.includes(tc.secret) && out.includes('[REDACTED]')) {
      passed++;
      console.log(`  [PASS] Redacted message secret: ${tc.secret}`);
    } else {
      failed++;
      console.log(`  [FAIL] Failed to redact message: ${tc.input}`);
    }
  }

  // 4. Test Release Mode Suppression
  console.log('\n--- 4. Testing Release Mode Privacy & StackTrace Suppression ---');
  loggerRelease.logs = [];
  loggerRelease.debug('This is a debug message with password=supersecret');
  loggerRelease.info('This is an info message with token=abc12345');
  if (loggerRelease.logs.length === 0) {
    passed++;
    console.log('  [PASS] debug() and info() are 100% suppressed in release mode.');
  } else {
    failed++;
    console.log(`  [FAIL] debug()/info() emitted logs in release mode: ${loggerRelease.logs}`);
  }

  // Test stack trace suppression in release mode
  loggerRelease.logs = [];
  const fakeStackTrace = 'Error\n    at Object.test (/some/internal/path/file.dart:42:15)';
  loggerRelease.warning('Warning in release', 'Some error', fakeStackTrace);
  loggerRelease.error('Error in release', 'Some error', fakeStackTrace);
  const releaseLogs = loggerRelease.logs.join('\n');
  if (!releaseLogs.includes('file.dart:42:15') && !releaseLogs.includes('[WARN STACK]') && !releaseLogs.includes('[ERROR STACK]')) {
    passed++;
    console.log('  [PASS] Stack traces are completely suppressed in release mode.');
  } else {
    failed++;
    console.log(`  [FAIL] Stack trace LEAKED in release mode: ${releaseLogs}`);
  }

  // 5. Test Debug Mode StackTrace Preservation
  loggerDebug.logs = [];
  loggerDebug.warning('Warning in debug', 'Some error', fakeStackTrace);
  const debugLogs = loggerDebug.logs.join('\n');
  if (debugLogs.includes('file.dart:42:15') && debugLogs.includes('[WARN STACK]')) {
    passed++;
    console.log('  [PASS] Stack traces are preserved for debugging in non-release mode.');
  } else {
    failed++;
    console.log(`  [FAIL] Stack trace missing in debug mode: ${debugLogs}`);
  }

  console.log('\n' + '='.repeat(60));
  console.log(`SAFE_LOGGER ADVERSARIAL RESULTS: ${passed} PASSED, ${failed} FAILED`);
  console.log('='.repeat(60));

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
