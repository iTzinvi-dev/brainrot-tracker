import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/features/auth/data/mock_auth_repository.dart';
import 'package:brainrot_tracker_pro/features/auth/domain/auth_user.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/auth_controller.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/auth_state.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/screens/auth_screen.dart';
import 'package:brainrot_tracker_pro/main.dart';

void main() {
  group('Auth Routing Gate Tests', () {
    testWidgets('unauthenticated state displays AuthScreen', (tester) async {
      final mockRepo = MockAuthRepository(seedDevAccount: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(MainNavigationShell), findsNothing);
    });

    testWidgets('authenticated user state routes to MainNavigationShell', (tester) async {
      final authenticatedUser = AuthUser(
        id: 'usr_authenticated_42',
        email: 'operative42@brainrot.app',
        displayName: 'Operative 42',
        isGuest: false,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            final mockRepo = MockAuthRepository(seedDevAccount: false);
            final controller = AuthController(authRepository: mockRepo, ref: ref);
            controller.state = AuthState(
              status: AuthStatus.authenticated,
              user: authenticatedUser,
            );
            return controller;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.text('OPERATIVE 42'), findsOneWidget);
    });

    testWidgets('guest user routes to MainNavigationShell with upgrade button', (tester) async {
      final guestUser = AuthUser.guest(id: 'guest_test_999');

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith((ref) {
            final mockRepo = MockAuthRepository(seedDevAccount: false);
            final controller = AuthController(authRepository: mockRepo, ref: ref);
            controller.state = AuthState(
              status: AuthStatus.authenticated,
              user: guestUser,
            );
            return controller;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationShell), findsOneWidget);
      expect(find.text('GUEST OPERATIVE'), findsOneWidget);
      expect(find.text('UPGRADE'), findsOneWidget);
    });
  });
}
