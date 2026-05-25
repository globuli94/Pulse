// Copyright 2024 Social Media Company. All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/follows/presentation/bloc/follow_bloc.dart';
import 'package:pulse/features/search/presentation/widgets/user_search_result_tile.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';

class MockFollowsRepository extends Mock implements FollowsRepository {}

void main() {
  late MockFollowsRepository mockFollowsRepository;
  late UserProfile testUser;

  setUpAll(() {
    registerFallbackValue(const FollowStatusCheckRequested(
      followerId: 'fallback-follower',
      followeeId: 'fallback-followee',
    ));
  });

  setUp(() {
    mockFollowsRepository = MockFollowsRepository();
    testUser = UserProfile(
      uid: 'test-uid',
      displayName: 'Test User',
      bio: 'Test bio',
      avatarUrl: null,
      postCount: 0,
      followerCount: 10,
      followingCount: 5,
    );
  });

  group('UserSearchResultTile', () {
    testWidgets(
        'shows CircularProgressIndicator when FollowBloc is in FollowLoading',
        (WidgetTester tester) async {
      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: testUser,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      // Initially FollowBloc is in FollowLoading state waiting for status check
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets(
        'shows Follow button when FollowLoaded(isFollowing: false)',
        (WidgetTester tester) async {
      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: testUser,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Follow'), findsWidgets);
    });

    testWidgets(
        'shows Unfollow button when FollowLoaded(isFollowing: true)',
        (WidgetTester tester) async {
      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: testUser,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unfollow'), findsWidgets);
    });

    testWidgets(
        'shows Retry button when FollowFailure',
        (WidgetTester tester) async {
      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: testUser,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsWidgets);
    });

    testWidgets(
        'dispatches FollowRequested when Follow button tapped',
        (WidgetTester tester) async {
      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => false);
      when(() => mockFollowsRepository.followUser(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: testUser,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Follow'));
      await tester.pump();

      verify(() => mockFollowsRepository.followUser(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).called(1);
    });

    testWidgets(
        'dispatches UnfollowRequested when Unfollow button tapped',
        (WidgetTester tester) async {
      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => true);
      when(() => mockFollowsRepository.unfollowUser(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: testUser,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Unfollow'));
      await tester.pump();

      verify(() => mockFollowsRepository.unfollowUser(
            followerId: 'current-uid',
            followeeId: 'test-uid',
          )).called(1);
    });

    testWidgets(
        'follow button absent when user.uid == currentUserId',
        (WidgetTester tester) async {
      final currentUserProfile = UserProfile(
        uid: 'current-uid',
        displayName: 'Current User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockFollowsRepository.isFollowing(
            followerId: 'current-uid',
            followeeId: 'current-uid',
          )).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepositoryProvider<FollowsRepository>.value(
              value: mockFollowsRepository,
              child: UserSearchResultTile(
                user: currentUserProfile,
                currentUserId: 'current-uid',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No follow/unfollow button should be visible for the current user
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Unfollow'), findsNothing);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
