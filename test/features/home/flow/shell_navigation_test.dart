import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/home/presentation/screens/shell_screen.dart';
import 'package:pulse/features/feed/presentation/screens/feed_screen.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}

void main() {
  group('Navigation Shell - Flow Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockProfileBloc mockProfileBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockProfileBloc = MockProfileBloc();
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      // Mock authenticated state
      when(() => mockAuthBloc.state).thenReturn(
        Authenticated(testUser),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          Authenticated(testUser),
        ),
      );
      // Mock profile state
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    testWidgets(
      'ShellScreen renders BottomNavigationBar with Feed and Profile tabs',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            // Simulate authenticated state for this test
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Verify BottomNavigationBar is present
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Verify "Feed" tab is present
        expect(find.text('Feed'), findsOneWidget);

        // Verify "Profile" tab is present
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Profile tab shows ProfileScreen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Tap the Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pump();

        // Verify ProfileScreen is displayed
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Feed tab shows FeedScreen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // First tap Profile to switch away from Feed
        await tester.tap(find.text('Profile'));
        await tester.pump();

        // Now tap Feed tab
        await tester.tap(find.text('Feed'));
        await tester.pump();

        // Verify FeedScreen is displayed
        expect(find.byType(FeedScreen), findsOneWidget);
      },
    );
  });
}
