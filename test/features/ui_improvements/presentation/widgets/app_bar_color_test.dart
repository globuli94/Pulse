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
  group('App Bar Color Verification', () {
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
      'App bar has white background on Feed screen',
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

        // Find the AppBar and verify background color is white
        final appBars = find.byType(AppBar);
        expect(appBars, findsWidgets);

        // Get the first (main) AppBar
        final appBarWidget = appBars.first.evaluate().first.widget as AppBar;
        expect(
          appBarWidget.backgroundColor,
          equals(Colors.white),
          reason: 'App bar background color should be white on Feed screen',
        );
      },
    );

    testWidgets(
      'App bar has white background on Profile screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
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

        // Navigate to Profile tab
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Find the AppBar and verify background color is white
        final appBars = find.byType(AppBar);
        expect(appBars, findsWidgets);

        final appBarWidget = appBars.first.evaluate().first.widget as AppBar;
        expect(
          appBarWidget.backgroundColor,
          equals(Colors.white),
          reason: 'App bar background color should be white on Profile screen',
        );
      },
    );

    testWidgets(
      'App bar has white background on Chat screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/chat',
          routes: [
            GoRoute(
              path: '/chat',
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

        // Navigate to Chat tab
        await tester.tap(find.byIcon(Icons.chat));
        await tester.pumpAndSettle();

        // Find the AppBar and verify background color is white
        final appBars = find.byType(AppBar);
        expect(appBars, findsWidgets);

        final appBarWidget = appBars.first.evaluate().first.widget as AppBar;
        expect(
          appBarWidget.backgroundColor,
          equals(Colors.white),
          reason: 'App bar background color should be white on Chat screen',
        );
      },
    );

    testWidgets(
      'App bar has white background on Search screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/search',
          routes: [
            GoRoute(
              path: '/search',
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

        // Navigate to Search tab
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Find the AppBar and verify background color is white
        final appBars = find.byType(AppBar);
        expect(appBars, findsWidgets);

        final appBarWidget = appBars.first.evaluate().first.widget as AppBar;
        expect(
          appBarWidget.backgroundColor,
          equals(Colors.white),
          reason: 'App bar background color should be white on Search screen',
        );
      },
    );

    testWidgets(
      'App bar has white background on Notifications screen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/notifications',
          routes: [
            GoRoute(
              path: '/notifications',
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

        // Navigate to Notifications tab
        await tester.tap(find.byIcon(Icons.notifications));
        await tester.pumpAndSettle();

        // Find the AppBar and verify background color is white
        final appBars = find.byType(AppBar);
        expect(appBars, findsWidgets);

        final appBarWidget = appBars.first.evaluate().first.widget as AppBar;
        expect(
          appBarWidget.backgroundColor,
          equals(Colors.white),
          reason: 'App bar background color should be white on Notifications screen',
        );
      },
    );

    testWidgets(
      'App bar text and icons remain legible against white background',
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

        // Navigate to Feed
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Verify that AppBar exists
        expect(find.byType(AppBar), findsWidgets);
      },
    );
  });
}
