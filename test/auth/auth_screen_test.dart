import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/screens/auth_screen.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/widgets/password_text_field.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/rate_limiter_notifier.dart';

void main() {
  group('AuthScreen Widget Tests', () {
    testWidgets('renders Cyber UI branding, dual tabs, and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Branding
      expect(find.text('BRAINROT TRACKER PRO'), findsOneWidget);
      expect(find.text('Anti-Doomscroll Defense Protocol'), findsOneWidget);

      // Check Tabs
      expect(find.byKey(const Key('auth_tab_sign_in')), findsOneWidget);
      expect(find.byKey(const Key('auth_tab_sign_up')), findsOneWidget);

      // Check Initial Sign In Form Fields
      expect(find.byKey(const Key('sign_in_email_field')), findsOneWidget);
      expect(find.byKey(const Key('sign_in_password_field')), findsOneWidget);
      expect(find.byKey(const Key('sign_in_submit_button')), findsOneWidget);

      // Check Quick Access Buttons
      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
      expect(find.byKey(const Key('guest_sign_in_button')), findsOneWidget);
    });

    testWidgets('password field toggles obscure text on eye icon press', (tester) async {
      final controller = TextEditingController(text: 'SecretPass123!');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordTextField(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final toggleFinder = find.byKey(const Key('password_visibility_toggle'));
      expect(toggleFinder, findsOneWidget);

      // Initially obscured (visibility_off icon)
      expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

      // Tap toggle to reveal
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Now revealed (visibility icon)
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });

    testWidgets('displays lockout banner when RateLimiter is locked', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final rateLimiterNotifier = container.read(rateLimiterProvider.notifier);

      // Force 5 failed attempts to lock out
      for (int i = 0; i < 5; i++) {
        rateLimiterNotifier.recordFailure();
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('lockout_banner')), findsOneWidget);
      expect(find.textContaining('SECURITY LOCKOUT ACTIVE'), findsOneWidget);
      expect(find.textContaining('Cooldown:'), findsOneWidget);
    });

    testWidgets('switches to Sign Up tab when tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign Up Tab
      await tester.tap(find.byKey(const Key('auth_tab_sign_up')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign_up_name_field')), findsOneWidget);
      expect(find.byKey(const Key('sign_up_email_field')), findsOneWidget);
      expect(find.byKey(const Key('sign_up_password_field')), findsOneWidget);
      expect(find.byKey(const Key('sign_up_submit_button')), findsOneWidget);
      expect(find.text('Password Requirements:'), findsOneWidget);
    });
  });
}
