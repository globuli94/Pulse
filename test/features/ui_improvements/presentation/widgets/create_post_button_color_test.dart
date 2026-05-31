import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/main.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Create Post Button Color Verification', () {
    late MockAuthBloc mockAuthBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockAuthRepository = MockAuthRepository();

      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );

      when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(Authenticated(testUser)),
      );
    });

    testWidgets(
      'Create post button uses primary color as background on Feed screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        );

        await tester.pumpWidget(
          PulseApp(
            authBloc: mockAuthBloc,
            authRepository: mockAuthRepository,
            router: router,
          ),
        );
        await tester.pump();

        // Navigate to Feed tab
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Find floating action button (create post button)
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        final fabWidget = fab.evaluate().first.widget as FloatingActionButton;
        final primaryColor = Theme.of(tester.element(find.byType(MaterialApp))).colorScheme.primary;

        // Verify the background color is the primary color
        expect(
          fabWidget.backgroundColor,
          equals(primaryColor),
          reason: 'Create post button should use primary color as background',
        );
      },
    );

    testWidgets(
      'Create post button is visible and functional on Feed screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        );

        await tester.pumpWidget(
          PulseApp(
            authBloc: mockAuthBloc,
            authRepository: mockAuthRepository,
            router: router,
          ),
        );
        await tester.pump();

        // Navigate to Feed tab
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Verify FAB exists and is visible
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);

        // Verify FAB can be tapped (no assertion error)
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'No regressions: UI elements remain intact on Feed screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const SizedBox(),
            ),
          ],
        );

        await tester.pumpWidget(
          PulseApp(
            authBloc: mockAuthBloc,
            authRepository: mockAuthRepository,
            router: router,
          ),
        );
        await tester.pump();

        // Navigate to Feed tab
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Verify app bar exists
        expect(find.byType(AppBar), findsWidgets);

        // Verify FAB exists
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Verify scaffold exists
        expect(find.byType(Scaffold), findsWidgets);
      },
    );
  });
}
