// test/features/home/flow/shell_navigation_test.dart
//
// Shell navigation flow tests — verifies the BottomNavigationBar
// and IndexedStack work correctly across Feed and Profile tabs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/home/presentation/screens/shell_screen.dart';
import 'package:pulse/features/feed/presentation/screens/feed_screen.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockProfileBloc extends Mock implements ProfileBloc {}

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

      when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(Authenticated(testUser)),
      );

      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileInitial()),
      );
    });

    Widget buildTestApp() {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const ShellScreen(),
          ),
        ],
      );

      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'ShellScreen renders BottomNavigationBar with Feed and Profile tabs',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Feed'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Profile tab shows ProfileScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        await tester.tap(find.text('Profile'));
        await tester.pump();

        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Feed tab shows FeedScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pump();

        await tester.tap(find.text('Profile'));
        await tester.pump();

        await tester.tap(find.text('Feed'));
        await tester.pump();

        expect(find.byType(FeedScreen), findsOneWidget);
      },
    );
  });
}
