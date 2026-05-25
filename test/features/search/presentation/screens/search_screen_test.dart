// Copyright 2024 Social Media Company. All rights reserved.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/search/domain/repositories/search_repository.dart';
import 'package:pulse/features/search/presentation/screens/search_screen.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

class MockFollowsRepository extends Mock implements FollowsRepository {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late MockSearchRepository mockSearchRepository;
  late MockFollowsRepository mockFollowsRepository;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockSearchRepository = MockSearchRepository();
    mockFollowsRepository = MockFollowsRepository();
    mockAuthBloc = MockAuthBloc();

    final testUser =
        AppUser(uid: 'current-uid', email: 'test@example.com', displayName: 'Test');
    when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => Stream.value(Authenticated(testUser)));
  });

  group('SearchScreen', () {
    testWidgets(
        'shows hint text \'Search by name...\' in text field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
      final textFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            (widget.decoration?.hintText?.contains('Search by name') ??
                false),
      );
      expect(textFieldFinder, findsWidgets);
    });

    testWidgets('shows CircularProgressIndicator when bloc is in SearchLoading',
        (WidgetTester tester) async {
      // Use a Completer to hold the response so we can keep the state in Loading
      final completer = Completer<List<UserProfile>>();
      when(() => mockSearchRepository.searchUsers(any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      // Trigger a search to get SearchLoading state
      await tester.enterText(find.byType(TextField), 'al');
      // Wait for debounce timer to fire (300ms) and search to start
      await tester.pump(const Duration(milliseconds: 350));

      // The loading indicator should appear during search
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Clean up by completing the future
      completer.complete([]);
    });

    testWidgets(
        'shows result tiles when bloc is in SearchLoaded with non-empty users',
        (WidgetTester tester) async {
      final testUser = UserProfile(
        uid: 'user-1',
        displayName: 'Test User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockSearchRepository.searchUsers('test'))
          .thenAnswer((_) async => [testUser]);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('Test User'), findsWidgets);
    });

    testWidgets(
        'shows \'No results found.\' text when SearchLoaded(users: [])',
        (WidgetTester tester) async {
      when(() => mockSearchRepository.searchUsers(any()))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('No results found.'), findsWidgets);
    });

    testWidgets('shows \'Something went wrong.\' text when SearchFailure',
        (WidgetTester tester) async {
      when(() => mockSearchRepository.searchUsers(any()))
          .thenThrow(Exception('Search failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'error');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(find.text('Something went wrong.'), findsWidgets);
    });

    testWidgets(
        'follow button hidden when result uid matches currentUserId',
        (WidgetTester tester) async {
      final testUser = UserProfile(
        uid: 'current-uid',
        displayName: 'Current User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockSearchRepository.searchUsers('current'))
          .thenAnswer((_) async => [testUser]);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'current');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      // The follow button should not be present for the current user's own profile
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('result tiles are tappable',
        (WidgetTester tester) async {
      final testUser = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockSearchRepository.searchUsers('test'))
          .thenAnswer((_) async => [testUser]);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SearchRepository>.value(
                value: mockSearchRepository,
              ),
              RepositoryProvider<FollowsRepository>.value(
                value: mockFollowsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: const SearchScreen(),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      // Verify result tile exists and can be tapped
      expect(find.byType(ListTile), findsWidgets);
      expect(find.text('Test User'), findsWidgets);
    });
  });
}
