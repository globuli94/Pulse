// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/presentation/bloc/follow_bloc.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/user_profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/user_profile_view_screen.dart';

class MockUserProfileBloc extends MockBloc<UserProfileEvent, UserProfileState>
    implements UserProfileBloc {}

class MockFollowBloc extends MockBloc<FollowEvent, FollowState>
    implements FollowBloc {}

void main() {
  late MockUserProfileBloc mockUserProfileBloc;
  late MockFollowBloc mockFollowBloc;

  setUpAll(() {
    registerFallbackValue(const FollowStatusCheckRequested(
      followerId: 'fallback-follower',
      followeeId: 'fallback-followee',
    ));
  });

  setUp(() {
    mockUserProfileBloc = MockUserProfileBloc();
    mockFollowBloc = MockFollowBloc();
    // Ensure the mock blocs have proper initial states
    whenListen(
      mockUserProfileBloc,
      Stream.value(const UserProfileLoading()),
      initialState: const UserProfileLoading(),
    );
    whenListen(
      mockFollowBloc,
      Stream.value(const FollowInitial()),
      initialState: const FollowInitial(),
    );
  });

  group('UserProfileViewScreen', () {
    testWidgets('shows loading state with CircularProgressIndicator',
        (WidgetTester tester) async {
      when(() => mockUserProfileBloc.state)
          .thenReturn(const UserProfileLoading());
      when(() => mockFollowBloc.state).thenReturn(const FollowInitial());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays user display name when loaded',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'John Doe',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsWidgets);
    });

    testWidgets(
        'displays followerCount and followingCount when loaded',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Jane Doe',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 42,
        followingCount: 7,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.textContaining('42'), findsWidgets);
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets(
        'shows Follow button when viewing other user and not following',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User To Follow',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Follow'), findsWidgets);
    });

    testWidgets(
        'shows Unfollow button when viewing other user and already following',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Already Following',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 50,
        followingCount: 30,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: true));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'Unfollow'), findsWidgets);
    });

    testWidgets('hides follow button on own profile',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'current-uid',
        displayName: 'My Profile',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 20,
        followingCount: 15,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'current-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.text('Follow'), findsNothing);
      expect(find.text('Unfollow'), findsNothing);
    });

    testWidgets('shows loading indicator when FollowBloc is loading',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state).thenReturn(const FollowLoading());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows Retry button when FollowBloc fails',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowFailure(error: 'Network error'));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsWidgets);
    });

    testWidgets('dispatches FollowRequested when Follow button tapped',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User To Follow',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Follow').first);
      await tester.pump();

      verify(() => mockFollowBloc.add(any(
          that: isA<FollowRequested>()
              .having((e) => e.followerId, 'followerId', 'current-uid')
              .having((e) => e.followeeId, 'followeeId', 'other-uid'))))
          .called(1);
    });

    testWidgets('dispatches UnfollowRequested when Unfollow button tapped',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Already Following',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 50,
        followingCount: 30,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: true));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
            BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          ],
          child: const MaterialApp(
            home: UserProfileViewScreen(
              viewedUid: 'other-uid',
              currentUserId: 'current-uid',
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Unfollow').first);
      await tester.pump();

      verify(() => mockFollowBloc.add(any(
          that: isA<UnfollowRequested>()
              .having((e) => e.followerId, 'followerId', 'current-uid')
              .having((e) => e.followeeId, 'followeeId', 'other-uid'))))
          .called(1);
    });
  });
}
